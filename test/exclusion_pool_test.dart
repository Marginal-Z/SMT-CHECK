import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/checker.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/services/report_export.dart';

import 'checker_test.dart' as f;

void main() {
  for (final desc in ['贴纸', '高温贴纸 10*10', '树脂碳带', '锡膏 SAC305']) {
    test(
      '$desc goes directly into Excluded, even with invalid import fields',
      () {
        final report = f.check([
          f.row('SUPPLY', '1', '', desc: desc, importIssues: ['位号为空']),
        ], []);
        expect(report.errors, isEmpty);
        expect(report.count(CheckStatus.excluded), 1);
        expect(report.items.single.reasons.last, contains('位号为空'));
        expect(report.items.single.excludedKeywords, isNotEmpty);
      },
    );
  }
  test('keyword hit on either source excludes all counterparts across A+B', () {
    for (final hitInBom in [true, false]) {
      final report = Checker().run(
        f.input([
          f.row(' supply ', '1', '', desc: hitInBom ? '贴纸' : 'Label'),
        ], bom: true),
        [
          f.input([
            f.row('SUPPLY', '2', '', desc: hitInBom ? 'Label' : '贴纸'),
          ], path: 'a.xlsx'),
          f.input([
            f.row('supply', '', '', desc: 'Label', candidate: true),
          ], path: 'b.xlsx'),
        ],
        const CheckRules(),
      );
      expect(report.errors, isEmpty);
      expect(report.count(CheckStatus.pass), 0);
      expect(report.count(CheckStatus.candidate), 0);
      expect(report.count(CheckStatus.excluded), 3);
      expect(report.totalPartCount, 1);
      for (final item in report.items) {
        expect(item.excludedKeywords, ['贴纸']);
        expect(item.toJson()['status'], 'excluded');
      }
      expect(
        report.items.where((i) => i.reasons.first.contains('同料号')),
        hasLength(2),
      );
      expect(ReportExport.csv(report), contains('贴纸'));
    }
  });
  test(
    'exclusions never propagate via empty part or missing position alone',
    () {
      final report = f.check([
        f.row('', '1', '', desc: '锡膏'),
        f.row('', '1', '', desc: '电容'),
        f.row('R', '1', '', desc: '电阻'),
      ], []);
      expect(report.count(CheckStatus.excluded), 1);
      expect(report.errors, hasLength(2));
    },
  );
  test('disabling or editing keywords restores material checking', () {
    final rows = [f.row('P', '1', '', desc: '贴纸')];
    for (final rules in [
      const CheckRules(excludeEnabled: false),
      const CheckRules(keywords: ['锡膏']),
    ]) {
      expect(f.check(rows, [], rules: rules).errors, hasLength(1));
    }
    expect(
      CheckRules.restoreKeywords(CheckRules.legacyKeywords),
      contains('贴纸'),
    );
    expect(CheckRules.restoreKeywords(null), CheckRules.defaultKeywords);
    expect(CheckRules.restoreKeywords(['高温贴纸']), ['高温贴纸']);
    expect(CheckRules.restoreKeywords([]), isEmpty);
  });
}
