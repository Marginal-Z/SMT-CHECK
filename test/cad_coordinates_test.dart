import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/coordinate_reader.dart';
import 'package:smt_check/core/station_merge.dart';
import 'package:smt_check/services/background_tasks.dart';
import 'package:smt_check/services/cad_workbook_export.dart';

import 'support/cad_fixture.dart';

void main() {
  test(
    'Bottom uses unselected full-source range and adds 180, not angle negation',
    () {
      final p = CadGenerator.generate(cadBom(), cadCoordinates(), CadUnit.mm);
      expect(p.canExport, isTrue);
      expect(p.rows.single.cells, [
        'RES',
        'R1',
        'R0402',
        2,
        'Bottom',
        210.0,
        10.0,
        70.0,
        'Yes',
        'No',
      ]);
      expect(p.minY, 0);
      expect(p.maxY, 100);
      expect(p.omitted, 2);
      expect(p.rows.single.bom.sources.single.row, 2);
    },
  );
  test('Top is unchanged and negative angles normalize', () {
    final p = CadGenerator.generate(
      cadBom(),
      cadCoordinates(layer: 'Top', angle: 30),
      CadUnit.mm,
    );
    expect(p.rows.single.angle, 30);
    expect(p.rows.single.y, 30);
    expect(
      CadGenerator.generate(
        cadBom(),
        cadCoordinates(angle: -270),
        CadUnit.mm,
      ).rows.single.angle,
      270,
    );
  });
  test('units are explicit regardless of coordinate magnitude', () {
    final p = CadGenerator.generate(
      cadBom(),
      cadCoordinates(x: 600),
      CadUnit.mm,
    );
    expect(p.rows.single.x, 600);
    final mil = CadGenerator.generate(
      cadBom(),
      cadCoordinates(x: 400),
      CadUnit.mil,
    );
    expect(mil.rows.single.x, closeTo(10.16, 1e-9));
    expect(mil.rows.single.y, closeTo(1.778, 1e-9));
    expect(
      CadGenerator.generate(
        cadBom(),
        cadCoordinates(x: 1),
        CadUnit.inch,
      ).rows.single.x,
      25.4,
    );
  });
  test(
    'BOM order is retained; raw identifiers are not inferred from part number',
    () {
      final bom = cadBom(positions: 'MARK2 R1', quantity: '2');
      expect(
        CadGenerator.generate(
          bom,
          cadCoordinates(),
          CadUnit.mm,
        ).rows.map((r) => r.source.reference),
        ['MARK2', 'R1'],
      );
    },
  );
  test('missing and duplicate coordinates prevent export', () {
    final original = cadCoordinates();
    final missing = CadGenerator.generate(
      cadBom(positions: 'R9'),
      original,
      CadUnit.mm,
    );
    expect(missing.canExport, isFalse);
    expect(
      missing.errors.singleWhere((i) => i.reference == 'R9').reason,
      contains('缺少原始坐标'),
    );
    final duplicate = CadGenerator.generate(
      cadBom(),
      CoordinateImport('coords.xlsx', [
        ...original.records,
        original.records.last,
      ], []),
      CadUnit.mm,
    );
    expect(duplicate.canExport, isFalse);
    expect(duplicate.errors.any((i) => i.reference == 'MARK2'), isTrue);
    expect(() => CadWorkbookExport.encode(duplicate), throwsFormatException);
  });
  test('conflicting BOM references, fractions and missing quantities prevent export', () {
    final original = cadBom();
    final conflict = MergedStationFile(
      rows: [
        ...original.rows,
        ...cadBom(part: 'OTHER').rows,
      ],
      includedSourceRows: 2,
      omittedSourceRows: 0,
      revision: 0,
      mode: MergeMode.details,
    );
    expect(
      CadGenerator.generate(conflict, cadCoordinates(), CadUnit.mm).canExport,
      isFalse,
    );
      for (final quantity in ['', 'x', '0.5', '2', '-1', '1,5']) {
      expect(
        CadGenerator.generate(
          cadBom(quantity: quantity),
          cadCoordinates(),
          CadUnit.mm,
        ).canExport,
        isFalse,
        reason: quantity,
      );
    }
  });
  test('blank candidate is counted, while a nonzero quantity without references blocks', () {
    final p = CadGenerator.generate(
      cadBom(positions: '', quantity: ''),
      cadCoordinates(),
      CadUnit.mm,
    );
    expect(p.noReferenceRows, 1);
    expect(p.canExport, isFalse);
    expect(
      CadGenerator.generate(
        cadBom(positions: '', quantity: '1'),
        cadCoordinates(),
        CadUnit.mm,
      ).errors.any((i) => i.reason.contains('有用量')),
      isTrue,
    );
  });

  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('smt-cad-test-'));
  tearDown(() => temp.deleteSync(recursive: true));
  File textFile(String content, [String name = 'coordinates.csv']) =>
      File('${temp.path}/$name')..writeAsStringSync(content, encoding: utf8);
  test(
    'CSV aliases, quoted comma and embedded newline preserve source data',
    () {
      final file = textFile(
        'Name,X/mm,Y/mm,Orientation,Layer,Part Type,Package\r\n'
        'r1,10,30,30,Bottom,"type, value","package\nline"\r\n',
      );
      final result = CoordinateReader().read(file.path);
      expect(result.unitHint, CadUnit.mm);
      expect(result.records.single.reference, 'R1');
      expect(result.records.single.partType, 'type, value');
      expect(result.records.single.decal, 'package\nline');
      expect(result.records.single.row, 2);
      expect(result.records.single.raw['Name'], 'r1');
    },
  );
  test('blank X is reported, a real zero remains valid', () {
    final file = textFile(
      'RefDes,X,Y,Orient.,Layer\nR1,,0,0,Top\nR2,0,0,0,Top\n',
    );
    final result = CoordinateReader().read(file.path);
    expect(result.records.single.reference, 'R2');
    expect(result.records.single.x, 0);
    expect(result.issues.single.reason, contains('X 坐标为空'));
    expect(result.issues.single.row, 2);
  });
  test('non-finite coordinate, bad layer and bad angle are visible', () {
    final f = textFile(
      'RefDes,X,Y,Orient.,Layer\nR1,NaN,2,0,Top\nR2,1,2,no,Top\nR3,1,2,30,Unknown\n',
    );
    final data = CoordinateReader().read(f.path);
    expect(data.records, isEmpty);
    expect(data.issues.length, 3);
    expect(
      CadGenerator.generate(cadBom(), data, CadUnit.mm).canExport,
      isFalse,
    );
  });
  test(
    'legacy no-header text and leading blank lines retain one-based rows',
    () {
      final result = CoordinateReader().read(
        textFile('\n# comment\nR1 10 30 30 m R0402\n', 'coordinates.txt').path,
      );
      expect(result.records.single.layer, 'Bottom');
      expect(result.records.single.row, 3);
      expect(result.records.single.decal, 'R0402');
    },
  );
  test('missing side and malformed CSV are rejected', () {
    expect(
      () => CoordinateReader().read(textFile('Name,X,Y\nR1,1,2\n').path),
      throwsFormatException,
    );
    expect(
      () => CoordinateReader().read(
        textFile('Name,X,Y,Layer\nR1,1,2,"Top\n').path,
      ),
      throwsFormatException,
    );
  });
  test('native OOXML export has exact schema, numeric types and four decimal display', () async {
    final preview = CadGenerator.generate(
      cadBom(),
      cadCoordinates(),
      CadUnit.mm,
    );
    final bytes = await encodeCadInBackground(preview);
    final file = File('${temp.path}/output.xlsx')..writeAsBytesSync(bytes);
    final decoded = CoordinateReader().read(file.path);
    expect(decoded.records.single.reference, 'R1');
    expect(decoded.records.single.y, 70);
    expect(decoded.records.single.angle, 210);
    final zip = ZipDecoder().decodeBytes(bytes);
    final sheet = utf8.decode(
      zip.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
    );
    expect(sheet, contains('r="G2" t="n"'));
    expect(sheet, isNot(contains('<f>')));
    expect(
      utf8.decode(zip.findFile('xl/styles.xml')!.content as List<int>),
      contains('formatCode="0.0000"'),
    );
    expect(
      utf8.decode(zip.findFile('xl/workbook.xml')!.content as List<int>),
      contains('name="Sheet1"'),
    );
  });
  test(
    'spreadsheet-looking metadata is literal text and unsafe XML is rejected',
    () {
      final data = CoordinateImport('coords.xlsx', [
        CoordinateRecord(
          reference: 'R1',
          x: 0,
          y: 0,
          angle: 0,
          layer: 'Top',
          file: 'coords.xlsx',
          sheet: 'CAD',
          row: 2,
          partType: '=HYPERLINK("bad")',
        ),
      ], []);
      final zip = ZipDecoder().decodeBytes(
        CadWorkbookExport.encode(
          CadGenerator.generate(cadBom(), data, CadUnit.mm),
        ),
      );
      final sheet = utf8.decode(
        zip.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      expect(sheet, contains('inlineStr'));
      expect(sheet, isNot(contains('<f>')));
    },
  );
  test('export guard protects originals and manual names keep xlsx once', () {
    final original = File('${temp.path}/input.xlsx')
      ..writeAsStringSync('original');
    expect(
      CadWorkbookExport.targetsOriginal(original.path, [original.path]),
      isTrue,
    );
    expect(
      CadWorkbookExport.targetsOriginal('${temp.path}/new.xlsx', [
        original.path,
      ]),
      isFalse,
    );
    expect(original.readAsStringSync(), 'original');
    expect(cadFileName('Order CAD.xlsx'), 'Order CAD.xlsx');
    expect(cadFileName('Order CAD'), 'Order CAD.xlsx');
    for (final bad in ['', '../input', 'CON', 'name/other', 'name.']) {
      expect(() => cadFileName(bad), throwsFormatException);
    }
  });
}
