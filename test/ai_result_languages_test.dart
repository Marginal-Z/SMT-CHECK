import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smt_check/services/ai_findings.dart';
import 'package:smt_check/services/ai_result_languages.dart';
import 'package:smt_check/services/ai_service.dart';

const categories = {
  'zh': '数量不符',
  'en': 'Quantity mismatch',
  'th': 'จำนวนไม่ตรงกัน',
};
const reasons = {
  'zh': 'SMT 比 BOM 多 1 个。',
  'en': 'SMT has 1 more than BOM.',
  'th': 'SMT มากกว่า BOM 1 ชิ้น',
};
const narrative = {
  'zh': '核实 R1 的数量，不批准替代。',
  'en': 'Verify the quantity of R1; no substitution is approved.',
  'th': 'ตรวจสอบจำนวน R1 โดยยังไม่อนุมัติการทดแทน',
};
const config = AiConfig(baseUrl: 'http://localhost/v1', model: 'test');

http.Response jsonReply(Object value) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'choices': [
        {
          'message': {'content': jsonEncode(value)},
        },
      ],
    }),
  ),
  200,
);

Map<String, dynamic> findingJson() => {
  'part': 'P1',
  'category': categories,
  'reason': reasons,
  'bom': ' 原始中文 BOM 数量 1\n',
  'smt': ' 原始 SMT 数量 2\n',
  'source': ' 文件.xlsx / 中文工作表:3 ',
};

void main() {
  test('all three explanation languages parse, while evidence remains byte-for-byte original', () {
    final raw = findingJson();
    final finding = parseAiFindings(
      '```json\n${jsonEncode({
        'anomalies': [raw],
      })}\n```',
    ).single;
    expect(finding.hasAllLanguages, true);
    for (final lang in ['zh', 'en', 'th']) {
      expect(finding.categoryFor(lang), categories[lang]);
      expect(finding.reasonFor(lang), reasons[lang]);
      expect(finding.toText(language: lang), contains(reasons[lang]!));
    }
    expect(finding.bom, raw['bom']);
    expect(finding.smt, raw['smt']);
    expect(finding.source, raw['source']);
    expect(finding.toJson()['reason'], reasons);
    expect(
      finding.localized({
        ...categories,
        'en': 'Changed English',
      }, reasons).identity,
      finding.identity,
    );
  });
  test(
    'complete multilingual responses need no translation requests',
    () async {
      var calls = 0;
      final service = AiService(
        client: MockClient((_) async {
          calls++;
          throw StateError('unexpected network call');
        }),
      );
      addTearDown(service.close);
      final findings = parseAiFindings(
        jsonEncode({
          'anomalies': [findingJson()],
        }),
      );
      expect(await service.localizeFindings(config, findings), same(findings));
      expect(await service.localizeFindings(config, []), isEmpty);
      expect(
        await service.localizeAnalysis(
          config,
          jsonEncode({'analysis': narrative}),
        ),
        narrative,
      );
      expect(calls, 0);
    },
  );
  test('single-language endpoint repair sends only explanations, and cannot alter evidence or identities', () async {
    const legacy = AiFinding(
      part: 'ORIGINAL',
      category: '数量不符',
      reason: 'SMT 多 1',
      bom: 'BOM-EVIDENCE-PRIVATE',
      smt: 'SMT-EVIDENCE-PRIVATE',
      source: 'PRIVATE.xlsx Sheet:9',
    );
    final stages = <AiStage>[];
    final service = AiService(
      client: MockClient((request) async {
        final body = jsonDecode(request.body);
        final payload = jsonDecode(body['messages'][1]['content']);
        expect(payload['task'], 'translate_ai_findings');
        expect(payload['items'], [
          {'id': 0, 'category': '数量不符', 'reason': 'SMT 多 1'},
        ]);
        for (final value in [
          legacy.part,
          legacy.bom,
          legacy.smt,
          legacy.source,
        ]) {
          expect(request.body, isNot(contains(value)));
        }
        return jsonReply({
          'translations': [
            {
              'id': 0,
              'category': categories,
              'reason': reasons,
              'part': 'MALICIOUS REPLACEMENT',
              'bom': 'DO NOT ACCEPT',
              'source': 'OTHER.xlsx',
            },
          ],
        });
      }),
    );
    addTearDown(service.close);
    final result = (await service.localizeFindings(
      config,
      [legacy],
      language: 'th',
      onProgress: (p) => stages.add(p.stage),
    )).single;
    expect(result.part, legacy.part);
    expect(result.bom, legacy.bom);
    expect(result.smt, legacy.smt);
    expect(result.source, legacy.source);
    expect(result.reasonFor('th'), reasons['th']);
    expect(stages, everyElement(AiStage.localizing));
  });
  test('translation IDs may reorder responses but may not add or duplicate findings', () async {
    for (final ids in [
      [1, 0],
      [0, 0],
      [0, 2],
      [0],
    ]) {
      final service = AiService(
        client: MockClient(
          (_) async => jsonReply({
            'translations': [
              for (final id in ids)
                {
                  'id': id,
                  'category': categories,
                  'reason': {...reasons, 'zh': '原因$id'},
                },
            ],
          }),
        ),
      );
      addTearDown(service.close);
      final future = service.localizeFindings(config, [
        const AiFinding(part: 'A', category: '异常', reason: '原因A'),
        const AiFinding(part: 'B', category: '异常', reason: '原因B'),
      ]);
      if (ids.toString() == '[1, 0]') {
        final result = await future;
        expect(result.map((f) => f.part), ['A', 'B']);
        expect(result.map((f) => f.reason), ['原因0', '原因1']);
      } else {
        await expectLater(future, throwsFormatException);
      }
    }
  });
  test(
    'legacy local explanations are translated once and cached by callers',
    () async {
      final service = AiService(
        client: MockClient((request) async {
          final payload = jsonDecode(
            jsonDecode(request.body)['messages'][1]['content'],
          );
          expect(payload['task'], 'translate_ai_analysis');
          expect(payload['generatedAnalysis'], '核实 R1，不可替换。');
          expect(payload.containsKey('records'), false);
          return jsonReply({'analysis': narrative});
        }),
      );
      addTearDown(service.close);
      expect(await service.localizeAnalysis(config, '核实 R1，不可替换。'), narrative);
    },
  );
  test('missing locales, blank text and invalid types cannot masquerade as complete translations', () async {
    for (final map in [
      {'zh': '中文', 'en': 'English'},
      {...reasons, 'th': ''},
      {...reasons, 'en': 42},
    ]) {
      expect(() => aiLanguageMap(map, complete: true), throwsFormatException);
      expect(
        () => parseAiNarrative(jsonEncode({'analysis': map})),
        throwsFormatException,
      );
      final service = AiService(
        client: MockClient(
          (_) async => jsonReply({
            'translations': [
              {'id': 0, 'category': categories, 'reason': map},
            ],
          }),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.localizeFindings(config, [
          const AiFinding(part: 'P', category: 'x', reason: 'y'),
        ]),
        throwsFormatException,
      );
    }
  });
  test('translation failure does not ask the app to split and repeat source analysis', () async {
    final service = AiService(
      client: MockClient((_) async => http.Response('too long', 413)),
    );
    addTearDown(service.close);
    await expectLater(
      service.localizeFindings(config, [
        const AiFinding(part: 'P', category: 'x', reason: 'y'),
      ]),
      throwsA(
        isA<AiRequestException>().having(
          (e) => e.canSplitBatch,
          'canSplitBatch',
          false,
        ),
      ),
    );
  });
}
