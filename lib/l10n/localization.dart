import 'catalog.dart';

const supportedLanguages = ['zh', 'en', 'th'];
const languageNames = {'zh': '中文', 'en': 'English', 'th': 'ไทย'};

final _patterns = catalog.entries.where((e) => e.key.contains('{')).map((e) {
  final keys = RegExp(r'\{(\w+)\}')
      .allMatches(e.key)
      .map((m) => m[1]!)
      .toList();
  var pattern = RegExp.escape(e.key);
  for (final key in keys) {
    pattern = pattern.replaceFirst(
      RegExp.escape('{$key}'),
      ['count', 'row', 'pass', 'total'].contains(key) ? r'([0-9]+)' : '(.+?)',
    );
  }
  return (RegExp('^$pattern\$', dotAll: true), e, keys);
}).toList();

/// Only pass application text here. Spreadsheet values are displayed verbatim.
String translate(String text, String language) {
  if (language == 'zh' || !supportedLanguages.contains(language)) return text;
  final index = language == 'en' ? 0 : 1;
  final exact = catalog[text];
  if (exact != null) return exact[index];
  for (final (pattern, entry, keys) in _patterns) {
    final match = pattern.firstMatch(text);
    if (match == null) continue;
    var result = entry.value[index];
    for (var i = 0; i < keys.length; i++) {
      final value = match[i + 1]!;
      final nested = ['message', 'reason', 'detail', 'scope'].contains(keys[i]);
      result = result.replaceAll(
        '{${keys[i]}}',
        nested ? translate(value, language) : value,
      );
    }
    return result;
  }
  return text;
}
