import 'positions.dart';
import 'text_difference.dart';

enum InputKind { bom, station }

// Keep enum identities stable; presentation order is independent of serialization.
extension CheckStatusOrder on CheckStatus {
  int get displayOrder => switch (this) {
    CheckStatus.pass => 0,
    CheckStatus.error => 1,
    CheckStatus.excluded => 2,
    CheckStatus.candidate => 3,
  };
}

class MaterialRow {
  final String part,
      description,
      quantityText,
      positionsText,
      file,
      sheet,
      station,
      side;
  final int row;
  final List<String> importIssues;
  final bool candidate;
  const MaterialRow({
    required this.part,
    required this.description,
    required this.quantityText,
    required this.positionsText,
    required this.file,
    required this.sheet,
    required this.row,
    this.station = '',
    this.side = '',
    this.importIssues = const [],
    this.candidate = false,
  });
  double? get quantity {
    final raw = quantityText.trim();
    if (raw.contains(',') &&
        !RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(raw)) {
      return null;
    }
    final n = double.tryParse(raw.replaceAll(',', ''));
    return n != null && n.isFinite ? n : null;
  }

  String get location =>
      '$file / $sheet / 第 $row 行${station.isEmpty ? '' : ' / 站位 $station'}';
  Map<String, dynamic> toJson() => {
    'part': part,
    'description': description,
    'quantity': quantityText,
    'positions': positionsText,
    'file': file,
    'sheet': sheet,
    'row': row,
    'station': station,
    'side': side,
    'candidate': candidate,
    'importIssues': importIssues,
  };
}

class SourceRow {
  final int row;
  final Map<String, String> cells, formulas;
  const SourceRow(this.row, this.cells, {this.formulas = const {}});
  Map<String, dynamic> toJson() => {
    'row': row,
    'cells': cells,
    if (formulas.isNotEmpty) 'formulas': formulas,
  };
}

class SourceSheet {
  final String name, visibility;
  final List<SourceRow> rows;
  const SourceSheet(this.name, this.rows, {this.visibility = 'visible'});
}

class ImportedFile {
  final String path;
  final InputKind kind;
  final List<MaterialRow> rows;
  final List<String> notes;
  final List<String> mappings;
  final List<SourceSheet> sheets;
  const ImportedFile(
    this.path,
    this.kind,
    this.rows,
    this.notes,
    this.mappings, {
    this.sheets = const [],
  });
  String get name => path.replaceAll('\\', '/').split('/').last;
}

class CheckRules {
  static const legacyKeywords = ['锡膏', 'PCB', '助焊剂', '包装材料', '高温贴纸', '碳带'];
  static const defaultKeywords = ['锡膏', 'PCB', '助焊剂', '包装材料', '贴纸', '碳带'];
  // Upgrade only the old default profile. Deliberately customized lists survive.
  static List<String> restoreKeywords(List<String>? saved) {
    if (saved == null ||
        (saved.length == legacyKeywords.length &&
            saved.toSet().containsAll(legacyKeywords))) {
      return defaultKeywords;
    }
    return saved;
  }

  final bool excludeEnabled;
  final List<String> keywords;
  const CheckRules({
    this.excludeEnabled = true,
    this.keywords = defaultKeywords,
  });
  List<String> matchedKeywords(MaterialRow row) {
    if (!excludeEnabled) return const [];
    final description = row.description.toUpperCase().replaceAll(
      RegExp(r'\s'),
      '',
    );
    return keywords
        .map((key) => key.trim())
        .where(
          (key) =>
              key.isNotEmpty &&
              description.contains(
                key.toUpperCase().replaceAll(RegExp(r'\s'), ''),
              ),
        )
        .toSet()
        .toList();
  }

