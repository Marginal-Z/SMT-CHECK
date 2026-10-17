import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/l10n/localization.dart';

import 'merge_workflow_test.dart' as flow;

void main() {
  for (final language in ['zh', 'en', 'th']) {
    for (final width in [560.0, 800.0, 1280.0, 1560.0]) {
      testWidgets(
        '$language merge header stays aligned at $width with high DPI',
        (tester) async {
          await flow.prepareMerge(tester, width: width, language: language);
          tester.view.devicePixelRatio = 1.5;
          tester.view.physicalSize = Size(width * 1.5, 980 * 1.5);
          await tester.pumpAndSettle();
          final source = tester.getRect(
            find.byKey(const Key('merge-source-tools')),
          );
          final export = tester.getRect(
            find.byKey(const Key('merge-export-tools')),
          );
          final mode = tester.getRect(
            find.byKey(const Key('merge-mode-control')),
          );
          final label = tester.getRect(find.text(translate('合并方式', language)));
          final description = tester.getRect(
            find.byKey(const Key('merge-source-description')),
          );
          expect(mode.contains(label.topLeft), isTrue);
          expect(mode.contains(label.bottomRight), isTrue);
          expect(label.top, greaterThan(description.bottom));
          if (width >= 1200) {
            expect(export.left, greaterThan(source.right));
            expect(export.top, closeTo(source.top, .1));
          } else {
            expect(export.top, greaterThan(source.bottom));
          }
          final name = tester.getRect(find.byKey(const Key('merge-file-name')));
          final button = tester.getRect(find.byKey(const Key('export-merge')));
          expect(export.contains(name.center), isTrue);
          expect(export.contains(button.center), isTrue);
          expect(name.overlaps(button), isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      '$language enlarged text preserves the export draft and review state on resize',
      (tester) async {
        await flow.prepareMerge(tester, language: language);
        await tester.enterText(
          find.byKey(const Key('merge-file-name')),
          'CY028',
        );
        await tester.tap(find.byKey(const Key('confirm-include')));
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = const Size(800, 980);
        await tester.pumpAndSettle();
        expect(find.text('CY028'), findsOneWidget);
        expect(find.text(translate('已确认 1 / 3 项', language)), findsOneWidget);
        expect(flow.enabled(tester, 'generate-merge'), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
