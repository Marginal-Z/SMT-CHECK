import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';

import 'checker_test.dart' as fixture;

void main() {
  for (final size in [
    const Size(560, 900),
    const Size(800, 900),
    const Size(1560, 920),
  ]) {
    testWidgets(
      'desktop workbench adapts to $size and defaults to light without M3',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const SmtCheckApp(persist: false));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.light);
        expect(Theme.of(context).useMaterial3, false);
        await tester.tap(find.text('查看排除规则'));
        await tester.pumpAndSettle();
        expect(find.text('非贴片物料排除规则'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('results and detail fit $size with real row status', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final report = fixture.check(
        [fixture.row('K-123', '1', 'R1')],
        [fixture.row('K-123', '1', 'R2')],
      );
      await tester.pumpWidget(
        SmtCheckApp(persist: false, initialReport: report),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('K-123').first);
      await tester.pumpAndSettle();
      expect(find.text('核对原因'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('theme switch preserves results and search filters records', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1560, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = fixture.check(
      [fixture.row('ONE', '1', 'R1'), fixture.row('TWO', '1', 'R2')],
      [fixture.row('ONE', '1', 'R1'), fixture.row('TWO', '1', 'R2')],
    );
    await tester.pumpWidget(SmtCheckApp(persist: false, initialReport: report));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.enterText(find.byType(TextField), 'ONE');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'ONE'),
      findsOneWidget,
    );
    expect(find.text('TWO'), findsNothing);
    expect(report.count(CheckStatus.pass), 2);
    expect(tester.takeException(), isNull);
  });
}
