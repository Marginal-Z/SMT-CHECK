import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/coordinate_comparison.dart';
import 'package:smt_check/core/coordinate_reader.dart';
import 'package:smt_check/services/cad_workbook_export.dart';
import 'package:smt_check/core/special_pattern.dart';

import 'support/cad_fixture.dart';
import 'coordinate_comparison_test.dart' show record;

void main() {
  test(
    'review rules stay pending until explicit retain or exclude decisions',
    () {
      final s = CoordinateCompareSettings(
        specialRules: [
          const SpecialRule(
            'TP',
            reference: 'TP[0-9]+',
            action: SpecialAction.review,
          ),
        ],
      );
      final r = CoordinateComparator.compare(
        CoordinateImport('A', [record('TP1')], []),
        CoordinateImport('B', [record('TP1')], []),
        s,
        unitA: CadUnit.mm,
        unitB: CadUnit.mm,
        frameConfirmed: true,
      );
      final item = r.items.single;
      expect(item.status, 'PASS');
      expect(r.reviewPending(item), true);
      expect(r.displayStatus(item), '待人工确认');
      r.decide(item, true, 'not in this process');
      expect(r.reviewPending(item), false);
      expect(r.displayStatus(item), '已排除物料');
      expect(item.status, 'PASS');
      r.decide(item, false, 'process changed');
      expect(r.displayStatus(item), 'PASS');
      expect(r.decisionHistory.length, 2);
    },
  );
  test('invalid panel member is quality data, not a false extra component', () {
    final dir = Directory.systemTemp.createTempSync('cad-panel-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/a.csv')
      ..writeAsStringSync(
        'RefDes,X,Y,Orient.,Layer,Board\nR1,1,2,0,Top,1\nR1,,2,0,Top,2\n',
      );
    final a = CoordinateReader().read(file.path, forComparison: true);
    final r = CoordinateComparator.compare(
      a,
      CoordinateImport('b', [
        record('R1', board: '1'),
        record('R1', board: '2'),
      ], []),
      const CoordinateCompareSettings(),
      unitA: CadUnit.mm,
      unitB: CadUnit.mm,
      frameConfirmed: true,
    );
    expect(r.added, 0);
    expect(r.count(CadDifferenceType.quality), 1);
    expect(r.items.single.b.length, 2);
  });
  test('nonzero coordinate underflow is not silently turned into zero', () {
    final dir = Directory.systemTemp.createTempSync('cad-underflow-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/input.csv')
      ..writeAsStringSync('RefDes,X,Y,Orient.,Layer\nR1,1e-400,1,0,Top\n');
    final r = CoordinateReader().read(file.path);
    expect(r.records, isEmpty);
    expect(r.issues.single.reason, 'CAD 数值格式无效或超出比较范围');
    expect(r.totalCount, 1);
  });
  test(
    'invalid coordinates are data quality, never false added components',
    () {
      final a = CoordinateImport('A', [], [
        const CadIssue('invalid X', reference: 'R1', row: 2),
      ]);
      final r = CoordinateComparator.compare(
        a,
        CoordinateImport('B', [record('R1')], []),
        const CoordinateCompareSettings(),
        unitA: CadUnit.mm,
        unitB: CadUnit.mm,
        frameConfirmed: true,
      );
      expect(r.added, 0);
      expect(r.missing, 0);
      expect(r.matched, 0);
      expect(r.count(CadDifferenceType.quality), 1);
      expect(r.items.single.reference, 'R1');
      expect(r.items.single.issues.single.reason, 'invalid X');
    },
  );
  test(
    'special full-field patterns have bounded matching for long imported text',
    () {
      for (final pattern in [
        '[0-9]*TP[0-9]+[_0-9A-Z]*',
        'TP|TESTPOINT',
        'A?B+',
        '.*.*.*Z',
      ]) {
        final safe = SpecialPattern(pattern),
            regex = RegExp('^(?:$pattern)\$', caseSensitive: false);
        for (final value in [
          'TP10_1',
          '1TP2',
          'R1',
          'TESTPOINT',
          'testpoint',
          'ABBB',
          'BBB',
          'z',
          'ABCZ',
          'XYZ!',
        ]) {
          expect(
            safe.matches(value),
            regex.hasMatch(value),
            reason: '$pattern / $value',
          );
        }
      }
      expect(SpecialPattern('.*.*.*Z').matches('A' * 32767), false);
      expect(SpecialPattern('.*.*.*Z').matches('${'A' * 32766}Z'), true);
    },
  );
  test('invalid repeated rows cannot be hidden by a valid record', () {
    final dir = Directory.systemTemp.createTempSync('cad-quality-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(
      '${dir.path}/input.csv',
    )..writeAsStringSync('RefDes,X,Y,Orient.,Layer\nR1,1,2,0,Top\nr1,,2,0,t\n');
    final a = CoordinateReader().read(file.path, forComparison: true);
    expect(a.totalCount, 2);
    expect(a.records.length, 1);
    final r = CoordinateComparator.compare(
      a,
      CoordinateImport('B', [record('R1')], []),
      const CoordinateCompareSettings(),
      unitA: CadUnit.mm,
      unitB: CadUnit.mm,
      frameConfirmed: true,
    );
    expect(r.matched, 0);
    expect(r.count(CadDifferenceType.duplicate), 1);
    expect(r.count(CadDifferenceType.quality), greaterThan(0));
    expect(r.repeatedReferences(true), 1);
    expect(CadGenerator.generate(cadBom(), a, CadUnit.mm).canExport, false);
    file.writeAsStringSync('RefDes,X,Y,Layer\nR1,1,2,Top\n');
    expect(
      () => CoordinateReader().read(file.path, forComparison: true),
      throwsFormatException,
    );
    file.writeAsStringSync('RefDes,X,X/mm,Y,Orient.,Layer\nR1,1,1,2,0,Top\n');
    expect(() => CoordinateReader().read(file.path), throwsFormatException);
  });
  test(
    'mixed coordinate units remain pending even after frame confirmation',
    () {
      final a = CoordinateImport(
        'A',
        [record('R1')],
        [const CadIssue('unit conflict', code: 'unit')],
      );
      final r = CoordinateComparator.compare(
        a,
        CoordinateImport('B', [record('R1', x: '999')], []),
        const CoordinateCompareSettings(),
        unitA: CadUnit.mm,
        unitB: CadUnit.mm,
        frameConfirmed: true,
      );
      expect(r.frameConfirmed, false);
      expect(r.count(CadDifferenceType.coordinate), 0);
      expect(r.count(CadDifferenceType.quality), 1);
    },
  );
  test('generation linkage survives BOM and CAD reordering', () {
    final source = cadCoordinates();
    final a = CadGenerator.generate(
      cadBom(positions: 'R1 MARK2', quantity: '2'),
      source,
      CadUnit.mm,
    );
    final b = CadGenerator.generate(
      cadBom(positions: 'MARK2 R1', quantity: '2'),
      CoordinateImport('coords', source.records.reversed.toList(), []),
      CadUnit.mm,
    );
    expect(a.canExport, true);
    expect(b.canExport, true);
    final data = {for (final row in a.rows) row.source.reference: row.cells};
    for (final row in b.rows) {
      expect(row.cells, data[row.source.reference]);
    }
    expect(
      () => CadWorkbookExport.verify(CadWorkbookExport.encode(b), a),
      returnsNormally,
    );
    expect(source.records.first.y, 30);
  });
}
