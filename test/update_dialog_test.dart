import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smt_check/app.dart';
import 'package:smt_check/l10n/localization.dart';
import 'package:smt_check/services/update_service.dart';
import 'package:smt_check/ui/update_dialog.dart';

class ControlledUpdates extends UpdateService {
  final Future<AppRelease> result;
  bool closed = false;
  ControlledUpdates(this.result) {
    result.ignore();
  }
  @override
  Future<AppRelease> check({
    required String currentVersion,
    required String platform,
  }) => result;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

AppRelease newerRelease() => AppRelease(
  current: Version.parse('1.6.0'),
  latest: Version.parse('1.7.0'),
  notes: List.filled(18, 'Release notes 原始更新说明 / รายละเอียด').join('\n'),
  page: Uri.parse('$releaseRepository/releases/tag/v1.7.0'),
  installer: Uri.parse(
    '$releaseRepository/releases/download/v1.7.0/SMT-CHECK-Setup-x64.exe',
  ),
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'reads installed package version and hides download when up to date',
    (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'SMT-CHECK',
        packageName: 'smt_check',
        version: '1.7.0',
        buildNumber: '10',
        buildSignature: '',
      );
      await tester.pumpWidget(
        SmtCheckApp(
          persist: false,
          updateServiceFactory: () => ControlledUpdates(
            Future.value(
              AppRelease(
                current: Version.parse('1.7.0'),
                latest: Version.parse('1.7.0'),
                notes: '',
                page: releasesPage,
                installer: newerRelease().installer,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('check-updates')));
      await tester.pumpAndSettle();
      expect(find.text('当前版本：1.7.0'), findsOneWidget);
      expect(find.text('当前已是最新版本'), findsOneWidget);
      expect(find.text('此版本未提供更新说明。'), findsOneWidget);
      expect(find.text('下载 Windows 安装包'), findsNothing);
      expect(find.text('下载 Linux 安装包'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final language in ['zh', 'en', 'th']) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets(
        'single native brand and usable update dialog in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final opened = <Uri>[];
          await tester.pumpWidget(
            SmtCheckApp(
              persist: false,
              initialLanguage: language,
              installedVersionLoader: () async => '1.6.0',
              updateServiceFactory: () =>
                  ControlledUpdates(Future.value(newerRelease())),
              externalUrlLauncher: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('brand-icon')), findsNothing);
          expect(find.text('SMT-CHECK'), findsNothing);
          expect(find.byKey(const Key('check-updates')), findsOneWidget);
          await tester.tap(find.byKey(const Key('check-updates')));
          await tester.pumpAndSettle();
          expect(find.text(translate('当前版本：1.6.0', language)), findsOneWidget);
          expect(find.text(translate('发现新版本 1.7.0', language)), findsOneWidget);
          final downloadLabel = Platform.isLinux
              ? '下载 Linux 安装包'
              : '下载 Windows 安装包';
          // This controlled service supplies an installer on either CI platform.
          await tester.tap(find.text(translate(downloadLabel, language)));
          await tester.pumpAndSettle();
          expect(opened, [newerRelease().installer]);
          await tester.tap(find.text(translate('查看发布页面', language)));
          await tester.pumpAndSettle();
          expect(opened.last, newerRelease().page);
          await tester.tap(find.byTooltip(translate('关闭', language)));
          await tester.pumpAndSettle();
          expect(find.byType(UpdateDialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'progress is visible, early close cancels and ignores a late response',
    (tester) async {
      final pending = Completer<AppRelease>();
      final service = ControlledUpdates(pending.future);
      await tester.pumpWidget(
        SmtCheckApp(
          persist: false,
          installedVersionLoader: () async => '1.6.0',
          updateServiceFactory: () => service,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('check-updates')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('正在检查更新…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(service.closed, true);
      pending.complete(newerRelease());
      await tester.pumpAndSettle();
      expect(find.byType(UpdateDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed check retries and browser failure exposes a copyable link',
    (tester) async {
      var attempt = 0;
      await tester.pumpWidget(
        SmtCheckApp(
          persist: false,
          installedVersionLoader: () async => '1.6.0',
          externalUrlLauncher: (_) async => false,
          updateServiceFactory: () => ControlledUpdates(
            attempt++ == 0
                ? Future.error(const UpdateException('检查更新超时，请检查网络后重试。'))
                : Future.value(newerRelease()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('check-updates')));
      await tester.pumpAndSettle();
      expect(find.text('检查更新超时，请检查网络后重试。'), findsOneWidget);
      expect(find.text('当前已是最新版本'), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('发现新版本 1.7.0'), findsOneWidget);
      await tester.tap(find.text('查看发布页面'));
      await tester.pumpAndSettle();
      expect(find.text('无法打开系统浏览器，请复制链接后打开。'), findsOneWidget);
      expect(find.text('复制链接'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SelectableText && w.data == newerRelease().page.toString(),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
