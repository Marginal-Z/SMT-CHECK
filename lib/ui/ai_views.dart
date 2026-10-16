import 'package:flutter/material.dart';

import '../core/models.dart';
import 'design.dart';
import 'localized_text.dart';

class AiWorkbench extends StatelessWidget {
  final bool sourceMode, busy, canSource, canErrors;
  final int completed, total;
  final List<ImportedFile> files;
  final String result;
  final ValueChanged<bool> onMode;
  final VoidCallback onRun, onCancel, onSettings, onCopy;
  final VoidCallback? onResume;
  const AiWorkbench({
    super.key,
    required this.sourceMode,
    required this.busy,
    required this.canSource,
    required this.canErrors,
    required this.completed,
    required this.total,
    required this.files,
    required this.result,
    required this.onMode,
    required this.onRun,
    required this.onCancel,
    required this.onSettings,
    required this.onCopy,
    this.onResume,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DeskButton(
              '原始文件核对',
              selected: sourceMode,
              onPressed: busy ? null : () => onMode(true),
            ),
            DeskButton(
              '本地异常解读',
              selected: !sourceMode,
              onPressed: busy ? null : () => onMode(false),
            ),
            DeskButton(
              'AI 接口设置',
              icon: Icons.settings_outlined,
              onPressed: onSettings,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .28,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  caption(
                    context,
                    sourceMode
                        ? '直接读取原始单元格核对，包含排除料、候选料和额外工作表信息；无需先运行本地核对。'
                        : '依据本地核对结果解释异常；AI 建议不会改变本地核对状态。',
                  ),
                  const SizedBox(height: 8),
                  for (final f in files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${f.kind == InputKind.bom ? 'BOM' : 'SMT'}  ${f.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (files.isEmpty) caption(context, '请在核对工作台导入原始文件'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DeskButton(
                        sourceMode ? '分析原始文件' : '分析异常',
                        primary: true,
                        icon: Icons.auto_awesome_outlined,
                        onPressed: busy || !(sourceMode ? canSource : canErrors)
                            ? null
                            : onRun,
                      ),
                      if (busy) DeskButton('取消分析', onPressed: onCancel),
                      if (!busy && sourceMode && onResume != null)
                        DeskButton(
                          '重试未完成批次',
                          icon: Icons.refresh,
                          onPressed: onResume,
                        ),
                      if (sourceMode && total > 0)
                        LText(
                          '已完成 $completed / $total 批',
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (busy) ...[
          caption(context, '正在等待 AI 返回当前批次，可取消；每批最多等待 5 分钟。'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: sourceMode && total > 0 ? completed / total : null,
            minHeight: 2,
            color: p.accent,
            backgroundColor: p.line,
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: Pane(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LText(
                          sourceMode ? '原始文件 AI 核对结果' : 'AI 分析结果',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DeskButton(
                        '复制',
                        icon: Icons.copy_outlined,
                        onPressed: result.isEmpty ? null : onCopy,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: SelectableText(
                      result.isEmpty
                          ? localText(context, '尚未开始分析。配置接口后，选择分析方式并发送。')
                          : result,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.8,
                        color: p.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        caption(context, 'AI 结论仅供复核，原文件和本地核对状态不会被修改。'),
      ],
    );
  }
}

class AiSettingsPanel extends StatelessWidget {
  final TextEditingController url, model, apiKey;
  final int batchLimit;
  final bool busy;
  final String connection;
  final ValueChanged<int> onLimit;
  final ThemeAccent accent;
  final ValueChanged<ThemeAccent> onAccent;
  final VoidCallback onSave, onTest;
  const AiSettingsPanel({
    super.key,
    required this.url,
    required this.model,
    required this.apiKey,
    required this.batchLimit,
    required this.busy,
    required this.connection,
    required this.onLimit,
    required this.accent,
    required this.onAccent,
    required this.onSave,
    required this.onTest,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LText(
              '设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            caption(context, '外观与 AI 接口'),
            const SizedBox(height: 22),
            Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LText(
                    '外观',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const LText('主题色', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final choice in ThemeAccent.values)
                        Semantics(
                          selected: choice == accent,
                          child: OutlinedButton(
                            key: ValueKey('theme-color-${choice.name}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Palette.of(context).text,
                              backgroundColor: choice == accent
                                  ? Palette.of(context).accentSoft
                                  : Palette.of(context).panel,
                              side: BorderSide(
                                color: choice == accent
                                    ? Palette.of(context).accent
                                    : Palette.of(context).line,
                                width: choice == accent ? 2 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            onPressed: () => onAccent(choice),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Palette(false, choice).accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: choice == ThemeAccent.black
                                          ? Palette.of(context).muted
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                LText(
                                  choice.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (choice == accent) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check, size: 14),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  caption(context, '主题色即时生效并自动保存；一致为绿色，异常为红色。'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Pane(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LText(
                    'AI 接口',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('ai-url'),
                    controller: url,
                    decoration: InputDecoration(
                      labelText: localText(context, 'API 基础地址'),
                      hintText: 'https://example.com/v1',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('ai-model'),
                    controller: model,
                    decoration: InputDecoration(
                      labelText: localText(context, '模型名称'),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('ai-key'),
                    controller: apiKey,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: localText(context, 'API Key（本地无密钥服务可留空）'),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  caption(context, '密钥仅在当前会话使用，不写入设置文件'),
                  const SizedBox(height: 22),
                  const LText(
                    '原始文件分析分批',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  caption(context, '同料号的 BOM 和 A/B 记录放在同一批，所有批次完成才表示本次分析完整。'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    key: const Key('ai-batch-limit'),
                    initialValue: batchLimit,
                    decoration: InputDecoration(
                      labelText: localText(context, '单批原文字符上限'),
                    ),
                    items: [
                      for (final size in [12000, 24000, 48000, 96000, 120000])
                        DropdownMenuItem(value: size, child: Text('$size')),
                    ],
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v != null) onLimit(v);
                          },
                  ),
                  const SizedBox(height: 8),
                  caption(context, '原始文件较大时建议每批 12000 或 24000 字符；超时后会自动拆小重试。'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DeskButton(
                        '保存设置',
                        primary: true,
                        icon: Icons.save_outlined,
                        onPressed: busy ? null : onSave,
                      ),
                      DeskButton(
                        busy ? '处理中…' : '测试连接',
                        onPressed: busy ? null : onTest,
                      ),
                    ],
                  ),
                  if (connection.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: SelectableText(
                        connection,
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
