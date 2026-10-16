import 'dart:async';
import 'dart:convert';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/services/ai_service.dart';
import 'package:smt_check/services/source_analysis.dart';

import 'checker_test.dart' as f;

class _Files extends FileSelectorPlatform {
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile('source.xlsx');
}

http.Response reply(String text, {bool source = true}) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'choices': [
        {
          'message': {
            'content': source
                ? jsonEncode({
                    'anomalies': [
                      {
                        'part': 'K1',
                        'category': '位号差异',
                        'reason': text,
                        'bom': 'R1',
                        'smt': 'R2',
                        'source': 'bom.xlsx Sheet:2; station.xlsx Sheet:2',
                      },
                    ],
                  })
                : text,
          },
        },
      ],
    }),
  ),
  200,
);

Future<void> prepare(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler, {
  SourceAnalysisPlan? plan,
}) async {
  tester.view.physicalSize = const Size(1560, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final original = FileSelectorPlatform.instance;
  FileSelectorPlatform.instance = _Files();
  addTearDown(() => FileSelectorPlatform.instance = original);
  SharedPreferences.setMockInitialValues({
    'aiUrl': 'http://localhost/v1',
    'aiModel': 'demo',
  });
  await tester.pumpWidget(
    SmtCheckApp(
      workbookLoader: (_, kind, side) async => f.input(
        [f.row('K1', '1', kind == InputKind.bom ? 'R1' : 'R2')],
        bom: kind == InputKind.bom,
        path: kind == InputKind.bom ? 'bom.xlsx' : 'station.xlsx',
      ),
      aiServiceFactory: () => AiService(client: MockClient(handler)),
      sourcePlanner: (bom, stations, rules, limit) async =>
          plan ?? prepareSourceAnalysis(bom, stations, rules, limit),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('单站位表'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('导入 BOM'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('导入站位表'));
  await tester.pumpAndSettle();
  expect(find.text('导出 CSV'), findsNothing);
  await tester.tap(find.byTooltip('AI 分析核对'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('ai-url')), findsNothing);
}

Future<void> startSource(WidgetTester tester) async {
  await tester.tap(find.text('分析原始文件'));
  await tester.pumpAndSettle();
  expect(find.text('发送原始文件内容至 AI'), findsOneWidget);
  await tester.tap(find.text('发送并分析'));
  await tester.pump();
}

const twoBatches = SourceAnalysisPlan(
  [
    SourceAnalysisBatch('parts', '{"parts":[{"part":"A","records":[]}]}', 1),
    SourceAnalysisBatch('worksheet_context', '{"rows":[]}', 0),
  ],
  2,
  2,
  2,
);

void main() {
  testWidgets(
    'original AI runs without a local report and connection settings remain separate',
    (tester) async {
      var sourceRequests = 0;
      await prepare(tester, (request) async {
        final data = jsonDecode(request.body);
        if (data['messages'][1]['content'].contains('sourceData')) {
          sourceRequests++;
          expect(
            jsonDecode(
              data['messages'][1]['content'],
            )['sourceData']['parts'][0]['records'],
            hasLength(2),
          );
          return reply('SOURCE REVIEW');
        }
        return reply('CONNECTED', source: false);
      });
      await startSource(tester);
      await tester.pumpAndSettle();
      expect(sourceRequests, 1);
      expect(find.textContaining('SOURCE REVIEW'), findsOneWidget);
      expect(find.textContaining('全部 1 批分析完成'), findsOneWidget);
      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai-url')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('ai-key')), 'session-secret');
      await tester.ensureVisible(find.text('保存设置'));
      await tester.tap(find.text('保存设置'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aiModel'), 'demo');
      expect(prefs.getInt('aiBatchLimit'), 24000);
      expect(
        prefs.getKeys().any((k) => k.toLowerCase().contains('key')),
        isFalse,
      );
      await tester.ensureVisible(find.text('测试连接'));
      await tester.tap(find.text('测试连接'));
      await tester.pumpAndSettle();
      expect(find.text('CONNECTED'), findsOneWidget);
      await tester.tap(find.byTooltip('AI 分析核对'));
      await tester.pumpAndSettle();
      expect(find.textContaining('SOURCE REVIEW'), findsOneWidget);
      expect(find.text('CONNECTED'), findsNothing);
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      expect(find.text('导出 CSV'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cancel retains completed batches and ignores a late response', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    await prepare(
      tester,
      (_) async => ++calls == 1 ? reply('COMPLETED FIRST') : pending.future,
      plan: twoBatches,
    );
    await startSource(tester);
    for (var i = 0; i < 8 && calls < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(calls, 2);
    await tester.tap(find.text('取消分析'));
    await tester.pumpAndSettle();
    expect(find.textContaining('COMPLETED FIRST'), findsOneWidget);
    expect(find.textContaining('已完成 1 / 2 批，结果不完整'), findsOneWidget);
    pending.complete(reply('LATE RESPONSE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('LATE RESPONSE'), findsNothing);
    expect(find.textContaining('全部 2 批分析完成'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'batch failure preserves prior evidence and never claims complete coverage',
    (tester) async {
      var calls = 0;
      await prepare(
        tester,
        (_) async => ++calls == 1
            ? reply('FIRST EVIDENCE')
            : http.Response('overloaded', 503),
        plan: twoBatches,
      );
      await startSource(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('FIRST EVIDENCE'), findsOneWidget);
      expect(find.textContaining('原始文件分析中断，已完成 1 / 2 批'), findsOneWidget);
      expect(find.textContaining('全部 2 批分析完成'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a DeepSeek-style response after 90 seconds is still accepted', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await prepare(tester, (_) => pending.future);
    await startSource(tester);
    await tester.pump(const Duration(seconds: 95));
    expect(find.textContaining('原始文件分析中断'), findsNothing);
    expect(find.text('取消分析'), findsOneWidget);
    pending.complete(reply('SLOW FINAL ANSWER'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SLOW FINAL ANSWER'), findsOneWidget);
    expect(find.textContaining('全部 1 批分析完成'), findsOneWidget);
  });
  testWidgets(
    'retry sends only unfinished batches and retains completed evidence',
    (tester) async {
      var calls = 0;
      await prepare(tester, (request) async {
        calls++;
        if (calls == 1) return reply('KEPT EVIDENCE');
        if (calls == 2) return http.Response('unavailable', 503);
        expect(
          jsonDecode(
            jsonDecode(request.body)['messages'][1]['content'],
          )['sourceData'].containsKey('rows'),
          true,
        );
        return reply('RECOVERED BATCH');
      }, plan: twoBatches);
      await startSource(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重试未完成批次'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('发送并分析'));
      await tester.pumpAndSettle();
      expect(calls, 3);
      expect(find.textContaining('KEPT EVIDENCE'), findsOneWidget);
      expect(find.textContaining('RECOVERED BATCH'), findsOneWidget);
      expect(find.textContaining('全部 2 批分析完成'), findsOneWidget);
      expect(find.text('重试未完成批次'), findsNothing);
    },
  );
  testWidgets('context rejection automatically splits whole part groups', (
    tester,
  ) async {
    final sent = <List>[];
    await prepare(
      tester,
      (request) async {
        final parts =
            jsonDecode(
                  jsonDecode(request.body)['messages'][1]['content'],
                )['sourceData']['parts']
                as List;
        sent.add(parts);
        if (parts.length > 1) {
          return http.Response(
            jsonEncode({
              'error': {'code': 'context_length_exceeded'},
            }),
            400,
          );
        }
        return reply('CHECKED ${parts.single['part']}');
      },
      plan: const SourceAnalysisPlan(
        [
          SourceAnalysisBatch(
            'parts',
            '{"parts":[{"part":"A","records":[1,2,3]},{"part":"B","records":[4,5]}]}',
            2,
          ),
        ],
        2,
        5,
        5,
      ),
    );
    await startSource(tester);
    await tester.pumpAndSettle();
    expect(sent.map((parts) => parts.length), [2, 1, 1]);
    expect(sent[1].single['records'], [1, 2, 3]);
    expect(sent[2].single['records'], [4, 5]);
    expect(find.textContaining('CHECKED A'), findsOneWidget);
    expect(find.textContaining('CHECKED B'), findsOneWidget);
    expect(find.textContaining('全部 2 批分析完成'), findsOneWidget);
  });
  testWidgets(
    'an empty completed review shows no anomaly cards or passing rows',
    (tester) async {
      await prepare(
        tester,
        (_) async => reply('{"anomalies":[]}', source: false),
      );
      await startSource(tester);
      await tester.pumpAndSettle();
      expect(find.text('本次 AI 核对未发现异常'), findsOneWidget);
      expect(find.text('异常结果 (0)'), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-finding-0')), findsNothing);
      expect(find.textContaining('全部 1 批分析完成'), findsOneWidget);
    },
  );
  testWidgets(
    'an empty first batch followed by failure never claims no anomalies',
    (tester) async {
      var calls = 0;
      await prepare(
        tester,
        (_) async => ++calls == 1
            ? reply('{"anomalies":[]}', source: false)
            : http.Response('overloaded', 503),
        plan: twoBatches,
      );
      await startSource(tester);
      await tester.pumpAndSettle();
      expect(find.text('本次 AI 核对未发现异常'), findsNothing);
      expect(find.textContaining('结果不完整'), findsOneWidget);
      expect(find.text('重试未完成批次'), findsOneWidget);
    },
  );
  testWidgets(
    'unstructured model text is not displayed or counted as a completed review',
    (tester) async {
      await prepare(
        tester,
        (_) async => reply('REASONING AND MATCHING ROWS', source: false),
      );
      await startSource(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('REASONING AND MATCHING ROWS'), findsNothing);
      expect(find.textContaining('AI 未返回有效的异常清单'), findsOneWidget);
      expect(find.textContaining('全部 1 批分析完成'), findsNothing);
      expect(find.text('重试未完成批次'), findsOneWidget);
    },
  );
}
