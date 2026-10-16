import 'dart:convert';

enum AiStage {
  idle,
  preparing,
  confirming,
  connecting,
  thinking,
  receiving,
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
  const AiFinding({
    required this.part,
    required this.category,
    required this.reason,
    this.bom = '',
    this.smt = '',
    this.source = '',
  });
  Map<String, String> toJson() => {
    'part': part,
    'category': category,
    'reason': reason,
    'bom': bom,
    'smt': smt,
    'source': source,
  };
  String get identity => jsonEncode(toJson());
  String toText() => [
    '$part · $category',
    reason,
    if (bom.isNotEmpty) 'BOM: $bom',
    if (smt.isNotEmpty) 'SMT: $smt',
    if (source.isNotEmpty) source,
  ].join('\n');
}

/// Only explicit anomaly records are accepted. Invalid/incomplete output is
/// never converted into a successful "no anomalies" result.
List<AiFinding> parseAiFindings(String response) {
  const invalid = FormatException('AI 未返回有效的异常清单，本批未完成，请重试未完成批次。');
  var text = response.trim();
  if (text.startsWith('```') && text.endsWith('```')) {
    final firstLine = text.indexOf('\n');
    if (firstLine < 0) throw invalid;
    text = text.substring(firstLine + 1, text.length - 3).trim();
  }
  dynamic data;
  try {
    data = jsonDecode(text);
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
      return result is String ? result.trim() : '';
    }

    if (value.containsKey('status') &&
        !['error', 'anomaly'].contains(value['status'])) {
      throw invalid;
    }
    findings.add(
      AiFinding(
        part: field('part', required: true),
        category: field('category', required: true),
        reason: field('reason', required: true),
        bom: field('bom'),
        smt: field('smt'),
        source: field('source'),
      ),
    );
  }
  return findings;
}
