import 'dart:convert';

import '../l10n/localization.dart';

const incompleteAiLanguages = 'AI 返回的三语结果不完整，请重试分析。';

dynamic decodeAiJson(String response) {
  var text = response.trim();
  if (text.startsWith('```') && text.endsWith('```')) {
    final line = text.indexOf('\n');
    if (line < 0) throw const FormatException(incompleteAiLanguages);
    text = text.substring(line + 1, text.length - 3).trim();
  }
  try {
    return jsonDecode(text);
  } on FormatException {
    throw const FormatException(incompleteAiLanguages);
  }
}

Map<String, String> aiLanguageMap(dynamic value, {bool complete = false}) {
  if (value is! Map) throw const FormatException(incompleteAiLanguages);
  final result = <String, String>{};
  for (final language in supportedLanguages) {
    final text = value[language];
    if (text == null && !complete) continue;
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException(incompleteAiLanguages);
    }
    result[language] = text.trim();
  }
  if (result.isEmpty) throw const FormatException(incompleteAiLanguages);
  return Map.unmodifiable(result);
}

Map<String, String> parseAiNarrative(String response) {
  final data = decodeAiJson(response);
  if (data is! Map) throw const FormatException(incompleteAiLanguages);
  return aiLanguageMap(data['analysis'], complete: true);
}