  String? exclusion(MaterialRow row) {
    final matched = matchedKeywords(row);
    if (matched.isNotEmpty) {
      return '品名/物料描述命中排除关键词「${matched.join('、')}」';
    }
    if (row.quantity == 0 && row.positionsText.trim().isEmpty) {
      return '零用量且无插件位置的总成/占位记录';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'excludeEnabled': excludeEnabled,
    'keywords': keywords,
    'keywordScope': 'normalized_part_all_sources',
  };
}

enum CheckStatus { error, pass, excluded, candidate }

enum DifferenceField { part, description, quantity, positions }

class FieldDifference {
  // Quantity values are totals and position values are parsed sets. Part and
  // description values retain source spelling; CheckItem retains every raw row.
  final DifferenceField field;
  final String title, bomValue, smtValue;
  final List<String> reasons;
  String get reason => reasons.join('\n');
  final List<String> bomSources, smtSources;
  final bool highlightText;
  final bool bomMissing, smtMissing;
  final List<TextChangeRange> bomHighlights, smtHighlights;
  const FieldDifference({
    required this.field,
    required this.title,
    required this.bomValue,
    required this.smtValue,
    required this.reasons,
    this.bomSources = const [],
    this.smtSources = const [],
    this.highlightText = false,
    this.bomHighlights = const [],
    this.smtHighlights = const [],
    this.bomMissing = false,
    this.smtMissing = false,
  });
  Map<String, dynamic> toJson() => {
    'field': field.name,
    'title': title,
    'bomValue': bomValue,
    'smtValue': smtValue,
    'reason': reason,
    'reasons': reasons,
    'bomSources': bomSources,
    'smtSources': smtSources,
    'highlightText': highlightText,
    'bomMissing': bomMissing,
    'smtMissing': smtMissing,
    'bomHighlights': bomHighlights.map((r) => r.toJson(bomValue)).toList(),
    'smtHighlights': smtHighlights.map((r) => r.toJson(smtValue)).toList(),
  };
}

class CheckItem {
  final String part;
  final CheckStatus status;
  final List<MaterialRow> bom, smt;
  final List<FieldDifference> fieldDifferences;
  final List<String> reasons,
      missingPositions,
      extraPositions,
      excludedKeywords;
  const CheckItem({
    required this.part,
    required this.status,
    required this.bom,
    required this.smt,
    required this.reasons,
    this.fieldDifferences = const [],
    this.missingPositions = const [],
    this.extraPositions = const [],
    this.excludedKeywords = const [],
  });
  double? total(List<MaterialRow> rows) =>
      rows.isEmpty || rows.any((r) => r.quantity == null)
      ? null
      : rows.fold<double>(0, (v, r) => v + r.quantity!);
  double? get bomQuantity => total(bom);
  double? get smtQuantity => total(smt);
  // Keep source spelling, separators, line breaks and A+B row order intact.
  String get bomPositions => bom.map((r) => r.positionsText).join('\n');
  String get smtPositions => smt.map((r) => r.positionsText).join('\n');
  String get description => (bom.isNotEmpty ? bom : smt).first.description;
  String get label => switch (status) {
    CheckStatus.pass => 'PASS',
    CheckStatus.error => 'NG',
    CheckStatus.excluded => '已排除',
    CheckStatus.candidate => '候选替代料',
  };
  Map<String, dynamic> toJson() => {
    'part': part,
    'status': status.name,
    'label': label,
    'bomQuantity': bomQuantity,
    'smtQuantity': smtQuantity,
    'bomPositions': bomPositions,
    'smtPositions': smtPositions,
    'excludedKeywords': excludedKeywords,
    'reasons': reasons,
    'fieldDifferences': fieldDifferences.map((d) => d.toJson()).toList(),
    'missingPositions': missingPositions,
    'extraPositions': extraPositions,
    'bom': bom.map((r) => r.toJson()).toList(),
    'smt': smt.map((r) => r.toJson()).toList(),
  };
}

class CheckReport {
  final List<CheckItem> items;
  final CheckRules rules;
  final bool merged;
  final List<ImportedFile> files;
  final DateTime created;
  CheckReport(this.items, this.rules, this.merged, this.files)
    : created = DateTime.now();
  int count(CheckStatus status) =>
      items.where((i) => i.status == status).length;
  Set<String> _parts(InputKind? kind) => files
      .where((f) => kind == null || f.kind == kind)
      .expand((f) => f.rows)
      .map((r) => normalizePart(r.part))
      .where((part) => part.isNotEmpty)
      .toSet();
  int get totalPartCount => _parts(null).length;
  int get bomPartCount => _parts(InputKind.bom).length;
  int get smtPartCount => _parts(InputKind.station).length;
  List<CheckItem> get errors =>
      items.where((i) => i.status == CheckStatus.error).toList();
  Map<String, dynamic> toJson() => {
    'version': 2,
    'created': created.toIso8601String(),
    'mode': merged ? 'A+B合并' : '单站位表（与完整BOM比较）',
    'rules': rules.toJson(),
    'summary': {
      'totalPartCount': totalPartCount,
      'bomPartCount': bomPartCount,
      'smtPartCount': smtPartCount,
      'partCountBasis': 'unique normalized nonempty part numbers from all imported rows, including excluded and candidate rows; total is BOM/SMT union',
      for (final s in CheckStatus.values) s.name: count(s),
    },
    'files': files
        .map((f) => {'name': f.name, 'mappings': f.mappings, 'notes': f.notes})
        .toList(),
    'items': items.map((i) => i.toJson()).toList(),
  };
}
