import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../core/cad_coordinates.dart';
import '../core/coordinate_comparison.dart';
import '../core/models.dart';
import '../services/background_tasks.dart';
import '../services/cad_workbook_export.dart';
import '../services/coordinate_comparison_export.dart';
import 'design.dart';
import 'localized_text.dart';

enum CoordinateResultPool { active, excluded, all }

/// Retained by the application across navigation. Async work owns no widget State.
class CoordinateCompareController extends ChangeNotifier {
  CoordinateImport? a, b;
  CadUnit? unitA, unitB;
  CoordinateComparison? result;
  CoordinateDifferenceItem? selected;
  CoordinateCompareSettings settings;
  final Future<CoordinateImport> Function(String) loader;
  bool confirmed = false, busy = false, onlyErrors = false;
  bool _disposed = false;
  int _epoch = 0;
  String error = '', query = '';
  CadDifferenceType? filter;
  CoordinateResultPool pool = CoordinateResultPool.active;
  CoordinateCompareController({
    this.settings = const CoordinateCompareSettings(),
    this.loader = readComparisonCoordinatesInBackground,
  });
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void invalidate() {
    _epoch++;
    result = null;
    selected = null;
    pool = CoordinateResultPool.active;
    error = '';
    busy = false;
    _emit();
  }

  void clear() {
    a = null;
    b = null;
    unitA = null;
    unitB = null;
    confirmed = false;
    query = '';
    filter = null;
    onlyErrors = false;
    pool = CoordinateResultPool.active;
    invalidate();
  }

  void applySettings(CoordinateCompareSettings value) {
    settings = value;
    invalidate();
  }

  void unit(bool sideA, CadUnit value) {
    if (sideA) {
      unitA = value;
    } else {
      unitB = value;
    }
    confirmed = false;
    invalidate();
  }

  void frame(bool value) {
    confirmed = value;
    invalidate();
  }

  Future<void> load(String path, bool sideA) async {
    final token = ++_epoch;
    if (sideA) {
      a = null;
      unitA = null;
    } else {
      b = null;
      unitB = null;
    }
    confirmed = false;
    result = null;
    selected = null;
    pool = CoordinateResultPool.active;
    busy = true;
    error = '';
    _emit();
    try {
      final input = await loader(path);
      if (_disposed || token != _epoch) return;
      if (sideA) {
        a = input;
        unitA = input.unitHint;
      } else {
        b = input;
        unitB = input.unitHint;
      }
    } catch (e) {
      if (!_disposed && token == _epoch) {
        error = '坐标比较失败：${e is FormatException ? e.message : e}';
      }
    } finally {
      if (!_disposed && token == _epoch) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> compare() async {
    final aa = a, bb = b;
    if (aa == null || bb == null || busy) return;
    final token = ++_epoch;
    busy = true;
    error = '';
    result = null;
    selected = null;
    pool = CoordinateResultPool.active;
    _emit();
    try {
      final next = await compareCoordinatesInBackground(
        aa,
        bb,
        settings,
        unitA,
        unitB,
        confirmed,
      );
      if (_disposed || token != _epoch) return;
      result = next;
      selected = next.items.firstOrNull;
    } catch (e) {
      if (!_disposed && token == _epoch) {
        error = '坐标比较失败：${e is FormatException ? e.message : e}';
      }
    } finally {
      if (!_disposed && token == _epoch) {
        busy = false;
        _emit();
      }
    }
  }

  void changed() => _emit();
  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}

class CoordinateComparisonWorkspace extends StatefulWidget {
  final CoordinateCompareController controller;
  final VoidCallback onSettings;
  const CoordinateComparisonWorkspace({
    super.key,
    required this.controller,
    required this.onSettings,
  });
  @override
  State<CoordinateComparisonWorkspace> createState() =>
      _CoordinateComparisonWorkspaceState();
}

class _CoordinateComparisonWorkspaceState
    extends State<CoordinateComparisonWorkspace> {
  final horizontal = ScrollController(), vertical = ScrollController();
  late final TextEditingController search;
  CoordinateCompareController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: c.query);
  }

