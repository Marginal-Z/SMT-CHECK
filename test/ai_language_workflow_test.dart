import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/ai_service.dart';

import 'ai_result_languages_test.dart' as data;
import 'ai_workflow_test.dart' as flow;
import 'checker_test.dart' as f;

Future<void> chooseLanguage(WidgetTester tester, String language) async {
  // Bounded pumps also work while the analysis activity is animating.
  await tester.tap(find.byKey(const Key('language-selector')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(languageNames[language]!).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

http.Response sourceReply() => flow.reply(
  jsonEncode({
    'anomalies': [data.findingJson()],
  }),
  source: false,
);

void main() {
  for (final width in [560.0, 800.0, 1560.0]) {
    testWidgets(
      'cached source explanations and copied results follow all languages at $width',
      (tester) async {
        var calls = 0;
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = call.arguments['text'];
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await flow.prepare(tester, (_) async {
          calls++;
          return sourceReply();
        });
        tester.view.physicalSize = Size(width, 980);
        await tester.pumpAndSettle();
        await flow.startSource(tester);
        await tester.pumpAndSettle();
        for (final language in ['en', 'th', 'zh', 'en']) {
          await chooseLanguage(tester, language);
          await tester.pumpAndSettle();
          expect(find.text(data.categories[language]!), findsOneWidget);
          expect(find.text(data.reasons[language]!), findsOneWidget);
          expect(find.text(data.findingJson()['bom']), findsOneWidget);
          expect(find.text(data.findingJson()['source']), findsOneWidget);
          expect(
            find.text(translate('全部 1 批分析完成。AI 结论供复核，不改变本地核对状态。', language)),
            findsOneWidget,
          );
          await tester.tap(find.text(translate('复制', language)));
          await tester.pump();
          expect(copied, contains(data.reasons[language]!));
          expect(copied, contains(data.findingJson()['bom']));
          expect(copied, contains(data.findingJson()['source']));
          expect(calls, 1);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets(
    'switching language during a request shows the latest language on completion',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      await flow.prepare(tester, (_) {
        calls++;
        return pending.future;
      });
      await flow.startSource(tester);
      await chooseLanguage(tester, 'en');
      await chooseLanguage(tester, 'th');
      pending.complete(sourceReply());
      await tester.pumpAndSettle();
      expect(find.text(data.reasons['th']!), findsOneWidget);
      expect(find.text(data.reasons['zh']!), findsNothing);
      expect(calls, 1);
    },
  );
  testWidgets('local anomaly explanations also switch without reanalysis', (
    tester,
  ) async {
    var calls = 0;
    String? copied;
    SharedPreferences.setMockInitialValues({
      'aiUrl': 'http://localhost/v1',
      'aiModel': 'demo',
    });
    tester.view.physicalSize = const Size(1560, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied = call.arguments['text'];
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      SmtFusionApp(
        initialReport: f.check(
          [f.row('P', '1', 'R1')],
          [f.row('P', '1', 'R2')],
        ),
        aiServiceFactory: () => AiService(
          client: MockClient((_) async {
            calls++;
            return flow.reply(
              jsonEncode({'analysis': data.narrative}),
              source: false,
            );
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('AI 分析核对'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本地异常解读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分析异常'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送并分析'));
    await tester.pumpAndSettle();
    for (final language in ['en', 'th', 'zh']) {
      await chooseLanguage(tester, language);
      await tester.pumpAndSettle();
      expect(find.text(data.narrative[language]!), findsOneWidget);
      await tester.tap(find.text(translate('复制', language)));
      await tester.pump();
      expect(copied, data.narrative[language]);
      expect(calls, 1);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'a legacy Chinese-only endpoint is repaired without sending source evidence again',
    (tester) async {
      var calls = 0;
      await flow.prepare(tester, (request) async {
        calls++;
        final payload = jsonDecode(
          jsonDecode(request.body)['messages'][1]['content'],
        );
        if (payload['task'] == 'translate_ai_findings') {
          expect(payload.containsKey('sourceData'), false);
          expect(request.body, isNot(contains('原始中文 BOM')));
          return flow.reply(
            jsonEncode({
              'translations': [
                {'id': 0, 'category': data.categories, 'reason': data.reasons},
              ],
            }),
            source: false,
          );
        }
        return flow.reply(
          jsonEncode({
            'anomalies': [
              {...data.findingJson(), 'category': '数量不符', 'reason': 'SMT 多 1'},
            ],
          }),
          source: false,
        );
      });
      await flow.startSource(tester);
      await tester.pumpAndSettle();
      for (final language in ['en', 'th', 'zh']) {
        await chooseLanguage(tester, language);
        await tester.pumpAndSettle();
        expect(find.text(data.reasons[language]!), findsOneWidget);
      }
      expect(calls, 2);
    },
  );
  testWidgets(
    'an incomplete translation is not shown as a completed review or in the wrong language',
    (tester) async {
      var calls = 0;
      await flow.prepare(
        tester,
        (_) async => ++calls == 1
            ? flow.reply(
                jsonEncode({
                  'anomalies': [
                    {
                      ...data.findingJson(),
                      'category': '数量不符',
                      'reason': 'SMT 多 1',
                    },
                  ],
                }),
                source: false,
              )
            : flow.reply(
                jsonEncode({
                  'translations': [
                    {
                      'id': 0,
                      'category': data.categories,
                      'reason': {'zh': 'SMT 多 1', 'en': 'SMT has 1 more'},
                    },
                  ],
                }),
                source: false,
              ),
      );
      await flow.startSource(tester);
      await tester.pumpAndSettle();
      await chooseLanguage(tester, 'en');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('incomplete multilingual results'),
        findsOneWidget,
      );
      expect(find.text(translate('已完成 0 / 1 批', 'en')), findsOneWidget);
      expect(find.text('SMT 多 1'), findsNothing);
      expect(find.text(translate('本次 AI 核对未发现异常', 'en')), findsNothing);
      expect(find.text(translate('重试未完成批次', 'en')), findsOneWidget);
      expect(calls, 2);
    },
  );
  testWidgets(
    'cancelling while legacy explanations translate ignores a late response',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      await flow.prepare(tester, (_) async {
        calls++;
        return calls == 1
            ? flow.reply(
                jsonEncode({
                  'anomalies': [
                    {
                      ...data.findingJson(),
                      'category': '数量不符',
                      'reason': 'SMT 多 1',
                    },
                  ],
                }),
                source: false,
              )
            : pending.future;
      });
      await flow.startSource(tester);
      for (var i = 0; i < 8 && calls < 2; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('正在生成三语结果'), findsOneWidget);
      await chooseLanguage(tester, 'en');
      await tester.tap(find.text(translate('取消分析', 'en')));
      await tester.pumpAndSettle();
      pending.complete(
        flow.reply(
          jsonEncode({
            'translations': [
              {'id': 0, 'category': data.categories, 'reason': data.reasons},
            ],
          }),
          source: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(data.reasons['en']!), findsNothing);
      expect(find.textContaining('Results are incomplete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
