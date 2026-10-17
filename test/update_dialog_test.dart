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
import 'package:smt_check/services/update_installer.dart';
import 'package:smt_check/ui/update_dialog.dart';

class ControlledUpdates extends UpdateService {
  final Future<AppRelease> result;
  final transfer = Completer<DownloadedUpdate>();
  void Function(int, int)? progress;
  void Function()? verify;
  bool closed = false;
  ControlledUpdates(this.result) {
    result.ignore();
    transfer.future.ignore();
  }
  @override
  Future<AppRelease> check({
    required String currentVersion,
    required String platform,
    String? architecture,
  }) => result;
  @override
  Future<DownloadedUpdate> download(
    AppRelease release, {
    required void Function(int, int) onProgress,
    void Function()? onVerify,
  }) {
    progress = onProgress;
    verify = onVerify;
    onProgress(0, 100);
    return transfer.future;
  }

  @override
  void cancel() {
    if (!transfer.isCompleted) transfer.completeError(const UpdateCancelled());
    super.cancel();
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}

class ControlledInstaller extends UpdateInstaller {
  int calls = 0, restarts = 0;
  bool fail = false;
  Completer<bool>? pending;
  @override
  Future<bool> install(DownloadedUpdate update) async {
    calls++;
    if (fail) throw const UpdateException('安装未完成或已取消，请重试并允许系统安装授权。');
    return pending?.future ?? false;
  }

