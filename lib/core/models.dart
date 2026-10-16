import 'positions.dart';

enum InputKind { bom, station }

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
  final bool excludeEnabled;
  final List<String> keywords;
  const CheckRules({
    this.excludeEnabled = true,
    this.keywords = const ['锡膏', 'PCB', '助焊剂', '包装材料', '高温贴纸', '碳带'],
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
  };
}

enum CheckStatus { error, pass, excluded, candidate }

class CheckItem {
  final String part;
  final CheckStatus status;
  final List<MaterialRow> bom, smt;
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
    CheckStatus.pass => '一致',
    CheckStatus.error => '异常',
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
