import 'package:flutter/material.dart';

import '../core/models.dart';
import '../l10n/localization.dart';
import 'design.dart';
import 'localized_text.dart';

const desktopPages = ['核对工作台', 'AI 分析核对', '设置', '使用说明'];

class DesktopShell extends StatelessWidget {
  final int page;
  final String language, activity;
  final bool dark, busy, hasError;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onLanguage;
  final VoidCallback onTheme;
  final VoidCallback? onCheckUpdates;
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
    this.onCheckUpdates,
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
                                  height: 36,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: page == i
                                          ? p.accent
                                          : p.muted,
                                      backgroundColor: page == i
                                          ? p.accentSoft
                                          : Colors.transparent,
                                      minimumSize: Size(compact ? 32 : 80, 44),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 6 : 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () => onPage(i),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          [
                                            Icons.table_chart_outlined,
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: page == i
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
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
                  if (onCheckUpdates != null) ...[
                    const SizedBox(width: 8),
                    if (compact)
                      IconButton(
                        key: const Key('check-updates'),
                        tooltip: localText(context, '检查更新'),
                        onPressed: onCheckUpdates,
                        icon: const Icon(Icons.system_update_alt, size: 18),
                      )
                    else
                      DeskButton(
                        '检查更新',
                        key: const Key('check-updates'),
                        icon: Icons.system_update_alt,
                        variant: DeskButtonVariant.quiet,
                        onPressed: onCheckUpdates,
                      ),
                  ],
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
                  DeskButton(
                    dark ? '浅色' : '深色',
                    onPressed: onTheme,
                    variant: DeskButtonVariant.quiet,
                    icon: dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
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
                    color: hasError ? p.alertText : p.muted,
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
                  const Text('SMT-CHECK 1.8.0', style: TextStyle(fontSize: 10)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 34,
              decoration: BoxDecoration(
                color: p.hover,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.description_outlined, size: 17, color: p.muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Tooltip(
                message: file?.path ?? localText(context, '尚未选择文件'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (file != null) ...[
                          const SizedBox(width: 8),
                          LText(
                            '${file.rows.length}行',
                            style: TextStyle(fontSize: 10, color: p.muted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file?.name ?? localText(context, '待导入'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: file == null ? p.muted : p.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            DeskButton(
              action,
              variant: DeskButtonVariant.quiet,
              icon: Icons.folder_open_outlined,
              onPressed: enabled ? () => onPick(index) : null,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: p.panel,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 1000
            ? Row(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) Container(width: 1, height: 34, color: p.line),
                    Expanded(child: slot(entries[i])),
                  ],
                ],
              )
            : Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: p.line),
                    slot(entries[i]),
                  ],
                ],
              ),
      ),
    );
  }
}

class StationModeSwitch extends StatelessWidget {
  final bool merged, enabled;
  final ValueChanged<bool> onChanged;
  const StationModeSwitch({
    super.key,
    required this.merged,
    required this.enabled,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.hover,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, value) in [('单站位表', false), ('A + B 合并', true)])
            DeskButton(
              label,
              selected: merged == value,
              variant: DeskButtonVariant.segment,
              onPressed: enabled ? () => onChanged(value) : null,
            ),
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
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Wrap(
      spacing: 38,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (label, value) in [
          ('料号总数量', report.totalPartCount),
          ('BOM料号数量', report.bomPartCount),
          ('SMT站位表料号数量', report.smtPartCount),
        ])
          Column(
            key: ValueKey('stat-$label'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LText(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.of(context).muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 24,
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
