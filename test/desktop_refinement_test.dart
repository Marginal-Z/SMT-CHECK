import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/ui/results.dart';

import 'checker_test.dart' as f;

void main() {
  testWidgets(
    'filtered selection hides stale evidence and restores it with search',
    (tester) async {
      tester.view.physicalSize = const Size(1560, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SmtFusionApp(
          persist: false,
          initialReport: f.check(
            [f.row('ONE', '1', 'R1'), f.row('TWO', '1', 'R2')],
            [f.row('ONE', '1', 'R1'), f.row('TWO', '1', 'R3')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ONE').first);
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetail), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'TWO');
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetail), findsNothing);
      expect(find.text('ONE'), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetail), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('compact details action opens a dialog; export has one menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SmtFusionApp(
        persist: false,
        initialReport: f.check(
          [f.row('COMPACT', '1', 'R1')],
          [f.row('COMPACT', '1', 'R2')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('COMPACT').first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(ItemDetail))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('展开详情'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(ItemDetail))).pop();
    await tester.pumpAndSettle();
    expect(find.text('导出 CSV'), findsNothing);
    await tester.tap(find.byKey(const Key('export-results-menu')));
    await tester.pumpAndSettle();
    expect(find.text('导出 CSV'), findsOneWidget);
    expect(find.text('导出 JSON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('primary workbench has one merge and AI navigation entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1560, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmtFusionApp(persist: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-merge')), findsOneWidget);
    expect(find.byTooltip('AI 分析核对'), findsOneWidget);
    expect(find.text('原始文件 AI 核对'), findsNothing);
    expect(find.text('查看排除规则'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
