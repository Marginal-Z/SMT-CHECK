import 'dart:convert';

import '../core/models.dart';
import '../core/positions.dart';

class SourceAnalysisBatch {
  final String kind, payload;
  final int partCount;
  const SourceAnalysisBatch(this.kind, this.payload, this.partCount);
}

class SourceAnalysisPlan {
  final List<SourceAnalysisBatch> batches;
  final int fileCount, materialRows, sourceRows;
  const SourceAnalysisPlan(
    this.batches,
    this.fileCount,
    this.materialRows,
    this.sourceRows,
  );
}

/// Every imported material and every retained worksheet row is represented.
/// Grouping only aligns sources; this plan contains no local pass/error verdicts.
SourceAnalysisPlan prepareSourceAnalysis(
  ImportedFile bom,
  List<ImportedFile> stations,
  CheckRules rules,
  int characterLimit,
) {
  if (stations.isEmpty || stations.length > 2) {
    throw ArgumentError('需要一份或两份站位表');
  }
  if (stations
          .map((s) => s.path.replaceAll('\\', '/').toLowerCase())
          .toSet()
          .length !=
      stations.length) {
    throw ArgumentError('A、B 不可使用同一份文件，以免重复累计');
  }
  if (characterLimit < 12000 || characterLimit > 120000) {
    throw ArgumentError('AI 单批字符上限须为 12000 至 120000');
  }
  final files = [bom, ...stations];
  final groups = <String, List<Map<String, dynamic>>>{};
  final contextRows = <Map<String, dynamic>>[];
  final owners = <String, List<Map<String, dynamic>>>{};
  var materialRows = 0, sourceRows = 0;
  for (var fileIndex = 0; fileIndex < files.length; fileIndex++) {
    final f = files[fileIndex];
    for (final note in f.notes) {
      contextRows.add({
        'fileIndex': fileIndex,
        'kind': 'import_note',
        'text': note,
      });
    }
    for (final mapping in f.mappings) {
      contextRows.add({
        'fileIndex': fileIndex,
        'kind': 'header_mapping',
        'text': mapping,
      });
    }
    final rawIndex = <String, SourceRow>{
      for (final sheet in f.sheets)
        for (final row in sheet.rows) '${sheet.name}:${row.row}': row,
    };
    final mapped = <String>{};
    for (final row in f.rows) {
      materialRows++;
      final address = '${row.sheet}:${row.row}';
      mapped.add(address);
      final raw = rawIndex[address];
      final record = <String, dynamic>{
        'fileIndex': fileIndex,
        ...row.toJson(),
        if (raw != null) 'source': raw.toJson(),
      };
      final part = normalizePart(row.part);
      groups.putIfAbsent(part, () => []).add(record);
      for (final position in parsePositions(
        row.positionsText,
        bom: f.kind == InputKind.bom,
      ).unique) {
        owners.putIfAbsent('${f.kind.name}:$position', () => []).add({
          'file': f.name,
          'sheet': row.sheet,
          'row': row.row,
          'part': row.part,
          'side': row.side,
          'positions': row.positionsText,
        });
      }
    }
    for (final sheet in f.sheets) {
      for (final row in sheet.rows) {
        sourceRows++;
        if (!mapped.contains('${sheet.name}:${row.row}')) {
          contextRows.add({
            'fileIndex': fileIndex,
            'sheet': sheet.name,
            'visibility': sheet.visibility,
            ...row.toJson(),
          });
        }
      }
    }
  }
  final common = {
    'analysis': 'original_workbooks',
    'mode': stations.length == 2 ? 'A+B' : 'single SMT vs full BOM',
    'rules': rules.toJson(),
    'files': [
      for (final f in files)
        {
          'name': f.name,
          'kind': f.kind.name,
          'materialRows': f.rows.length,
          'mappingCount': f.mappings.length,
          'noteCount': f.notes.length,
          'sheets': [
            for (final s in f.sheets)
              {
                'name': s.name,
                'visibility': s.visibility,
                'rows': s.rows.length,
              },
          ],
        },
    ],
  };
  final batches = <SourceAnalysisBatch>[];
  void pack(String kind, String field, List<Map<String, dynamic>> entries) {
    var current = <Map<String, dynamic>>[];
    String payload(List<Map<String, dynamic>> value) =>
        jsonEncode({...common, 'scope': kind, field: value});
    for (final entry in entries) {
      if (payload([...current, entry]).length > characterLimit) {
        if (current.isNotEmpty) {
          batches.add(
            SourceAnalysisBatch(
              kind,
              payload(current),
              kind == 'parts' ? current.length : 0,
            ),
          );
          current = [];
        }
        if (payload([entry]).length > characterLimit) {
          throw FormatException(
            '原始记录超过单批上限：${entry['part'] ?? entry['sheet'] ?? entry['position'] ?? kind}；请在设置中增大单批字符上限或拆分超长记录。',
          );
        }
      }
      current.add(entry);
    }
    if (current.isNotEmpty) {
      batches.add(
        SourceAnalysisBatch(
          kind,
          payload(current),
          kind == 'parts' ? current.length : 0,
        ),
      );
    }
  }

  pack('parts', 'parts', [
    for (final e in groups.entries) {'part': e.key, 'records': e.value},
  ]);
  pack('worksheet_context', 'rows', contextRows);
  // Cross-part ownership evidence stays together even when parts span batches.
  pack('position_ownership', 'positions', [
    for (final e in owners.entries)
      if (e.value.length > 1) {'position': e.key, 'owners': e.value},
  ]);
  return SourceAnalysisPlan(batches, files.length, materialRows, sourceRows);
}
