import 'dart:async';
import 'dart:convert';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/coordinate_comparison.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/coordinate_comparison_export.dart';
import 'package:smt_check/ui/coordinate_comparison_workspace.dart';
import 'package:smt_check/ui/coordinate_compare_settings.dart';
import 'package:smt_check/ui/design.dart';

import 'coordinate_comparison_test.dart' as fixture;

class DelayedCoordinateSelector extends FileSelectorPlatform {
  final Completer<XFile?> selection;
  DelayedCoordinateSelector(this.selection);
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) => selection.future;
}

CoordinateCompareController prepared() {
  final c = CoordinateCompareController();
  c.a = CoordinateImport('a.xlsx', [
    fixture.record('R1'),
    fixture.record('TP10_1'),
  ], []);
  c.b = CoordinateImport('b.xlsx', [
    fixture.record('R1', x: '107.67500000000001'),
  ], []);
  c.unitA = c.unitB = CadUnit.mm;
  c.confirmed = true;
  c.result = CoordinateComparator.compare(
    c.a!,
    c.b!,
    c.settings,
    unitA: c.unitA,
    unitB: c.unitB,
    frameConfirmed: true,
  );
  c.selected = c.result!.items.last;
  return c;
}

void main() {
  testWidgets('clear rejects a late native file-picker selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1560, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previous = FileSelectorPlatform.instance,
        pending = Completer<XFile?>();
    FileSelectorPlatform.instance = DelayedCoordinateSelector(pending);
    addTearDown(() => FileSelectorPlatform.instance = previous);
    final c = CoordinateCompareController(
      loader: (_) async =>
          CoordinateImport('old.xlsx', [fixture.record('R1')], []),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: desktopTheme(false),
        home: Scaffold(
          body: CoordinateComparisonWorkspace(controller: c, onSettings: () {}),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('coordinate-import-a')));
    await tester.pump();
    c.clear();
    pending.complete(XFile('old.xlsx'));
    await tester.pumpAndSettle();
    expect(c.a, isNull);
    expect(c.busy, false);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'manual exclusion has a separate visible pool and retains original NG',
    (tester) async {
      tester.view.physicalSize = const Size(1560, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = prepared();
      addTearDown(c.dispose);
      final tp = c.result!.items.singleWhere((i) => i.reference == 'TP10_1');
      c.result!.decide(tp, true, 'process decision');
      await tester.pumpWidget(
        MaterialApp(
          theme: desktopTheme(false),
          home: Scaffold(
            body: CoordinateComparisonWorkspace(
              controller: c,
              onSettings: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coordinate-row-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('coordinate-row-1')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('coordinate-pool-excluded')));
      await tester.pumpAndSettle();
      expect(find.text('TP10_1'), findsWidgets);
      expect(c.result!.missing, 1);
      expect(tp.isError, true);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('coordinate-pool-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('coordinate-row-1')), findsOneWidget);
    },
  );
  testWidgets(
    'generated diagnostics translate while Excel field values stay literal',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('zh'), Locale('en'), Locale('th')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Column(
              children: [
                Text(
                  coordinateDifferenceValue(
                    context,
                    const CadDifference(
                      CadDifferenceType.quality,
                      'PartType',
                      '缺少字段',
                      '',
                      '',
                      1,
                    ),
                    true,
                  ),
                ),
                Text(
                  coordinateDifferenceValue(
                    context,
                    const CadDifference(
                      CadDifferenceType.attribute,
                      'PartType',
                      '缺少字段',
                      '',
                    ),
                    true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Missing field'), findsOneWidget);
      expect(find.text('缺少字段'), findsOneWidget);
    },
  );
  test(
    'clear and dispose reject delayed imports and preserve settings',
    () async {
      final pending = Completer<CoordinateImport>();
      final c = CoordinateCompareController(loader: (_) => pending.future);
      final loading = c.load('a.xlsx', true);
      c.clear();
      pending.complete(CoordinateImport('a.xlsx', [fixture.record('R1')], []));
      await loading;
      expect(c.a, isNull);
      expect(c.busy, false);
      expect(c.settings.xyTolerance, '0.001');
      final pending2 = Completer<CoordinateImport>();
      final d = CoordinateCompareController(loader: (_) => pending2.future);
      final loading2 = d.load('a.xlsx', true);
      d.dispose();
      pending2.complete(CoordinateImport('a.xlsx', [], []));
      await loading2;
      c.dispose();
    },
  );
  test(
    'rule/tolerance changes invalidate results and old manual decisions',
    () {
      final c = prepared(), old = prepared();
      final tp = c.result!.items.last;
      c.result!.decide(tp, true, 'first');
      c.result!.decide(tp, false, 'recheck');
      final json = coordinateComparisonJson(c.result!);
      expect((json['decisionHistory'] as List).length, 2);
      expect(jsonEncode(json), contains('TP10_1'));
      expect(c.result!.missing, 1);
      c.applySettings(const CoordinateCompareSettings(xyTolerance: '0.01'));
      expect(c.result, isNull);
      expect(c.selected, isNull);
      expect(old.result!.decisions, isEmpty);
      c.dispose();
      old.dispose();
    },
  );
  for (final language in supportedLanguages) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets(
        'comparison layout $language $width with filters and details',
        (tester) async {
          tester.view.physicalSize = Size(width, 980);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final c = prepared();
          addTearDown(c.dispose);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              supportedLocales: const [
                Locale('zh'),
                Locale('en'),
                Locale('th'),
              ],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: desktopTheme(false),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CoordinateComparisonWorkspace(
                    controller: c,
                    onSettings: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(translate('坐标差异检测', language)), findsOneWidget);
          await tester.enterText(
            find.byKey(const Key('coordinate-search')),
            'TP10_1',
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('coordinate-row-0')),
            findsOneWidget,
          );
          await tester.tapAt(
            tester.getTopLeft(find.byKey(const ValueKey('coordinate-row-0'))) +
                const Offset(50, 20),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              translate('可能为 PCB 特殊特征。默认保留；排除不删除记录，也不改变原始差异。', language),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('comparison settings validate before applying', (tester) async {
    CoordinateCompareSettings? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: desktopTheme(false),
        home: Scaffold(
          body: CoordinateCompareSettingsPanel(
            settings: const CoordinateCompareSettings(),
            onApply: (s) => saved = s,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('coordinate-xy-tolerance')),
      'NaN',
    );
    await tester.ensureVisible(
      find.byKey(const Key('coordinate-settings-save')),
    );
    await tester.tap(find.byKey(const Key('coordinate-settings-save')));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.ensureVisible(
      find.byKey(const Key('coordinate-xy-tolerance')),
    );
    await tester.enterText(
      find.byKey(const Key('coordinate-xy-tolerance')),
      '0.002',
    );
    await tester.ensureVisible(
      find.byKey(const Key('coordinate-settings-save')),
    );
    await tester.tap(find.byKey(const Key('coordinate-settings-save')));
    await tester.pumpAndSettle();
    expect(saved?.xyTolerance, '0.002');
    expect(tester.takeException(), isNull);
  });
  testWidgets('root navigation exposes independent comparison and settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1560, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmtCheckApp(persist: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('坐标差异检测'));
    await tester.pumpAndSettle();
    expect(find.byType(CoordinateComparisonWorkspace), findsOneWidget);
    await tester.tap(find.byKey(const Key('coordinate-open-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(CoordinateCompareSettingsPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'large text, high DPI, resize and language keep comparison state',
    (tester) async {
      final c = prepared();
      addTearDown(c.dispose);
      tester.view.devicePixelRatio = 1.5;
      tester.view.physicalSize = const Size(2340, 1470);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> render(String language) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: const [Locale('zh'), Locale('en'), Locale('th')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: desktopTheme(true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: CoordinateComparisonWorkspace(
                controller: c,
                onSettings: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await render('en');
      tester.view.physicalSize = const Size(840, 1470);
      await render('th');
      expect(c.result!.missing, 1);
      expect(c.selected!.reference, 'TP10_1');
    },
  );
  testWidgets(
    'corrupt comparison preferences do not prevent existing settings loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'coordinateCompareSettings': 'invalid',
        'language': 'th',
        'accentColor': 'blue',
        'exclude': false,
      });
      await tester.pumpWidget(const SmtCheckApp());
      await tester.pumpAndSettle();
      expect(find.byTooltip(translate('坐标差异检测', 'th')), findsOneWidget);
      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(theme.extension<AccentTheme>()!.accent, ThemeAccent.blue);
      expect(tester.takeException(), isNull);
    },
  );
}
