import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/station_merge.dart';
import 'design.dart';
import 'localized_text.dart';
import 'results.dart';

class MergeWorkspace extends StatefulWidget {
  final StationMergeSession? session;
  final TextEditingController nameController;
  final CheckItem? initialItem;
  final bool busy;
  final VoidCallback onChanged, onWorkbench;
  final Future<void> Function() onExport;
  const MergeWorkspace({
    super.key,
    required this.session,
    required this.nameController,
    required this.busy,
    required this.onChanged,
    required this.onWorkbench,
    required this.onExport,
    this.initialItem,
  });
  @override
  State<MergeWorkspace> createState() => _MergeWorkspaceState();
}

class _MergeWorkspaceState extends State<MergeWorkspace> {
  CheckItem? selected;
  bool showPreview = false;
  MergeMode mode = MergeMode.summarize;
  String error = '';
  final horizontal = ScrollController(), vertical = ScrollController();
  @override
  void initState() {
    super.initState();
    final session = widget.session;
    selected = widget.initialItem ?? session?.requiredItems.firstOrNull;
    showPreview = widget.initialItem == null && session?.preview != null;
    mode = session?.preview?.mode ?? MergeMode.summarize;
  }

  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  void confirm(bool include) {
    final session = widget.session!, item = selected!;
    session.confirm(item, include: include);
    setState(() {
      selected =
          session.requiredItems
              .where((i) => session.reviewFor(i) == null)
              .firstOrNull ??
          item;
      error = '';
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (session == null || !session.hasTwoStations) {
      return Pane(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.merge_type, size: 32),
                  const SizedBox(height: 16),
                  const LText(
                    'A+B 合并与导出',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  caption(context, '请先导入 BOM、站位表 A 和 B，并以 A+B 合并模式完成核对。'),
                  const SizedBox(height: 18),
                  DeskButton(
                    '返回核对工作台',
                    icon: Icons.arrow_back,
                    onPressed: widget.onWorkbench,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (constraints.maxHeight - 260).clamp(
                0.0,
                constraints.maxHeight,
              ),
            ),
            child: SingleChildScrollView(
              key: const Key('merge-header-scroll'),
              child: mergeHeader(context, session),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: showPreview
                ? preview(context, session)
                : review(context, session),
          ),
        ],
      ),
    );
  }

  Widget mergeHeader(BuildContext context, StationMergeSession session) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
          final source = sourceControls(context, session, scale);
          final export = exportControls(context, session, scale);
          if (constraints.maxWidth >= 1200 * scale) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: source),
                const SizedBox(width: 20),
                SizedBox(width: 440 * scale, child: export),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              source,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 560 * scale),
                  child: export,
                ),
              ),
            ],
          );
        },
      );

  Widget sourceControls(
    BuildContext context,
    StationMergeSession session,
    double scale,
  ) => Column(
    key: const Key('merge-source-tools'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const LText(
        'A+B 合并与导出',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 5),
      Container(
        key: const Key('merge-source-description'),
        child: caption(context, '仅合并 SMT 站位表原始记录，保留四列；人工确认不改变核对状态。'),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DeskButton(
              '人工确认',
              key: const Key('merge-review-tab'),
              selected: !showPreview,
              icon: Icons.fact_check_outlined,
              onPressed: () => setState(() => showPreview = false),
            ),
            DeskButton(
              '合并文件预览',
              key: const Key('merge-preview-tab'),
              selected: showPreview,
              icon: Icons.table_view_outlined,
              onPressed: () => setState(() => showPreview = true),
            ),
            SizedBox(
              key: const Key('merge-mode-control'),
              width: math.min(260 * scale, constraints.maxWidth),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Palette.of(context).panel,
                  border: Border.all(color: Palette.of(context).line),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    LText(
                      '合并方式',
                      style: TextStyle(
                        fontSize: 11,
                        color: Palette.of(context).muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MergeMode>(
                          key: ValueKey(mode),
                          value: mode,
                          isExpanded: true,
                          isDense: true,
                          borderRadius: BorderRadius.circular(6),
                          items: [
                            for (final value in MergeMode.values)
                              DropdownMenuItem(
                                value: value,
                                child: LText(
                                  value == MergeMode.summarize
                                      ? '同料号汇总'
                                      : '保留 A+B 明细',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: widget.busy
                              ? null
                              : (value) {
                                  if (value == null || value == mode) return;
                                  session.clearPreview();
                                  setState(() {
                                    mode = value;
                                    error = '';
                                  });
                                  widget.onChanged();
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DeskButton(
              '生成合并预览',
              key: const Key('generate-merge'),
              primary: true,
              icon: Icons.merge_type,
              onPressed: !session.canGenerate || widget.busy
                  ? null
                  : () {
                      try {
                        session.generate(mode);
                        setState(() {
                          showPreview = true;
                          error = '';
                        });
                        widget.onChanged();
                      } on StateError catch (e) {
                        setState(() => error = e.message);
                      } catch (e) {
                        setState(() => error = '$e');
                      }
                    },
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      caption(
        context,
        mode == MergeMode.summarize
            ? '料号、描述均相同且数量有效时汇总；其余保留明细，位号原样拼接，不去重。'
            : '按 A 表、B 表顺序保留每行原始内容，仅移除人工确认不纳入的 SMT 记录。',
      ),
      if (error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            localText(context, error),
            style: TextStyle(color: Palette.of(context).alertText),
          ),
        ),
    ],
  );

  Widget exportControls(
    BuildContext context,
    StationMergeSession session,
    double scale,
  ) {
    final p = Palette.of(context);
    final metrics = TextPainter(
      text: TextSpan(
        text: localText(context, '导出合并 Excel'),
        style: DefaultTextStyle.of(context).style
            .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final buttonWidth = metrics.width + 51;
    metrics.dispose();
    final nameField = TextField(
      key: const Key('merge-file-name'),
      controller: widget.nameController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(hintText: localText(context, '合并文件名')),
      style: const TextStyle(fontSize: 12),
    );
    final exportButton = DeskButton(
      '导出合并 Excel',
      key: const Key('export-merge'),
      icon: Icons.file_download_outlined,
      primary: true,
      onPressed: !session.canExport || widget.busy || !_validName
          ? null
          : widget.onExport,
    );
    return Pane(
      key: const Key('merge-export-tools'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              LText('合并文件名', style: TextStyle(fontSize: 11, color: p.muted)),
              Text(
                localText(
                  context,
                  '已确认 ${session.confirmedCount} / ${session.requiredItems.length} 项',
                ),
                key: const Key('merge-review-count'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: session.pendingCount > 0 ? p.alertText : p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= buttonWidth + 8 + 160 * scale) {
                return Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 8),
                    exportButton,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: exportButton),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Tooltip(
            message: _nameHint(context),
            child: Text(
              _nameHint(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: _validName ? p.muted : p.alertText,
              ),
            ),
          ),
          const SizedBox(height: 3),
          caption(context, '文件名自动以 BOM 结尾，格式为 .xlsx'),
        ],
      ),
    );
  }

  bool get _validName {
    try {
      mergedFileName(widget.nameController.text);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _nameHint(BuildContext context) {
    try {
      return mergedFileName(widget.nameController.text);
    } on FormatException catch (e) {
      return localText(context, e.message);
    }
  }

  Widget review(BuildContext context, StationMergeSession session) {
    if (session.requiredItems.isEmpty) {
      return Pane(child: Center(child: LText('全部为 PASS，可直接生成合并预览。')));
    }
    final item = selected ?? session.requiredItems.first;
    final decision = session.reviewFor(item), p = Palette.of(context);
    final list = Pane(
      padding: EdgeInsets.zero,
      child: Material(
        color: p.panel,
        child: ListView.builder(
          key: const PageStorageKey('merge-review-list'),
          itemCount: session.requiredItems.length,
          itemBuilder: (context, index) {
            final row = session.requiredItems[index],
                review = session.reviewFor(row);
            return ListTile(
              key: ValueKey('merge-item-$index'),
              selected: identical(row, item),
              selectedTileColor: p.accentSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 6,
              ),
              leading: Icon(
                review == null ? Icons.radio_button_unchecked : Icons.task_alt,
                size: 19,
                color: review == null ? p.alertText : p.accent,
              ),
              title: Text(
                row.part.isEmpty ? localText(context, '空料号') : row.part,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText(
                    row.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.alertText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  LText(
                    review == null
                        ? '待人工确认'
                        : review.include
                        ? '已确认：纳入合并'
                        : '已确认：不纳入合并',
                    style: TextStyle(fontSize: 11, color: p.muted),
                  ),
                ],
              ),
              onTap: () => setState(() => selected = row),
            );
          },
        ),
      ),
    );
    final detail = Pane(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.part.isEmpty ? localText(context, '空料号') : item.part,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.smt.isEmpty) ...[
                  caption(context, '此项仅 BOM 有记录，不能补造 SMT 内容；确认后不会写入合并文件。'),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DeskButton(
                      '确认纳入合并',
                      key: const Key('confirm-include'),
                      primary: true,
                      icon: Icons.check,
                      onPressed: widget.busy || item.smt.isEmpty
                          ? null
                          : () => confirm(true),
                    ),
                    DeskButton(
                      '确认不纳入合并',
                      key: const Key('confirm-omit'),
                      icon: Icons.remove_circle_outline,
                      onPressed: widget.busy ? null : () => confirm(false),
                    ),
                    if (decision != null)
                      DeskButton(
                        '撤销确认',
                        key: const Key('revoke-review'),
                        variant: DeskButtonVariant.quiet,
                        onPressed: widget.busy
                            ? null
                            : () {
                                session.revoke(item);
                                setState(() {});
                                widget.onChanged();
                              },
                      ),
                  ],
                ),
                if (decision != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${localText(context, decision.include ? '已确认：纳入合并' : '已确认：不纳入合并')} · ${decision.confirmedAt.toLocal().toString().split('.').first}',
                      style: TextStyle(fontSize: 11, color: p.muted),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          Expanded(
            child: ItemDetail(key: ValueKey(item), item: item, onAi: null),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Column(
            children: [
              SizedBox(
                height: math.min(150, constraints.maxHeight * .3),
                child: list,
              ),
              const SizedBox(height: 8),
              Expanded(child: detail),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 270, child: list),
            const SizedBox(width: 12),
            Expanded(child: detail),
          ],
        );
      },
    );
  }

  Widget preview(BuildContext context, StationMergeSession session) {
    final file = session.preview, p = Palette.of(context);
    if (file == null) {
      return Pane(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LText(
              session.pendingCount > 0
                  ? '还有 ${session.pendingCount} 项待人工确认，确认后才能合并和导出。'
                  : '人工确认已完成，点击“生成合并预览”。',
            ),
          ),
        ),
      );
    }
    return Pane(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: LText(
              '预览 ${file.rows.length} 行 · 纳入 ${file.includedSourceRows} 条 SMT 原始记录 · 不纳入 ${file.omittedSourceRows} 条',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.max(900.0, constraints.maxWidth);
                Widget cells(List<String> values, {bool header = false}) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var col = 0; col < 4; col++)
                      SizedBox(
                        width: width * [.18, .39, .10, .33][col],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 12,
                          ),
                          child: header
                              ? Text(
                                  values[col],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : SelectableText(
                                  values[col],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                  ],
                );
                return Scrollbar(
                  controller: horizontal,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          Container(
                            color: p.hover,
                            child: cells(
                              MergedStationFile.headers,
                              header: true,
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: vertical,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: vertical,
                                key: const Key('merged-preview-table'),
                                itemCount: file.rows.length,
                                itemBuilder: (context, index) {
                                  final row = file.rows[index];
                                  return Tooltip(
                                    message: row.sources
                                        .map(
                                          (s) =>
                                              '${s.side} · ${s.file} / ${s.sheet}:${s.row}',
                                        )
                                        .join('\n'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: index.isOdd ? p.bg : p.panel,
                                        border: Border(
                                          bottom: BorderSide(color: p.line),
                                        ),
                                      ),
                                      child: cells(row.cells),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (file.rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: caption(context, '没有纳入的 SMT 记录，导出文件将仅包含四列表头。'),
            ),
        ],
      ),
    );
  }
}
