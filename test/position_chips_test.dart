import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/services/report_export.dart';
import 'package:smt_check/ui/design.dart';
import 'package:smt_check/ui/desktop_shell.dart';
import 'package:smt_check/ui/position_chips.dart';

import 'checker_test.dart' as f;

void main() {
  testWidgets('PASS precedes NG in filters, default rows and exports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1560, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = f.check(
      [
        f.row('A-NG', '1', 'C1'),
        f.row('Z-PASS', '1', 'R1'),
        f.row('PASTE', '.2', '', desc: '锡膏'),
      ],
      [
        f.row('A-NG', '1', 'C2'),
        f.row('Z-PASS', '1', 'R1'),
        f.row('ALT', '', '', candidate: true),
      ],
    );
    expect(report.items.map((i) => i.status), [
      CheckStatus.pass,
      CheckStatus.error,
      CheckStatus.excluded,
      CheckStatus.candidate,
    ]);
    final csv = ReportExport.csv(report);
    expect(
      csv.indexOf('"PASS","Z-PASS"'),
      lessThan(csv.indexOf('"NG","A-NG"')),
    );
    await tester.pumpWidget(SmtFusionApp(persist: false, initialReport: report));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('PASS (1)')).dx,
      lessThan(tester.getTopLeft(find.text('NG (1)')).dx),
    );
    expect(
      tester.getTopLeft(find.byKey(ObjectKey(report.items[0]))).dy,
      lessThan(tester.getTopLeft(find.byKey(ObjectKey(report.items[1]))).dy),
    );
    await tester.tap(find.text('NG (1)'));
    await tester.pumpAndSettle();
    expect(find.text('A-NG'), findsOneWidget);
    expect(find.text('Z-PASS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final status in CheckStatus.values) {
      testWidgets('position boxes follow $status dark=$dark', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: desktopTheme(dark),
            home: Scaffold(
              body: SizedBox(
                width: 186,
                child: PositionChips(
                  rows: [f.row('P', '2', '4U1,3U2')],
                  bom: true,
                  status: status,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('4U1'), findsOneWidget);
        expect(find.text('3U2'), findsOneWidget);
        final tag = find.byType(PositionTag).first;
        final box =
            tester
                    .widget<Container>(
                      find
                          .descendant(of: tag, matching: find.byType(Container))
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(
          (box.border! as Border).top.color,
          Palette(dark).result(status).edge,
        );
        final text = tester.widget<Text>(
          find.descendant(of: tag, matching: find.byType(Text)).first,
        );
        expect(
          text.style!.color,
          status == CheckStatus.pass
              ? Palette(dark).result(status).ink
              : Palette(dark).alertText,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'overflow expands every reference with raw, duplicate and invalid evidence',
    (tester) async {
      const raw = '8R\n23,4U1,R1-R30,R1,??';
      await tester.pumpWidget(
        MaterialApp(
          theme: desktopTheme(false),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 186,
                height: 57,
                child: PositionChips(
                  rows: [f.row('P', '34', raw)],
                  bom: true,
                  status: CheckStatus.error,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip(raw), findsOneWidget);
      expect(
        tester.getBottomRight(find.byType(PositionTag).last).dy -
            tester.getTopLeft(find.byType(Wrap)).dy,
        lessThanOrEqualTo(49),
      );
      await tester.tap(find.byTooltip('Show all positions'));
      await tester.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expect(
        find.descendant(of: dialog, matching: find.text('8R23')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('4U1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('R1')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: dialog, matching: find.text('R30')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (w) => w is PositionTag && w.label == '??' && w.invalid,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (w) => w is SelectableText && w.data == raw,
          ),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty refs and invalid-only refs remain distinct; rows never join',
    (tester) async {
      Future<void> show(List<MaterialRow> rows) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 186,
              child: PositionChips(
                rows: rows,
                bom: true,
                status: CheckStatus.error,
              ),
            ),
          ),
        ),
      );
      await show([f.row('P', '1', '')]);
      expect(find.text('—'), findsOneWidget);
      await show([f.row('P', '1', '??')]);
      expect(find.text('??'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      await show([f.row('P', '1', '8R'), f.row('P', '1', '23')]);
      expect(find.text('8R23'), findsNothing);
      expect(find.text('8R'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'larger system text keeps references inside the fixed table row',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: desktopTheme(false),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 186,
                  height: 57,
                  child: PositionChips(
                    rows: [f.row('P', '30', 'R1-R30')],
                    bom: true,
                    status: CheckStatus.pass,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(find.byType(PositionChips)).dy;
      for (final element in find.byType(PositionTag).evaluate()) {
        expect(
          tester.getBottomRight(find.byWidget(element.widget)).dy - top,
          lessThanOrEqualTo(57),
        );
      }
      expect(find.byTooltip('Show all positions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grouped station modes retain keyboard activation and disabled behavior',
    (tester) async {
      var merged = true, enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return StationModeSwitch(
                  merged: merged,
                  enabled: enabled,
                  onChanged: (value) => setState(() => merged = value),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(merged, false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(merged, true);
      update(() => enabled = false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is DeskButton && w.label == '单站位表'),
      );
      expect(merged, true);
      expect(tester.takeException(), isNull);
    },
  );
}
