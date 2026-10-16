import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/report_export.dart';
import 'package:smt_check/ui/design.dart';
import 'package:smt_check/ui/desktop_shell.dart';
import 'package:smt_check/ui/results.dart';

import 'checker_test.dart' as f;

CheckReport sample() => f.check(
  [
    f.row('R-PART', '1', 'R1'),
    f.row('C-PART', '1', 'C1'),
    f.row('PASTE', '.2', '', desc: '锡膏'),
  ],
  [
    f.row('R-PART', '1', 'R1'),
    f.row('C-PART', '1', 'C2'),
    f.row('ALT', '', '', candidate: true),
  ],
);

void main() {
  test(
    'PASS/NG export labels preserve excluded and candidate classifications',
    () {
      final report = sample();
      expect(report.count(CheckStatus.pass), 1);
      expect(report.count(CheckStatus.error), 1);
      expect(report.count(CheckStatus.excluded), 1);
      expect(report.count(CheckStatus.candidate), 1);
      for (final language in ['zh', 'en', 'th']) {
        final csv = ReportExport.csv(report, language: language);
        expect(csv, contains('"PASS","R-PART"'));
        expect(csv, contains('"NG","C-PART"'));
        expect(csv, contains(translate('已排除', language)));
        expect(csv, contains(translate('候选替代料', language)));
      }
      expect(desktopPages, isNot(contains('导入与规则')));
    },
  );
  for (final language in ['zh', 'en', 'th']) {
    testWidgets(
      'red audit statuses, vivid reasons and settings navigation work in $language',
      (tester) async {
        tester.view.physicalSize = const Size(1560, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final report = sample();
        await tester.pumpWidget(
          SmtCheckApp(
            persist: false,
            initialLanguage: language,
            initialReport: report,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PASS'), findsOneWidget);
        expect(find.text('NG'), findsOneWidget);
        expect(find.text('PASS (1)'), findsOneWidget);
        expect(find.text('NG (1)'), findsOneWidget);
        for (final item in report.items.where(
          (i) => i.status != CheckStatus.pass,
        )) {
          final row = find.byKey(ObjectKey(item));
          final decoration =
              tester.widget<Container>(row).decoration as BoxDecoration;
          expect(
            decoration.color,
            Palette(false).result(CheckStatus.error).fill,
          );
          expect(
            find.descendant(of: row, matching: find.byType(ResultBadge)),
            findsOneWidget,
          );
        }
        final ng = report.errors.single;
        await tester.tap(find.byKey(ObjectKey(ng)));
        await tester.pumpAndSettle();
        final reasonWidgets = tester.widgetList<SelectableText>(
          find.descendant(
            of: find.byType(ItemDetail),
            matching: find.byType(SelectableText),
          ),
        );
        for (final reason in ng.reasons) {
          final text = reasonWidgets.singleWhere(
            (w) => w.data == translate(reason, language),
          );
          expect(text.style!.color, const Color(0xFFE00012));
          expect(text.style!.fontWeight, FontWeight.w600);
        }
        await tester.tap(find.byTooltip(translate('设置', language)));
        await tester.pumpAndSettle();
        await tester.tap(find.text(translate('导入与规则', language)));
        await tester.pumpAndSettle();
        expect(find.text(translate('非贴片物料排除规则', language)), findsOneWidget);
        expect(find.text(translate('导入审计', language)), findsOneWidget);
        await tester.tap(find.text(translate('外观与 AI 接口', language)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('ai-url')), findsOneWidget);
        await tester.tap(find.byTooltip(translate('核对工作台', language)));
        await tester.pumpAndSettle();
        expect(find.text('NG (1)'), findsOneWidget);
        expect(find.byKey(const Key('selected-row-marker')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
