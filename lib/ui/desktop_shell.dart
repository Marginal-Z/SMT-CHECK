import 'package:flutter/material.dart';

import '../core/models.dart';
import '../l10n/localization.dart';
import 'design.dart';
import 'localized_text.dart';

const desktopPages = ['核对工作台', '导入与规则', 'AI 分析核对', '设置', '使用说明'];

class DesktopShell extends StatelessWidget {
  final int page;
  final String language, activity;
  final bool dark, busy, hasError;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onLanguage;
  final VoidCallback onTheme;
  final Widget child;
  const DesktopShell({
    super.key,
    required this.page,
    required this.language,
    required this.activity,
    required this.dark,
    required this.busy,
    required this.hasError,
    required this.onPage,
    required this.onLanguage,
    required this.onTheme,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 1050;
        return Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.panel,
                border: Border(bottom: BorderSide(color: p.line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    color: p.text,
                    child: Text(
                      'SC',
                      style: TextStyle(
                        color: p.panel,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: c.maxWidth < 700 ? 90 : 108,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SMT-CHECK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < desktopPages.length; i++)
                            Tooltip(
                              message: localText(context, desktopPages[i]),
                              child: Semantics(
                                selected: page == i,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: page == i
                                            ? p.text
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: page == i
                                          ? p.text
                                          : p.muted,
                                      backgroundColor: page == i
                                          ? p.hover
                                          : Colors.transparent,
                                      minimumSize: Size(compact ? 32 : 80, 44),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 6 : 14,
                                      ),
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    onPressed: () => onPage(i),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          [
                                            Icons.table_chart_outlined,
                                            Icons.rule_outlined,
                                            Icons.auto_awesome_outlined,
                                            Icons.settings_outlined,
                                            Icons.help_outline,
                                          ][i],
                                          size: 17,
                                        ),
                                        if (!compact) ...[
                                          const SizedBox(width: 7),
                                          LText(
                                            desktopPages[i],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    key: const Key('language-selector'),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: language,
                        isDense: true,
                        icon: const Icon(Icons.expand_more, size: 16),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontSize: 12, color: p.text),
                        items: [
                          for (final code in supportedLanguages)
                            DropdownMenuItem(
                              value: code,
                              child: Text(languageNames[code]!),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) onLanguage(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DeskButton(dark ? '浅色' : '深色', onPressed: onTheme),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(page == 0 ? 12 : 20),
                child: child,
              ),
            ),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.panel,
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: Row(
                children: [
                  Icon(
                    busy
                        ? Icons.hourglass_top
                        : hasError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 12,
                    color: hasError ? bad : p.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LText(
                      busy ? '正在处理…' : activity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.muted),
                    ),
                  ),
                  const Text('SMT-CHECK 1.3', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class FileStrip extends StatelessWidget {
  final ImportedFile? bom, a, b;
  final bool merged, enabled;
  final ValueChanged<int> onPick;
  const FileStrip({
    super.key,
    required this.bom,
    required this.a,
    required this.b,
    required this.merged,
    required this.enabled,
    required this.onPick,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final entries = [
      ('BOM', bom, '导入 BOM', 0),
      (merged ? 'SMT A' : 'SMT', a, merged ? '导入站位 A' : '导入站位表', 1),
      if (merged) ('SMT B', b, '导入站位 B', 2),
    ];
    Widget slot((String, ImportedFile?, String, int) entry) {
      final (label, file, action, index) = entry;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: p.panel,
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: file?.path ?? localText(context, '尚未选择文件'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file?.name ?? localText(context, '待导入'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: file == null ? p.muted : p.text,
                      ),
                    ),
                    if (file != null)
                      LText(
                        '${file.rows.length}行',
                        style: TextStyle(fontSize: 10, color: p.muted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            DeskButton(
              action,
              icon: Icons.folder_open_outlined,
              onPressed: enabled ? () => onPick(index) : null,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 1000
          ? Row(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: slot(entries[i])),
                ],
              ],
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  slot(entries[i]),
                ],
              ],
            ),
    );
  }
}

class SummaryStrip extends StatelessWidget {
  final CheckReport report;
  const SummaryStrip({super.key, required this.report});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Wrap(
      spacing: 26,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (label, value) in [
          ('料号总数量', report.totalPartCount),
          ('BOM料号数量', report.bomPartCount),
          ('SMT站位表料号数量', report.smtPartCount),
        ])
          Row(
            key: ValueKey('stat-$label'),
            mainAxisSize: MainAxisSize.min,
            children: [
              LText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.of(context).muted,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        Tooltip(
          message: localText(
            context,
            '料号数按去重统计，含已排除和候选料；总数为 BOM 与 SMT 并集，A+B 相同料号只计一次，空料号不计。',
          ),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: Palette.of(context).muted,
          ),
        ),
      ],
    ),
  );
}
