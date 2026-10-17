import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/cad_decimal.dart';
import 'package:smt_check/core/coordinate_comparison.dart';
import 'package:smt_check/core/coordinate_reader.dart';
import 'package:smt_check/services/cad_workbook_export.dart';

import 'support/cad_fixture.dart';

CoordinateRecord record(
  String ref, {
  String x = '107.675',
  String y = '0',
  String angle = '0',
  String layer = 'Top',
  String board = '',
  String decal = 'R0402',
  String type = 'RES',
  int pins = 2,
  int row = 2,
}) => CoordinateRecord(
  reference: ref,
  x: double.parse(x),
  y: double.parse(y),
  angle: double.parse(angle),
  layer: layer,
  file: 'sample.xlsx',
  sheet: 'CAD',
  row: row,
  board: board,
  rawX: x,
  rawY: y,
  rawAngle: angle,
  partType: type,
  decal: decal,
  pins: pins,
);
CoordinateComparison compare(
  List<CoordinateRecord> a,
  List<CoordinateRecord> b, {
  bool confirmed = true,
  CadUnit unitA = CadUnit.mm,
  CadUnit unitB = CadUnit.mm,
  CoordinateCompareSettings settings = const CoordinateCompareSettings(),
}) => CoordinateComparator.compare(
  CoordinateImport('A', a, []),
  CoordinateImport('B', b, []),
  settings,
  unitA: unitA,
  unitB: unitB,
  frameConfirmed: confirmed,
);

