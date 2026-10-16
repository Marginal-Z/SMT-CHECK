import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/checker.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/text_difference.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/report_export.dart';

import 'checker_test.dart' as f;

void main() {
  List<String> fragments(String text, List<TextChangeRange> ranges) =>
      ranges.map((r) => text.substring(r.start, r.end)).toList();
  test(
    'same file names and row numbers on A/B remain individually traceable',
    () {
      MaterialRow side(String side) => MaterialRow(
        part: 'A',
        description: '电阻 10K',
        quantityText: '1',
        positionsText: 'R1',
        file: 'same.xlsx',
        sheet: 'Sheet',
        row: 5,
        side: side,
      );
      final report = Checker().run(
        f.input([f.row('A', '3', 'R1,R2,R3')], bom: true),
        [
          f.input([side('A')], path: 'a/same.xlsx'),
          f.input([side('B')], path: 'b/same.xlsx'),
        ],
        const CheckRules(),
      );
      final item = report.errors.single;
      final diff = item.fieldDifferences.firstWhere(
        (d) => d.field == DifferenceField.quantity,
      );
      expect(diff.smtSources, [
        'A · same.xlsx / Sheet:5',
        'B · same.xlsx / Sheet:5',
      ]);
      final conflict = item.reasons.firstWhere((r) => r.contains('跨行重复'));
      expect(conflict, contains('A · same.xlsx'));
      expect(conflict, contains('B · same.xlsx'));
    },
  );

  test('description highlights point to actual specifications without changing source text', () {
    const bom = '贴片电阻 10K ±5% 0402';
    const smt = '贴片电阻 20K ±1% 0603';
    final item = f
        .check(
          [f.row('PART', '1', 'R1', desc: bom)],
          [f.row('PART', '1', 'R1', desc: smt)],
        )
        .errors
        .single;
    final diff = item.fieldDifferences.single;
    expect(diff.field, DifferenceField.description);
    expect(diff.bomValue, bom);
    expect(diff.smtValue, smt);
    expect(fragments(bom, diff.bomHighlights), contains('10K'));
    expect(fragments(smt, diff.smtHighlights), contains('20K'));
    expect(item.reasons.join(), contains('BOM「$bom」；SMT「$smt」'));
    expect(diff.bomSources.single, contains('Sheet:2'));
    expect(item.bom.single.description, bom);
  });
  test(
    'case, whitespace, line breaks and uppercase expansions stay ignored',
    () {
      for (final (bom, smt) in [
        ('RT0201\n10K ±5%', 'rt0201 10k ±5%'),
        ('1 0 K', '10K'),
        ('ä 😀', 'Ä😀'),
      ]) {
        final diff = compareDescriptionText(bom, smt);
        expect(diff.bom, isEmpty);
        expect(diff.smt, isEmpty);
      }
    },
  );
  test(
    'insertions, removals, decimals and unicode retain valid original ranges',
    () {
      for (final (bom, smt) in [
        ('10K', '100K'),
        ('0.1UF', '0.01UF'),
        ('品牌😀电容', '品牌😃电容'),
        ('', '新增'),
        ('移除', ''),
      ]) {
        final diff = compareDescriptionText(bom, smt);
        expect(diff.bom.isNotEmpty || diff.smt.isNotEmpty, true);
        for (final (raw, ranges) in [(bom, diff.bom), (smt, diff.smt)]) {
          var end = 0;
          for (final range in ranges) {
            expect(range.start, greaterThanOrEqualTo(end));
            expect(range.end, lessThanOrEqualTo(raw.length));
            expect(range.end, greaterThan(range.start));
            expect(
              raw.substring(range.start, range.end),
              isNot(contains('\uFFFD')),
            );
            end = range.end;
          }
        }
      }
    },
  );
  test(
    'unusually long descriptions use a bounded comparison and preserve suffix',
    () {
      final prefix = List.filled(3000, '共同').join();
      final bom = '${prefix}10K 尾部';
      final smt = '${prefix}20K 尾部';
      final diff = compareDescriptionText(bom, smt);
      expect(fragments(bom, diff.bom), ['10K']);
      expect(fragments(smt, diff.smt), ['20K']);
    },
  );
  test(
    'quantity and reference evidence explains more and fewer separately',
    () {
      for (final (sq, positions, direction, qty) in [
        ('3', 'R1,R2,R3', '多', '1'),
        ('1', 'R1', '少', '1'),
      ]) {
        final item = f
            .check([f.row('A', '2', 'R1,R2')], [f.row('A', sq, positions)])
            .errors
            .single;
        final q = item.fieldDifferences.singleWhere(
          (d) => d.field == DifferenceField.quantity,
        );
        expect(q.bomValue, '2');
        expect(q.smtValue, sq);
        expect(q.reason, 'SMT 比 BOM $direction $qty');
        final p = item.fieldDifferences.singleWhere(
          (d) => d.field == DifferenceField.positions,
        );
        expect(p.highlightText, true);
        expect(p.reason, contains(direction == '多' ? '多出位号：R3' : '缺少位号：R2'));
      }
    },
  );
  test('only missing and extra references are highlighted', () {
    final item = f
        .check(
          [f.row('A', '3', '4U1,3U2,R10')],
          [f.row('A', '3', '4U1,3U2,R11')],
        )
        .errors
        .single;
    final diff = item.fieldDifferences.single;
    expect(fragments(diff.bomValue, diff.bomHighlights), ['R10']);
    expect(fragments(diff.smtValue, diff.smtHighlights), ['R11']);
  });
  test(
    'wrong ownership identifies the specific position and both part numbers',
    () {
      final report = f.check(
        [f.row('BOM-PART', '1', '4U1')],
        [f.row('SMT-PART', '1', '4U1')],
      );
      expect(report.errors, hasLength(2));
      for (final item in report.errors) {
        final ownership = item.fieldDifferences.singleWhere(
          (d) => d.title == '位号 4U1 对应料号',
        );
        expect(ownership.bomValue, 'BOM-PART');
        expect(ownership.smtValue, 'SMT-PART');
        expect(item.reasons.join(), contains('位号 4U1 对应料号不一致'));
        expect(ownership.bomMissing, false);
        expect(ownership.smtMissing, false);
      }
    },
  );
  test(
    'multirow descriptions are explained without pretending one-to-one pairing',
    () {
      final item = f
          .check(
            [
              f.row('A', '1', 'R1', desc: '电阻10K'),
              f.row('A', '1', 'R2', desc: '电阻20K', line: 3),
            ],
            [f.row('A', '2', 'R1,R2', desc: '电阻10K')],
          )
          .errors
          .single;
      final diff = item.fieldDifferences.single;
      expect(diff.bomValue, '电阻10K\n电阻20K');
      expect(diff.highlightText, false);
      expect(diff.bomSources, hasLength(2));
      expect(item.reasons.join(), contains('BOM 同一料号存在 2 种不同描述'));
    },
  );
  test('A+B quantity comparisons use totals and retain both source files', () {
    final report = Checker().run(
      f.input([f.row('A', '3', 'R1,R2,R3')], bom: true),
      [
        f.input([f.row('A', '1', 'R1', file: 'side-a.xlsx')], path: 'a.xlsx'),
        f.input([f.row('A', '1', 'R2', file: 'side-b.xlsx')], path: 'b.xlsx'),
      ],
      const CheckRules(),
    );
    final q = report.errors.single.fieldDifferences.firstWhere(
      (d) => d.field == DifferenceField.quantity,
    );
    expect(q.bomValue, '3');
    expect(q.smtValue, '2');
    expect(q.smtSources.join(), contains('side-a.xlsx'));
    expect(q.smtSources.join(), contains('side-b.xlsx'));
  });
  test('missing records differ from blank values; PASS and excluded keep their classifications', () {
    final missing = f.check([f.row('ONLY-BOM', '1', 'R1')], []).errors.single;
    final part = missing.fieldDifferences.first;
    expect(part.bomMissing, false);
    expect(part.smtMissing, true);
    final report = f.check(
      [f.row('PASS', '1', 'R1'), f.row('PASTE', '.2', '', desc: '锡膏')],
      [f.row('PASS', '1', 'R1')],
    );
    expect(report.errors, isEmpty);
    for (final item in report.items) {
      expect(item.fieldDifferences, isEmpty);
    }
  });
  test('localized exports preserve original values, highlight fragments and traceability', () {
    const bom = '原始名称 10K ±5%';
    const smt = '原始名称 20K ±1%';
    final report = f.check(
      [f.row('A', '1', 'R1', desc: bom)],
      [f.row('A', '2', 'R2,R3', desc: smt)],
    );
    for (final language in ['zh', 'en', 'th']) {
      final csv = ReportExport.csv(report, language: language);
      expect(csv, contains(bom));
      expect(csv, contains(smt));
      expect(csv, contains(translate('字段差异', language)));
      final data = jsonDecode(ReportExport.json(report, language: language));
      final diff = (data['items'][0]['fieldDifferences'] as List).firstWhere(
        (d) => d['field'] == 'description',
      );
      expect(diff['bomValue'], bom);
      expect(diff['smtValue'], smt);
      expect(diff['bomHighlights'], isNotEmpty);
      expect(diff['bomSources'][0], contains('Sheet:2'));
      expect(
        diff['reason'],
        contains(
          language == 'zh'
              ? '不一致'
              : language == 'en'
              ? 'mismatch'
              : 'ไม่ตรงกัน',
        ),
      );
      expect(
        csv,
        isNot(
          language == 'zh'
              ? contains('impossible-marker')
              : contains('SMT 缺少位号'),
        ),
      );
    }
  });
}
