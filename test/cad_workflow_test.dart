import 'dart:async';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/coordinate_reader.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/ui/cad_workspace.dart';
import 'package:smt_check/ui/design.dart';

import 'support/cad_fixture.dart';
import 'support/merge_fixture.dart';

class CadSelector extends FileSelectorPlatform {
  final String input;
  final Future<FileSaveLocation?> Function(SaveDialogOptions)? save;
  String? suggested;
  CadSelector(this.input, {this.save});
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile(input);
  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) {
    suggested = options.suggestedName;
    return save?.call(options) ?? Future.value(null);
  }
}

bool enabled(WidgetTester tester, String key) =>
    tester.widget<DeskButton>(find.byKey(Key(key))).onPressed != null;
CoordinateImport coordinates(String path) => CoordinateImport(path, [
  ...cadCoordinates().records,
  cadRecord('R2', 20, 40, layer: 'Top', row: 5),
], []);
Future<void> openCad(WidgetTester tester) async {
  await tester.tap(find.byTooltip('CAD 坐标'));
  await tester.pumpAndSettle();
}

Future<void> prepare(
  WidgetTester tester, {
  Future<CoordinateImport> Function(String)? loader,
  CheckReport? report,
}) async {
  tester.view.physicalSize = const Size(1560, 980);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    SmtCheckApp(
      persist: false,
      initialReport: report ?? mergeReport(),
      coordinateLoader: loader ?? (p) async => coordinates(p),
      cadPlanner: (b, c, u) async => CadGenerator.generate(b, c, u),
    ),
  );
  await tester.pumpAndSettle();
  await openCad(tester);
}

