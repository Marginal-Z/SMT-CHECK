import 'dart:convert';

import '../l10n/localization.dart';
import 'ai_result_languages.dart';

enum AiStage {
  idle,
  preparing,
  confirming,
  connecting,
  thinking,
  receiving,
  localizing,
  complete,
  failed,
  cancelled,
}

class AiTransfer {
  final AiStage stage;
  final int characters;
  const AiTransfer(this.stage, [this.characters = 0]);
}

class AiFinding {
  final String part, category, reason, bom, smt, source;
  final Map<String, String> categories, reasons;
  const AiFinding({
    required this.part,
    required this.category,
    required this.reason,
    this.bom = '',
    this.smt = '',
    this.source = '',
    this.categories = const {},
    this.reasons = const {},
  });
  bool get hasAllLanguages => supportedLanguages.every(
    (language) =>
        (categories[language]?.trim().isNotEmpty ?? false) &&
        (reasons[language]?.trim().isNotEmpty ?? false),
  );
  String categoryFor(String language) => categories[language] ?? category;
  String reasonFor(String language) => reasons[language] ?? reason;
  AiFinding localized(
    Map<String, String> categoryValues,
    Map<String, String> reasonValues,
  ) => AiFinding(
    part: part,
    category: categoryValues['zh']!,
    reason: reasonValues['zh']!,
    categories: categoryValues,
    reasons: reasonValues,
    bom: bom,
    smt: smt,
    source: source,
  );
  Map<String, dynamic> toJson() => {
    'part': part,
    'category': categories.isEmpty ? category : categories,
    'reason': reasons.isEmpty ? reason : reasons,
    'bom': bom,
    'smt': smt,
    'source': source,
  };
  // Secondary translations must not turn the same finding into duplicates.
  String get identity =>
      jsonEncode([part, categoryFor('zh'), reasonFor('zh'), bom, smt, source]);
  String toText({String language = 'zh'}) => [
    '$part · ${categoryFor(language)}',
    reasonFor(language),
    if (bom.isNotEmpty) 'BOM: $bom',
    if (smt.isNotEmpty) 'SMT: $smt',
    if (source.isNotEmpty) source,
  ].join('\n');
}

/// Only explicit anomaly records are accepted. Invalid/incomplete output is
/// never converted into a successful "no anomalies" result.
List<AiFinding> parseAiFindings(String response) {
  const invalid = FormatException('AI 未返回有效的异常清单，本批未完成，请重试未完成批次。');
  dynamic data;
  try {
    data = decodeAiJson(response);
  } catch (_) {
    throw invalid;
  }
  if (data is! Map || data['anomalies'] is! List) throw invalid;
  final findings = <AiFinding>[];
  for (final value in data['anomalies']) {
    if (value is! Map) throw invalid;
    String field(String key, {bool required = false}) {
      final result = value[key];
      if ((result != null && result is! String) ||
          (required && (result is! String || result.trim().isEmpty))) {
        throw invalid;
      }
      return result is String ? (required ? result.trim() : result) : '';
    }

    Map<String, String> translations(String key) {
      final result = value[key];
      if (result is String && result.trim().isNotEmpty) return const {};
      try {
        return aiLanguageMap(result);
      } on FormatException {
        throw invalid;
      }
    }

    final categories = translations('category'),
        reasons = translations('reason');
    String base(String key, Map<String, String> values) => values.isEmpty
        ? field(key, required: true)
        : values['zh'] ?? values.values.first;

    if (value.containsKey('status') &&
        !['error', 'anomaly'].contains(value['status'])) {
      throw invalid;
    }
    findings.add(
      AiFinding(
        part: field('part', required: true),
        category: base('category', categories),
        reason: base('reason', reasons),
        categories: categories,
        reasons: reasons,
        bom: field('bom'),
        smt: field('smt'),
        source: field('source'),
      ),
    );
  }
  return findings;
}