  @override
  Future<void> restart() async {
    restarts++;
  }
}

AppRelease newerRelease() => AppRelease(
  current: Version.parse('1.12.0'),
  latest: Version.parse('1.13.0'),
  notes: List.filled(18, 'Release notes 原始更新说明 / รายละเอียด').join('\n'),
  page: Uri.parse('$releaseRepository/releases/tag/v1.13.0'),
  installer: Uri.parse(
    '$releaseRepository/releases/download/v1.13.0/SMT-CHECK-Setup-x64.exe',
  ),
  installerSize: 100,
  sha256: 'a' * 64,
);

Future<void> openUpdateSettings(
  WidgetTester tester, [
  String language = 'zh',
]) async {
  await tester.tap(find.byTooltip(translate('设置', language)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(translate('关于与更新', language)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('check-updates')));
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('reads installed version and never offers a downgrade', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'SMT Fusion',
      packageName: 'smt_check',
      version: '1.13.0',
      buildNumber: '19',
      buildSignature: '',
    );
    await tester.pumpWidget(
      SmtFusionApp(
        persist: false,
        updateServiceFactory: () => ControlledUpdates(
          Future.value(
            AppRelease(
              current: Version.parse('1.13.0'),
              latest: Version.parse('1.13.0'),
              notes: '',
              page: releasesPage,
              installer: newerRelease().installer,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openUpdateSettings(tester);
    expect(find.text('当前版本：1.13.0'), findsOneWidget);
    expect(find.text('当前已是最新版本'), findsOneWidget);
    expect(find.text('此版本未提供更新说明。'), findsOneWidget);
    expect(find.text('下载更新'), findsNothing);
    expect(find.text('查看发布页面'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['zh', 'en', 'th']) {
    for (final width in [560.0, 800.0, 1560.0]) {
      testWidgets(
        'in-app progress, verified install and restart in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final updates = <ControlledUpdates>[];
          final installer = ControlledInstaller();
          var quits = 0;
          await tester.pumpWidget(
            SmtFusionApp(
              persist: false,
              initialLanguage: language,
              installedVersionLoader: () async => '1.12.0',
              updateInstaller: installer,
              updateQuit: () async {
                quits++;
              },
              updateServiceFactory: () {
                final service = ControlledUpdates(Future.value(newerRelease()));
                updates.add(service);
                return service;
              },
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('brand-icon')), findsNothing);
          expect(find.text('SMT Fusion'), findsOneWidget);
          await openUpdateSettings(tester, language);
          expect(
            find.text(translate('发现新版本 1.13.0', language)),
            findsOneWidget,
          );
          expect(find.text(translate('查看发布页面', language)), findsNothing);
          await tester.tap(find.text(translate('下载更新', language)));
          await tester.pump();
          expect(find.text(translate('正在下载安装包…', language)), findsOneWidget);
          updates.last.progress!(40, 100);
          await tester.pump();
          expect(
            tester
                .widget<LinearProgressIndicator>(
                  find.byKey(const Key('update-download-progress')),
                )
                .value,
            .4,
          );
          expect(find.text(translate('安装更新', language)), findsNothing);
          updates.last.verify!();
          await tester.pump();
          expect(find.text(translate('正在校验安装包…', language)), findsOneWidget);
          updates.last.transfer.complete(
            DownloadedUpdate(
              File('nonexistent-updater-fixture'),
              newerRelease(),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(translate('安装包已通过 SHA-256 校验。', language)),
            findsOneWidget,
          );
          installer.pending = Completer<bool>();
          await tester.tap(find.text(translate('安装更新', language)));
          await tester.pump();
          expect(installer.calls, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump();
          expect(find.byType(UpdateDialog), findsOneWidget);
          installer.pending!.complete(false);
          await tester.pumpAndSettle();
          expect(
            find.text(translate('更新已安装，重新启动后生效。', language)),
            findsOneWidget,
          );
          await tester.tap(find.text(translate('重新启动应用', language)));
          await tester.pumpAndSettle();
          expect(installer.restarts, 1);
          expect(quits, 1);
          await tester.tap(find.byTooltip(translate('关闭', language)));
          await tester.pumpAndSettle();
          expect(find.byType(UpdateDialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('closing cancels a pending check and ignores its late result', (
    tester,
  ) async {
    final pending = Completer<AppRelease>();
    final service = ControlledUpdates(pending.future);
    await tester.pumpWidget(
      SmtFusionApp(
        persist: false,
        installedVersionLoader: () async => '1.12.0',
        updateServiceFactory: () => service,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关于与更新'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-updates')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('正在检查更新…'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(service.closed, true);
    pending.complete(newerRelease());
    await tester.pumpAndSettle();
    expect(find.byType(UpdateDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cancel transfer, retry failure, and installation failure remain explicit',
    (tester) async {
      var attempt = 0;
      final updates = <ControlledUpdates>[];
      final installer = ControlledInstaller()..fail = true;
      await tester.pumpWidget(
        SmtFusionApp(
          persist: false,
          installedVersionLoader: () async => '1.12.0',
          updateInstaller: installer,
          updateServiceFactory: () {
            final service = ControlledUpdates(
              attempt++ == 0
                  ? Future.error(const UpdateException('检查更新超时，请检查网络后重试。'))
                  : Future.value(newerRelease()),
            );
            updates.add(service);
            return service;
          },
        ),
      );
      await tester.pumpAndSettle();
      await openUpdateSettings(tester);
      expect(find.text('检查更新超时，请检查网络后重试。'), findsOneWidget);
      expect(find.text('当前已是最新版本'), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下载更新'));
      await tester.pump();
      await tester.tap(find.text('取消下载'));
      await tester.pumpAndSettle();
      expect(find.text('下载已取消，可重新下载。'), findsOneWidget);
      await tester.tap(find.text('下载更新'));
      await tester.pump();
      updates.last.transfer.completeError(
        const UpdateException('安装包校验失败，请重新下载。'),
      );
      await tester.pumpAndSettle();
      expect(find.text('安装包校验失败，请重新下载。'), findsOneWidget);
      expect(find.text('安装更新'), findsNothing);
      await tester.tap(find.text('下载更新'));
      await tester.pump();
      updates.last.transfer.complete(
        DownloadedUpdate(File('nonexistent-updater-fixture'), newerRelease()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('安装更新'));
      await tester.pumpAndSettle();
      expect(find.text('安装未完成或已取消，请重试并允许系统安装授权。'), findsOneWidget);
      expect(find.text('更新已安装，重新启动后生效。'), findsNothing);
      installer.fail = false;
      installer.pending = Completer<bool>();
      await tester.tap(find.text('安装更新'));
      await tester.pump();
      installer.pending!.completeError(
        const UpdateVerificationException('安装包已丢失或无法读取，请重新下载。'),
      );
      await tester.pumpAndSettle();
      expect(find.text('下载更新'), findsOneWidget);
      expect(find.text('安装更新'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
