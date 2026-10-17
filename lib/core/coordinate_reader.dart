import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'cad_coordinates.dart';

class _TableRow {
  final int number;
  final List<String> cells;
  const _TableRow(this.number, this.cells);
}

class _Table {
  final String name;
  final List<_TableRow> rows;
  const _Table(this.name, this.rows);
}

class CoordinateReader {
  static String _normal(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s._/()\-]'), '');
  static const _aliases = {
    'ref': [
      'refdes',
      'ref',
      'reference',
      '位号',
      'name',
      'designator',
      'component',
      'componentname',
    ],
    'x': [
      'x',
      'posx',
      'xmm',
      'x坐标',
      'centerx',
      'midx',
      'xcoord',
      'xcoordinate',
    ],
    'y': [
      'y',
      'posy',
      'ymm',
      'y坐标',
      'centery',
      'midy',
      'ycoord',
      'ycoordinate',
    ],
    'layer': ['layer', 'side', '面别'],
    'angle': [
      'orient',
      'orientation',
      'rotation',
      'angle',
      '角度',
      'rotationdeg',
      'rotationdegree',
    ],
    'type': ['parttype', 'part', 'componenttype', 'type'],
    'decal': ['partdecal', 'decal', 'package', 'footprint', 'pattern'],
    'pins': ['pins'],
    'smd': ['smd'],
    'glued': ['glued'],
  };
  CoordinateImport read(String path) {
    final file = File(path);
    if (file.lengthSync() > 30 * 1024 * 1024) {
      throw const FormatException('文件超过 30 MB，请拆分工作簿后导入。');
    }
    final extension = path.toLowerCase().split('.').last;
    if (!['xlsx', 'csv', 'txt'].contains(extension)) {
      throw const FormatException(
        'CAD 支持 .xlsx、.csv、.txt 坐标文件；旧版 .xls 请先另存为 .xlsx',
      );
    }
    final tables = extension == 'xlsx'
        ? _xlsx(file.readAsBytesSync())
        : [
            _text(
              utf8.decode(file.readAsBytesSync()).replaceFirst('\uFEFF', ''),
            ),
          ];
    _Table? best;
    _TableRow? header;
    Map<String, int> columns = {};
    var score = -1;
    for (final table in tables) {
      for (final row in table.rows.where((r) => r.number <= 100)) {
        final detected = <String, int>{};
        for (var i = 0; i < row.cells.length && i < 100; i++) {
          final name = _normal(row.cells[i]);
          for (final entry in _aliases.entries) {
            if (entry.value.contains(name)) {
              detected.putIfAbsent(entry.key, () => i);
            }
          }
        }
        if (!['ref', 'x', 'y'].every(detected.containsKey)) continue;
        final value =
            detected.length + (detected.containsKey('layer') ? 10 : 0);
        if (value > score) {
          score = value;
          best = table;
          header = row;
          columns = detected;
        }
      }
    }
    if (best == null || header == null) {
      throw const FormatException('CAD 未找到位号、X、Y 坐标表头');
    }
    if (!columns.containsKey('layer')) {
      throw const FormatException('CAD 原坐标缺少 Layer／面别列');
    }
    final records = <CoordinateRecord>[], issues = <CadIssue>[];
    final filename = path.replaceAll('\\', '/').split('/').last;
    CadUnit? hint;
    if (_normal(header.cells[columns['x']!]) == 'xmm' &&
        _normal(header.cells[columns['y']!]) == 'ymm') {
      hint = CadUnit.mm;
    }
    for (final row in best.rows.where((r) => r.number > header!.number)) {
      String val(String key, [String fallback = '']) {
        final col = columns[key];
        return col == null
            ? fallback
            : (col < row.cells.length ? row.cells[col].trim() : '');
      }

      if (row.cells.every((c) => c.trim().isEmpty)) continue;
      final ref = val('ref').toUpperCase();
      void issue(String reason) => issues.add(
        CadIssue(
          reason,
          reference: ref,
          file: filename,
          sheet: best!.name,
          row: row.number,
          raw: {
            for (var i = 0; i < row.cells.length; i++)
              (i < header!.cells.length ? header.cells[i] : '$i'): row.cells[i],
          },
        ),
      );
      if (ref.isEmpty) {
        issue('CAD 原坐标位号为空');
        continue;
      }
      if (columns.values.any(
        (col) =>
            col < row.cells.length &&
            (row.cells[col].startsWith('#EXCEL_ERROR:') ||
                row.cells[col] == '#FORMULA_CACHE_MISSING'),
      )) {
        issue('CAD 原坐标含 Excel 错误或缺少公式缓存');
        continue;
      }
      final x = double.tryParse(val('x')), y = double.tryParse(val('y'));
      final angle = double.tryParse(val('angle', '0'));
      var invalid = false;
      if (x == null || !x.isFinite) {
        issue('CAD X 坐标为空或不是有限数值');
        invalid = true;
      }
      if (y == null || !y.isFinite) {
        issue('CAD Y 坐标为空或不是有限数值');
        invalid = true;
      }
      if (angle == null || !angle.isFinite) {
        issue('CAD 角度为空或不是有限数值');
        invalid = true;
      }
      final layer = switch (val('layer').toLowerCase()) {
        'top' || 't' || 'adt' || 'front' => 'Top',
        'bottom' || 'bot' || 'b' || 'adb' || 'back' || 'm' => 'Bottom',
        _ => '',
      };
      if (layer.isEmpty) {
        issue('CAD 无法识别面别：${val('layer')}');
        invalid = true;
      }
      final pins = int.tryParse(val('pins', '2'));
      if (pins == null || pins < 0) {
        issue('CAD Pins 必须为非负整数');
        invalid = true;
      }
      if (invalid) continue;
      final partType = val('type', 'AAA');
      records.add(
        CoordinateRecord(
          reference: ref,
          x: x!,
          y: y!,
          angle: angle!,
          layer: layer,
          pins: pins!,
          partType: partType,
          decal: val('decal', partType),
          smd: val('smd', 'Yes'),
          glued: val('glued', 'No'),
          file: filename,
          sheet: best.name,
          row: row.number,
          raw: {
            for (var i = 0; i < row.cells.length; i++)
              (i < header.cells.length ? header.cells[i] : '$i'): row.cells[i],
          },
        ),
      );
    }
    if (records.isEmpty && issues.isEmpty) {
      throw const FormatException('CAD 原坐标没有有效数据行');
    }
    if (!columns.containsKey('angle')) {
      issues.add(
        CadIssue(
          'CAD 原文件没有角度列，按 0° 处理，请复核',
          file: filename,
          sheet: best.name,
          row: header.number,
          blocking: false,
        ),
      );
    }
    return CoordinateImport(
      path,
      List.unmodifiable(records),
      List.unmodifiable(issues),
      unitHint: hint,
    );
  }