void main() {
  test(
    'shuffled and case/space normalized references never use row number',
    () {
      final r = compare(
        [record('r1 '), record('C2', row: 3)],
        [record('C2'), record(' R1', row: 900)],
      );
      expect(r.matched, 2);
      expect(r.orderChanged, true);
      expect(r.items.every((i) => !i.isError), true);
    },
  );
  test('decimal tolerance includes exact boundary, excludes next decimal', () {
    for (final x in ['107.67500000000001', '107.676']) {
      expect(
        compare([record('R1')], [record('R1', x: x)]).items.single.isError,
        false,
      );
    }
    expect(
      compare(
        [record('R1')],
        [record('R1', x: '107.67600000000001')],
      ).count(CadDifferenceType.coordinate),
      1,
    );
    expect(CadDecimal.parse('-1e-5').toString(), '-0.00001');
    expect(() => CadDecimal.parse('1e999'), throwsFormatException);
  });
  test(
    'angles wrap around 0/360; tolerance and negative angles are circular',
    () {
      for (final angle in ['360', '-360', '0.001', '359.999']) {
        expect(
          compare(
            [record('R1')],
            [record('R1', angle: angle)],
          ).count(CadDifferenceType.angle),
          0,
        );
      }
      expect(
        compare(
          [record('R1')],
          [record('R1', angle: '359.9989')],
        ).count(CadDifferenceType.angle),
        1,
      );
    },
  );
  test('missing TP remains a real missing component and is classified', () {
    final r = compare(
      [record('R1'), record('TP10_1')],
      [record('R1'), record('C2')],
    );
    expect(r.missing, 1);
    expect(r.added, 1);
    expect(r.specialCount(true), 1);
    final tp = r.items.singleWhere((i) => i.reference == 'TP10_1');
    expect(tp.isError, true);
    expect(tp.special, ['TP']);
    expect(r.decisions, isEmpty);
    r.decide(tp, true, 'Process review');
    expect(tp.isError, true);
    expect(r.missing, 1);
    expect(r.decisions[tp]!.excluded, true);
  });
  test(
    'duplicate composite keys retain every source without arbitrary pairs',
    () {
      final r = compare([record('R1'), record('R1', row: 3)], [record('R1')]);
      expect(r.matched, 0);
      expect(r.count(CadDifferenceType.duplicate), 1);
      expect(r.items.single.a.length, 2);
      expect(r.items.single.b.length, 1);
    },
  );
  test(
    'board and layer disambiguate repeats; insufficient board metadata blocks',
    () {
      final a = [record('R1', board: '1'), record('R1', board: '2')];
      expect(compare(a, a.reversed.toList()).matched, 2);
      expect(compare(a, [record('R1'), record('R1')]).matched, 0);
      final layers = [record('R1'), record('R1', layer: 'Bottom')];
      expect(compare(layers, layers.reversed.toList()).matched, 2);
    },
  );
  test(
    'layer and every supported component attribute have explicit differences',
    () {
      final r = compare(
        [record('R1')],
        [record('R1', layer: 'Bottom', type: 'CAP', decal: 'C0603', pins: 3)],
      );
      expect(r.count(CadDifferenceType.layer), 1);
      expect(r.count(CadDifferenceType.attribute), 1);
      expect(
        r.items.single.differences.map((d) => d.field),
        containsAll(['Layer', 'PartType', 'PartDecal', 'Pins']),
      );
    },
  );
  test(
    'unknown reference frames do not label every coordinate as an anomaly',
    () {
      final r = compare(
        [record('R1')],
        [record('R1', x: '999')],
        confirmed: false,
      );
      expect(r.frameConfirmed, false);
      expect(r.items.single.status, '待确认');
      expect(r.count(CadDifferenceType.coordinate), 0);
      expect(
        compare(
          [record('R1', x: '25.4')],
          [record('R1', x: '1')],
          unitB: CadUnit.inch,
        ).items.single.isError,
        false,
      );
    },
  );
  test(
    'custom compound full-field rules distinguish normal parts and keep data',
    () {
      final s = CoordinateCompareSettings(
        specialRules: [
          SpecialRule(
            'CUSTOM',
            reference: r'X[0-9]+',
            partType: 'TEST',
            decal: 'PAD',
            action: SpecialAction.review,
          ),
        ],
      );
      s.validate();
      expect(s.classify(record('X1', type: 'TEST', decal: 'PAD')).length, 1);
      expect(s.classify(record('X1', type: 'RES', decal: 'PAD')), isEmpty);
      expect(
        const CoordinateCompareSettings().classify(record('ATP1')),
        isEmpty,
      );
      expect(
        CoordinateCompareSettings.decode(s.encode()).specialRules.single.action,
        SpecialAction.review,
      );
      expect(
        () => const CoordinateCompareSettings(xyTolerance: 'NaN').validate(),
        throwsFormatException,
      );
      expect(
        () => const SpecialRule('x', reference: '(a+)+').validate(),
        throwsFormatException,
      );
    },
  );
  test('readback rejects swapped, lost or changed device coordinates', () {
    final p = CadGenerator.generate(cadBom(), cadCoordinates(), CadUnit.mm);
    final other = CadGenerator.generate(
      cadBom(),
      cadCoordinates(x: 999),
      CadUnit.mm,
    );
    expect(
      () => CadWorkbookExport.verify(CadWorkbookExport.encode(other), p),
      throwsFormatException,
    );
    expect(
      () => CadWorkbookExport.verify(CadWorkbookExport.encode(p), p),
      returnsNormally,
    );
  });
  test(
    'reader preserves decimal literals, board and invalid source totals',
    () {
      final dir = Directory.systemTemp.createTempSync('cad-reader-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/input.csv')
        ..writeAsStringSync(
          'RefDes,X/mm,Y/mm,Orient.,Layer,Board\nr1,107.67500000000001,0,360,top,1\nR2,,0,0,Top,1\n',
        );
      final r = CoordinateReader().read(file.path, forComparison: true);
      expect(r.records.single.xText, '107.67500000000001');
      expect(r.records.single.board, '1');
      expect(r.totalCount, 2);
      expect(r.issues.single.reference, 'R2');
      file.writeAsStringSync(
        'RefDes,X/mm,Y/inch,Orient.,Layer\nR1,1,1,0,Top\n',
      );
      expect(
        CoordinateReader()
            .read(file.path, forComparison: true)
            .issues
            .any((i) => i.reason.contains('单位不一致')),
        true,
      );
    },
  );
}
