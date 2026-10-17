import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/cad_coordinates.dart';
import '../core/station_merge.dart';
import 'design.dart';
import 'localized_text.dart';

class CadWorkspace extends StatefulWidget {
  final MergedStationFile? bom;
  final CoordinateImport? coordinates;
  final CadPreview? preview;
  final CadUnit? unit;
  final TextEditingController nameController;
  final bool busy, canGenerate, canExport;
  final bool singleStation;
  final String error, stage;
  final VoidCallback onImport, onGenerate, onExport, onMerge;
  final ValueChanged<CadUnit> onUnit;
  const CadWorkspace({
    super.key,
    required this.bom,
    required this.coordinates,
    required this.preview,
    required this.unit,
    required this.nameController,
    required this.busy,
    required this.canGenerate,
    required this.canExport,
    required this.error,
    required this.stage,
    required this.onImport,
    required this.onGenerate,
    required this.onExport,
    required this.onMerge,
    required this.onUnit,
    this.singleStation = false,
  });
  @override
  State<CadWorkspace> createState() => _CadWorkspaceState();
}

class _CadWorkspaceState extends State<CadWorkspace> {
  final horizontal = ScrollController(), vertical = ScrollController();
  bool showIssues = false;
  int selected = 0;
  @override
  void didUpdateWidget(covariant CadWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preview, widget.preview) ||
        !identical(oldWidget.coordinates, widget.coordinates)) {
      selected = 0;
      showIssues = issues.any((i) => i.blocking);
    }
  }

  List<CadIssue> get issues =>
      widget.preview?.issues ?? widget.coordinates?.issues ?? const [];
  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return LayoutBuilder(
      builder: (context, c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(0, c.maxHeight - 360),
            ),
            child: SingleChildScrollView(
              key: const Key('cad-header-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header(context),
                  if (widget.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LText(
                        widget.error,
                        style: TextStyle(color: p.alertText),
                      ),
                    ),
                  if (widget.busy)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          if (!MediaQuery.disableAnimationsOf(context))
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.hourglass_top, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: LText(widget.stage)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Pane(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DeskButton(
                          '坐标预览',
                          key: const Key('cad-preview-tab'),
                          variant: DeskButtonVariant.segment,
                          selected: !showIssues,
                          onPressed: () => setState(() => showIssues = false),
                        ),
                        DeskButton(
                          '坐标问题（${issues.length}）',
                          key: const Key('cad-issues-tab'),
                          variant: DeskButtonVariant.segment,
                          selected: showIssues,
                          color: issues.isNotEmpty ? p.alertText : null,
                          onPressed: () => setState(() => showIssues = true),
                        ),
                        if (widget.preview != null)
                          LText(
                            widget.preview!.canExport
                                ? 'PASS · ${widget.preview!.rows.length} 个位号'
                                : 'NG · ${widget.preview!.errors.length} 项坐标问题',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: widget.preview!.canExport
                                  ? (p.dark ? good : const Color(0xFF087343))
                                  : p.alertText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: p.line),
                  Expanded(
                    child: showIssues ? issueList(context) : table(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget header(BuildContext context) {
    final p = Palette.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const LText(
              'FAI-i450 CAD 坐标',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: p.panel,
                border: Border.all(color: p.line),
                borderRadius: BorderRadius.circular(5),
              ),
              child: LText(
                widget.singleStation ? '单表 CAD' : 'A+B CAD',
                style: TextStyle(fontSize: 11, color: p.muted),
              ),
            ),
            DeskButton(
              '核对与人工确认',
              key: const Key('cad-go-merge'),
              icon: Icons.fact_check_outlined,
              variant: DeskButtonVariant.quiet,
              onPressed: widget.busy ? null : widget.onMerge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              widget.bom == null
                  ? Icons.pending_outlined
                  : Icons.check_circle_outline,
              size: 16,
              color: widget.bom == null ? p.muted : p.accent,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: LText(
                widget.bom == null
                    ? '待完成人工确认与 BOM 预览'
                    : '已确认 BOM · ${widget.bom!.rows.length} 行',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.bom == null ? p.muted : p.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Pane(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, c) {
              final input = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LText(
                    '原坐标文件',
                    style: TextStyle(fontSize: 11, color: p.muted),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        size: 20,
                        color: p.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: widget.coordinates?.path ?? '',
                              child: Text(
                                widget.coordinates?.name ??
                                    localText(context, '尚未导入原坐标'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.coordinates != null) ...[
                              const SizedBox(height: 3),
                              caption(
                                context,
                                '原坐标 ${widget.coordinates!.records.length} 条有效记录',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DeskButton(
                        '导入原坐标',
                        key: const Key('import-cad'),
                        icon: Icons.folder_open,
                        onPressed: widget.busy ? null : widget.onImport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        key: const Key('cad-unit-control'),
                        width: math.min(244 * scale, c.maxWidth),
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.line),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              flex: 4,
                              child: LText(
                                '原坐标单位',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: p.muted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<CadUnit>(
                                  key: const Key('cad-unit'),
                                  value: widget.unit,
                                  isExpanded: true,
                                  isDense: true,
                                  borderRadius: BorderRadius.circular(6),
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(fontSize: 12, color: p.text),
                                  hint: const LText(
                                    '请选择坐标单位',
                                    style: TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  items: [
                                    for (final unit in CadUnit.values)
                                      DropdownMenuItem(
                                        value: unit,
                                        child: LText(
                                          unit.label,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: widget.busy
                                      ? null
                                      : (unit) {
                                          if (unit != null) widget.onUnit(unit);
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DeskButton(
                        '生成 CAD 预览',
                        key: const Key('generate-cad'),
                        icon: Icons.transform,
                        primary: true,
                        onPressed: widget.canGenerate && !widget.busy
                            ? widget.onGenerate
                            : null,
                      ),
                    ],
                  ),
                ],
              );
              final output = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LText(
                    'CAD 文件名',
                    style: TextStyle(fontSize: 11, color: p.muted),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    key: const Key('cad-file-name'),
                    controller: widget.nameController,
                    enabled: !widget.busy,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: 'FAI450-CAD',
                      suffixText: '.xlsx',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DeskButton(
                        '导出 CAD Excel',
                        key: const Key('export-cad'),
                        icon: Icons.download,
                        onPressed: widget.canExport && !widget.busy
                            ? widget.onExport
                            : null,
                      ),
                      caption(context, '保留设备十列格式'),
                    ],
                  ),
                ],
              );
              if (c.maxWidth >= 1080 * scale) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: input),
                    const SizedBox(width: 28),
                    Expanded(flex: 2, child: output),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  input,
                  const SizedBox(height: 16),
                  Divider(height: 1, color: p.line),
                  const SizedBox(height: 14),
                  output,
                ],
              );
            },
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('cad-conversion-help'),
            tilePadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: LText(
              '坐标转换说明',
              style: TextStyle(fontSize: 11, color: p.muted),
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    caption(
                      context,
                      'V1.6 兼容：Top 保持，Bottom 按完整原坐标 Y 范围镜像，角度 +180°。',
                    ),
                    if (widget.preview?.minY != null &&
                        widget.preview?.maxY != null)
                      caption(
                        context,
                        '镜像范围：${widget.preview!.minY!.toStringAsFixed(4)} ～ ${widget.preview!.maxY!.toStringAsFixed(4)} mm',
                      ),
                    caption(context, '输出已预镜像，导入 FAI-i450 时 Bottom 不要再次勾选“镜面”。'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget issueList(BuildContext context) {
    final p = Palette.of(context);
    if (issues.isEmpty) return const Center(child: LText('没有坐标问题'));
    return ListView.separated(
      key: const Key('cad-issue-list'),
      padding: const EdgeInsets.all(12),
      itemCount: issues.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final issue = issues[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: issue.blocking ? bad : p.line),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (issue.reference.isNotEmpty)
                SelectableText(
                  issue.reference,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              LText(
                issue.reason,
                style: TextStyle(
                  color: p.alertText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (issue.raw.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const LText(
                    'CAD 原始字段',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    for (final entry in issue.raw.entries)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              if (issue.file.isNotEmpty) ...[
                const SizedBox(height: 4),
                SelectableText(
                  '${issue.file} / ${issue.sheet} / ${localText(context, '第 ${issue.row} 行')}',
                  style: TextStyle(fontSize: 11, color: p.muted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget table(BuildContext context) {
    final preview = widget.preview, p = Palette.of(context);
    if (preview == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LText('完成准备后生成 CAD 预览；修改文件、单位或人工确认会使旧预览失效。'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: LText(
            '输出 ${preview.rows.length} 行 · 未纳入 ${preview.omitted} 条原坐标 · 无位号 BOM ${preview.noReferenceRows} 行',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final width = math.max(1100.0, c.maxWidth);
              Widget cells(List<Object> values, {bool header = false}) => Row(
                children: [
                  for (var col = 0; col < 10; col++)
                    SizedBox(
                      width:
                          width *
                          [
                            .16,
                            .10,
                            .16,
                            .06,
                            .08,
                            .08,
                            .10,
                            .10,
                            .08,
                            .08,
                          ][col],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Text(
                          values[col] is double && (col == 6 || col == 7)
                              ? (values[col] as double).toStringAsFixed(4)
                              : values[col].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: header || col == 1
                                ? FontWeight.w700
                                : FontWeight.normal,
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
                          child: cells(CadPreview.headers, header: true),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: vertical,
                            thumbVisibility: true,
                            child: ListView.builder(
                              key: const Key('cad-preview-table'),
                              controller: vertical,
                              itemCount: preview.rows.length,
                              itemBuilder: (context, i) {
                                final row = preview.rows[i];
                                return Tooltip(
                                  message:
                                      '${row.source.file} / ${row.source.sheet}:${row.source.row}\n${row.bom.part}',
                                  child: Material(
                                    color: selected == i
                                        ? p.accentSoft
                                        : i.isOdd
                                        ? p.bg
                                        : p.panel,
                                    child: InkWell(
                                      onTap: () => setState(() => selected = i),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: p.line),
                                          ),
                                        ),
                                        child: cells(row.cells),
                                      ),
                                    ),
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
        if (preview.rows.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 90),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Builder(
                  builder: (context) {
                    final row = preview
                        .rows[selected.clamp(0, preview.rows.length - 1)];
                    return SelectableText(
                      '${row.source.reference} · ${row.bom.part}\n${row.source.file} / ${row.source.sheet}:${row.source.row}'
                      ' · X ${row.source.x} → ${row.x.toStringAsFixed(4)} · Y ${row.source.y} → ${row.y.toStringAsFixed(4)}'
                      ' · ° ${row.source.angle} → ${row.angle}',
                      style: TextStyle(fontSize: 11, color: p.muted),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
