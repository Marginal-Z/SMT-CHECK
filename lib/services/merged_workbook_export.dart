import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../core/station_merge.dart';

/// Native, offline OOXML export. Source strings are inline text, so identifiers
/// keep leading zeroes and spreadsheet-looking content never executes formulas.
class MergedWorkbookExport {
  static Uint8List encode(MergedStationFile file) {
    if (file.rows.length > 1048575) {
      throw const FormatException('合并记录超过 Excel 行数限制');
    }
    final archive = Archive();
    void add(String path, String xml) =>
        archive.addFile(ArchiveFile.string(path, xml));
    add(
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''',
    );
    add(
      '_rels/.rels',
      '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
    );
    add(
      'xl/workbook.xml',
      '''<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="BOM" sheetId="1" r:id="rId1"/></sheets></workbook>''',
    );
    add(
      'xl/_rels/workbook.xml.rels',
      '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>''',
    );
    add(
      'xl/styles.xml',
      '''<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="11"/><name val="Arial"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Arial"/></font></fonts>
<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF191919"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center"/></xf><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment horizontal="right" vertical="top" wrapText="1"/></xf></cellXfs>
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
          attributes: {'ref': 'A1:D${file.rows.length + 1}'},
        );
        xml.element(
          'sheetViews',
          nest: () => xml.element(
            'sheetView',
            attributes: {'workbookViewId': '0', 'showGridLines': '0'},
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
        xml.element('sheetFormatPr', attributes: {'defaultRowHeight': '24'});
        xml.element(
          'cols',
          nest: () {
            for (final (index, width) in [(1, 24), (2, 68), (3, 14), (4, 52)]) {
              xml.element(
                'col',
                attributes: {
                  'min': '$index',
                  'max': '$index',
                  'width': '$width',
                  'customWidth': '1',
                },
              );
            }
          },
        );
        xml.element(
          'sheetData',
          nest: () {
            final rows = [
              MergedStationFile.headers,
              ...file.rows.map((r) => r.cells),
            ];
            for (var i = 0; i < rows.length; i++) {
              var lines = 1;
              for (var col = 0; col < 4; col++) {
                final width = [24, 68, 14, 52][col];
                final wrapped = rows[i][col].split('\n').fold<int>(0, (
                  n,
                  line,
                ) {
                  final units = line.runes.fold<int>(
                    0,
                    (sum, c) => sum + (c > 255 ? 2 : 1),
                  );
                  return n + (units / width).ceil().clamp(1, 409);
                });
                if (wrapped > lines) lines = wrapped;
              }
              xml.element(
                'row',
                attributes: {
                  'r': '${i + 1}',
                  'ht': i == 0 ? '28' : '${(lines * 16 + 8).clamp(24, 409)}',
                  'customHeight': '1',
                },
                nest: () {
                  for (var col = 0; col < 4; col++) {
                    final value = rows[i][col];
                    if (value.length > 32767 ||
                        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]')
                            .hasMatch(value)) {
                      throw FormatException(
                        '单元格内容无法完整写入 Excel：${String.fromCharCode(65 + col)}${i + 1}',
                      );
                    }
                    final numeric =
                        i > 0 &&
                        col == 2 &&
                        RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$')
                            .hasMatch(value.trim().replaceAll(',', '')) &&
                        (!value.contains(',') ||
                            RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$')
                                .hasMatch(value.trim())) &&
                        (double.tryParse(value.trim().replaceAll(',', ''))
                                ?.isFinite ??
                            false) &&
                        (!value.toLowerCase().contains('e') ||
                            (int.tryParse(value.toLowerCase().split('e').last)
                                        ?.abs() ??
                                    999) <=
                                308) &&
                        value
                                .replaceAll(RegExp(r'[^0-9]'), '')
                                .replaceFirst(RegExp(r'^0+'), '')
                                .length <=
                            15;
                    xml.element(
                      'c',
                      attributes: {
                        'r': '${String.fromCharCode(65 + col)}${i + 1}',
                        's': i == 0
                            ? '1'
                            : col == 2
                            ? '2'
                            : '0',
                        't': numeric ? 'n' : 'inlineStr',
                      },
                      nest: () {
                        if (numeric) {
                          xml.element(
                            'v',
                            nest: value.trim().replaceAll(',', ''),
                          );
                        } else {
                          xml.element(
                            'is',
                            nest: () => xml.element(
                              't',
                              attributes: {'xml:space': 'preserve'},
                              nest: value,
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
          attributes: {'ref': 'A1:D${file.rows.length + 1}'},
        );
      },
    );
    add(
      'xl/worksheets/sheet1.xml',
      xml.buildDocument().toXmlString().replaceAll('\r', '&#13;'),
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
