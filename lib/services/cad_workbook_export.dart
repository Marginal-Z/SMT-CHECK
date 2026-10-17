import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../core/cad_coordinates.dart';
import '../core/coordinate_reader.dart';

class CadWorkbookExport {
  static Uint8List encode(CadPreview preview) {
    if (!preview.canExport) throw const FormatException('CAD 存在异常，不能导出');
    if (preview.rows.length > 1048575) {
      throw const FormatException('合并记录超过 Excel 行数限制');
    }
    final archive = Archive();
    void add(String name, String value) =>
        archive.addFile(ArchiveFile.string(name, value));
    add(
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>''',
    );
    add(
      '_rels/.rels',
      '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
    );
    add(
      'xl/workbook.xml',
      '''<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>''',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''',
    );
    add(
      'xl/styles.xml',
      '''<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="1"><numFmt numFmtId="164" formatCode="0.0000"/></numFmts>
<fonts count="2"><font><sz val="11"/><name val="Arial"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Arial"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF191919"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>''',
    );
    final xml = XmlBuilder();
    xml.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    xml.element(
      'worksheet',
      attributes: {
        'xmlns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
      },
      nest: () {
        xml.element(
          'dimension',
          attributes: {'ref': 'A1:J${preview.rows.length + 1}'},
        );
        xml.element(
          'sheetViews',
          nest: () => xml.element(
            'sheetView',
            attributes: {'workbookViewId': '0'},
            nest: () => xml.element(
              'pane',
              attributes: {
                'ySplit': '1',
                'topLeftCell': 'A2',
                'activePane': 'bottomLeft',
                'state': 'frozen',
              },
            ),
          ),
        );
        xml.element(
          'cols',
          nest: () {
            for (var i = 1; i <= 10; i++) {
              xml.element(
                'col',
                attributes: {
                  'min': '$i',
                  'max': '$i',
                  'width': i == 1 || i == 3 ? '30' : '16',
                  'customWidth': '1',
                },
              );
            }
          },
        );
        xml.element(
          'sheetData',
          nest: () {
            final rows = <List<Object>>[
              CadPreview.headers,
              ...preview.rows.map((r) => r.cells),
            ];
            for (var i = 0; i < rows.length; i++) {
              xml.element(
                'row',
                attributes: {'r': '${i + 1}'},
                nest: () {
                  for (var col = 0; col < 10; col++) {
                    final value = rows[i][col], numeric = value is num;
                    final text = value.toString();
                    if (text.length > 32767 ||
                        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]')
                            .hasMatch(text) ||
                        (numeric && !value.isFinite)) {
                      throw const FormatException('CAD 单元格内容无法完整写入 Excel');
                    }
                    xml.element(
                      'c',
                      attributes: {
                        'r': '${String.fromCharCode(65 + col)}${i + 1}',
                        't': numeric ? 'n' : 'inlineStr',
                        's': i == 0
                            ? '1'
                            : col == 6 || col == 7
                            ? '2'
                            : '0',
                      },
                      nest: () {
                        if (numeric) {
                          xml.element('v', nest: text);
                        } else {
                          xml.element(
                            'is',
                            nest: () => xml.element(
                              't',
                              attributes: {'xml:space': 'preserve'},
                              nest: text,
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              );
            }
          },
        );
        xml.element(
          'autoFilter',
          attributes: {'ref': 'A1:J${preview.rows.length + 1}'},
        );
      },
    );
    add(
      'xl/worksheets/sheet1.xml',
      xml.buildDocument().toXmlString().replaceAll('\r', '&#13;'),
    );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    verify(bytes, preview);
    return bytes;
  }

  /// Read the actual emitted OOXML, checking every identity and all ten fields.
  /// No tolerance/rounding is applied to generated device coordinates.
  static void verify(List<int> bytes, CadPreview expected) {
    final decoded = CoordinateReader().readBytes(bytes, forComparison: true);
    if (decoded.headers.join('\u0000') != CadPreview.headers.join('\u0000') ||
        decoded.records.any((r) => r.sheet != 'Sheet1') ||
        decoded.issues.isNotEmpty ||
        decoded.records.length != expected.rows.length ||
        decoded.totalCount != expected.rows.length) {
      throw const FormatException('CAD 导出回读核验失败：元件数量或数据质量不一致');
    }
    final index = <String, CoordinateRecord>{};
    for (final row in decoded.records) {
      if (index.containsKey(row.reference)) {
        throw const FormatException('CAD 导出回读核验失败：位号重复');
      }
      index[row.reference] = row;
    }
    final expectedReferences = <String>{};
    for (final want in expected.rows) {
      final reference = want.source.reference.trim().toUpperCase(),
          got = index[want.source.reference.trim().toUpperCase()];
      if (got == null ||
          !expectedReferences.add(reference) ||
          got.x != want.x ||
          got.y != want.y ||
          got.angle != want.angle ||
          got.partType != want.source.partType ||
          got.decal != want.source.decal ||
          got.pins != want.source.pins ||
          got.layer != want.source.layer ||
          got.smd != want.source.smd ||
          got.glued != want.source.glued) {
        throw FormatException('CAD 导出回读核验失败：${want.source.reference}');
      }
    }
  }

  /// Resolves existing parents too, so symlinked directories cannot alias input.
  static bool targetsOriginal(String target, Iterable<String> originals) {
    String canonical(String name) {
      final file = File(name);
      final resolved = file.existsSync()
          ? file.resolveSymbolicLinksSync()
          : '${file.parent.resolveSymbolicLinksSync()}${Platform.pathSeparator}${file.uri.pathSegments.last}';
      final normalized = resolved.replaceAll('\\', '/');
      return Platform.isWindows ? normalized.toLowerCase() : normalized;
    }

    final destination = canonical(target);
    return originals.any((p) => canonical(p) == destination);
  }
}
