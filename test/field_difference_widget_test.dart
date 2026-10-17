import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/text_difference.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/ui/design.dart';
import 'package:smt_check/ui/field_difference.dart';
import 'package:smt_check/ui/results.dart';

import 'checker_test.dart' as f;

CheckReport differenceReport() => f.check(
  [
    f.row(
      'PART-DETAIL',
      '3',
      'R1,R2,R3',
      desc: '贴片电阻 10K ±5% 0402',
      file: 'bom-input.xlsx',
      line: 8,
    ),
  ],
  [
    f.row(
      'PART-DETAIL',
      '2',
      'R1,R4',
      desc: '贴片电阻 20K ±1% 0603',
      file: 'smt-input.xlsx',
      line: 12,
    ),
  ],
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final language in ['zh', 'en', 'th']) {
    for (final width in [560.0, 1560.0]) {
      testWidgets(
        'exact field differences, originals and sources fit $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 950);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final report = differenceReport();
          await tester.pumpWidget(
            SmtFusionApp(
              persist: false,
              initialLanguage: language,
              initialReport: report,
            ),
          );
          await tester.pumpAndSettle();
          if (width < 1508) {
            await tester.drag(
              find.descendant(
                of: find.byType(ResultsView),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is SingleChildScrollView &&
                      w.scrollDirection == Axis.horizontal,
                ),
              ),
              const Offset(-2200, 0),
            );
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byTooltip(translate('查看具体差异', language)));
          await tester.pumpAndSettle();
          expect(find.byType(ItemDetail), findsOneWidget);
          expect(
            find.byType(Dialog),
            width < 1160 ? findsOneWidget : findsNothing,
          );
          expect(find.text(translate('字段差异对照', language)), findsOneWidget);
          expect(find.byType(FieldDifferenceCard), findsNWidgets(3));
          final description = find.byKey(
            const ValueKey('field-difference-description-品名 / 物料描述'),
          );
          final values = tester
              .widgetList<DifferenceValue>(
                find.descendant(
                  of: description,
                  matching: find.byType(DifferenceValue),
                ),
              )
              .toList();
          expect(values.map((w) => w.value), [
            '贴片电阻 10K ±5% 0402',
            '贴片电阻 20K ±1% 0603',
          ]);
          expect(values.every((w) => w.highlights.isNotEmpty), true);
          final rich = tester
              .widgetList<SelectableText>(
                find.descendant(
                  of: description,
                  matching: find.byType(SelectableText),
                ),
              )
              .where((w) => w.textSpan != null)
              .toList();
          expect(
            rich.map((w) => w.textSpan!.toPlainText()),
            values.map((w) => w.value),
          );
          expect(find.textContaining('bom-input.xlsx / Sheet:8'), findsWidgets);
          expect(
            find.textContaining('smt-input.xlsx / Sheet:12'),
            findsWidgets,
          );
          expect(
            find.text(translate('SMT 比 BOM 少 1', language)),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(FieldDifferenceCard),
              matching: find.text(translate('SMT 缺少位号：R2、R3', language)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(FieldDifferenceCard),
              matching: find.text(translate('SMT 多出位号：R4', language)),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final dark in [false, true]) {
    testWidgets('highlighted fragments are vivid and readable dark=$dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: desktopTheme(dark),
          home: Scaffold(
            body: DifferenceValue(
              value: '10K',
              highlights: const [TextChangeRange(0, 3)],
              highlightText: true,
            ),
          ),
        ),
      );
      final span =
          tester
                  .widget<SelectableText>(find.byType(SelectableText))
                  .textSpan!
                  .children!
                  .single
              as TextSpan;
      expect(span.style!.color, Palette(dark).alertText);
      final background = Color.alphaBlend(
        span.style!.backgroundColor!,
        Palette(dark).panel,
      );
      final a = span.style!.color!.computeLuminance(),
          b = background.computeLuminance();
      expect(
        ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05),
        greaterThanOrEqualTo(4.5),
      );
    });
  }
  testWidgets(
    'choosing another record resets the long comparison pane to its first difference',
    (tester) async {
      tester.view.physicalSize = const Size(1560, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = differenceReport();
      final report = f.check(
        [...base.items.single.bom, f.row('SECOND', '1', 'C1', desc: '电容 10NF')],
        [...base.items.single.smt, f.row('SECOND', '1', 'C2', desc: '电容 20NF')],
      );
      await tester.pumpWidget(
        SmtFusionApp(persist: false, initialReport: report),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ObjectKey(report.errors.first)));
      await tester.pumpAndSettle();
      final scroll = find.descendant(
        of: find.byType(ItemDetail),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scroll, const Offset(0, -600));
      await tester.pumpAndSettle();
      ScrollableState position() => tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ItemDetail),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(position().position.pixels, greaterThan(0));
      await tester.tap(find.byKey(ObjectKey(report.errors.last)));
      await tester.pumpAndSettle();
      expect(position().position.pixels, 0);
      expect(find.text('字段差异对照').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