  @override
  void dispose() {
    search.dispose();
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  Future<void> import(bool sideA) async {
    final controller = c, epoch = c._epoch;
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CAD', extensions: ['xlsx', 'csv', 'txt']),
        ],
      );
      if (file != null &&
          mounted &&
          identical(c, controller) &&
          epoch == controller._epoch) {
        await controller.load(file.path, sideA);
      }
    } catch (e) {
      if (mounted && identical(c, controller) && epoch == controller._epoch) {
        c.error = '坐标比较失败：$e';
        c.changed();
      }
    }
  }

  Future<void> export() async {
    final snapshot = c.result;
    if (snapshot == null) return;
    final decisionRevision = snapshot.decisionHistory.length;
    bool current() =>
        mounted &&
        identical(snapshot, c.result) &&
        snapshot.decisionHistory.length == decisionRevision;
    try {
      final location = await getSaveLocation(
        suggestedName: 'CAD-comparison.json',
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (!current() || location == null) {
        return;
      }
      if (!location.path.toLowerCase().endsWith('.json')) {
        throw const FormatException('差异报告必须保存为 .json');
      }
      if (CadWorkbookExport.targetsOriginal(location.path, [
        snapshot.a.path,
        snapshot.b.path,
      ])) {
        throw const FormatException('不能覆盖原始文件，请选择其他文件名或目录');
      }
      final content = const JsonEncoder.withIndent('  ')
          .convert(coordinateComparisonJson(snapshot));
      final target = File(location.path),
          temporary = File(
            '${location.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
          );
      try {
        await temporary.writeAsString(content, flush: true);
        if (!current()) return;
        await temporary.rename(target.path);
      } finally {
        if (temporary.existsSync()) await temporary.delete();
      }
    } catch (e) {
      if (mounted) {
        c.error = '坐标比较失败：${e is FormatException ? e.message : e}';
        c.changed();
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final p = Palette.of(context), r = c.result;
        final rows =
            r?.items
                .where(
                  (i) =>
                      (c.pool == CoordinateResultPool.all ||
                          (r.decisions[i]?.excluded == true) ==
                              (c.pool == CoordinateResultPool.excluded)) &&
                      (!c.onlyErrors || i.isError) &&
                      (c.filter == null ||
                          i.differences.any((d) => d.type == c.filter)) &&
                      i.reference.toUpperCase().contains(
                        c.query.trim().toUpperCase(),
                      ),
                )
                .toList() ??
            [];
        final selected = rows.contains(c.selected) ? c.selected : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(
                  0,
                  constraints.maxHeight -
                      360 * MediaQuery.textScalerOf(context).scale(1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: LText(
                            '坐标差异检测',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DeskButton(
                          '设置',
                          key: const Key('coordinate-open-settings'),
                          onPressed: widget.onSettings,
                          icon: Icons.tune,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, space) {
                        final files = [
                          filePane(context, true),
                          filePane(context, false),
                        ];
                        return space.maxWidth > 780
                            ? Row(
                                children: [
                                  Expanded(child: files[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: files[1]),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  files[0],
                                  const SizedBox(height: 8),
                                  files[1],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DeskButton(
                          '比较坐标文件',
                          key: const Key('coordinate-compare'),
                          primary: true,
                          icon: Icons.compare_arrows,
                          onPressed: c.a != null && c.b != null && !c.busy
                              ? () => unawaited(c.compare())
                              : null,
                        ),
                        DeskButton(
                          '清空重来',
                          key: const Key('coordinate-clear'),
                          onPressed: () {
                            search.clear();
                            c.clear();
                          },
                          icon: Icons.restart_alt,
                        ),
                        DeskButton(
                          '导出差异报告',
                          onPressed: r == null || c.busy
                              ? null
                              : () => unawaited(export()),
                          icon: Icons.download_outlined,
                        ),
                        if (c.busy) ...[
                          if (!MediaQuery.disableAnimationsOf(context))
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.hourglass_top, size: 16),
                          const LText('正在读取或比较坐标…'),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          key: const Key('coordinate-frame-confirm'),
                          value: c.confirmed,
                          onChanged: c.busy ? null : (v) => c.frame(v ?? false),
                        ),
                        const Expanded(
                          child: LText(
                            '已确认两文件的单位、原点、轴方向及 Top/Bottom 镜像约定；仅统一单位，不自动平移或镜像。',
                          ),
                        ),
                      ],
                    ),
                    if (!c.confirmed ||
                        c.unitA == null ||
                        c.unitB == null ||
                        r?.frameConfirmed == false)
                      LText(
                        '坐标基准或单位未确认：仅比较位号和属性，数值检查待确认。',
                        style: TextStyle(color: p.alertText),
                      ),
                    LText(
                      '比较容差：X/Y ±${c.settings.xyTolerance} mm · 角度 ±${c.settings.angleTolerance}°（不是设备检测公差）',
                      style: TextStyle(color: p.muted),
                    ),
                    if (c.error.isNotEmpty)
                      LText(c.error, style: TextStyle(color: p.alertText)),
                    if (r != null) ...[
                      const SizedBox(height: 10),
                      const LText('原始文件差异统计'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          stat(context, '文件 A 元件', r.a.totalCount),
                          stat(context, '文件 B 元件', r.b.totalCount),
                          stat(context, '匹配成功', r.matched),
                          stat(context, '缺失元件', r.missing),
                          stat(context, '新增元件', r.added),
                          stat(
                            context,
                            '坐标异常',
                            r.count(CadDifferenceType.coordinate),
                          ),
                          stat(
                            context,
                            '角度异常',
                            r.count(CadDifferenceType.angle),
                          ),
                          stat(
                            context,
                            '属性不一致',
                            r.count(CadDifferenceType.attribute),
                          ),
                          stat(
                            context,
                            '层别异常',
                            r.count(CadDifferenceType.layer),
                          ),
                          stat(
                            context,
                            '重复或歧义',
                            r.count(CadDifferenceType.duplicate),
                          ),
                          stat(
                            context,
                            '数据质量',
                            r.count(CadDifferenceType.quality),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LText(
                        '普通元件 A/B：${r.a.records.length - r.specialCount(true)} / ${r.b.records.length - r.specialCount(false)} · 特殊 PCB 特征 A/B：${r.specialCount(true)} / ${r.specialCount(false)}',
                      ),
                      if (r.orderChanged) const LText('存在排序差异，仅提示，不影响匹配或检测结果。'),
                      LText(
                        '重复位号 A/B：${r.repeatedReferences(true)} / ${r.repeatedReferences(false)}；可确定的板号与层别组合分别匹配。',
                      ),
                      LText(
                        '人工排除：${r.decisions.values.where((d) => d.excluded).length} 项；原始差异及全部操作保留在报告中。',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Pane(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final entry in [
                            (CoordinateResultPool.active, '核对结果'),
                            (CoordinateResultPool.excluded, '已排除物料'),
                            (CoordinateResultPool.all, '全部'),
                          ])
                            DeskButton(
                              entry.$2,
                              key: ValueKey('coordinate-pool-${entry.$1.name}'),
                              variant: DeskButtonVariant.segment,
                              selected: c.pool == entry.$1,
                              onPressed: () {
                                c.pool = entry.$1;
                                if (c.pool == CoordinateResultPool.excluded) {
                                  c.filter = null;
                                  c.onlyErrors = false;
                                }
                                c.changed();
                              },
                            ),
                          SizedBox(
                            width: math.min(240, constraints.maxWidth - 50),
                            child: TextField(
                              key: const Key('coordinate-search'),
                              controller: search,
                              decoration: InputDecoration(
                                hintText: localText(context, '搜索 RefDes'),
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                c.query = v;
                                c.changed();
                              },
                            ),
                          ),
                          SizedBox(
                            width: math.min(
                              260 * MediaQuery.textScalerOf(context).scale(1),
                              constraints.maxWidth - 50,
                            ),
                            child: DropdownButton<CadDifferenceType?>(
                              key: const Key('coordinate-filter'),
                              isExpanded: true,
                              itemHeight: null,
                              value: c.filter,
                              selectedItemBuilder: (context) => [
                                for (final label in [
                                  '全部',
                                  ...CadDifferenceType.values.map(
                                    (v) => v.label,
                                  ),
                                ])
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Tooltip(
                                      message: localText(context, label),
                                      child: LText(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: LText('全部'),
                                ),
                                for (final type in CadDifferenceType.values)
                                  DropdownMenuItem(
                                    value: type,
                                    child: LText(type.label),
                                  ),
                              ],
                              onChanged: (v) {
                                c.filter = v;
                                c.changed();
                              },
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: c.onlyErrors,
                                onChanged: (v) {
                                  c.onlyErrors = v ?? false;
                                  c.changed();
                                },
                              ),
                              const LText('仅显示异常'),
                            ],
                          ),
                          Text('${rows.length}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? Center(
                              child: LText(
                                r == null ? '导入两个坐标文件后开始比较。' : '没有符合筛选条件的记录。',
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, box) => Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: table(context, rows)),
                                  if (box.maxWidth >= 1250 &&
                                      selected != null) ...[
                                    VerticalDivider(width: 1, color: p.line),
                                    SizedBox(
                                      width: 340,
                                      child: detail(context, selected),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget stat(BuildContext context, String label, int value) => Container(
    width: 125,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Palette.of(context).panel,
      border: Border.all(color: Palette.of(context).line),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LText(
          label,
          style: TextStyle(fontSize: 11, color: Palette.of(context).muted),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
  Widget filePane(BuildContext context, bool sideA) {
    final input = sideA ? c.a : c.b, unit = sideA ? c.unitA : c.unitB;
    return Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                sideA ? 'A' : 'B',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              DeskButton(
                sideA ? '导入文件 A' : '导入文件 B',
                key: Key('coordinate-import-${sideA ? 'a' : 'b'}'),
                onPressed: c.busy ? null : () => unawaited(import(sideA)),
                icon: Icons.folder_open,
              ),
              DropdownButton<CadUnit>(
                key: Key('coordinate-unit-${sideA ? 'a' : 'b'}'),
                value: unit,
                hint: const LText('确认坐标单位'),
                items: [
                  for (final u in CadUnit.values)
                    DropdownMenuItem(value: u, child: Text(u.name)),
                ],
                onChanged: c.busy
                    ? null
                    : (v) {
                        if (v != null) c.unit(sideA, v);
                      },
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            input?.name ?? '—',
            style: const TextStyle(fontSize: 12),
          ),
          if (input != null && input.metadata.isNotEmpty)
            SelectableText(
              input.metadata.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget table(BuildContext context, List<CoordinateDifferenceItem> rows) {
    final p = Palette.of(context);
    return Scrollbar(
      controller: horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1660,
          child: Column(
            children: [
              Container(
                color: p.hover,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    for (final (label, width) in [
                      ('RefDes', 130.0),
                      ('元件类型', 130.0),
                      ('层别 / 板号', 150.0),
                      ('文件 A：X / Y / 角度', 280.0),
                      ('文件 B：X / Y / 角度', 280.0),
                      ('差异类型', 180.0),
                      ('差异数值', 370.0),
                      ('检测结果', 120.0),
                    ])
                      SizedBox(
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LText(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: vertical,
                  child: ListView.builder(
                    controller: vertical,
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final item = rows[index],
                          chosen = identical(c.selected, item);
                      final decision = c.result?.decisions[item];
                      final color = p.result(
                        item.isError || decision?.excluded == true
                            ? CheckStatus.error
                            : CheckStatus.pass,
                      );
                      final status =
                          c.result?.displayStatus(item) ?? item.status;
                      String coords(CoordinateRecord? row) => row == null
                          ? '—'
                          : '${row.xText} / ${row.yText} / ${row.angleText}°';
                      final row = item.a.firstOrNull ?? item.b.firstOrNull;
                      final values = [
                        item.reference,
                        item.special.isEmpty
                            ? row?.partType ?? '—'
                            : item.special.join(', '),
                        '${item.a.firstOrNull?.layer ?? '—'} → ${item.b.firstOrNull?.layer ?? '—'} / ${row?.board ?? '—'}',
                        item.a.length > 1
                            ? '${item.a.length} ×'
                            : coords(item.a.firstOrNull),
                        item.b.length > 1
                            ? '${item.b.length} ×'
                            : coords(item.b.firstOrNull),
                        item.differences.isEmpty
                            ? localText(context, status)
                            : item.differences
                                  .map((d) => localText(context, d.type.label))
                                  .toSet()
                                  .join(' · '),
                        item.differences
                            .map(
                              (d) =>
                                  '${localText(context, d.field)}: ${d.delta.isEmpty ? '${coordinateDifferenceValue(context, d, true)} → ${coordinateDifferenceValue(context, d, false)}' : d.delta}',
                            )
                            .join('\n'),
                        decision?.excluded == true
                            ? localText(context, '已排除物料')
                            : localText(context, status),
                      ];
                      return Material(
                        color:
                            (item.numericPending ||
                                    c.result?.reviewPending(item) == true) &&
                                !item.isError &&
                                decision?.excluded != true
                            ? p.hover
                            : color.fill,
                        child: InkWell(
                          key: ValueKey('coordinate-row-$index'),
                          onTap: () {
                            c.selected = item;
                            c.changed();
                            if (MediaQuery.sizeOf(context).width < 1290) {
                              showDialog<void>(
                                context: context,
                                builder: (_) => Dialog(
                                  child: SizedBox(
                                    width: 680,
                                    height: math.min(
                                      650,
                                      MediaQuery.sizeOf(context).height - 80,
                                    ),
                                    child: detail(context, item),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  width: 4,
                                  color: chosen ? p.accent : Colors.transparent,
                                ),
                                bottom: BorderSide(color: p.panel),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < values.length; i++)
                                  SizedBox(
                                    width: [
                                      126.0,
                                      130.0,
                                      150.0,
                                      280.0,
                                      280.0,
                                      180.0,
                                      370.0,
                                      120.0,
                                    ][i],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        values[i],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.ink,
                                          fontWeight: chosen || i == 0
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget detail(BuildContext context, CoordinateDifferenceItem item) =>
      _ComparisonDetail(controller: c, item: item);
}

// Kept separate so decisions update an already open detail dialog as well.
class _ComparisonDetail extends StatefulWidget {
  final CoordinateCompareController controller;
  final CoordinateDifferenceItem item;
  const _ComparisonDetail({required this.controller, required this.item});
  @override
  State<_ComparisonDetail> createState() => _ComparisonDetailState();
}

class _ComparisonDetailState extends State<_ComparisonDetail> {
  final reason = TextEditingController();
  String error = '';
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ComparisonDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.item, widget.item)) {
      reason.clear();
      error = '';
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final item = widget.item,
          p = Palette.of(context),
          r = widget.controller.result,
          decision = r?.decisions[item];
      void decide(bool exclude) {
        try {
          r?.decide(item, exclude, reason.text);
          widget.controller.pool = exclude
              ? CoordinateResultPool.excluded
              : CoordinateResultPool.active;
          if (exclude) {
            widget.controller.filter = null;
            widget.controller.onlyErrors = false;
          }
          setState(() => error = '');
          widget.controller.changed();
        } on FormatException catch (e) {
          setState(() => error = e.message);
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              item.reference,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            LText(
              r?.displayStatus(item) ?? item.status,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: item.isError || decision?.excluded == true
                    ? p.alertText
                    : r?.reviewPending(item) == true
                    ? p.muted
                    : good,
              ),
            ),
            if (item.numericPending)
              const LText('坐标基准或单位未确认：仅比较位号和属性，数值检查待确认。'),
            const SizedBox(height: 12),
            for (final d in item.differences)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(
                      d.type.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: d.type == CadDifferenceType.precision
                            ? p.muted
                            : p.alertText,
                      ),
                    ),
                    SelectableText(
                      '${localText(context, d.field)}\nA: ${coordinateDifferenceValue(context, d, true)}\nB: ${coordinateDifferenceValue(context, d, false)}${d.delta.isEmpty ? '' : '\nΔ (B−A): ${d.delta}'}',
                      style: TextStyle(
                        color: d.type == CadDifferenceType.precision
                            ? p.text
                            : p.alertText,
                      ),
                    ),
                  ],
                ),
              ),
            for (final issue in item.issues) ...[
              LText(issue.reason, style: TextStyle(color: p.alertText)),
              SelectableText(
                '${issue.file} / ${issue.sheet} / ${issue.row}\n${jsonEncode(issue.raw)}',
              ),
            ],
            if (item.special.isNotEmpty) ...[
              const Divider(),
              Text(
                item.special.join(' · '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const LText('可能为 PCB 特殊特征。默认保留；排除不删除记录，也不改变原始差异。'),
              for (final rule in [
                ...item.a,
                ...item.b,
              ].expand(widget.controller.settings.classify).toSet())
                LText('规则建议：${specialActionLabel(rule.action)}'),
              TextField(
                controller: reason,
                decoration: InputDecoration(
                  labelText: localText(context, '操作原因（必填）'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  DeskButton(
                    '确认保留',
                    onPressed: r?.items.contains(item) == true
                        ? () => decide(false)
                        : null,
                  ),
                  DeskButton(
                    '确认排除',
                    onPressed: r?.items.contains(item) == true
                        ? () => decide(true)
                        : null,
                    color: p.alertText,
                  ),
                ],
              ),
              if (error.isNotEmpty)
                LText(error, style: TextStyle(color: p.alertText)),
              if (decision != null) ...[
                LText(decision.excluded ? '已排除物料' : '已人工确认保留'),
                SelectableText(
                  '${decision.at.toIso8601String()}\n${decision.reason}',
                ),
              ],
            ],
            for (final (label, records) in [('A', item.a), ('B', item.b)]) ...[
              const Divider(),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              for (final row in records)
                SelectableText(
                  '${row.file}\n${row.sheet} / ${row.row}\nRefDes: ${row.reference}\nBoard: ${row.board}\nLayer: ${row.layer}\nPartType: ${row.partType}\nPartDecal: ${row.decal}\nPins: ${row.pins}\nX: ${row.xText}\nY: ${row.yText}\nOrient.: ${row.angleText}\n${jsonEncode(row.raw)}',
                ),
            ],
          ],
        ),
      );
    },
  );
}

String specialActionLabel(SpecialAction action) => switch (action) {
  SpecialAction.retain => '保留',
  SpecialAction.exclude => '排除（需确认）',
  SpecialAction.review => '人工确认',
};

String coordinateDifferenceValue(
  BuildContext context,
  CadDifference difference,
  bool sideA,
) {
  final value = sideA ? difference.a : difference.b;
  return difference.messageMask & (sideA ? 1 : 2) != 0
      ? localText(context, value)
      : value;
}
