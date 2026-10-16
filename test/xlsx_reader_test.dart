import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/xlsx_reader.dart';
import 'package:smt_check/services/background_tasks.dart';

void main() {
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('smt-reader-'));
  tearDown(() => temp.deleteSync(recursive: true));
  File workbook(String data, {String sheet = '材料', String strings = ''}) {
    final archive = Archive();
    void add(String name, String text) {
      final bytes = utf8.encode(text);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      'xl/workbook.xml',
      '<workbook xmlns:r="urn:r"><sheets><sheet name="$sheet" r:id="rId1"/></sheets></workbook>',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>',
    );
    add(
      'xl/worksheets/sheet1.xml',
      '<worksheet><sheetData>$data</sheetData></worksheet>',
    );
    if (strings.isNotEmpty) add('xl/sharedStrings.xml', strings);
    return File('${temp.path}/test.xlsx')
      ..writeAsBytesSync(ZipEncoder().encode(archive));
  }

  String cell(String col, String value, {String type = 'inlineStr'}) =>
      '<c r="$col" t="$type">${type == 'inlineStr' ? '<is><t>$value</t></is>' : '<v>$value</v>'}</c>';
  String headers() =>
      '<row r="8">${cell('A8', '站位')}${cell('B8', '料号')}${cell('C8', '关联料号')}${cell('D8', '物料描述')}${cell('G8', '数量')}${cell('H8', '位号')}</row>';
  test('detects row8 header and exact 料号 column, not 关联料号', () {
    final f = workbook(
      '${headers()}<row r="9">${cell('A9', '1-2')}${cell('B9', 'K001')}${cell('C9', 'OTHER')}${cell('D9', '电阻')}${cell('G9', '2')}${cell('H9', 'R1 R2')}</row>',
    );
    final result = XlsxReader().read(f.path, InputKind.station, side: 'A');
    expect(result.rows.single.part, 'K001');
    expect(result.rows.single.row, 9);
    expect(result.rows.single.quantity, 2);
    expect(result.rows.single.station, '1-2');
  });
  test('background workbook import and reconciliation send plain data across isolates', () async {
    final f = workbook(
      '${headers()}<row r="9">${cell('A9', '1')}${cell('B9', 'K1')}${cell('D9', '电阻')}${cell('G9', '1')}${cell('H9', 'R1')}</row>',
    );
    final imported = await readWorkbookInBackground(
      f.path,
      InputKind.station,
      'A',
    );
    final bom = ImportedFile('bom.xlsx', InputKind.bom, imported.rows, [], []);
    final report = await checkInBackground(bom, [imported], const CheckRules());
    expect(report.count(CheckStatus.pass), 1);
    expect(imported.rows.single.side, 'A');
  });
  test('reads shared rich strings and numeric cell', () {
    final f = workbook(
      '${headers()}<row r="9">${cell('A9', '1')}${cell('B9', '0', type: 's')}${cell('D9', '1', type: 's')}${cell('G9', '1', type: 'n')}${cell('H9', 'R1')}</row>',
      strings: '<sst><si><t>K001</t></si><si><r><t>贴片</t></r><r><t>电阻</t></r></si></sst>',
    );
    final r = XlsxReader().read(f.path, InputKind.station).rows.single;
    expect(r.part, 'K001');
    expect(r.description, '贴片电阻');
    expect(r.quantity, 1);
  });
  test('candidate row recognized without carrying quantity or positions down', () {
    final f = workbook(
      '${headers()}<row r="9">${cell('B9', 'ALT')}${cell('D9', '替代描述')}</row>',
    );
    final r = XlsxReader().read(f.path, InputKind.station).rows.single;
    expect(r.candidate, true);
    expect(r.quantity, isNull);
    expect(r.positionsText, isEmpty);
  });
  test('uncached formula is explicit issue rather than zero', () {
    final f = workbook(
      '${headers()}<row r="9">${cell('B9', 'K1')}${cell('D9', '电阻')}<c r="G9"><f>SUM(1)</f></c>${cell('H9', 'R1')}</row>',
    );
    final r = XlsxReader().read(f.path, InputKind.station).rows.single;
    expect(r.importIssues.single, contains('没有缓存值'));
    expect(r.candidate, false);
    expect(r.quantity, isNull);
  });
  test('cached formula and Excel error are audited', () {
    final f = workbook(
      '${headers()}<row r="9">${cell('B9', 'K1')}${cell('D9', '电阻')}<c r="G9"><f>SUM(1)</f><v>1</v></c>${cell('H9', '#REF!', type: 'e')}</row>',
    );
    final r = XlsxReader().read(f.path, InputKind.station);
    expect(r.notes.join(), contains('公式缓存'));
    expect(r.rows.single.importIssues.single, contains('Excel 错误'));
  });
  test('wrong type and missing mandatory headers reject import', () {
    expect(
      () => XlsxReader().read('${temp.path}/old.xls', InputKind.bom),
      throwsFormatException,
    );
    expect(
      () => XlsxReader().read(
        workbook('<row r="1">${cell('A1', '料号')}</row>').path,
        InputKind.bom,
      ),
      throwsFormatException,
    );
  });
}
