/// Full-field pattern matching with a small NFA, avoiding backtracking against
/// long imported descriptions. Supports literals, classes, ., * + ?, |, ^ and $.
class SpecialPattern {
  final List<List<_Token>> _alternatives;
  SpecialPattern(String pattern) : _alternatives = _parse(pattern);

  static List<List<_Token>> _parse(String pattern) {
    final branches = <List<_Token>>[], tokens = <_Token>[];
    var repeats = 0;
    if (pattern.isEmpty || pattern.length > 160) {
      throw const FormatException('特殊元件规则正则格式无效');
    }
    for (var i = 0; i < pattern.length; i++) {
      final c = pattern[i];
      if (c == '|') {
        if (tokens.isEmpty) throw const FormatException('特殊元件规则正则格式无效');
        branches.add(List.of(tokens));
        tokens.clear();
        continue;
      }
      if (c == '^' && tokens.isEmpty) continue;
      if (c == r'$' && (i == pattern.length - 1 || pattern[i + 1] == '|')) {
        continue;
      }
      if ('(){}\\*+?^\$]'.contains(c)) {
        throw const FormatException('规则仅支持安全的正则子集：字符、字符组、点、星号、加号、问号及锚点');
      }
      String atom;
      if (c == '[') {
        final end = pattern.indexOf(']', i + 1);
        if (end < 0) throw const FormatException('特殊元件规则正则格式无效');
        atom = pattern.substring(i, end + 1);
        i = end;
      } else {
        atom = c == '.' ? r'[\s\S]' : RegExp.escape(c);
      }
      var quantifier = '';
      if (i + 1 < pattern.length && '*+?'.contains(pattern[i + 1])) {
        quantifier = pattern[++i];
        repeats++;
      }
      if (repeats > 3) {
        throw const FormatException('规则仅支持安全的正则子集：字符、字符组、点、星号、加号、问号及锚点');
      }
      try {
        tokens.add(
          _Token(RegExp('^(?:$atom)\$', caseSensitive: false), quantifier),
        );
      } on FormatException {
        throw const FormatException('特殊元件规则正则格式无效');
      }
    }
    if (tokens.isEmpty) throw const FormatException('特殊元件规则正则格式无效');
    branches.add(List.of(tokens));
    return branches;
  }

  bool matches(String text) {
    for (final tokens in _alternatives) {
      Set<int> closure(Set<int> states) {
        final pending = states.toList();
        for (var n = 0; n < pending.length; n++) {
          final state = pending[n];
          if (state < tokens.length &&
              tokens[state].optional &&
              states.add(state + 1)) {
            pending.add(state + 1);
          }
        }
        return states;
      }

      var states = closure({0});
      for (final rune in text.runes) {
        final next = <int>{}, char = String.fromCharCode(rune);
        for (final state in states) {
          if (state < tokens.length && tokens[state].character.hasMatch(char)) {
            next.add(state + 1);
            if (tokens[state].repeat) next.add(state);
          }
        }
        states = closure(next);
        if (states.isEmpty) break;
      }
      if (states.contains(tokens.length)) return true;
    }
    return false;
  }
}

class _Token {
  final RegExp character;
  final String quantifier;
  const _Token(this.character, this.quantifier);
  bool get optional => quantifier == '*' || quantifier == '?';
  bool get repeat => quantifier == '*' || quantifier == '+';
}