Future<void> reviewAndGenerate(WidgetTester tester, {int count = 3}) async {
  await tester.tap(find.byTooltip('合并与导出'));
  await tester.pumpAndSettle();
  for (var i = 0; i < count; i++) {
    await tester.tap(find.byKey(const Key('confirm-omit')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('generate-merge')));
  await tester.pumpAndSettle();
  await openCad(tester);
}

Future<void> selectUnit(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('cad-unit')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> ready(WidgetTester tester) async {
  await prepare(tester);
  await reviewAndGenerate(tester);
  await tester.tap(find.byKey(const Key('import-cad')));
  await tester.pumpAndSettle();
  await selectUnit(tester, '毫米（mm）');
  await tester.tap(find.byKey(const Key('generate-cad')));
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  late Directory temp;
  late FileSelectorPlatform previous;
  late String input;
  setUp(() {
    temp = Directory.systemTemp.createTempSync('cad-workflow-');
    input = '${temp.path}/source.xlsx';
    File(input).writeAsStringSync('original coordinate bytes');
    previous = FileSelectorPlatform.instance;
    FileSelectorPlatform.instance = CadSelector(input);
  });
  tearDown(() {
    FileSelectorPlatform.instance = previous;
    temp.deleteSync(recursive: true);
  });
  testWidgets(
    'single table requires NG excluded candidate and BOM-only acknowledgment before CAD',
    (tester) async {
      await prepare(tester, report: singleReport());
      await tester.tap(find.byKey(const Key('import-cad')));
      await tester.pumpAndSettle();
      await selectUnit(tester, '毫米（mm）');
      expect(enabled(tester, 'generate-cad'), isFalse);
      await reviewAndGenerate(tester, count: 4);
      expect(enabled(tester, 'generate-cad'), isTrue);
      await tester.tap(find.byKey(const Key('generate-cad')));
      await tester.pumpAndSettle();
      expect(find.text('单表 CAD'), findsOneWidget);
      expect(find.text('PASS · 1 个位号'), findsOneWidget);
      expect(enabled(tester, 'export-cad'), isTrue);
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A + B 合并'));
      await tester.pumpAndSettle();
      await openCad(tester);
      expect(enabled(tester, 'export-cad'), isFalse);
    },
  );
  testWidgets('single table PASS flow needs no B file and exports CAD', (
    tester,
  ) async {
    final target = '${temp.path}/single-CAD.xlsx';
    FileSelectorPlatform.instance = CadSelector(
      input,
      save: (_) async => FileSaveLocation(target),
    );
    await prepare(tester, report: singleReport(allPass: true));
    await reviewAndGenerate(tester, count: 0);
    await tester.tap(find.byKey(const Key('import-cad')));
    await tester.pumpAndSettle();
    await selectUnit(tester, '毫米（mm）');
    await tester.tap(find.byKey(const Key('generate-cad')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('export-cad')));
      for (var i = 0; i < 300 && !File(target).existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(File(target).existsSync(), isTrue);
    expect(CoordinateReader().read(target).records.map((r) => r.reference), [
      'R1',
    ]);
  });
  testWidgets('review and explicit units gate CAD preview and export', (
    tester,
  ) async {
    await prepare(tester);
    await tester.tap(find.byKey(const Key('import-cad')));
    await tester.pumpAndSettle();
    expect(enabled(tester, 'generate-cad'), isFalse);
    await reviewAndGenerate(tester);
    expect(enabled(tester, 'generate-cad'), isFalse);
    await selectUnit(tester, '毫米（mm）');
    expect(enabled(tester, 'generate-cad'), isTrue);
    await tester.tap(find.byKey(const Key('generate-cad')));
    await tester.pumpAndSettle();
    expect(enabled(tester, 'export-cad'), isTrue);
    expect(find.byKey(const Key('cad-preview-table')), findsOneWidget);
    expect(find.text('PASS · 2 个位号'), findsOneWidget);
  });
  testWidgets('unit changes and revoked reviews invalidate old CAD output', (
    tester,
  ) async {
    await ready(tester);
    expect(enabled(tester, 'export-cad'), isTrue);
    await selectUnit(tester, '密耳（mil）');
    expect(enabled(tester, 'export-cad'), isFalse);
    expect(find.byKey(const Key('cad-preview-table')), findsNothing);
    await tester.tap(find.byKey(const Key('generate-cad')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('合并与导出'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('merge-review-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('revoke-review')));
    await tester.pumpAndSettle();
    await openCad(tester);
    expect(enabled(tester, 'generate-cad'), isFalse);
    expect(enabled(tester, 'export-cad'), isFalse);
  });
  testWidgets(
    'a coordinate read completing after clear cannot restore stale input',
    (tester) async {
      final load = Completer<CoordinateImport>();
      await prepare(tester, loader: (_) => load.future);
      await tester.tap(find.byKey(const Key('import-cad')));
      await tester.pump();
      await tester.tap(find.byTooltip('核对工作台'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('clear-session')));
      await tester.pumpAndSettle();
      load.complete(coordinates(input));
      await tester.pumpAndSettle();
      await openCad(tester);
      expect(find.text('尚未导入原坐标'), findsOneWidget);
      expect(enabled(tester, 'export-cad'), isFalse);
    },
  );
  testWidgets('pending save is cancelled by clearing the check session', (
    tester,
  ) async {
    final save = Completer<FileSaveLocation?>();
    FileSelectorPlatform.instance = CadSelector(
      input,
      save: (_) => save.future,
    );
    await ready(tester);
    await tester.tap(find.byKey(const Key('export-cad')));
    await tester.pump();
    await tester.tap(find.byTooltip('核对工作台'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('clear-session')));
    await tester.pumpAndSettle();
    final output = '${temp.path}/stale.xlsx';
    save.complete(FileSaveLocation(output));
    await tester.pumpAndSettle();
    expect(File(output).existsSync(), isFalse);
  });
  testWidgets('CAD cannot overwrite the imported source', (tester) async {
    FileSelectorPlatform.instance = CadSelector(
      input,
      save: (_) async => FileSaveLocation(input),
    );
    await ready(tester);
    await tester.tap(find.byKey(const Key('export-cad')));
    await tester.pumpAndSettle();
    expect(find.text('不能覆盖原始文件，请选择其他文件名或目录'), findsOneWidget);
    expect(File(input).readAsStringSync(), 'original coordinate bytes');
  });
  testWidgets('manual CAD filename exports one usable ten-column workbook', (
    tester,
  ) async {
    final output = '${temp.path}/Manual-CAD.xlsx';
    final selector = CadSelector(
      input,
      save: (_) async => FileSaveLocation(output),
    );
    FileSelectorPlatform.instance = selector;
    await ready(tester);
    await tester.enterText(
      find.byKey(const Key('cad-file-name')),
      'Manual-CAD',
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('export-cad')));
      for (var i = 0; i < 300 && !File(output).existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(selector.suggested, 'Manual-CAD.xlsx');
    expect(File(output).existsSync(), isTrue);
    final imported = CoordinateReader().read(output);
    expect(imported.records.map((r) => r.reference), ['R1', 'R2']);
    expect(imported.records.first.angle, 210);
    expect(imported.records.first.y, 70);
    expect(File(input).readAsStringSync(), 'original coordinate bytes');
  });

  for (final language in supportedLanguages) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets(
        'CAD preview fits $language at $width including enlarged text',
        (tester) async {
          tester.view.physicalSize = Size(width, 980);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = TextEditingController(text: 'Test-FAI450');
          addTearDown(controller.dispose);
          final bom = cadBom(), coords = cadCoordinates();
          await tester.pumpWidget(
            MaterialApp(
              theme: desktopTheme(false),
              locale: Locale(language),
              supportedLocales: const [
                Locale('zh'),
                Locale('en'),
                Locale('th'),
              ],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CadWorkspace(
                    bom: bom,
                    coordinates: coords,
                    preview: CadGenerator.generate(bom, coords, CadUnit.mm),
                    unit: CadUnit.mm,
                    nameController: controller,
                    busy: false,
                    canGenerate: true,
                    canExport: true,
                    error: '',
                    stage: '',
                    onImport: () {},
                    onGenerate: () {},
                    onExport: () {},
                    onMerge: () {},
                    onUnit: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(translate('FAI-i450 CAD 坐标', language)),
            findsOneWidget,
          );
          expect(find.byKey(const Key('cad-preview-table')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
