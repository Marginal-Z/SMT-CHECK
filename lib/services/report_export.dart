import 'dart:convert';

import '../core/models.dart';
import '../core/positions.dart';
import '../l10n/localization.dart';

class ReportExport {
  static String json(CheckReport report, {String language = 'zh'}) {
    final data = report.toJson();
    data['language'] = language;
    data['mode'] = translate(data['mode'] as String, language);
    for (final item in data['items'] as List) {
      item['label'] = translate(item['label'] as String, language);
      item['reasons'] = (item['reasons'] as List)
          .map((r) => translate(r as String, language))
          .toList();
    }
    for (final file in data['files'] as List) {
      file['notes'] = (file['notes'] as List)
          .map((r) => translate(r as String, language))
          .toList();
      file['mappings'] = (file['mappings'] as List)
          .map((r) => translate(r as String, language))
          .toList();
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String csv(CheckReport report, {String language = 'zh'}) {
    String t(String value) => translate(value, language);
    String location(MaterialRow row) =>
        '${row.file} / ${row.sheet} / ${t('第 ${row.row} 行')}${row.station.isEmpty ? '' : ' / ${t('站位 ${row.station}')}'}';
    String cell(Object? value) {
      var s = value?.toString() ?? '';
      if (RegExp(r'^[\s]*[=+@-]').hasMatch(s)) {
        s = "'$s";
      }
      return '"${s.replaceAll('"', '""')}"';
    }

    final rows = <List<Object?>>[
      [
        t('核对模式'),
        t(report.merged ? 'A+B合并' : '单站位表与完整BOM比较'),
        t('时间'),
        report.created.toIso8601String(),
      ],
      [
        t('排除启用'),
        report.rules.excludeEnabled,
        t('排除关键词'),
        report.rules.keywords.join('；'),
      ],
      [
        t('料号总数量'),
        report.totalPartCount,
        t('BOM料号数量'),
        report.bomPartCount,
        t('SMT站位表料号数量'),
        report.smtPartCount,
      ],
      [t('料号数按去重统计，含已排除和候选料；总数为 BOM 与 SMT 并集，A+B 相同料号只计一次，空料号不计。')],
      [
        '状态',
        '料号',
        'BOM品名',
        'SMT物料描述',
        'BOM用量',
        'SMT数量',
        'BOM插件位置',
        'SMT站位表位号',
        '命中排除关键词',
        '异常/原因',
        'BOM来源',
        'SMT来源',
      ].map(t).toList(),
      for (final item in report.items)
        [
          t(item.label),
          item.part,
          item.bom.map((r) => r.description).toSet().join('\n'),
          item.smt.map((r) => r.description).toSet().join('\n'),
          numberText(item.bomQuantity),
          numberText(item.smtQuantity),
          item.bomPositions,
          item.smtPositions,
          item.excludedKeywords.join('、'),
          item.reasons.map(t).join('\n'),
          item.bom.map(location).join('\n'),
          item.smt.map(location).join('\n'),
        ],
      [t('导入审计')],
      for (final f in report.files) ...[
        [f.name, t('表头映射'), f.mappings.map(t).join('\n')],
        [f.name, t('导入说明'), f.notes.map(t).join('\n')],
      ],
    ];
    return '\uFEFF${rows.map((r) => r.map(cell).join(',')).join('\r\n')}';
  }
}
