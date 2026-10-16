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
import 'services/ai_findings.dart';
import 'services/report_export.dart';
import 'services/source_analysis.dart';
import 'ui/design.dart';
import 'ui/results.dart';
import 'ui/localized_text.dart';
import 'ui/desktop_shell.dart';
import 'ui/ai_views.dart';
import 'l10n/localization.dart';

class SmtCheckApp extends StatefulWidget {
  final List<String> arguments;
  final bool persist;
  final CheckReport? initialReport;
  final String initialLanguage;
  final ThemeAccent initialAccent;
  final Future<ImportedFile> Function(String, InputKind, String)?
  workbookLoader;
  final AiService Function()? aiServiceFactory;
  final Future<SourceAnalysisPlan> Function(
    ImportedFile,
    List<ImportedFile>,
    CheckRules,
    int,
  )?
  sourcePlanner;
  const SmtCheckApp({
    super.key,
    this.arguments = const [],
    this.persist = true,
    this.initialReport,
    this.initialLanguage = 'zh',
    this.initialAccent = ThemeAccent.black,
    this.workbookLoader,
    this.aiServiceFactory,
    this.sourcePlanner,
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
  int aiEpoch = 0, batchLimit = 24000, sourceCompleted = 0, sourceTotal = 0;
  List<SourceAnalysisBatch> sourceBatches = [];
  bool aiSourceMode = true;
  String sourceAiText = '', connectionText = '';
  List<AiFinding> sourceFindings = [];
  AiStage aiStage = AiStage.idle;
  AiStage sourceStage = AiStage.idle;
  int receivedCharacters = 0;
  DateTime? aiStartedAt;
  String sourceNotice = '';
  late String language;
  late ThemeAccent accent;
  String aiText = '', activity = '就绪 · 文件在本机核对', error = '';
  SharedPreferences? prefs;
  AiService? activeAi;
  @override
  void initState() {
    super.initState();
    language = widget.initialLanguage;
    accent = widget.initialAccent;
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
        accent =
            ThemeAccent.values
                .where((a) => a.name == prefs!.getString('accentColor'))
                .firstOrNull ??
            accent;
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
        final savedLimit = prefs!.getInt('aiBatchLimit');
        if ([12000, 24000, 48000, 96000, 120000].contains(savedLimit)) {
          batchLimit = savedLimit!;
        }
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
    stopAi();
    report = null;
    selected = null;
    aiText = '';
    sourceAiText = '';
    sourceFindings = [];
    sourceNotice = '';
    aiStage = AiStage.idle;
    sourceStage = AiStage.idle;
    receivedCharacters = 0;
    aiStartedAt = null;
    sourceCompleted = 0;
    sourceTotal = 0;
    sourceBatches = [];
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

  Future<void> changeAccent(ThemeAccent value) async {
    setState(() => accent = value);
    try {
      await prefs?.setString('accentColor', value.name);
    } catch (_) {
      notify('主题色已切换，持久保存失败');
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
    if (busy || aiBusy) return;
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
      await prefs?.setInt('aiBatchLimit', batchLimit);
      notify('接口和模型已保存，密钥仅在当前会话使用');
    } catch (e) {
      notify('保存失败：$e');
    }
  }

  bool get sourcesReady => bom != null && a != null && (!merged || b != null);
  List<ImportedFile> get sourceFiles => [?bom, ?a, if (merged && b != null) b!];
  AiConfig get aiConfig =>
      AiConfig(baseUrl: url.text, model: model.text, apiKey: apiKey.text);

  void stopAi({bool cancelled = false}) {
    aiEpoch++;
    activeAi?.close();
    activeAi = null;
    aiBusy = false;
    if (cancelled) {
      if (aiSourceMode) {
        sourceNotice = translate(
          '分析已取消，已完成 $sourceCompleted / $sourceTotal 批，结果不完整。',
          language,
        );
      } else {
        aiText += '\n${translate('分析已取消', language)}';
      }
      activity = '分析已取消';
      aiStage = AiStage.cancelled;
      if (aiSourceMode) sourceStage = AiStage.cancelled;
    }
  }

  void trackAi(int epoch, AiTransfer transfer) {
    if (!mounted || epoch != aiEpoch) return;
    if (aiStage == transfer.stage &&
        (transfer.characters - receivedCharacters).abs() < 128) {
      return;
    }
    setState(() {
      aiStage = transfer.stage;
      if (aiSourceMode) sourceStage = transfer.stage;
      receivedCharacters = transfer.characters;
    });
  }

  String safeAiError(Object error, AiConfig config) =>
      config.apiKey.trim().isEmpty
      ? error.toString()
      : error.toString().replaceAll(config.apiKey.trim(), '[已隐藏]');

  bool validateAi(AiConfig config) {
    try {
      config.endpoint;
      return true;
    } catch (e) {
      setState(() => page = 3);
      notify(e.toString());
      return false;
    }
  }

  Future<bool> confirmAi(AiConfig config, String title, String scope) async =>
      await showDialog<bool>(
        context: navigator.currentState!.overlay!.context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SelectableText(
                    '${localText(context, '接收地址')}：${config.endpoint.host}\n\n$scope',
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
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
      ) ??
      false;

  Future<void> askAi({bool test = false, CheckItem? item}) async {
    if (aiBusy) return;
    if (!test && report == null) {
      notify('请先完成一次核对');
      return;
    }
    final config = aiConfig;
    if (!validateAi(config)) return;
    final epoch = ++aiEpoch, currentReport = report, requestLanguage = language;
    AiService? service;
    setState(() {
      aiBusy = true;
      if (!test) {
        aiStage = AiStage.confirming;
        receivedCharacters = 0;
        aiStartedAt = null;
      }
      page = test ? 3 : 2;
      if (test) {
        connectionText = translate('正在测试连接…', language);
      } else {
        aiSourceMode = false;
      }
    });
    try {
      if (!test) {
        final scope = translate(
          '接收地址：${config.endpoint.host}\n将发送${item == null ? '最多前 40 项异常' : '当前料号 ${item.part}'}的料号、描述、数量、位号及来源行号。原始 Excel 文件不会上传。',
          requestLanguage,
        );
        if (!await confirmAi(config, '发送异常数据至 AI', scope) ||
            !mounted ||
            epoch != aiEpoch) {
          return;
        }
        setState(() => aiText = translate('正在分析异常…', requestLanguage));
      }
      service = (widget.aiServiceFactory ?? AiService.new)();
      activeAi = service;
      if (!test) {
        setState(() {
          aiStage = AiStage.connecting;
          aiStartedAt = DateTime.now();
        });
      }
      final text = await service.complete(
        config,
        report: test ? null : currentReport,
        item: item,
        language: requestLanguage,
        onProgress: test ? null : (transfer) => trackAi(epoch, transfer),
      );
      if (mounted &&
          epoch == aiEpoch &&
          (test || identical(report, currentReport))) {
        setState(() {
          if (test) {
            connectionText = text;
          } else {
            aiText = text;
          }
          if (!test) aiStage = AiStage.complete;
        });
      }
    } catch (e) {
      if (mounted && epoch == aiEpoch) {
        setState(() {
          final text = translate(
            '调用失败：${safeAiError(e, config)}\n请核对接口地址、模型、密钥与网络；规则核对结果仍然保留。',
            requestLanguage,
          );
          if (!test) aiStage = AiStage.failed;
          if (test) {
            connectionText = text;
          } else {
            aiText = text;
          }
        });
      }
    } finally {
      service?.close();
      if (identical(activeAi, service)) activeAi = null;
      if (mounted && epoch == aiEpoch) setState(() => aiBusy = false);
    }
  }

  Future<void> analyzeSources({bool resume = false}) async {
    if (busy || aiBusy) return;
    if (!sourcesReady) {
      notify(merged ? '请先导入 BOM、站位表 A 和 B' : '请先导入 BOM 和一份站位表');
      return;
    }
    final config = aiConfig;
    if (!validateAi(config)) return;
    final epoch = ++aiEpoch, requestLanguage = language;
    final inputBom = bom!,
        stations = [a!, if (merged) b!],
        inputRules = rules,
        limit = batchLimit;
    AiService? service;
    setState(() {
      page = 2;
      aiSourceMode = true;
      aiBusy = true;
      aiStage = AiStage.preparing;
      sourceStage = AiStage.preparing;
      aiStartedAt = null;
      receivedCharacters = 0;
      sourceNotice = '';
      if (!resume) {
        sourceCompleted = 0;
        sourceTotal = 0;
        sourceBatches = [];
        sourceAiText = '';
        sourceFindings = [];
      }
      activity = '正在准备原始文件分析…';
    });
    try {
      if (!resume) {
        final plan =
            await (widget.sourcePlanner ?? prepareSourceAnalysisInBackground)(
              inputBom,
              stations,
              inputRules,
              limit,
            );
        if (!mounted || epoch != aiEpoch) return;
        setState(() {
          sourceBatches = [...plan.batches];
          sourceTotal = sourceBatches.length;
        });
      }
      final scope = translate(
        '将发送 ${stations.length + 1} 份文件中 ${[inputBom, ...stations].fold(0, (count, file) => count + file.rows.length)} 条物料记录及全部已读取的原始单元格、表头和公式文本，共 $sourceTotal 批。包括排除料、候选料和额外工作表内容；不上传 Excel 二进制文件。',
        requestLanguage,
      );
      setState(() {
        aiStage = AiStage.confirming;
        sourceStage = AiStage.confirming;
      });
      final confirmed = await confirmAi(
        config,
        '发送原始文件内容至 AI',
        '$scope${resume ? '\n${translate('仅重试未完成批次，保留已完成结果。', requestLanguage)}' : ''}\n\n${[inputBom, ...stations].map((f) => f.name).join('\n')}',
      );
      if (!mounted || epoch != aiEpoch) return;
      if (!confirmed) {
        setState(() {
          if (!resume) {
            sourceTotal = 0;
            sourceBatches = [];
          }
          activity = '已取消发送';
          aiStage = AiStage.cancelled;
          sourceStage = AiStage.cancelled;
        });
        return;
      }
      service = (widget.aiServiceFactory ?? AiService.new)();
      activeAi = service;
      setState(() => aiStartedAt = DateTime.now());
      for (var index = sourceCompleted; index < sourceBatches.length; index++) {
        final batch = sourceBatches[index];
        setState(() {
          aiStage = AiStage.connecting;
          sourceStage = AiStage.connecting;
          receivedCharacters = 0;
        });
        List<AiFinding> findings;
        try {
          final text = await service!.analyzeSourceBatch(
            config,
            batch,
            language: requestLanguage,
            onProgress: (transfer) => trackAi(epoch, transfer),
          );
          findings = parseAiFindings(text);
        } on AiRequestException catch (e) {
          if (!mounted || epoch != aiEpoch) return;
          final smaller = e.canSplitBatch ? batch.split() : null;
          if (smaller == null) rethrow;
          service!.close();
          service = (widget.aiServiceFactory ?? AiService.new)();
          activeAi = service;
          setState(() {
            sourceBatches.replaceRange(index, index + 1, smaller);
            sourceTotal = sourceBatches.length;
            activity = '本批响应超时或超出接口限制，已自动拆小重试';
          });
          index--;
          continue;
        }
        if (!mounted || epoch != aiEpoch) return;
        setState(() {
          sourceCompleted = index + 1;
          final identities = sourceFindings.map((f) => f.identity).toSet();
          sourceFindings.addAll(
            findings.where((finding) => identities.add(finding.identity)),
          );
          sourceAiText = sourceFindings.map((f) => f.toText()).join('\n\n');
        });
      }
      if (mounted && epoch == aiEpoch) {
        setState(() {
          sourceNotice = translate(
            '全部 $sourceTotal 批分析完成。AI 结论供复核，不改变本地核对状态。',
            requestLanguage,
          );
          if (sourceFindings.isEmpty) {
            sourceAiText = translate('本次 AI 核对未发现异常', requestLanguage);
          }
          aiStage = AiStage.complete;
          sourceStage = AiStage.complete;
          activity = '原始文件 AI 核对完成';
        });
      }
    } catch (e) {
      if (mounted && epoch == aiEpoch) {
        setState(() {
          sourceNotice = translate(
            '原始文件分析中断，已完成 $sourceCompleted / $sourceTotal 批，结果不完整：${safeAiError(e, config)}',
            requestLanguage,
          );
          aiStage = AiStage.failed;
          sourceStage = AiStage.failed;
          activity = '原始文件 AI 分析失败';
        });
      }
    } finally {
      service?.close();
      if (identical(activeAi, service)) activeAi = null;
      if (mounted && epoch == aiEpoch) setState(() => aiBusy = false);
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
    theme: desktopTheme(dark, accent),
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
          body: DesktopShell(
            page: page,
            language: language,
            activity: activity,
            dark: dark,
            busy: busy || aiBusy,
            hasError: error.isNotEmpty,
            onPage: (value) => setState(() => page = value),
            onLanguage: (value) => unawaited(changeLanguage(value)),
            onTheme: () {
              setState(() => dark = !dark);
              unawaited(prefs?.setBool('dark', dark));
            },
            child: switch (page) {
              0 => workspace(context),
              1 => rulesPage(context),
              2 => aiPage(context),
              3 => settingsPage(context),
              _ => helpPage(context),
            },
          ),
        ),
      ),
    ),
  );

  Widget workspace(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (c.maxHeight - 300).clamp(0.0, c.maxHeight),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                      onPressed: busy || aiBusy
                          ? null
                          : () => setState(() {
                              merged = false;
                              invalidate();
                            }),
                    ),
                    DeskButton(
                      'A + B 合并',
                      selected: merged,
                      onPressed: busy || aiBusy
                          ? null
                          : () => setState(() {
                              merged = true;
                              invalidate();
                            }),
                    ),
                    DeskButton(
                      busy ? '处理中…' : '开始核对',
                      primary: true,
                      icon: Icons.play_arrow,
                      onPressed: busy || aiBusy || !settingsLoaded
                          ? null
                          : runCheck,
                    ),
                    DeskButton(
                      '原始文件 AI 核对',
                      icon: Icons.auto_awesome_outlined,
                      onPressed: busy || aiBusy ? null : analyzeSources,
                    ),
                    DeskButton(
                      '清空重来',
                      key: const Key('clear-session'),
                      icon: Icons.restart_alt,
                      onPressed: clearSession,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FileStrip(
                  bom: bom,
                  a: a,
                  b: b,
                  merged: merged,
                  enabled: !busy && !aiBusy,
                  onPick: (slot) => unawaited(pick(slot)),
                ),
                if (!merged)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: caption(context, '单表模式对完整 BOM 核对；未覆盖另一面的料号仍列为异常。'),
                  ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: SelectableText(
                      localText(context, error),
                      style: TextStyle(
                        color: Palette.of(context)
                            .result(CheckStatus.error)
                            .ink,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (report != null)
                  SummaryStrip(report: report!)
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
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

  Widget emptyState(BuildContext context) => Pane(
    child: Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.compare_outlined, size: 36),
              const SizedBox(height: 16),
              const LText(
                '从原始文件，核对每一项物料',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              caption(
                context,
                '导入 T100-BOM 与一份或两份 SMT 站位表。自动识别表头，按料号汇总，用数量和位号交叉验证。',
              ),
              const SizedBox(height: 20),
              const LText(
                'BOM  料件编号 · 品名 · 组成用量 · 插件位置',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const LText(
                'SMT  料号 · 物料描述 · 数量 · 位号',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              DeskButton(
                '查看排除规则',
                icon: Icons.rule_outlined,
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
                    onPressed: () => setState(() {
                      rules = CheckRules(
                        excludeEnabled: !rules.excludeEnabled,
                        keywords: rules.keywords,
                      );
                      invalidate();
                    }),
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
  Widget aiPage(BuildContext context) => AiWorkbench(
    sourceMode: aiSourceMode,
    busy: aiBusy,
    canSource: sourcesReady && !busy,
    canErrors: report != null && !busy,
    completed: sourceCompleted,
    total: sourceTotal,
    files: sourceFiles,
    result: aiSourceMode ? sourceAiText : aiText,
    findings: sourceFindings,
    stage: aiSourceMode ? sourceStage : aiStage,
    runId: aiEpoch,
    characters: receivedCharacters,
    startedAt: aiStartedAt,
    notice: aiSourceMode ? sourceNotice : '',
    onMode: (value) => setState(() => aiSourceMode = value),
    onRun: () {
      if (aiSourceMode) {
        unawaited(analyzeSources());
      } else {
        unawaited(askAi());
      }
    },
    onCancel: () => setState(() => stopAi(cancelled: true)),
    onResume:
        sourceCompleted < sourceBatches.length &&
            sourceTotal > 0 &&
            sourcesReady &&
            !busy
        ? () => unawaited(analyzeSources(resume: true))
        : null,
    onSettings: () => setState(() => page = 3),
    onCopy: () {
      Clipboard.setData(
        ClipboardData(text: aiSourceMode ? sourceAiText : aiText),
      );
      notify('分析结果已复制');
    },
  );

  Widget settingsPage(BuildContext context) => AiSettingsPanel(
    url: url,
    model: model,
    apiKey: apiKey,
    batchLimit: batchLimit,
    busy: aiBusy,
    connection: connectionText,
    accent: accent,
    onAccent: (value) => unawaited(changeAccent(value)),
    onLimit: (value) => setState(() => batchLimit = value),
    onSave: () => unawaited(saveAi()),
    onTest: () => unawaited(askAi(test: true)),
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
              'CSV 可由 Excel 打开，JSON 保留来源和规则。在设置中配置 AI 接口，可选择原始文件核对或本地异常解读。确认发送范围后才发送提取的原文或异常证据；无需 AI 也能完成本地核对。',
            ),
            (
              '快捷键',
              'Ctrl+O 导入 BOM；Ctrl+Enter 开始核对；Ctrl+E 导出 CSV；Ctrl+N 清空重来。表格可横向滚动，点击行查看证据，右侧详情可以收起。',
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
