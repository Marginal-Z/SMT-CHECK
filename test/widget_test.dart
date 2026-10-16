import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/ui/results.dart';

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
  testWidgets(
    'desktop evidence pane collapses without losing selection or search',
    (tester) async {
      tester.view.physicalSize = const Size(1560, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        SmtCheckApp(
          persist: false,
          initialReport: fixture.check(
            [fixture.row('KEEP', '1', 'R1')],
            [fixture.row('KEEP', '1', 'R2')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'KEEP');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is Text && w.data == 'KEEP'),
      );
      await tester.pumpAndSettle();
      expect(find.text('来源与差异详情'), findsOneWidget);
      await tester.tap(find.byTooltip('收起详情'));
      await tester.pumpAndSettle();
      expect(find.text('来源与差异详情'), findsNothing);
      expect(find.text('KEEP'), findsWidgets);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'KEEP',
      );
      await tester.tap(find.text('展开详情'));
      await tester.pumpAndSettle();
      expect(find.text('核对原因'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final language in ['zh', 'en', 'th']) {
    testWidgets(
      'counts, source positions and excluded materials are visible in $language',
      (tester) async {
        tester.view.physicalSize = const Size(1560, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final report = fixture.check(
          [
            fixture.row('MATCH', '2', 'R1,R2'),
            fixture.row(
              'PASTE',
              '.2',
              '原始位置',
              desc: '锡膏 原始描述',
              importIssues: ['数量 含 Excel 错误值 #VALUE!'],
            ),
          ],
          [fixture.row('MATCH', '2', 'R2 R1'), fixture.row('EXTRA', '1', 'C5')],
        );
        await tester.pumpWidget(
          SmtCheckApp(
            persist: false,
            initialLanguage: language,
            initialReport: report,
          ),
        );
        await tester.pumpAndSettle();
        for (final (label, count) in [
          ('料号总数量', '3'),
          ('BOM料号数量', '2'),
          ('SMT站位表料号数量', '2'),
        ]) {
          final stat = find.byKey(ValueKey('stat-$label'));
          expect(
            find.descendant(
              of: stat,
              matching: find.text(translate(label, language)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: stat, matching: find.text(count)),
            findsOneWidget,
          );
        }
        expect(find.text(translate('BOM插件位置', language)), findsOneWidget);
        expect(find.text(translate('SMT站位表位号', language)), findsOneWidget);
        expect(find.text('R1,R2'), findsOneWidget);
        expect(find.text('R2 R1'), findsOneWidget);
        await tester.tap(find.text('${translate('已排除物料', language)} (1)'));
        await tester.pumpAndSettle();
        expect(find.text('PASTE'), findsOneWidget);
        expect(find.text('MATCH'), findsNothing);
        expect(find.text('EXTRA'), findsNothing);
        expect(find.text('锡膏 原始描述'), findsOneWidget);
        expect(find.text('原始位置'), findsOneWidget);
        final horizontal = find.descendant(
          of: find.byType(ResultsView),
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        );
        await tester.drag(horizontal, const Offset(-900, 0));
        await tester.pumpAndSettle();
        expect(find.textContaining('#VALUE!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