  List<_Table> _xlsx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.fold<int>(0, (n, f) => n + f.size) > 150 * 1024 * 1024) {
      throw const FormatException('工作簿解压体积超过限制。');
    }
    XmlDocument? doc(String name) {
      final entry = archive.findFile(name);
      return entry == null
          ? null
          : XmlDocument.parse(utf8.decode(entry.content as List<int>));
    }

    final book = doc('xl/workbook.xml'),
        relationships = doc('xl/_rels/workbook.xml.rels');
    if (book == null || relationships == null) {
      throw const FormatException('无法读取工作簿，文件可能损坏或已加密。');
    }
    final targets = {
      for (final r in relationships.findAllElements('Relationship'))
        r.getAttribute('Id'): r.getAttribute('Target') ?? '',
    };
    final strings =
        doc('xl/sharedStrings.xml')
            ?.findAllElements('si')
            .map((e) => e.findAllElements('t').map((t) => t.innerText).join())
            .toList() ??
        <String>[];
    final tables = <_Table>[];
    for (final sheet in book.findAllElements('sheet')) {
      final id = sheet.attributes
          .where((a) => a.name.local == 'id')
          .firstOrNull
          ?.value;
      final target = targets[id];
      if (target == null) throw const FormatException('CAD 工作表数据缺失');
      final document = doc(
        target.startsWith('/') ? target.substring(1) : 'xl/$target',
      );
      if (document == null) throw const FormatException('CAD 工作表数据缺失');
      final rows = <_TableRow>[];
      for (final row in document.findAllElements('row')) {
        final cells = <String>[];
        for (final c in row.findElements('c')) {
          final column = (c.getAttribute('r') ?? '').replaceAll(
            RegExp(r'\d'),
            '',
          );
          var index = 0;
          for (final rune in column.codeUnits) {
            index = index * 26 + rune - 64;
          }
          if (index < 1 || index > 16384) continue;
          while (cells.length < index) {
            cells.add('');
          }
          final value = c.getElement('v')?.innerText ?? '',
              type = c.getAttribute('t');
          cells[index - 1] = type == 's'
              ? (int.tryParse(value) != null &&
                        int.parse(value) >= 0 &&
                        int.parse(value) < strings.length
                    ? strings[int.parse(value)]
                    : '')
              : type == 'inlineStr'
              ? c.findAllElements('t').map((t) => t.innerText).join()
              : type == 'e'
              ? '#EXCEL_ERROR:$value'
              : c.getElement('f') != null && value.isEmpty
              ? '#FORMULA_CACHE_MISSING'
              : value;
        }
        if (cells.any((v) => v.trim().isNotEmpty)) {
          rows.add(
            _TableRow(
              int.tryParse(row.getAttribute('r') ?? '') ?? rows.length + 1,
              cells,
            ),
          );
        }
      }
      tables.add(_Table(sheet.getAttribute('name') ?? 'Sheet', rows));
    }
    return tables;
  }

  _Table _text(String text) {
    final first = text
        .split(RegExp(r'\r?\n'))
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    var delimiter = ',', maximum = 0;
    for (final d in ['\t', ',', ';']) {
      var count = 0, quoted = false;
      for (var i = 0; i < first.length; i++) {
        if (first[i] == '"') quoted = !quoted;
        if (!quoted && first[i] == d) count++;
      }
      if (count > maximum) {
        maximum = count;
        delimiter = d;
      }
    }
    final parsed = maximum == 0
        ? <_TableRow>[
            for (final (i, line) in text.split(RegExp(r'\r?\n')).indexed)
              if (line.trim().isNotEmpty)
                _TableRow(i + 1, line.trim().split(RegExp(r'\s+'))),
          ]
        : _csv(text, delimiter);
    if (parsed.any(
      (r) => r.cells.any((c) => _aliases['ref']!.contains(_normal(c))),
    )) {
      return _Table('Text', parsed);
    }
    final rows = <_TableRow>[
      const _TableRow(0, [
        'RefDes',
        'X',
        'Y',
        'Orient.',
        'Layer',
        'PartType',
        'PartDecal',
      ]),
    ];
    for (final r in parsed) {
      if (r.cells.isEmpty ||
          r.cells.first.startsWith('#') ||
          r.cells.first.startsWith(';')) {
        continue;
      }
      if (r.cells.length < 4) {
        throw const FormatException('CAD 无表头文本需要 Ref X Y Angle 和可选封装');
      }
      final bottom = r.cells
          .skip(4)
          .any((s) => ['m', 'bottom', 'bot'].contains(s.toLowerCase()));
      final decal = r.cells.length > 4 ? r.cells.last : 'AAA';
      rows.add(
        _TableRow(r.number, [
          r.cells[0],
          r.cells[1],
          r.cells[2],
          r.cells[3],
          bottom ? 'Bottom' : 'Top',
          decal,
          decal,
        ]),
      );
    }
    return _Table('Text', rows);
  }

  List<_TableRow> _csv(String text, String delimiter) {
    final rows = <_TableRow>[], fields = <String>[];
    var field = StringBuffer(), quoted = false, line = 1, start = 1;
    void endField() {
      fields.add(field.toString());
      field = StringBuffer();
    }

    void endRow() {
      endField();
      if (fields.any((s) => s.trim().isNotEmpty)) {
        rows.add(_TableRow(start, List.of(fields)));
      }
      fields.clear();
      start = line + 1;
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (c == delimiter && !quoted) {
        endField();
      } else if ((c == '\n' || c == '\r') && !quoted) {
        endRow();
        line++;
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      } else {
        field.write(c);
        if (c == '\n') line++;
      }
    }
    if (quoted) throw const FormatException('CAD CSV 引号未闭合，请检查原文件');
    if (field.isNotEmpty || fields.isNotEmpty) endRow();
    return rows;
  }
}
