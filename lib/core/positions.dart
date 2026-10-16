class ParsedPositions {
  final List<String> values, issues;
  const ParsedPositions(this.values, this.issues);
  Set<String> get unique => values.toSet();
}

ParsedPositions parsePositions(String text, {bool bom = false}) {
  var raw = text
      .toUpperCase()
      .replaceAll('，', ',')
      .replaceAll('；', ';')
      .replaceAll('、', ',')
      .replaceAll('～', '~')
      .replaceAll('－', '-')
      .replaceAll('—', '-');
  // T100 exports insert hard wraps in the middle of designators (8R\n23, 1\nC39).
  if (bom) {
    raw = raw.replaceAll(RegExp(r'(?<=[A-Z0-9])\r?\n(?=[0-9])'), '');
    raw = raw.replaceAllMapped(
      RegExp(r'(^|[,;\s])(\d+)\r?\n(?=[A-Z])'),
      (m) => '${m[1]}${m[2]}',
    );
  }
  final values = <String>[], issues = <String>[];
  for (final token
      in raw.split(RegExp(r'[,;\s]+')).where((s) => s.isNotEmpty)) {
    final range = RegExp(r'^(\d*[A-Z]+)(\d+)[~-](?:(\d*[A-Z]+))?(\d+)$')
        .firstMatch(token);
    if (range != null) {
      final prefix = range[1]!, endPrefix = range[3] ?? prefix;
      final start = int.parse(range[2]!), end = int.parse(range[4]!);
      if (prefix != endPrefix || end < start || end - start > 10000) {
        issues.add('无法解析位号区间「$token」');
        continue;
      }
      for (var i = start; i <= end; i++) {
        values.add('$prefix$i');
      }
    } else if (RegExp(r'^\d*[A-Z]+\d+[A-Z]?(?:_\d+)*$').hasMatch(token) ||
        token == 'PCB') {
      values.add(token);
    } else {
      issues.add('无法识别位号「$token」');
    }
  }
  final counts = <String, int>{};
  for (final p in values) {
    counts[p] = (counts[p] ?? 0) + 1;
  }
  for (final e in counts.entries.where((e) => e.value > 1)) {
    issues.add('位号 ${e.key} 在同一行重复 ${e.value} 次');
  }
  return ParsedPositions(values, issues);
}

String normalizePart(String s) => s.trim().toUpperCase();
String normalizeDescription(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'\s+'), '');
String numberText(double? n) => n == null
    ? '—'
    : n == n.roundToDouble()
    ? n.toInt().toString()
    : n.toString();
