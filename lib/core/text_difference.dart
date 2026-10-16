import 'dart:typed_data';

class TextChangeRange {
  final int start, end;
  const TextChangeRange(this.start, this.end);
  Map<String, Object> toJson(String value) => {
    'start': start,
    'end': end,
    'text': value.substring(start, end),
  };
}

class _Token {
  final String value;
  final int start, end;
  const _Token(this.value, this.start, this.end);
}

List<_Token> _tokens(String value) {
  final text = StringBuffer(), starts = <int>[], ends = <int>[];
  for (final match in RegExp(r'\S', unicode: true).allMatches(value)) {
    final normalized = match[0]!.toUpperCase();
    text.write(normalized);
    for (var i = 0; i < normalized.length; i++) {
      starts.add(match.start);
      ends.add(match.end);
    }
  }
  return [
    for (final match in RegExp(r'.', unicode: true).allMatches(text.toString()))
      _Token(match[0]!, starts[match.start], ends[match.end - 1]),
  ];
}

/// Compare the same case/whitespace-normalized text as the checker, but return
/// ranges in the untouched original strings. Numeric values/units remain whole.
({List<TextChangeRange> bom, List<TextChangeRange> smt}) compareDescriptionText(
  String bom,
  String smt,
) {
  final a = _tokens(bom), b = _tokens(smt);
  final keptA = <int>{}, keptB = <int>{};
  if (a.length <= 512 && b.length <= 512 && a.length * b.length <= 65536) {
    final lengths = List.generate(
      a.length + 1,
      (_) => Uint16List(b.length + 1),
    );
    for (var i = a.length - 1; i >= 0; i--) {
      for (var j = b.length - 1; j >= 0; j--) {
        lengths[i][j] = a[i].value == b[j].value
            ? lengths[i + 1][j + 1] + 1
            : lengths[i + 1][j] >= lengths[i][j + 1]
            ? lengths[i + 1][j]
            : lengths[i][j + 1];
      }
    }
    var i = 0, j = 0;
    while (i < a.length && j < b.length) {
      if (a[i].value == b[j].value) {
        keptA.add(i++);
        keptB.add(j++);
      } else if (lengths[i + 1][j] >= lengths[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
  } else {
    // Bound work for unusually long cells; preserve equal prefix/suffix tokens.
    var prefix = 0;
    while (prefix < a.length &&
        prefix < b.length &&
        a[prefix].value == b[prefix].value) {
      keptA.add(prefix);
      keptB.add(prefix++);
    }
    var i = a.length - 1, j = b.length - 1;
    while (i >= prefix && j >= prefix && a[i].value == b[j].value) {
      keptA.add(i--);
      keptB.add(j--);
    }
  }
  List<TextChangeRange> ranges(String raw, List<_Token> tokens, Set<int> kept) {
    final result = <TextChangeRange>[];
    for (var i = 0; i < tokens.length; i++) {
      if (kept.contains(i)) continue;
      final token = tokens[i];
      if (result.isNotEmpty &&
          (result.last.end >= token.start ||
              raw.substring(result.last.end, token.start).trim().isEmpty)) {
        result[result.length - 1] = TextChangeRange(
          result.last.start,
          token.end,
        );
      } else {
        result.add(TextChangeRange(token.start, token.end));
      }
    }
    final expanded = <TextChangeRange>[];
    final numeric = RegExp(r'\d+(?:\.\d+)?[A-Za-z]*').allMatches(raw).toList();
    for (final range in result) {
      var start = range.start, end = range.end;
      for (final match in numeric) {
        if (match.start < range.end && match.end > range.start) {
          if (match.start < start) start = match.start;
          if (match.end > end) end = match.end;
        }
      }
      if (expanded.isNotEmpty && expanded.last.end >= start) {
        expanded[expanded.length - 1] = TextChangeRange(
          expanded.last.start,
          end > expanded.last.end ? end : expanded.last.end,
        );
      } else {
        expanded.add(TextChangeRange(start, end));
      }
    }
    return expanded;
  }

  return (bom: ranges(bom, a, keptA), smt: ranges(smt, b, keptB));
}

List<TextChangeRange> positionChangeRanges(
  List<String> positions,
  Set<String> changed,
) {
  final ranges = <TextChangeRange>[];
  var offset = 0;
  for (final position in positions) {
    if (changed.contains(position)) {
      ranges.add(TextChangeRange(offset, offset + position.length));
    }
    offset += position.length + 1; // The comparison value uses the separator 、.
  }
  return ranges;
}
