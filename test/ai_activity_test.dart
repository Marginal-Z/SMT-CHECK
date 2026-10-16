import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/services/ai_findings.dart';
import 'package:smt_check/ui/ai_activity.dart';
import 'package:smt_check/ui/ai_findings_view.dart';
import 'package:smt_check/ui/design.dart';

void main() {
  testWidgets(
    'reopening the activity restores request elapsed time and disposes its ticker',
    (tester) async {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 2));
      Widget view() => MaterialApp(
        theme: desktopTheme(false),
        home: Scaffold(
          body: AiActivity(
            busy: true,
            stage: AiStage.connecting,
            completed: 0,
            total: 2,
            characters: 0,
            startedAt: startedAt,
          ),
        ),
      );
      await tester.pumpWidget(view());
      expect(
        tester.widget<Text>(find.byKey(const Key('ai-elapsed'))).data,
        startsWith('Elapsed 2:'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(view());
      expect(
        tester.widget<Text>(find.byKey(const Key('ai-elapsed'))).data,
        startsWith('Elapsed 2:'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'waiting visibly animates, tracks elapsed time and stops on cancellation',
    (tester) async {
      Widget view(bool busy, AiStage stage) => MaterialApp(
        theme: desktopTheme(false),
        home: Scaffold(
          body: AiActivity(
            busy: busy,
            stage: stage,
            completed: 0,
            total: 4,
            characters: 0,
          ),
        ),
      );
      await tester.pumpWidget(view(true, AiStage.connecting));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('ai-busy-animation')), findsOneWidget);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(find.text('Elapsed 0:02'), findsOneWidget);
      expect(find.textContaining('0 / 4'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, isNull);
      await tester.pumpWidget(view(false, AiStage.cancelled));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai-busy-animation')), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
  testWidgets('reduced motion shows static progress while receiving', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: desktopTheme(false),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AiActivity(
              busy: true,
              stage: AiStage.receiving,
              completed: 2,
              total: 4,
              characters: 512,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('ai-busy-animation')), findsNothing);
    expect(find.textContaining('512'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .5,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  for (final width in [560.0, 800.0, 1560.0]) {
    testWidgets('anomaly evidence fits desktop width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: desktopTheme(false),
          home: Scaffold(
            body: AiFindingsView(
              findings: const [
                AiFinding(
                  part: 'PART-1',
                  category: '数量差异',
                  reason: 'BOM 1, SMT 2',
                  bom: 'BOM 原始数量1',
                  smt: 'SMT 原始数量2',
                  source: 'a.xlsx Sheet:2',
                ),
              ],
              complete: true,
              busy: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BOM 原始数量1'), findsOneWidget);
      expect(find.text('SMT 原始数量2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
