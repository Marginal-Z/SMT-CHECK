import 'localized_text.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/positions.dart';
import 'design.dart';

class ResultsView extends StatefulWidget {
  final CheckReport report;
  final CheckItem? selected;
  final ValueChanged<CheckItem> onSelect;
  final ValueChanged<CheckItem>? onAi;
  final ValueChanged<bool> onExport;
  const ResultsView({
    super.key,
    required this.report,
    required this.selected,
    required this.onSelect,
    required this.onAi,
    required this.onExport,
  });
  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  CheckStatus? filter;
  String query = '';
  bool detailsOpen = false;
  final horizontal = ScrollController(), vertical = ScrollController();
  @override
  void dispose() {
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final list = widget.report.items
        .where(
          (i) =>
              (filter == null || filter == i.status) &&
              '${i.part} ${i.description} ${i.reasons.join(' ')} ${i.reasons.map((r) => localText(context, r)).join(' ')} ${i.bom.map((r) => r.positionsText).join(' ')} ${i.smt.map((r) => r.positionsText).join(' ')}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (label, status) in [
              ('全部', null),
              ('异常', CheckStatus.error),
              ('一致', CheckStatus.pass),
              ('已排除物料', CheckStatus.excluded),
              ('候选料', CheckStatus.candidate),
            ])
              FilterTab(
                '${localText(context, label)} (${status == null ? widget.report.items.length : widget.report.count(status)})',
                selected: filter == status,
                onPressed: () => setState(() => filter = status),
              ),
            SizedBox(
              width: 200,
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: localText(context, '搜索料号、位号或原因'),
                  prefixIcon: Icon(Icons.search, size: 17),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
            ),
            DeskButton(
              '导出 CSV',
              icon: Icons.download_outlined,
              onPressed: () => widget.onExport(false),
            ),
            DeskButton('JSON', onPressed: () => widget.onExport(true)),
            DeskButton(
              detailsOpen ? '收起详情' : '展开详情',
              icon: Icons.vertical_split_outlined,
              onPressed: widget.selected == null
                  ? null
                  : () => setState(() => detailsOpen = !detailsOpen),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final showDetail = c.maxWidth > 1160;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, tableConstraints) {
                        final tableWidth = math.max(
                          1478.0,
                          tableConstraints.maxWidth - 2,
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: p.panel,
                            border: Border.all(color: p.line),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Scrollbar(
                            controller: horizontal,
                            thumbVisibility: true,
                            notificationPredicate: (n) =>
                                n.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: horizontal,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 38,
                                      color: p.hover,
                                      child: rowCells(
                                        context,
                                        [
                                          '状态',
                                          '料号',
                                          '品名 / 物料描述',
                                          'BOM数量',
                                          'SMT数量',
                                          'BOM插件位置',
                                          'SMT站位表位号',
                                          '核对结果 / 异常原因',
                                        ],
                                        header: true,
                                        width: tableWidth,
                                      ),
                                    ),
                                    Expanded(
                                      child: list.isEmpty
                                          ? const Center(
                                              child: LText(
                                                '没有符合筛选条件的记录',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            )
                                          : Scrollbar(
                                              controller: vertical,
                                              child: ListView.builder(
                                                controller: vertical,
                                                itemCount: list.length,
                                                itemExtent: 57,
                                                itemBuilder: (context, index) {
                                                  final item = list[index],
                                                      isSelected =
                                                          widget.selected ==
                                                          item;
                                                  final colors = p.result(
                                                    item.status,
                                                    selected: isSelected,
                                                  );
                                                  return Semantics(
                                                    button: true,
                                                    label:
                                                        '${item.part} ${localText(context, item.label)}',
                                                    child: InkWell(
                                                      onTap: () {
                                                        widget.onSelect(item);
                                                        setState(
                                                          () => detailsOpen =
                                                              true,
                                                        );
                                                        if (!showDetail) {
                                                          showDialog<void>(
                                                            context: context,
                                                            builder: (context) => Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child: ConstrainedBox(
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      maxWidth:
                                                                          690,
                                                                      maxHeight:
                                                                          760,
                                                                    ),
                                                                child: ItemDetail(
                                                                  item: item,
                                                                  onAi: widget
                                                                      .onAi,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        key: ObjectKey(item),
                                                        decoration: BoxDecoration(
                                                          color: colors.fill,
                                                          border: Border(
                                                            left: BorderSide(
                                                              color:
                                                                  colors.edge,
                                                              width: 5,
                                                            ),
                                                            bottom: BorderSide(
                                                              color: isSelected
                                                                  ? p.accent
                                                                  : colors.edge
                                                                        .withValues(
                                                                          alpha:
                                                                              .35,
                                                                        ),
                                                              width: 1,
                                                            ),
                                                          ),
                                                        ),
                                                        child: rowCells(
                                                          context,
                                                          [
                                                            item.label,
                                                            item.part,
                                                            item.description,
                                                            numberText(
                                                              item.bomQuantity,
                                                            ),
                                                            numberText(
                                                              item.smtQuantity,
                                                            ),
                                                            item.bomPositions,
                                                            item.smtPositions,
                                                            item.reasons
                                                                .map(
                                                                  (r) =>
                                                                      localText(
                                                                        context,
                                                                        r,
                                                                      ),
                                                                )
                                                                .join('；'),
                                                          ],
                                                          color: colors.ink,
                                                          status: item.status,
                                                          width: tableWidth,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (showDetail && detailsOpen && widget.selected != null) ...[
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 360,
                      child: Pane(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 18,
                                right: 6,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: LText(
                                      '来源与差异详情',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: localText(context, '收起详情'),
                                    icon: const Icon(Icons.close, size: 17),
                                    onPressed: () =>
                                        setState(() => detailsOpen = false),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ItemDetail(
                                item: widget.selected!,
                                onAi: widget.onAi,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        caption(
          context,
          '显示 ${list.length} / ${widget.report.items.length} 条记录 · 点击行查看完整差异 · 已排除和候选料单独统计',
        ),
      ],
    );
  }

  Widget rowCells(
    BuildContext context,
    List<String> values, {
    bool header = false,
    Color? color,
    CheckStatus? status,
    required double width,
  }) {
    final widths = [
      128.0,
      180.0,
      220.0,
      80.0,
      80.0,
      210.0,
      210.0,
      width - 1118,
    ];
    return Row(
      children: [
        for (var i = 0; i < values.length; i++)
          SizedBox(
            width: widths[i],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Tooltip(
                message: header || i == 0
                    ? localText(context, values[i])
                    : values[i],
                child:
                    i == 0 &&
                        (status == CheckStatus.pass ||
                            status == CheckStatus.error)
                    ? ResultBadge(status: status!, label: values[i])
                    : Text(
                        header || i == 0
                            ? localText(context, values[i])
                            : values[i],
                        maxLines: header ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: header ? 11 : 12,
                          height: 1.55,
                          fontWeight: header || i == 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i == 0
                              ? color
                              : header
                              ? Palette.of(context).muted
                              : Palette.of(context).text,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class ItemDetail extends StatelessWidget {
  final CheckItem item;
  final ValueChanged<CheckItem>? onAi;
  const ItemDetail({super.key, required this.item, required this.onAi});
  @override
  Widget build(BuildContext context) {
    final color = Palette.of(context).result(item.status).ink;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultBadge(status: item.status, label: item.label),
          const SizedBox(height: 9),
          SelectableText(
            item.part.isEmpty ? localText(context, '空料号') : item.part,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          if (item.excludedKeywords.isNotEmpty) ...[
            const LText(
              '命中排除关键词',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SelectableText(
              item.excludedKeywords.join('、'),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 18),
          ],
          const LText(
            '核对原因',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final reason in item.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: SelectableText(
                localText(context, reason),
                style: TextStyle(fontSize: 12, height: 1.6, color: color),
              ),
            ),
          if (item.status == CheckStatus.error)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: DeskButton(
                'AI 分析此项',
                icon: Icons.auto_awesome_outlined,
                onPressed: onAi == null
                    ? null
                    : () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                        onAi!(item);
                      },
              ),
            ),
          const Divider(height: 24),
          for (final (title, rows) in [
            ('T100-BOM 原始记录', item.bom),
            ('SMT 站位表原始记录', item.smt),
          ]) ...[
            LText(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty) caption(context, '没有对应记录'),
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Palette.of(context).hover,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '${r.side.isEmpty ? '' : '${localText(context, r.side)} · '}${r.sheet} / ${localText(context, '第 ${r.row} 行')}${r.station.isEmpty ? '' : ' / ${localText(context, '站位 ${r.station}')}'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SelectableText(
                      r.description,
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                    const SizedBox(height: 7),
                    SelectableText(
                      '${localText(context, '数量')}：${r.quantityText.isEmpty ? localText(context, '空') : r.quantityText}\n${localText(context, '位号')}：${r.positionsText.isEmpty ? localText(context, '空') : r.positionsText}',
                      style: const TextStyle(fontSize: 12, height: 1.7),
                    ),
                    const SizedBox(height: 6),
                    caption(context, r.file),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
