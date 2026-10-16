import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/l10n/catalog.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/report_export.dart';

import 'checker_test.dart' as fixture;

void main() {
  test('all messages have complete English and Thai entries and matching placeholders', () {
    Set<String> keys(String s) =>
        RegExp(r'\{\w+\}').allMatches(s).map((m) => m[0]!).toSet();
    for (final entry in catalog.entries) {
      expect(entry.value.length, 2, reason: entry.key);
      for (final translation in entry.value) {
        expect(translation, isNotEmpty, reason: entry.key);
        expect(keys(translation), keys(entry.key), reason: entry.key);
      }
    }
  });
  test('dynamic domain reasons translated while retaining source evidence', () {
    expect(translate('SMT 缺少位号：R1、R2', 'en'), 'SMT missing references: R1、R2');
    final reason = translate('input.xlsx 第 42 行：数量 3 与位号数 2 不一致', 'th');
    expect(reason, contains('input.xlsx'));
    expect(reason, contains('42'));
    expect(reason, contains('จำนวน 3'));
    expect(reason, isNot(contains('不一致')));
    expect(
      translate('数量不符：BOM 1，SMT 2，差额 1（SMT − BOM）', 'en'),
      contains('Quantity mismatch'),
    );
    expect(
      translate('BOM 位号 4U1 跨行重复/冲突：K1（A Sheet:3）', 'th'),
      contains('4U1'),
    );
    expect(translate('第 3 行', 'en'), 'Row 3');
    expect(translate('未知原始字段', 'en'), '未知原始字段');
  });
  test(
    'localized export translates labels and reasons, never raw descriptions',
    () {
      final report = fixture.check(
        [fixture.row('PART-A', '1', 'R1', desc: '贴片电阻 原始描述')],
        [fixture.row('PART-A', '2', 'R2 R3', desc: '贴片电阻 原始描述')],
      );
      for (final language in ['en', 'th']) {
        final csv = ReportExport.csv(report, language: language);
        expect(csv, contains('贴片电阻 原始描述'));
        expect(csv, contains(translate('异常/原因', language)));
        expect(csv, isNot(contains('SMT 缺少位号')));
        final json = jsonDecode(ReportExport.json(report, language: language));
        expect(json['language'], language);
        expect(json['items'][0]['bom'][0]['description'], '贴片电阻 原始描述');
      }
      expect(report.errors.single.reasons.join(), contains('SMT 缺少位号'));
    },
  );
}
