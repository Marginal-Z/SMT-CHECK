import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/station_merge.dart';
import 'package:smt_check/core/xlsx_reader.dart';
import 'package:smt_check/services/background_tasks.dart';
import 'package:smt_check/services/merged_workbook_export.dart';

import 'support/merge_fixture.dart';

StationMergeSession passSession(List<MaterialRow> a, List<MaterialRow> b) =>
    StationMergeSession(
      CheckReport(
        [
          for (final row in [...a, ...b])
            CheckItem(
              part: row.part,
              status: CheckStatus.pass,
              bom: [],
              smt: [row],
              reasons: ['PASS'],
            ),
        ],
        const CheckRules(),
        true,
        [
          const ImportedFile('BOM.xlsx', InputKind.bom, [], [], []),
          ImportedFile('A.xlsx', InputKind.station, a, [], []),
          ImportedFile('B.xlsx', InputKind.station, b, [], []),
        ],
      ),
    );

void main() {
  test('single station preserves reviewed source coverage and cannot invent other-side rows', () {
    final report = singleReport(),
        session = StationMergeSession(singleReport());
    expect(session.hasStationInput, isTrue);
    expect(session.pendingCount, 4);
    expect(() => session.generate(MergeMode.details), throwsStateError);
    for (final item in session.requiredItems) {
      session.confirm(item, include: false);
    }
    final preview = session.generate(MergeMode.details);
    expect(preview.rows.single.positions, 'R1');
    expect(preview.includedSourceRows, 1);
    expect(preview.omittedSourceRows, 3);
    expect(session.canExport, isTrue);
    expect(
      session.report.items.map((i) => i.status),
      report.items.map((i) => i.status),
    );
    session.revoke(session.requiredItems.first);
    expect(session.canExport, isFalse);
  });
  test(
    'background check preserves source identity for safe merged export',
    () async {
      final a = sourceRow('P1', '1', 'R1');
      final b = sourceRow('P1', '1', 'R2', side: 'B');
      final report = await checkInBackground(
        ImportedFile(
          'BOM.xlsx',
          InputKind.bom,
          [sourceRow('P1', '2', 'R1,R2')],
          [],
          [],
        ),
        [
          ImportedFile('A.xlsx', InputKind.station, [a], [], []),
          ImportedFile('B.xlsx', InputKind.station, [b], [], []),
        ],
        const CheckRules(),
      );
      final session = StationMergeSession(report);
      expect(session.requiredItems, isEmpty);
      expect(session.generate(MergeMode.summarize).rows.single.cells, [
        'P1',
        '电阻 10K',
        '2',
        'R1\nR2',
      ]);
    },
  );

  test('every NG, excluded and candidate needs explicit review before merge/export', () {
    final report = mergeReport(), session = StationMergeSession(mergeReport());
    expect(session.pendingCount, 3);
    expect(() => session.generate(MergeMode.summarize), throwsStateError);
    final items = session.requiredItems;
    session.confirm(items[0], include: true);
    session.confirm(items[1], include: false);
    expect(session.pendingCount, 1);
    expect(session.canGenerate, isFalse);
    session.confirm(items[2], include: false);
    expect(session.canGenerate, isTrue);
    expect(session.canExport, isFalse);
    final preview = session.generate(MergeMode.summarize);
    expect(preview.rows.map((r) => r.cells), [
      ['00123', '电阻 10K', '2', 'R1\nR2'],
      ['NG-PART', '电阻 10K', '2', 'C1'],
    ]);
    expect(preview.includedSourceRows, 3);
    expect(preview.omittedSourceRows, 2);
    expect(session.canExport, isTrue);
    expect(
      session.report.items.map((i) => i.status),
      report.items.map((i) => i.status),
    );
    session.revoke(items[1]);
    expect(session.preview, isNull);
    expect(session.canExport, isFalse);
    expect(session.pendingCount, 1);
  });

  test('confirmation is tied to report item identity and never reused for a new check', () {
    final session = StationMergeSession(mergeReport());
    expect(
      () => session.confirm(mergeReport().items[1], include: true),
      throwsArgumentError,
    );
    for (final i in session.requiredItems) {
      session.confirm(i, include: false);
    }
    session.generate(MergeMode.details);
    final fresh = StationMergeSession(session.report);
    expect(fresh.pendingCount, 3);
    expect(fresh.preview, isNull);
  });

  test(
    'BOM-only exceptions require acknowledgment and cannot invent SMT records',
    () {
      final report = mergeReport();
      final missing = CheckItem(
        part: 'BOM-ONLY',
        status: CheckStatus.error,
        bom: [sourceRow('BOM-ONLY', '1', 'U1')],
        smt: [],
        reasons: ['SMT 缺失'],
      );
      report.items.add(missing);
      final session = StationMergeSession(report);
      expect(
        () => session.confirm(missing, include: true),
        throwsArgumentError,
      );
      session.confirm(missing, include: false);
      expect(session.reviewFor(missing)!.include, isFalse);
    },
  );

  test('same part across excluded A/B rows keeps separate decisions', () {
    final a = sourceRow('PASTE', '1', '', description: '锡膏');
    final b = sourceRow('PASTE', '2', '', description: '锡膏', side: 'B');
    final base = passSession([a], [b]).report;
    final items = [
      for (final row in [a, b])
        CheckItem(
          part: row.part,
          status: CheckStatus.excluded,
          bom: [],
          smt: [row],
          reasons: ['锡膏'],
        ),
    ];
    final session = StationMergeSession(
      CheckReport(items, base.rules, true, base.files),
    );
    session.confirm(items[0], include: false);
    expect(session.pendingCount, 1);
    session.confirm(items[1], include: true);
    expect(session.generate(MergeMode.summarize).rows.single.quantity, '2');
  });

  test('detail mode preserves A then B raw fields, blanks and duplicated references', () {
    final a = sourceRow('001', '1.00', 'R1,R1', description: '=SUM(1,2)');
    final b = sourceRow(
      '001',
      '',
      ' R2\nR3 ',
      description: '=SUM(1,2)',
      side: 'B',
    );
    final session = passSession([a], [b]);
    final rows = session.generate(MergeMode.details).rows;
    expect(rows.map((r) => r.cells), [
      ['001', '=SUM(1,2)', '1.00', 'R1,R1'],
      ['001', '=SUM(1,2)', '', ' R2\nR3 '],
    ]);
    expect(rows[0].sources.single, same(a));
    expect(rows[1].sources.single, same(b));
  });

  test('summary uses exact part/description, exact decimal arithmetic and retains invalid quantities', () {
    final session = passSession(
      [
        sourceRow('001', '.1', 'R1'),
        sourceRow('001', '', ''),
        sourceRow('001', '1', 'R3', description: 'Other'),
        sourceRow('001 ', '1', 'R4'),
      ],
      [
        sourceRow('001', '2e-1', 'R1', side: 'B'),
        sourceRow('001', 'bad', '', side: 'B'),
      ],
    );
    final rows = session.generate(MergeMode.summarize).rows;
    expect(rows.length, 5);
    expect(rows.first.quantity, '0.3');
    expect(rows.first.positions, 'R1\nR1');
    expect(rows.map((r) => r.quantity), ['0.3', '', '1', '1', 'bad']);
    expect(rows.map((r) => r.sources.length).reduce((a, b) => a + b), 6);
  });

  test(
    'single station and incomplete or duplicate report coverage fail closed',
    () {
      final report = mergeReport();
      final single = StationMergeSession(
        CheckReport(report.items, report.rules, false, report.files),
      );
      expect(single.canGenerate, isFalse);
      expect(() => single.generate(MergeMode.details), throwsStateError);
      final session = passSession([sourceRow('X', '1', 'U1')], []);
      session.report.items.clear();
      expect(() => session.generate(MergeMode.details), throwsStateError);
      final duplicate = passSession([sourceRow('X', '1', 'U1')], []);
      duplicate.report.items.add(duplicate.report.items.first);
      expect(() => duplicate.generate(MergeMode.details), throwsStateError);
    },
  );

  test('Excel export roundtrips the four headers, source fields and literal formulas safely', () async {
    final a = sourceRow(
      '0000123',
      '1,000',
      'R1\nR2',
      description: '=HYPERLINK("http://invalid") & <测试> ไทย',
    );
    final b = sourceRow('=1+1', '', '', description: '备用', side: 'B');
    final output = passSession([a], [b]).generate(MergeMode.details);
    final bytes = await encodeMergedWorkbookInBackground(output);
    final zip = ZipDecoder().decodeBytes(bytes);
    final xml = XmlDocument.parse(
      utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content),
    );
    expect(xml.findAllElements('f'), isEmpty);
    expect(
      xml
          .findAllElements('row')
          .first
          .findAllElements('t')
          .map((e) => e.innerText),
      MergedStationFile.headers,
    );
    expect(
      xml
          .findAllElements('c')
          .firstWhere((e) => e.getAttribute('r') == 'C2')
          .getAttribute('t'),
      'n',
    );
    final temp = Directory.systemTemp.createTempSync('smt-merge-');
    try {
      final file = File('${temp.path}/自定义-BOM.xlsx')..writeAsBytesSync(bytes);
      final read = XlsxReader().read(file.path, InputKind.station);
      expect(read.rows.length, 2);
      expect(read.rows.first.part, a.part);
      expect(read.rows.first.description, a.description);
      expect(read.rows.first.quantityText, '1000');
      expect(read.rows.first.positionsText, a.positionsText);
      expect(read.rows.last.part, '=1+1');
      expect(read.rows.last.quantityText, '');
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('oversized and invalid XML cells are rejected without truncation', () {
    for (final text in ['x' * 32768, 'a\x01b']) {
      final file = passSession([
        sourceRow('X', '1', 'U1', description: text),
      ], []).generate(MergeMode.details);
      expect(() => MergedWorkbookExport.encode(file), throwsFormatException);
    }
  });

  test(
    'large exponents remain raw detail and never trigger enormous powers',
    () {
      final session = passSession([
        sourceRow('ZERO', '0e999999999', 'R1'),
        sourceRow('ZERO', '1', 'R2'),
        sourceRow('ZERO', '1', 'R3'),
      ], []);
      expect(
        session.generate(MergeMode.summarize).rows.map((r) => r.quantity),
        ['0e999999999', '2'],
      );
    },
  );

  test('empty included set still exports exactly the four headers', () {
    final session = StationMergeSession(mergeReport());
    for (final item in session.requiredItems) {
      session.confirm(item, include: false);
    }
    final file = session.generate(MergeMode.details);
    expect(file.rows.length, 2);
    final empty = passSession([], []).generate(MergeMode.details);
    final zip = ZipDecoder().decodeBytes(MergedWorkbookExport.encode(empty));
    final xml = XmlDocument.parse(
      utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content),
    );
    expect(xml.findAllElements('row').length, 1);
    expect(
      xml.findAllElements('t').map((t) => t.innerText),
      MergedStationFile.headers,
    );
  });

  test('carriage returns, tabs and long integer quantities are not silently changed', () {
    final data = passSession([
      sourceRow('0001', '9007199254740993', 'R1\r\nR2', description: 'A\tB\rC'),
    ], []).generate(MergeMode.details);
    final zip = ZipDecoder().decodeBytes(MergedWorkbookExport.encode(data));
    final xml = XmlDocument.parse(
      utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content),
    );
    final cells = xml
        .findAllElements('row')
        .last
        .findAllElements('t')
        .map((e) => e.innerText)
        .toList();
    expect(cells, data.rows.single.cells);
  });

  test(
    'custom names get one BOM suffix and reject paths and reserved names',
    () {
      for (final input in ['订单123', '订单123-BOM', '订单123-BOM.xlsx']) {
        expect(mergedFileName(input), '订单123-BOM.xlsx');
      }
      expect(mergedFileName('订单 #1'), '订单 #1-BOM.xlsx');
      for (final bad in [
        '',
        '../abc',
        r'D:\abc',
        'abc*',
        'CON',
        'NUL.xlsx',
        'abc.',
        'x' * 190,
      ]) {
        expect(() => mergedFileName(bad), throwsFormatException, reason: bad);
      }
    },
  );
}
