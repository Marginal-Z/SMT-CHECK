import 'dart:convert';

import '../core/models.dart';
import '../core/positions.dart';

class ReportExport {
  static String json(CheckReport report) =>
      const JsonEncoder.withIndent('  ').convert(report.toJson());
  static String csv(CheckReport report) {
    String cell(Object? value) {
      var s = value?.toString() ?? '';
      if (RegExp(r'^[\s]*[=+@-]').hasMatch(s)) {
        s = "'$s";
      }
      return '"${s.replaceAll('"', '""')}"';
    }

    final rows = <List<Object?>>[
      [
        '核对模式',
        report.merged ? 'A+B合并' : '单站位表与完整BOM比较',
        '时间',
        report.created.toIso8601String(),
      ],
      [
        '排除启用',
        report.rules.excludeEnabled,
        '排除关键词',
        report.rules.keywords.join('；'),
      ],
      [
        '状态',
        '料号',
        'BOM品名',
        'SMT物料描述',
        'BOM用量',
        'SMT数量',
        'BOM位号',
        'SMT位号',
        '异常/原因',
        'BOM来源',
        'SMT来源',
      ],
      for (final item in report.items)
        [
          item.label,
          item.part,
          item.bom.map((r) => r.description).toSet().join('\n'),
          item.smt.map((r) => r.description).toSet().join('\n'),
          numberText(item.bomQuantity),
          numberText(item.smtQuantity),
          item.bom.map((r) => r.positionsText).join('\n'),
          item.smt.map((r) => r.positionsText).join('\n'),
          item.reasons.join('\n'),
          item.bom.map((r) => r.location).join('\n'),
          item.smt.map((r) => r.location).join('\n'),
        ],
      ['导入审计'],
      for (final f in report.files) ...[
        [f.name, '表头映射', f.mappings.join('\n')],
        [f.name, '导入说明', f.notes.join('\n')],
      ],
    ];
    return '\uFEFF${rows.map((r) => r.map(cell).join(',')).join('\r\n')}';
  }
}
