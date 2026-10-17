import 'positions.dart';
import 'station_merge.dart';

enum CadUnit {
  mm(1, '毫米（mm）'),
  mil(.0254, '密耳（mil）'),
  inch(25.4, '英寸（inch）');

  final double factor;
  final String label;
  const CadUnit(this.factor, this.label);
}

class CadIssue {
  final String reason, file, sheet, reference;
  final int row;
  final bool blocking;
  final Map<String, String> raw;
  const CadIssue(
    this.reason, {
    this.file = '',
    this.sheet = '',
    this.row = 0,
    this.reference = '',
    this.blocking = true,
    this.raw = const {},
  });
}

class CoordinateRecord {
  final String reference, partType, decal, layer, smd, glued, file, sheet;
  final int pins, row;
  final double x, y, angle;
  final Map<String, String> raw;
  const CoordinateRecord({
    required this.reference,
    required this.x,
    required this.y,
    required this.angle,
    required this.layer,
    required this.file,
    required this.sheet,
    required this.row,
    this.partType = 'AAA',
    this.decal = 'AAA',
    this.pins = 2,
    this.smd = 'Yes',
    this.glued = 'No',
    this.raw = const {},
  });
}

class CoordinateImport {
  final String path;
  final List<CoordinateRecord> records;
  final List<CadIssue> issues;
  final CadUnit? unitHint;
  const CoordinateImport(this.path, this.records, this.issues, {this.unitHint});
  String get name => path.replaceAll('\\', '/').split('/').last;
}

class CadOutputRow {
  final CoordinateRecord source;
  final MergedStationRow bom;
  final double x, y, angle;
  const CadOutputRow(this.source, this.bom, this.x, this.y, this.angle);
  List<Object> get cells => [
    source.partType,
    source.reference,
    source.decal,
    source.pins,
    source.layer,
    angle,
    x,
    y,
    source.smd,
    source.glued,
  ];
}

class CadPreview {
  static const headers = [
    'PartType',
    'RefDes',
    'PartDecal',
    'Pins',
    'Layer',
    'Orient.',
    'X',
    'Y',
    'SMD',
    'Glued',
  ];
  final MergedStationFile bom;
  final CoordinateImport coordinates;
  final CadUnit unit;
  final List<CadOutputRow> rows;
  final List<CadIssue> issues;
  final double? minY, maxY;
  final int omitted, noReferenceRows;
  const CadPreview({
    required this.bom,
    required this.coordinates,
    required this.unit,
    required this.rows,
    required this.issues,
    required this.minY,
    required this.maxY,
    required this.omitted,
    required this.noReferenceRows,
  });
  List<CadIssue> get errors => issues.where((i) => i.blocking).toList();
  bool get canExport => rows.isNotEmpty && !issues.any((i) => i.blocking);
}

class CadGenerator {
  /// V1.6 Bottom Y mirror / +180 rule. Units are explicit, and the mirror
  /// range uses the full valid coordinate file BEFORE BOM filtering.
  static CadPreview generate(
    MergedStationFile bom,
    CoordinateImport coordinates,
    CadUnit unit,
  ) {
    final issues = [...coordinates.issues];
    final index = <String, CoordinateRecord>{};
    double? minY, maxY;
    for (final record in coordinates.records) {
      final reference = record.reference.toUpperCase().trim();
      if (index.containsKey(reference)) {
        final first = index[reference]!;
        issues.add(
          CadIssue(
            'CAD 原坐标位号重复：首次位于 ${first.sheet} 第 ${first.row} 行',
            reference: reference,
            file: record.file,
            sheet: record.sheet,
            row: record.row,
          ),
        );
      } else {
        index[reference] = record;
      }
      final y = record.y * unit.factor, x = record.x * unit.factor;
      if (!y.isFinite || !x.isFinite) {
        issues.add(
          CadIssue(
            'CAD 单位换算后坐标超出有效范围',
            reference: reference,
            file: record.file,
            sheet: record.sheet,
            row: record.row,
          ),
        );
        continue;
      }
      if (minY == null || y < minY) minY = y;
      if (maxY == null || y > maxY) maxY = y;
    }
    final selected = <String>{}, output = <CadOutputRow>[];
    var noReferenceRows = 0;
    for (var i = 0; i < bom.rows.length; i++) {
      final row = bom.rows[i], source = bom.rows[i].sources.firstOrNull;
      void issue(String reason, [String reference = '']) => issues.add(
        CadIssue(
          reason,
          reference: reference,
          file: source?.file ?? '',
          sheet: source?.sheet ?? '',
          row: source?.row ?? i + 2,
        ),
      );
      if (row.positions.trim().isEmpty) {
        noReferenceRows++;
        final qty = double.tryParse(row.quantity.trim());
        if (row.quantity.trim().isNotEmpty && (qty == null || qty != 0)) {
          issue('CAD BOM 有用量但没有位号');
        }
        continue;
      }
      final positions = parsePositions(row.positions);
      for (final reason in positions.issues) {
        issue('CAD BOM 位号无效：$reason');
      }
      final qty = double.tryParse(row.quantity.trim().replaceAll(',', ''));
      final validGrouping =
          !row.quantity.contains(',') ||
          RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(row.quantity.trim());
      if (!validGrouping ||
          qty == null ||
          !qty.isFinite ||
          qty < 0 ||
          qty != qty.roundToDouble()) {
        issue('CAD BOM 数量必须为非负整数');
      } else if (qty != positions.values.length) {
        issue('CAD BOM 数量 ${row.quantity} 与位号数 ${positions.values.length} 不一致');
      }
      for (final reference in positions.values) {
        if (!selected.add(reference)) {
          issue('CAD BOM 位号重复或归属冲突', reference);
          continue;
        }
        final record = index[reference];
        if (record == null) {
          issue('CAD BOM 位号缺少原始坐标', reference);
          continue;
        }
        final x = record.x * unit.factor;
        var y = record.y * unit.factor, angle = record.angle;
        if (record.layer == 'Bottom' && minY != null && maxY != null) {
          y = minY + maxY - y;
          angle += 180;
        }
        angle = ((angle % 360) + 360) % 360;
        if (!x.isFinite || !y.isFinite || !angle.isFinite) {
          issue('CAD 单位换算后坐标超出有效范围', reference);
          continue;
        }
        output.add(
          CadOutputRow(record, row, x == 0 ? 0 : x, y == 0 ? 0 : y, angle),
        );
      }
    }
    if (output.isEmpty) issues.add(const CadIssue('CAD 没有可导出的有效坐标'));
    return CadPreview(
      bom: bom,
      coordinates: coordinates,
      unit: unit,
      rows: List.unmodifiable(output),
      issues: List.unmodifiable(issues),
      minY: minY,
      maxY: maxY,
      omitted: index.keys.where((r) => !selected.contains(r)).length,
      noReferenceRows: noReferenceRows,
    );
  }
}

String cadFileName(String input) {
  final name = input.trim().replaceFirst(
    RegExp(r'\.xlsx$', caseSensitive: false),
    '',
  );
  if (name.isEmpty ||
      name.endsWith('.') ||
      RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(name) ||
      RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
        caseSensitive: false,
      ).hasMatch(name)) {
    throw const FormatException('请输入有效文件名，不含路径或特殊字符');
  }
  if (name.length > 180) throw const FormatException('文件名过长，请缩短至 180 个字符以内');
  return '$name.xlsx';
}
