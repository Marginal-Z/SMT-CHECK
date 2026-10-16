import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models.dart';
import 'services/background_tasks.dart';
import 'services/ai_service.dart';
import 'services/report_export.dart';
import 'ui/design.dart';
import 'ui/results.dart';
import 'ui/localized_text.dart';
import 'l10n/localization.dart';

class SmtCheckApp extends StatefulWidget {
  final List<String> arguments;
  final bool persist;
  final CheckReport? initialReport;
  final String initialLanguage;
  final Future<ImportedFile> Function(String, InputKind, String)?
  workbookLoader;
  const SmtCheckApp({
    super.key,
    this.arguments = const [],
    this.persist = true,
    this.initialReport,
    this.initialLanguage = 'zh',
    this.workbookLoader,
  });
  @override
  State<SmtCheckApp> createState() => _SmtCheckAppState();
}

class _SmtCheckAppState extends State<SmtCheckApp> {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  final navigator = GlobalKey<NavigatorState>();
  final keywordController = TextEditingController();
  final url = TextEditingController(),
      model = TextEditingController(),
      apiKey = TextEditingController();
  ImportedFile? bom, a, b;
  CheckReport? report;
  CheckItem? selected;
  var rules = const CheckRules();
  bool dark = false,
      merged = true,
      busy = false,
      aiBusy = false,
      settingsLoaded = false;
  int page = 0;
  int sessionEpoch = 0;
  late String language;
  String aiText = '', activity = '就绪 · 文件在本机核对', error = '';
  SharedPreferences? prefs;
  AiService? activeAi;
  @override
  void initState() {
    super.initState();
    language = widget.initialLanguage;
    report = widget.initialReport;
    if (report != null) {
      bom = report!.files.first;
      a = report!.files[1];
      b = report!.files.length > 2 ? report!.files[2] : null;
      merged = report!.merged;
    }
    keywordController.text = rules.keywords.join('\n');
    unawaited(initialize());
  }

  Future<void> initialize() async {
    if (widget.persist) {
      try {
        prefs = await SharedPreferences.getInstance();
        dark = prefs!.getBool('dark') ?? false;
        final savedLanguage = prefs!.getString('language');
        if (supportedLanguages.contains(savedLanguage)) {
          language = savedLanguage!;
        }
        rules = CheckRules(
          excludeEnabled: prefs!.getBool('exclude') ?? true,
          keywords:
              prefs!.getStringList('keywords') ?? const CheckRules().keywords,
        );
        keywordController.text = rules.keywords.join('\n');
        url.text = prefs!.getString('aiUrl') ?? '';
        model.text = prefs!.getString('aiModel') ?? '';
      } catch (_) {
        activity = '设置存储不可用 · 当前会话仍可核对';
      }
    }
    settingsLoaded = true;
    if (!mounted) return;
    setState(() {});
    if (widget.arguments.isNotEmpty) await importArguments();
  }

  Future<void> importArguments() async {
    final epoch = sessionEpoch;
    for (final (flag, slot) in [('--bom', 0), ('--a', 1), ('--b', 2)]) {
      if (!mounted || epoch != sessionEpoch) return;
      final index = widget.arguments.indexOf(flag);
      if (index >= 0 && index + 1 < widget.arguments.length) {
        await loadPath(widget.arguments[index + 1], slot);
      }
    }
    if (epoch == sessionEpoch && bom != null && a != null) {
      setState(() => merged = b != null);
      await runCheck();
    }
  }

  @override
  void dispose() {
    activeAi?.close();
    keywordController.dispose();
    url.dispose();
    model.dispose();
    apiKey.dispose();
    super.dispose();
  }

