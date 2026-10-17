import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/ui/design.dart';

import 'checker_test.dart' as f;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  test('status highlights are opaque, distinct from the panel and readable in every theme', () {
    for (final dark in [false, true]) {
      for (final accent in ThemeAccent.values) {
        final p = Palette(dark, accent);
        expect(contrast(p.accent, p.onAccent), greaterThanOrEqualTo(4.5));
        expect(contrast(p.alertText, p.panel), greaterThanOrEqualTo(4.5));
        expect(contrast(p.alertText, p.bg), greaterThanOrEqualTo(4.5));
        for (final status in CheckStatus.values) {
          for (final selected in [false, true]) {
            final colors = p.result(status, selected: selected);
            expect(colors.fill.a, 1);
            expect(
              contrast(colors.ink, colors.fill),
              greaterThanOrEqualTo(4.5),
              reason: '$dark $accent $status $selected',
            );
            expect(
              contrast(colors.badge, colors.onBadge),
              greaterThanOrEqualTo(4.5),
            );
            expect(contrast(colors.fill, p.panel), greaterThanOrEqualTo(1.25));
            expect(
              colors.fill,
              Palette(dark).result(status, selected: selected).fill,
            );
          }
        }
      }
    }
  });

  testWidgets(
    'accent selection persists, preserves the report and keeps status colors independent',
    (tester) async {
      tester.view.physicalSize = const Size(1560, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final report = f.check(
        [f.row('PASS', '1', 'R1'), f.row('ERROR', '1', 'C1')],
        [f.row('PASS', '1', 'R1'), f.row('ERROR', '1', 'C2')],
      );
      await tester.pumpWidget(SmtFusionApp(initialReport: report));
      await tester.pumpAndSettle();
      for (final accent in [ThemeAccent.blue, ThemeAccent.green]) {
        await tester.tap(find.byTooltip('设置'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('theme-color-${accent.name}')));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Scaffold));
        expect(Theme.of(context).extension<AccentTheme>()!.accent, accent);
        expect(Theme.of(context).brightness, Brightness.light);
        expect(Theme.of(context).useMaterial3, isFalse);
        expect(
          (await SharedPreferences.getInstance()).getString('accentColor'),
          accent.name,
        );
        await tester.tap(find.byTooltip('核对工作台'));
        await tester.pumpAndSettle();
        for (final item in report.items) {
          final container = tester.widget<Container>(
            find.byKey(ObjectKey(item)),
          );
          expect(
            (container.decoration! as BoxDecoration).color,
            Palette(false).result(item.status).fill,
          );
        }
        expect(report.count(CheckStatus.pass), 1);
        expect(report.count(CheckStatus.error), 1);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(SmtFusionApp(initialReport: report));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold)))
            .extension<AccentTheme>()!
            .accent,
        ThemeAccent.green,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('platform icon resources contain valid dimensions and transparent rounded corners', () async {
    final png = File('assets/icons/app_icon.png').readAsBytesSync();
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width, image.height);
    expect(image.width, greaterThanOrEqualTo(1024));
    final rgba = (await image.toByteData())!.buffer.asUint8List();
    for (final pixel in [
      0,
      image.width - 1,
      image.width * (image.height - 1),
      image.width * image.height - 1,
    ]) {
      expect(rgba[pixel * 4 + 3], 0);
    }
    expect(
      rgba[((image.height ~/ 2) * image.width + image.width ~/ 2) * 4 + 3],
      greaterThanOrEqualTo(250),
    );
    image.dispose();
    codec.dispose();
    final ico = File('windows/runner/resources/app_icon.ico').readAsBytesSync();
    final header = ByteData.sublistView(ico);
    expect(header.getUint16(2, Endian.little), 1);
    final count = header.getUint16(4, Endian.little);
    final sizes = {
      for (var i = 0; i < count; i++)
        ico[6 + i * 16] == 0 ? 256 : ico[6 + i * 16],
    };
    expect(sizes, containsAll([16, 24, 32, 48, 64, 128, 256]));
    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      final bytes = ByteData.sublistView(
        File(
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
        ).readAsBytesSync(),
      );
      expect(bytes.getUint32(16), size);
      expect(bytes.getUint32(20), size);
    }
    final linux = ByteData.sublistView(
      File('docs/app-icon.png').readAsBytesSync(),
    );
    expect(linux.getUint32(16), 256);
  });
}
