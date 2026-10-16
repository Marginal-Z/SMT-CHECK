import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/services/ai_findings.dart';

void main() {
  test('only anomaly fields are retained, including original evidence', () {
    final data = {
      'anomalies': [
        {
          'part': 'P1',
          'category': '数量不符',
          'reason': '1 != 2',
          'bom': '原始 BOM 数量1',
          'smt': '原始 SMT 数量2',
          'source': 'a.xlsx Sheet:3',
        },
      ],
      'reasoning': 'DO NOT DISPLAY',
      'matches': ['PASS'],
    };
    final findings = parseAiFindings('```json\n${jsonEncode(data)}\n```');
    expect(findings.single.part, 'P1');
    expect(findings.single.bom, '原始 BOM 数量1');
    expect(findings.single.toText(), isNot(contains('DO NOT DISPLAY')));
    expect(findings.single.toText(), isNot(contains('PASS')));
    expect(parseAiFindings('{"anomalies":[]}'), isEmpty);
  });
  test('missing, partial or non-anomaly results never become a successful empty review', () {
    for (final input in [
      'all passed',
      '{"matches":[]}',
      '{"anomalies":null}',
      '{"anomalies":[{}]}',
      '{"anomalies":[{"part":"P1","category":"pass","reason":"match","status":"pass"}]}',
      '{"anomalies":[{"part":"P1","category":"x","reason":42}]}',
    ]) {
      expect(() => parseAiFindings(input), throwsFormatException);
    }
  });
}