  void notify(String text) {
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: LText(translate(text, language)),
        backgroundColor: const Color(0xFF282828),
      ),
    );
  }

  void invalidate() {
    report = null;
    selected = null;
    aiText = '';
    error = '';
  }

  void clearSession() {
    sessionEpoch++;
    activeAi?.close();
    activeAi = null;
    setState(() {
      bom = null;
      a = null;
      b = null;
      busy = false;
      aiBusy = false;
      invalidate();
      page = 0;
      activity = '已清空，可重新导入文件';
    });
  }

  Future<void> changeLanguage(String value) async {
    setState(() => language = value);
    try {
      await prefs?.setString('language', value);
    } catch (_) {
      notify('语言已切换，持久保存失败');
    }
  }

  Future<void> loadPath(String path, int slot) async {
    final epoch = sessionEpoch;
    setState(() {
      busy = true;
      error = '';
      activity = '正在解析原始工作簿…';
    });
    try {
      final imported =
          await (widget.workbookLoader ?? readWorkbookInBackground)(
            path,
            slot == 0 ? InputKind.bom : InputKind.station,
            slot == 1
                ? (merged ? 'A' : '单表')
                : slot == 2
                ? 'B'
                : '',
          );
      if (!mounted || epoch != sessionEpoch) return;
      setState(() {
        if (slot == 0) {
          bom = imported;
        } else if (slot == 1) {
          a = imported;
        } else {
          b = imported;
        }
        invalidate();
        activity = '已导入 ${imported.name} · ${imported.rows.length} 行';
      });
    } catch (e) {
      if (mounted && epoch == sessionEpoch) {
        setState(() {
          error = '导入失败：$e';
          activity = '导入失败';
        });
      }
    } finally {
      if (mounted && epoch == sessionEpoch) setState(() => busy = false);
    }
  }

  Future<void> pick(int slot) async {
    try {
      final file = await openFile(
        confirmButtonText: translate('导入', language),
        acceptedTypeGroups: [
          XTypeGroup(
            label: translate('Excel 工作簿', language),
            extensions: ['xlsx'],
            uniformTypeIdentifiers: ['org.openxmlformats.spreadsheetml.sheet'],
          ),
        ],
      );
      if (file != null) await loadPath(file.path, slot);
    } catch (e) {
      if (mounted) setState(() => error = '文件选择失败：$e');
    }
  }

  Future<void> runCheck() async {
    if (busy) return;
    final epoch = sessionEpoch;
    if (bom == null || a == null || (merged && b == null)) {
      notify(merged ? '请先导入 BOM、站位表 A 和 B' : '请先导入 BOM 和一份站位表');
      return;
    }
    setState(() => busy = true);
    final inputBom = bom!,
        inputStations = [a!, if (merged) b!],
        inputRules = rules;
    try {
      final result = await checkInBackground(
        inputBom,
        inputStations,
        inputRules,
      );
      if (!mounted || epoch != sessionEpoch) return;
      setState(() {
        report = result;
        selected = null;
        aiText = '';
        error = '';
        page = 0;
        activity =
            '核对完成 · ${result.count(CheckStatus.pass)} 项一致 / ${result.errors.length} 项异常';
      });
    } catch (e) {
      if (mounted && epoch == sessionEpoch) setState(() => error = '核对失败：$e');
    } finally {
      if (mounted && epoch == sessionEpoch) setState(() => busy = false);
    }
  }

  Future<void> saveRules() async {
    final words = keywordController.text
        .split(RegExp(r'[\n,，;；]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      rules = CheckRules(excludeEnabled: rules.excludeEnabled, keywords: words);
      invalidate();
    });
    try {
      await prefs?.setStringList('keywords', words);
      await prefs?.setBool('exclude', rules.excludeEnabled);
    } catch (_) {
      notify('规则已应用，持久保存失败');
    }
    if (bom != null && a != null && (!merged || b != null)) {
      await runCheck();
    } else {
      notify('排除规则已保存');
    }
  }

  Future<void> saveAi() async {
    try {
      AiConfig(
        baseUrl: url.text,
        model: model.text,
        apiKey: apiKey.text,
      ).endpoint;
      await prefs?.setString('aiUrl', url.text.trim());
      await prefs?.setString('aiModel', model.text.trim());
      notify('接口和模型已保存，密钥仅在当前会话使用');
    } catch (e) {
      notify('保存失败：$e');
    }
  }

  Future<void> askAi({bool test = false, CheckItem? item}) async {
    final epoch = sessionEpoch;
    if (!test && report == null) {
      notify('请先完成一次核对');
      return;
    }
    final config = AiConfig(
      baseUrl: url.text,
      model: model.text,
      apiKey: apiKey.text,
    );
    try {
      config.endpoint;
    } catch (e) {
      setState(() => page = 2);
      notify(e.toString());
      return;
    }
    if (aiBusy) return;
    final currentReport = report;
    setState(() => page = 2);
    if (!test) {
      final proceed = await showDialog<bool>(
        context: navigator.currentState!.overlay!.context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LText(
                    '发送异常数据至 AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  LText(
                    '接收地址：${config.endpoint.host}\n将发送${item == null ? '最多前 40 项异常' : '当前料号 ${item.part}'}的料号、描述、数量、位号及来源行号。原始 Excel 文件不会上传。',
                    style: const TextStyle(height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [
                      DeskButton(
                        '发送并分析',
                        primary: true,
                        onPressed: () => Navigator.pop(context, true),
                      ),
                      DeskButton(
                        '取消',
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (proceed != true || !mounted || epoch != sessionEpoch) return;
    }
    setState(() {
      aiBusy = true;
      aiText = test ? '正在测试连接…' : '正在分析异常…';
    });
    final service = AiService();
    activeAi = service;
    try {
      final text = await service.complete(
        config,
        report: test ? null : currentReport,
        item: item,
        language: language,
      );
      if (mounted &&
          epoch == sessionEpoch &&
          (test || identical(report, currentReport))) {
        setState(() => aiText = text);
      }
    } catch (e) {
      if (mounted &&
          epoch == sessionEpoch &&
          (test || identical(report, currentReport))) {
        setState(() => aiText = '调用失败：$e\n请核对接口地址、模型、密钥与网络；规则核对结果仍然保留。');
      }
    } finally {
      service.close();
      if (identical(activeAi, service)) activeAi = null;
      if (mounted && epoch == sessionEpoch) setState(() => aiBusy = false);
    }
  }

  Future<void> export(bool json) async {
    if (report == null) return;
    final snapshot = report!;
    try {
      final ext = json ? 'json' : 'csv';
      final location = await getSaveLocation(
        confirmButtonText: translate('保存', language),
        suggestedName:
            'SMT-CHECK-${snapshot.created.toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.$ext',
        acceptedTypeGroups: [
          XTypeGroup(
            label: ext.toUpperCase(),
            extensions: [ext],
            uniformTypeIdentifiers: [
              json ? 'public.json' : 'public.comma-separated-values-text',
            ],
          ),
        ],
      );
      if (location == null) return;
      await File(location.path).writeAsBytes(
        utf8.encode(
          json
              ? ReportExport.json(snapshot, language: language)
              : ReportExport.csv(snapshot, language: language),
        ),
        flush: true,
      );
      notify('报告已导出：${location.path}');
    } catch (e) {
      notify('导出失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    title: 'SMT-CHECK',
    debugShowCheckedModeBanner: false,
    theme: desktopTheme(dark),
    locale: Locale(language),
    supportedLocales: const [Locale('zh'), Locale('en'), Locale('th')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    scaffoldMessengerKey: messenger,
    home: Builder(
      builder: (context) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
              unawaited(runCheck()),
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
              unawaited(pick(0)),
          const SingleActivator(LogicalKeyboardKey.keyE, control: true): () =>
              unawaited(export(false)),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              clearSession,
        },
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1000,
                  p = Palette.of(context);
              return Row(
                children: [
                  sidebar(context, compact),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 68,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: p.panel,
                            border: Border(bottom: BorderSide(color: p.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    LText(
                                      [
                                        '核对工作台',
                                        '导入与规则',
                                        'AI 异常分析',
                                        '使用说明',
                                      ][page],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (constraints.maxWidth > 650)
                                      caption(
                                        context,
                                        'T100 BOM  /  SMT 站位表  ·  双向核对',
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                key: const Key('language-selector'),
                                height: 35,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: p.line),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: language,
                                    icon: const Icon(Icons.language, size: 16),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.text,
                                      fontFamilyFallback: const [
                                        'Noto Sans Thai',
                                      ],
                                    ),
                                    items: [
                                      for (final code in supportedLanguages)
                                        DropdownMenuItem(
                                          value: code,
                                          child: Text(languageNames[code]!),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        unawaited(changeLanguage(value));
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: localText(
                                  context,
                                  dark ? '切换浅色主题' : '切换深色主题',
                                ),
                                child: DeskButton(
                                  dark ? '浅色' : '深色',
                                  icon: dark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                  onPressed: () {
                                    setState(() => dark = !dark);
                                    unawaited(prefs?.setBool('dark', dark));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(
                              constraints.maxWidth < 700 ? 12 : 22,
                            ),
                            child: page == 0
                                ? workspace(context)
                                : page == 1
                                ? rulesPage(context)
                                : page == 2
                                ? aiPage(context)
                                : helpPage(context),
                          ),
                        ),
                        Container(
                          height: 29,
                          color: p.panel,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                color: error.isNotEmpty ? bad : good,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LText(
                                  busy ? '正在处理…' : activity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: p.muted,
                                  ),
                                ),
                              ),
                              const LText(
                                'SMT-CHECK  1.2',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget sidebar(BuildContext context, bool compact) {
    final labels = ['核对工作台', '导入与规则', 'AI 异常分析', '使用说明'];
    const icons = [
      Icons.fact_check_outlined,
      Icons.tune_outlined,
      Icons.auto_awesome_outlined,
      Icons.help_outline,
    ];
    return Container(
      width: compact ? 64 : 190,
      color: const Color(0xFF151515),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: 24,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const LText(
                    'SC',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: LText(
                        'SMT-CHECK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 0, 14),
              child: LText(
                '生产工程  /  QUALITY',
                style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
              ),
            ),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              child: Tooltip(
                message: localText(context, labels[i]),
                child: Semantics(
                  button: true,
                  selected: page == i,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: page == i
                          ? Colors.white
                          : const Color(0xFFAAAAAA),
                      backgroundColor: page == i
                          ? const Color(0xFF303030)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => setState(() => page = i),
                    child: Row(
                      mainAxisAlignment: compact
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(icons[i], size: 19),
                        if (!compact) ...[
                          const SizedBox(width: 11),
                          Expanded(
                            child: LText(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (!compact)
            const Padding(
              padding: EdgeInsets.all(22),
              child: LText(
                '本地核对引擎\n原文件只读 · 来源可追溯',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 10,
                  height: 1.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget importBar(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DeskButton(
            '单站位表',
            selected: !merged,
            onPressed: busy
                ? null
                : () {
                    setState(() {
                      merged = false;
                      invalidate();
                    });
                  },
          ),
          DeskButton(
            'A + B 合并',
            selected: merged,
            onPressed: busy
                ? null
                : () {
                    setState(() {
                      merged = true;
                      invalidate();
                    });
                  },
          ),
          const SizedBox(width: 5),
          DeskButton(
            '导入 BOM',
            icon: Icons.upload_file_outlined,
            onPressed: busy ? null : () => pick(0),
          ),
          DeskButton(
            merged ? '导入站位 A' : '导入站位表',
            icon: Icons.upload_file_outlined,
            onPressed: busy ? null : () => pick(1),
          ),
          if (merged)
            DeskButton(
              '导入站位 B',
              icon: Icons.upload_file_outlined,
              onPressed: busy ? null : () => pick(2),
            ),
          DeskButton(
            busy ? '处理中…' : '开始核对',
            icon: Icons.play_arrow,
            primary: true,
            onPressed: busy || !settingsLoaded ? null : runCheck,
          ),
          DeskButton(
            '清空重来',
            key: const Key('clear-session'),
            icon: Icons.restart_alt,
            onPressed: clearSession,
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 5,
        children: [
          for (final (label, f) in [
            ('BOM', bom),
            ('A', a),
            if (merged) ('B', b),
          ])
            Tooltip(
              message: f?.path ?? localText(context, '尚未选择文件'),
              child: LText(
                '$label  ${f == null ? localText(context, '待导入') : '${f.name.length > 29 ? '${f.name.substring(0, 26)}…' : f.name}  · ${localText(context, '${f.rows.length}行')}'}',
                style: TextStyle(
                  fontSize: 11,
                  color: f == null
                      ? Palette.of(context).muted
                      : Palette.of(context).text,
                ),
              ),
            ),
        ],
      ),
      if (!merged)
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: caption(context, '单表模式对完整 BOM 核对；未覆盖另一面的料号仍列为异常。'),
        ),
      if (error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: SelectableText(
            localText(context, error),
            style: const TextStyle(color: bad, fontSize: 12),
          ),
        ),
    ],
  );
  Widget workspace(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (constraints.maxHeight - 300).clamp(
              0.0,
              constraints.maxHeight,
            ),
          ),
          child: SingleChildScrollView(child: workspaceHeader(context)),
        ),
        Expanded(
          child: report == null
              ? emptyState(context)
              : ResultsView(
                  report: report!,
                  selected: selected,
                  onSelect: (i) => setState(() => selected = i),
                  onAi: aiBusy ? null : (item) => askAi(item: item),
                  onExport: (json) => export(json),
                ),
        ),
      ],
    ),
  );
  Widget workspaceHeader(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      importBar(context),
      const SizedBox(height: 18),
      if (report != null) ...[
        Row(
          children: [
            Expanded(
              child: stat(
                context,
                '料号总数量',
                report!.totalPartCount.toString(),
                null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: stat(
                context,
                'BOM料号数量',
                report!.bomPartCount.toString(),
                null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: stat(
                context,
                'SMT站位表料号数量',
                report!.smtPartCount.toString(),
                null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        caption(
          context,
          '料号数按去重统计，含已排除和候选料；总数为 BOM 与 SMT 并集，A+B 相同料号只计一次，空料号不计。',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 6,
          children: [
            for (final (label, status, color) in [
              ('一致料号', CheckStatus.pass, good),
              ('异常料号', CheckStatus.error, bad),
              ('排除记录', CheckStatus.excluded, Palette.of(context).muted),
              ('候选料记录', CheckStatus.candidate, Palette.of(context).muted),
            ])
              LText(
                '${localText(context, label)}  ${report!.count(status)}',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
  Widget stat(BuildContext context, String label, String value, Color? color) =>
      Container(
        key: ValueKey('stat-$label'),
        child: Pane(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: LText(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Palette.of(context).muted,
                  ),
                ),
              ),
              LText(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
  Widget emptyState(BuildContext context) => Pane(
    child: Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 610),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 40,
                color: Palette.of(context).muted,
              ),
              const SizedBox(height: 20),
              const LText(
                '从原始文件，核对每一项物料',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              caption(
                context,
                '导入 T100-BOM 与一份或两份 SMT 站位表。自动识别表头，按料号汇总，用数量和位号交叉验证。',
              ),
              const SizedBox(height: 28),
              for (final line in [
                '01   导入 BOM：料件编号 / 品名 / 组成用量 / 插件位置',
                '02   导入 SMT：料号 / 物料描述 / 数量 / 位号',
                '03   核对双向差异，逐项查看原因和原文件行号',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LText(line, style: const TextStyle(fontSize: 12)),
                ),
              const SizedBox(height: 20),
              DeskButton(
                '查看排除规则',
                icon: Icons.tune,
                onPressed: () => setState(() => page = 1),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget rulesPage(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LText(
                '非贴片物料排除规则',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  DeskButton(
                    rules.excludeEnabled ? '关键词排除：开启' : '关键词排除：关闭',
                    selected: rules.excludeEnabled,
                    onPressed: () => setState(
                      () => rules = CheckRules(
                        excludeEnabled: !rules.excludeEnabled,
                        keywords: rules.keywords,
                      ),
                    ),
                  ),
                  DeskButton(
                    '恢复默认关键词',
                    onPressed: () {
                      keywordController.text = const CheckRules().keywords.join(
                        '\n',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              caption(
                context,
                '按 BOM 品名 / SMT 物料描述包含关键词匹配，忽略大小写和空白。每行一条，也可用逗号分隔。',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: keywordController,
                minLines: 5,
                maxLines: 9,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: localText(context, '例如：锡膏\nPCB\n助焊剂\n包装材料'),
                ),
              ),
              const SizedBox(height: 12),
              caption(
                context,
                '排除记录单独显示并写入报告，注明命中词与来源。零用量且无位号的总成记录单独排除；候选替代料不自动替换 BOM 料号。',
              ),
              const SizedBox(height: 16),
              DeskButton(
                '应用规则并重新核对',
                primary: true,
                icon: Icons.check,
                onPressed: busy ? null : saveRules,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Pane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LText(
                '导入审计',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (bom == null && a == null && b == null)
                caption(context, '导入文件后显示工作表、表头映射与读取记录。'),
              for (final f in [bom, a, b].whereType<ImportedFile>()) ...[
                SelectableText(
                  f.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                for (final line in [...f.mappings, ...f.notes])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: caption(context, line),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  Widget aiPage(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LText(
                '兼容 Chat Completions 的 AI 接口',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              caption(
                context,
                '填写服务商或本地模型接口。分析前显示接收地址和发送范围；AI 建议独立显示，不改变核对状态。',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: url,
                decoration: InputDecoration(
                  labelText: localText(context, 'API 基础地址'),
                  hintText: localText(
                    context,
                    'https://服务商地址/v1 或 http://localhost:11434/v1',
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: model,
                decoration: InputDecoration(
                  labelText: localText(context, '模型名称'),
                  hintText: localText(context, '填写服务商实际支持的模型'),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: apiKey,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: localText(context, 'API Key（本地无密钥服务可留空）'),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  caption(context, '密钥仅在当前会话使用，不写入设置文件'),
                  DeskButton(
                    '保存设置',
                    icon: Icons.save_outlined,
                    onPressed: saveAi,
                  ),
                  DeskButton(
                    '测试连接',
                    onPressed: aiBusy ? null : () => askAi(test: true),
                  ),
                  DeskButton(
                    aiBusy ? '正在分析…' : '分析异常',
                    primary: true,
                    icon: Icons.auto_awesome_outlined,
                    onPressed: aiBusy || report == null ? null : () => askAi(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Pane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: LText(
                      'AI 分析结果',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DeskButton(
                    '复制',
                    icon: Icons.copy_outlined,
                    onPressed: aiText.isEmpty
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: aiText));
                            notify('分析结果已复制');
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                localText(
                  context,
                  aiText.isEmpty ? '尚未调用 AI。可先测试连接，再分析核对异常。' : aiText,
                ),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.8,
                  color: Palette.of(context).text,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget helpPage(BuildContext context) => SingleChildScrollView(
    child: Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LText(
            '核对规则与操作',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          for (final (title, body) in [
            (
              '文件与字段',
              '支持 .xlsx 原文件，自动扫描工作表寻找四个必需表头。旧版 .xls 请先另存为 .xlsx。BOM：料件编号→料号，品名→物料描述，组成用量→数量，插件位置→位号。',
            ),
            (
              '双向核对',
              '以料号关联，同料号跨站位/跨 A、B 面累计数量并合并位号；检查 BOM 缺料、SMT 多料、描述不符、数量差异、缺失/多出位号、跨行重复位号和位号归属冲突。',
            ),
            ('单表核对', '单表仍与完整 BOM 比较。另一面的料号可能没有覆盖，会明确列为异常，不能据此声称整板一致。'),
            (
              '位号解析',
              '支持逗号、空格、分号、中文分隔符和 R1-R4 / R1~R4 区间。T100 折行在数字续接或纯数字前缀处还原；无法识别的位号会报错，不静默丢弃。',
            ),
            (
              '排除与替代料',
              '关键词只匹配品名/物料描述。排除和候选替代料不会算入通过数，全部可复查。没有数量和位号的候选替代料不会自动替代主料号。',
            ),
            (
              '描述判断',
              '只忽略空白与英文大小写。±/+/数值/封装/品牌差异均保留并报告，不自动判断为等效。数量与各原始行的位号数也逐行交叉检查。',
            ),
            (
              '导出与 AI',
              'CSV 可由 Excel 打开，JSON 保留完整来源和规则。主动点击发送分析后才向所填 AI 接口发送异常数据。没有 AI 密钥也能完成本地核对。',
            ),
            (
              '快捷键',
              'Ctrl+O 导入 BOM；Ctrl+Enter 开始核对；Ctrl+E 导出 CSV。表格可横向滚动，点击料号行查看完整证据。',
            ),
          ]) ...[
            LText(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            caption(context, body),
            const SizedBox(height: 20),
          ],
        ],
      ),
    ),
  );
}
