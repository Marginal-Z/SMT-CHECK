import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'models.dart';

class XlsxReader {
  static const aliases = {
    InputKind.bom: {
      'part': ['料件编号', '料件编码'],
      'description': ['品名'],
      'quantity': ['组成用量'],
      'positions': ['插件位置'],
    },
    InputKind.station: {
      'part': ['料号', '物料编码', '物料编号'],
      'description': ['物料描述'],
      'quantity': ['数量'],
      'positions': ['位号'],
    },
  };
  ImportedFile read(String path, InputKind kind, {String side = ''}) {
    if (!path.toLowerCase().endsWith('.xlsx')) {
      throw const FormatException('请使用 .xlsx 文件；旧版 .xls 请先另存为 .xlsx。');
    }
    final file = File(path);
    if (file.lengthSync() > 30 * 1024 * 1024) {
      throw const FormatException('文件超过 30 MB，请拆分工作簿后导入。');
    }
    final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    if (archive.fold<int>(0, (n, f) => n + f.size) > 150 * 1024 * 1024) {
      throw const FormatException('工作簿解压体积超过限制。');
    }
    XmlDocument? doc(String name) {
      final entry = archive.findFile(name);
      return entry == null
          ? null
          : XmlDocument.parse(utf8.decode(entry.content as List<int>));
    }

    final workbook = doc('xl/workbook.xml'),
        relations = doc('xl/_rels/workbook.xml.rels');
    if (workbook == null || relations == null) {
      throw const FormatException('无法读取工作簿，文件可能损坏或已加密。');
    }
    final targets = {
      for (final r in relations.findAllElements('Relationship'))
        r.getAttribute('Id'): r.getAttribute('Target')!,
    };
    final strings =
        doc('xl/sharedStrings.xml')
            ?.findAllElements('si')
            .map((e) => e.findAllElements('t').map((t) => t.innerText).join())
            .toList() ??
        <String>[];
    final rows = <MaterialRow>[], notes = <String>[], mappings = <String>[];
    final filename = path.replaceAll('\\', '/').split('/').last;
    for (final sheet in workbook.findAllElements('sheet')) {
      final name = sheet.getAttribute('name') ?? 'Sheet';
      final id = sheet.attributes
          .where((a) => a.name.local == 'id')
          .firstOrNull
          ?.value;
      final target = targets[id];
      if (target == null) {
        notes.add('$name：工作表关系缺失');
        continue;
      }
      final sheetPath = target.startsWith('/')
          ? target.substring(1)
          : 'xl/$target';
      final data = doc(sheetPath);
      if (data == null) {
        throw FormatException('$name：缺少工作表数据，无法完成完整核对');
      }
      Map<String, String>? mapping;
      var header = 0, imported = 0;
      for (final row in data.findAllElements('row')) {
        final rowNum = int.tryParse(row.getAttribute('r') ?? '') ?? 0;
        final cells = <String, String>{},
            uncached = <String>{},
            formulas = <String>{};
        for (final c in row.findElements('c')) {
          final col = (c.getAttribute('r') ?? '').replaceAll(RegExp(r'\d'), '');
          final type = c.getAttribute('t');
          final v = c.getElement('v')?.innerText ?? '';
          if (c.getElement('f') != null) {
            formulas.add(col);
            if (v.isEmpty) {
              uncached.add(col);
            }
          }
          cells[col] = type == 's'
              ? (int.tryParse(v) != null && int.parse(v) < strings.length
                    ? strings[int.parse(v)]
                    : '')
              : type == 'inlineStr'
              ? c.findAllElements('t').map((e) => e.innerText).join()
              : type == 'e'
              ? '#EXCEL_ERROR:$v'
              : v;
        }
        if (cells.values.every((v) => v.trim().isEmpty) && uncached.isEmpty) {
          continue;
        }
        final detected = <String, String>{};
        for (final field in aliases[kind]!.entries) {
          for (final cell in cells.entries) {
            final value = cell.value.replaceAll(RegExp(r'\s'), '');
            if (field.value.contains(value)) {
              detected[field.key] = cell.key;
              break;
            }
          }
        }
        if (detected.length == 4) {
          mapping = detected;
          header = rowNum;
          mappings.add(
            '$name 第 $header 行：${mapping.entries.map((e) => '${e.key}=${e.value}').join(' / ')}',
          );
          continue;
        }
        if (mapping == null) {
          continue;
        }
        String val(String field) => cells[mapping![field]] ?? '';
        final part = val('part').trim(),
            description = val('description'),
            qty = val('quantity'),
            positions = val('positions');
        if ([
          part,
          description,
          qty,
          positions,
        ].every((s) => s.trim().isEmpty)) {
          continue;
        }
        final issues = <String>[];
        for (final e in mapping.entries) {
          if (uncached.contains(e.value)) {
            issues.add('${e.key} 含公式但没有缓存值，请用 Excel 重算并保存');
          }
          if ((cells[e.value] ?? '').startsWith('#EXCEL_ERROR:')) {
            issues.add('${e.key} 含 Excel 错误值 ${cells[e.value]}');
          }
        }
        if (formulas.intersection(mapping.values.toSet()).isNotEmpty) {
          notes.add('$name 第 $rowNum 行使用公式缓存值，请确保原文件已重算保存');
        }
        final stationColumn = kind == InputKind.station
            ? cells.entries.where((e) => e.key == 'A').firstOrNull?.value ?? ''
            : '';
        final candidate =
            kind == InputKind.station &&
            part.isNotEmpty &&
            qty.trim().isEmpty &&
            positions.trim().isEmpty &&
            stationColumn.trim().isEmpty &&
            issues.isEmpty;
        rows.add(
          MaterialRow(
            part: part,
            description: description,
            quantityText: qty,
            positionsText: positions,
            file: filename,
            sheet: name,
            row: rowNum,
            side: side,
            station: stationColumn,
            importIssues: issues,
            candidate: candidate,
          ),
        );
        imported++;
      }
      if (header == 0) {
        notes.add('$name：未检测到四个必需表头，未作为数据表导入');
      } else {
        notes.add('$name：导入 $imported 行，含候选替代料行');
      }
    }
    if (mappings.isEmpty || rows.isEmpty) {
      throw FormatException(
        '未找到有效${kind == InputKind.bom ? 'T100-BOM' : 'SMT站位表'}数据。必需字段：${aliases[kind]!.values.map((v) => v.first).join('、')}',
      );
    }
    return ImportedFile(path, kind, rows, notes, mappings);
  }
}
