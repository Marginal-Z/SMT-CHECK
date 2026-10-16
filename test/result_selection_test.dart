import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/ui/design.dart';

import 'checker_test.dart' as f;

void main() {
  for (final accent in ThemeAccent.values) {
    for (final dark in [false, true]) {
      testWidgets(
        'selection has a marker, outline and label for $accent dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(1560, 980);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final report = f.check(
            [
              f.row('PASS', '1', 'R1'),
              f.row('ERROR', '1', 'C1'),
              f.row('PASTE', '.2', '', desc: '锡膏'),
            ],
            [f.row('PASS', '1', 'R1'), f.row('ERROR', '1', 'C2')],
          );
          await tester.pumpWidget(
            SmtCheckApp(
              persist: false,
              initialAccent: accent,
              initialReport: report,
            ),
          );
          await tester.pumpAndSettle();
          if (dark) {
            await tester.tap(find.text('深色'));
            await tester.pumpAndSettle();
          }
          for (final item in report.items) {
            await tester.tap(find.byKey(ObjectKey(item)));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('selected-row-marker')),
              findsOneWidget,
            );
            expect(find.text('当前选中料号：${item.part}'), findsOneWidget);
            final decoration =
                tester.widget<Container>(find.byKey(ObjectKey(item))).decoration
                    as BoxDecoration;
            final border = decoration.border as Border;
            expect(border.top.color, Palette(dark, accent).accent);
            expect(border.top.width, 2);
            expect(border.right.color, Palette(dark, accent).accent);
            expect(
              decoration.color,
              Palette(dark, accent).result(item.status, selected: true).fill,
            );
          }
          await tester.tap(find.byTooltip('收起详情'));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('selected-row-marker')), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'NOT PRESENT');
          await tester.pumpAndSettle();
          expect(find.textContaining('已被筛选隐藏'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final width in [560.0, 800.0]) {
    testWidgets(
      'selected record remains visible after closing detail at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 940);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final report = f.check(
          [f.row('PART', '1', 'R1')],
          [f.row('PART', '1', 'R1')],
        );
        await tester.pumpWidget(
          SmtCheckApp(persist: false, initialReport: report),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('PART').first);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('selected-row-marker')), findsOneWidget);
        expect(find.text('当前选中料号：PART'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
