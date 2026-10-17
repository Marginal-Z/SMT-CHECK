import 'dart:async';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/xlsx_reader.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/ui/design.dart';

import 'support/merge_fixture.dart';

class MergeSelector extends FileSelectorPlatform {
  String? suggestedName;
  final Future<FileSaveLocation?> Function(SaveDialogOptions) save;
  MergeSelector(this.save);
  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) {
    suggestedName = options.suggestedName;
    return save(options);
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile('new.xlsx');
}

bool enabled(WidgetTester tester, String key) =>
    tester.widget<DeskButton>(find.byKey(Key(key))).onPressed != null;

Future<void> openMerge(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-merge')));
  await tester.pumpAndSettle();
}

Future<void> confirmAll(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('confirm-include')));
  await tester.pumpAndSettle();
  for (var i = 0; i < 2; i++) {
    await tester.tap(find.byKey(const Key('confirm-omit')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('generate-merge')));
  await tester.pumpAndSettle();
}

Future<void> prepareMerge(
  WidgetTester tester, {
  double width = 1560,
  String language = 'zh',
  CheckReport? report,
  Future<ImportedFile> Function(String, InputKind, String)? loader,
}) async {
  tester.view.physicalSize = Size(width, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SmtCheckApp(
      persist: false,
      initialLanguage: language,
      initialReport: report ?? mergeReport(),
      workbookLoader: loader,
    ),
  );
  await tester.pumpAndSettle();
  await openMerge(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final change in ['mode', 'rules', 'import']) {
    testWidgets('$change invalidates existing review and preview', (
      tester,
    ) async {
      final previous = FileSelectorPlatform.instance;
      FileSelectorPlatform.instance = MergeSelector((_) async => null);
      addTearDown(() => FileSelectorPlatform.instance = previous);
      await prepareMerge(
        tester,
        loader: (_, _, _) async => mergeReport().files[1],
      );
      await confirmAll(tester);
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      if (change == 'mode') {
        await tester.tap(find.text('单站位表'));
      } else if (change == 'import') {
        await tester.tap(find.text('导入站位 A'));
      } else {
        await tester.tap(find.byTooltip('设置'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('导入与规则'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('关键词排除：开启'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('合并与导出'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export-merge')), findsNothing);
      expect(find.text('请先导入 BOM、站位表 A 和 B，并以 A+B 合并模式完成核对。'), findsOneWidget);
    });
  }

  testWidgets('export cannot overwrite any original workbook', (tester) async {
    final previous = FileSelectorPlatform.instance;
    final temp = Directory.systemTemp.createTempSync('merge-original-');
    final original = File('${temp.path}/original-BOM.xlsx')
      ..writeAsStringSync('original bytes');
    final report = mergeReport();
    report.files[1] = ImportedFile(
      original.path,
      InputKind.station,
      report.files[1].rows,
      [],
      [],
    );
    FileSelectorPlatform.instance = MergeSelector(
      (_) async => FileSaveLocation(original.path),
    );
    addTearDown(() {
      FileSelectorPlatform.instance = previous;
      temp.deleteSync(recursive: true);
    });
    await prepareMerge(tester, report: report);
    await confirmAll(tester);
    await tester.tap(find.byKey(const Key('export-merge')));
    await tester.pumpAndSettle();
    expect(find.text('不能覆盖原始文件，请选择其他文件名或目录'), findsOneWidget);
    expect(original.readAsStringSync(), 'original bytes');
  });

  for (final language in ['zh', 'en', 'th']) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets('$language review, gated preview and revoke fit $width', (
        tester,
      ) async {
        await prepareMerge(tester, width: width, language: language);
        expect(enabled(tester, 'generate-merge'), isFalse);
        expect(enabled(tester, 'export-merge'), isFalse);
        await tester.tap(find.byKey(const Key('merge-preview-tab')));
        await tester.pumpAndSettle();
        expect(
          find.text(translate('还有 3 项待人工确认，确认后才能合并和导出。', language)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('merged-preview-table')), findsNothing);
        await tester.tap(find.byKey(const Key('merge-review-tab')));
        await tester.pumpAndSettle();
        await confirmAll(tester);
        expect(enabled(tester, 'export-merge'), isTrue);
        expect(
          find.text('料号'),
          findsOneWidget,
        ); // Raw/export schema remains Chinese.
        expect(find.text('物料描述'), findsOneWidget);
        expect(find.text('R1\nR2'), findsOneWidget);
        expect(find.text('PASTE'), findsNothing);
        expect(find.text('ALT'), findsNothing);
        await tester.tap(find.byKey(const Key('merge-review-tab')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('revoke-review')));
        await tester.pumpAndSettle();
        expect(enabled(tester, 'generate-merge'), isFalse);
        expect(enabled(tester, 'export-merge'), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'name and confirmation survive page/language changes, then clearing removes both preview and review',
    (tester) async {
      await prepareMerge(tester);
      await tester.enterText(find.byKey(const Key('merge-file-name')), '订单 #1');
      await confirmAll(tester);
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      expect(find.text('NG (1)'), findsOneWidget);
      await openMerge(tester);
      expect(enabled(tester, 'export-merge'), isTrue);
      expect(find.text('订单 #1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('Reviewed 3 / 3 items'), findsOneWidget);
      expect(enabled(tester, 'export-merge'), isTrue);
      expect(find.text('00123'), findsOneWidget);
      await tester.tap(find.byTooltip('Workbench'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Merge & export'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export-merge')), findsNothing);
      expect(
        find.text(
          'Import BOM and placement tables A and B, then complete an A+B check.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'real export uses custom BOM suffix and contains exactly four columns',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync('merge-ui-');
      final previous = FileSelectorPlatform.instance;
      final selector = MergeSelector(
        (_) async => FileSaveLocation('${temp.path}/订单 #1.xlsx'),
      );
      FileSelectorPlatform.instance = selector;
      addTearDown(() {
        FileSelectorPlatform.instance = previous;
        temp.deleteSync(recursive: true);
      });
      await prepareMerge(tester);
      await confirmAll(tester);
      await tester.enterText(find.byKey(const Key('merge-file-name')), '订单 #1');
      final output = File('${temp.path}/订单 #1-BOM.xlsx');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('export-merge')));
        for (var i = 0; i < 100 && !output.existsSync(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(selector.suggestedName, '订单 #1-BOM.xlsx');
      expect(output.existsSync(), isTrue);
      final read = XlsxReader().read(output.path, InputKind.station);
      expect(read.rows.map((r) => r.part), ['00123', 'NG-PART']);
      expect(read.sheets.single.rows.first.cells.values, [
        '料号',
        '物料描述',
        '数量',
        '位号',
      ]);
      expect(read.rows.first.quantity, 2);
    },
  );

  testWidgets(
    'a pending save dialog cannot export after the session is cleared',
    (tester) async {
      final previous = FileSelectorPlatform.instance,
          pending = Completer<FileSaveLocation?>();
      final temp = Directory.systemTemp.createTempSync('merge-stale-');
      FileSelectorPlatform.instance = MergeSelector((_) => pending.future);
      addTearDown(() {
        FileSelectorPlatform.instance = previous;
        temp.deleteSync(recursive: true);
      });
      await prepareMerge(tester);
      await confirmAll(tester);
      await tester.tap(find.byKey(const Key('export-merge')));
      await tester.pump();
      // Navigate while native dialog is pending, then clear the session.
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-session')));
      await tester.pumpAndSettle();
      pending.complete(FileSaveLocation('${temp.path}/stale-BOM.xlsx'));
      await tester.pumpAndSettle();
      expect(File('${temp.path}/stale-BOM.xlsx').existsSync(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual review entry on NG detail opens the corresponding merge item',
    (tester) async {
      await prepareMerge(tester);
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NG-PART').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('人工确认合并'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-include')), findsOneWidget);
      expect(enabled(tester, 'generate-merge'), isFalse);
      expect(find.text('NG-PART'), findsWidgets);
    },
  );
}
