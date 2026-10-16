import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/l10n/localization.dart';

import 'checker_test.dart' as fixture;

class _Selector extends FileSelectorPlatform {
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile('new.xlsx');
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final language in ['en', 'th']) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets('$language fits all screens at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final report = fixture.check(
          [fixture.row('K-123', '1', 'R1')],
          [fixture.row('K-123', '1', 'R2')],
        );
        await tester.pumpWidget(
          SmtCheckApp(
            persist: false,
            initialLanguage: language,
            initialReport: report,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(translate('开始核对', language)), findsOneWidget);
        await tester.tap(find.text('K-123').first);
        await tester.pumpAndSettle();
        expect(find.text(translate('核对原因', language)), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (width < 1400) {
          Navigator.of(tester.element(find.text(translate('核对原因', language))))
              .pop();
          await tester.pumpAndSettle();
        }
        for (final title in ['AI 分析核对', '设置', '使用说明']) {
          await tester.tap(find.byTooltip(translate(title, language)));
          await tester.pumpAndSettle();
          final expected = {
            'AI 分析核对': '原始文件核对',
            '设置': 'API 基础地址',
            '使用说明': '核对规则与操作',
          }[title]!;
          expect(find.text(translate(expected, language)), findsOneWidget);
          if (title == '设置') {
            await tester.tap(find.text(translate('导入与规则', language)));
            await tester.pumpAndSettle();
            expect(find.text(translate('非贴片物料排除规则', language)), findsOneWidget);
            expect(find.text(translate('导入审计', language)), findsOneWidget);
            await tester.tap(find.text(translate('关于与更新', language)));
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('check-updates')), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(translate('外观与 AI 接口', language)));
            await tester.pumpAndSettle();
            expect(find.text(translate('API 基础地址', language)), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets(
    'clear removes results and imported files, then permits reimport',
    (tester) async {
      final original = FileSelectorPlatform.instance;
      FileSelectorPlatform.instance = _Selector();
      addTearDown(() => FileSelectorPlatform.instance = original);
      final report = fixture.check(
        [fixture.row('OLD', '1', 'R1')],
        [fixture.row('OLD', '1', 'R1')],
      );
      final loaded = fixture.input(
        [fixture.row('NEW', '1', 'R5')],
        bom: true,
        path: 'new.xlsx',
      );
      await tester.pumpWidget(
        SmtCheckApp(
          persist: false,
          initialReport: report,
          workbookLoader: (_, _, _) async => loaded,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-session')));
      await tester.pumpAndSettle();
      expect(find.text('OLD'), findsNothing);
      expect(find.text('导出 CSV'), findsNothing);
      expect(find.textContaining('已清空'), findsOneWidget);
      await tester.tap(find.text('导入 BOM'));
      await tester.pumpAndSettle();
      expect(find.textContaining('new.xlsx'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('clearing cancels stale asynchronous import completion', (
    tester,
  ) async {
    final original = FileSelectorPlatform.instance;
    FileSelectorPlatform.instance = _Selector();
    addTearDown(() => FileSelectorPlatform.instance = original);
    final pending = Completer<ImportedFile>();
    await tester.pumpWidget(
      SmtCheckApp(persist: false, workbookLoader: (_, _, _) => pending.future),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入 BOM'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('clear-session')));
    await tester.pumpAndSettle();
    pending.complete(
      fixture.input(
        [fixture.row('STALE', '1', 'R1')],
        bom: true,
        path: 'stale.xlsx',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('stale.xlsx'), findsNothing);
    expect(find.textContaining('已清空'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'language switch preserves the loaded report and persists the choice',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final report = fixture.check(
        [fixture.row('KEPT', '1', 'R1')],
        [fixture.row('KEPT', '1', 'R1')],
      );
      await tester.pumpWidget(SmtCheckApp(initialReport: report));
      await tester.pumpAndSettle();
      for (final language in ['en', 'th', 'zh']) {
        await tester.tap(find.byKey(const Key('language-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(languageNames[language]!).last);
        await tester.pumpAndSettle();
        expect(find.text(translate('开始核对', language)), findsOneWidget);
        expect(find.text('KEPT'), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getString('language'),
          language,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
