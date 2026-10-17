import 'models.dart';

enum MergeMode { summarize, details }

class ManualReview {
  final bool include;
  final DateTime confirmedAt;
  ManualReview(this.include) : confirmedAt = DateTime.now();
}

class MergedStationRow {
  final String part, description, quantity, positions;
  final List<MaterialRow> sources;
  const MergedStationRow({
    required this.part,
    required this.description,
    required this.quantity,
    required this.positions,
    required this.sources,
  });
  List<String> get cells => [part, description, quantity, positions];
}

class MergedStationFile {
  static const headers = ['料号', '物料描述', '数量', '位号'];
  final List<MergedStationRow> rows;
  final int includedSourceRows, omittedSourceRows, revision;
  final MergeMode mode;
  const MergedStationFile({
    required this.rows,
    required this.includedSourceRows,
    required this.omittedSourceRows,
    required this.revision,
    required this.mode,
  });
}

/// Decisions belong to this exact report, never to a part number shared by
/// multiple excluded/candidate records. A new check must create a new session.
class StationMergeSession {
  final CheckReport report;
  final Map<CheckItem, ManualReview> _reviews = {};
  int _revision = 0;
  MergedStationFile? preview;
  StationMergeSession(this.report);

  List<CheckItem> get requiredItems => report.items
      .where((i) => i.status != CheckStatus.pass)
      .toList(growable: false);
  ManualReview? reviewFor(CheckItem item) => _reviews[item];
  int get pendingCount =>
      requiredItems.where((i) => !_reviews.containsKey(i)).length;
  int get confirmedCount => requiredItems.length - pendingCount;
  bool get hasTwoStations =>
      report.merged &&
      report.files.where((f) => f.kind == InputKind.station).length == 2;
  bool get canGenerate => hasTwoStations && pendingCount == 0;
  bool get canExport =>
      canGenerate && preview != null && preview!.revision == _revision;

  void confirm(CheckItem item, {required bool include}) {
    if (!requiredItems.contains(item)) throw ArgumentError('此项不属于当前待确认核对结果');
    if (include && item.smt.isEmpty) {
      throw ArgumentError('仅 BOM 有记录，不能生成 SMT 原始数据');
    }
    _reviews[item] = ManualReview(include);
    _invalidate();
  }

  void revoke(CheckItem item) {
    if (_reviews.remove(item) != null) _invalidate();
  }

  void _invalidate() {
    _revision++;
    preview = null;
  }

  void clearPreview() => _invalidate();

  MergedStationFile generate(MergeMode mode) {
    if (!hasTwoStations) throw StateError('请先以 A+B 合并模式完成核对');
    if (pendingCount != 0) throw StateError('请先逐项确认 NG、已排除物料和候选料');
    final decisions = <MaterialRow, bool>{};
    for (final item in report.items) {
      final include =
          item.status == CheckStatus.pass || _reviews[item]!.include;
      for (final row in item.smt) {
        if (decisions.containsKey(row)) throw StateError('站位表记录重复归属，请重新核对');
        decisions[row] = include;
      }
    }
    final original = report.files
        .where((f) => f.kind == InputKind.station)
        .expand((f) => f.rows)
        .toList();
    if (original.toSet().length != original.length ||
        decisions.length != original.length ||
        original.any((r) => !decisions.containsKey(r))) {
      throw StateError('核对结果与站位表记录不完整对应，请重新核对');
    }
    final included = original.where((r) => decisions[r]!).toList();
    final groups = <List<MaterialRow>>[];
    final indexes = <(String, String), int>{};
    for (final row in included) {
      final key = (row.part, row.description);
      final index = indexes[key];
      if (mode == MergeMode.summarize &&
          row.quantity != null &&
          _canSum(row.quantityText) &&
          row.part.trim().isNotEmpty) {
        if (index != null &&
            groups[index].fold<int>(
                      0,
                      (n, r) => n + r.positionsText.length + 1,
                    ) +
                    row.positionsText.length <=
                32767) {
          groups[index].add(row);
          continue;
        }
        indexes[key] = groups.length;
      }
      groups.add([row]);
    }
    preview = MergedStationFile(
      rows: List.unmodifiable(
        groups.map(
          (group) => MergedStationRow(
            part: group.first.part,
            description: group.first.description,
            quantity: group.length == 1
                ? group.first.quantityText
                : _sum(group),
            // Keep duplicate references visible; never hide a known conflict by
            // deduplicating. A and B retain their original reference spelling.
            positions: group
                .map((r) => r.positionsText)
                .where((p) => p.isNotEmpty)
                .join('\n'),
            sources: List.unmodifiable(group),
          ),
        ),
      ),
      includedSourceRows: included.length,
      omittedSourceRows: original.length - included.length,
      revision: _revision,
      mode: mode,
    );
    return preview!;
  }
}

// Decimal arithmetic avoids 0.1 + 0.2 becoming 0.30000000000000004.
bool _canSum(String raw) {
  final text = raw.trim().replaceAll(',', '');
  final exponent = text.toLowerCase().split('e');
  return text.length <= 400 &&
      (exponent.length == 1 ||
          (int.tryParse(exponent.last)?.abs() ?? 999) <= 308);
}

String _sum(List<MaterialRow> rows) {
  final numbers = rows.map((r) {
    final text = r.quantityText.trim().replaceAll(',', '');
    final parts = text.toLowerCase().split('e');
    final decimal = parts.first.split('.');
    final scale =
        (decimal.length == 2 ? decimal.last.length : 0) -
        (parts.length == 2 ? int.parse(parts.last) : 0);
    return (BigInt.parse(decimal.join().replaceFirst('+', '')), scale);
  }).toList();
  final scale = numbers.map((n) => n.$2).reduce((a, b) => a > b ? a : b);
  final total = numbers.fold<BigInt>(
    BigInt.zero,
    (sum, n) => sum + n.$1 * BigInt.from(10).pow(scale - n.$2),
  );
  if (scale <= 0) return (total * BigInt.from(10).pow(-scale)).toString();
  final digits = total.abs().toString().padLeft(scale + 1, '0');
  final value =
      '${digits.substring(0, digits.length - scale)}.${digits.substring(digits.length - scale)}'
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
  return '${total.isNegative ? '-' : ''}$value';
}

String mergedFileName(String input) {
  var name = input.trim().replaceFirst(
    RegExp(r'\.xlsx$', caseSensitive: false),
    '',
  );
  if (name.isEmpty ||
      RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(name) ||
      name.endsWith('.') ||
      name == '.' ||
      name == '..' ||
      RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
        caseSensitive: false,
      ).hasMatch(name)) {
    throw const FormatException('请输入有效文件名，不含路径或特殊字符');
  }
  if (!name.toUpperCase().endsWith('BOM')) name = '$name-BOM';
  if (name.length > 180) throw const FormatException('文件名过长，请缩短至 180 个字符以内');
  return '$name.xlsx';
}
