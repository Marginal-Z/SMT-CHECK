import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:smt_check/services/update_service.dart';
import 'package:smt_check/services/update_installer.dart';
import 'package:smt_check/services/preferences_migration.dart';

const payload = [0x4d, 0x5a, 1, 2, 3, 4, 5, 6];
AppRelease release({String platform = 'windows', String? hash, int? size}) {
  final name = platform == 'macos'
      ? 'SMT-Fusion-macos-universal.pkg'
      : installerFilename(platform, 'x64')!;
  return AppRelease(
    current: Version.parse('1.12.0'),
    latest: Version.parse('1.13.0'),
    notes: '',
    page: Uri.parse('$releaseRepository/releases/tag/v1.13.0'),
    installer: Uri.parse('$releaseRepository/releases/download/v1.13.0/$name'),
    installerSize: size ?? payload.length,
    sha256: hash ?? sha256.convert(payload).toString(),
  );
}

Future<DownloadedUpdate> artifact(
  Directory root, {
  String platform = 'windows',
}) async {
  final meta = release(platform: platform);
  final file = File('${root.path}/${meta.installer!.pathSegments.last}');
  await file.writeAsBytes(payload);
  return DownloadedUpdate(file, meta);
}

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('smt-fusion-update-test-');
  });
  tearDown(() async {
    if (await root.exists()) {
      // Test-owned path only; every fixture lives within this unique temp root.
      expect(
        root.path.split(Platform.pathSeparator).last,
        startsWith('smt-fusion-update-test-'),
      );
      await root.delete(recursive: true);
    }
  });
  test(
    'streamed download verifies bytes, progress, and a second on-disk read',
    () async {
      final progress = <int>[];
      final service = UpdateService(
        temporaryDirectory: () async => root,
        client: MockClient((r) async {
          expect(r.url, release().installer);
          expect(
            r.headers.keys.map((x) => x.toLowerCase()),
            isNot(contains('authorization')),
          );
          return http.Response.bytes(payload, 200);
        }),
      );
      addTearDown(service.close);
      var verifying = false;
      final result = await service.download(
        release(),
        onProgress: (n, total) {
          progress.add(n);
          expect(total, payload.length);
        },
        onVerify: () => verifying = true,
      );
      expect(progress.first, 0);
      expect(progress.last, payload.length);
      expect(verifying, isTrue);
      expect(await result.file.readAsBytes(), payload);
      expect(await File('${result.file.path}.partial').exists(), false);
      await result.verify();
      await result.file.writeAsBytes([0, ...payload.skip(1)]);
      await expectLater(result.verify(), throwsA(isA<UpdateException>()));
    },
  );
  for (final mode in [
    'hash',
    'truncated',
    'too-large',
    'html',
    'http-error',
    'missing-hash',
  ]) {
    test(
      '$mode never yields an installable file and cleans up partial output',
      () async {
        final service = UpdateService(
          temporaryDirectory: () async => root,
          client: MockClient(
            (_) async => http.Response.bytes(
              mode == 'truncated'
                  ? payload.sublist(1)
                  : mode == 'too-large'
                  ? [...payload, 9]
                  : mode == 'html'
                  ? [60, 104, 116, 109, 108, 62, 10, 10]
                  : payload,
              mode == 'http-error' ? 503 : 200,
            ),
          ),
        );
        addTearDown(service.close);
        await expectLater(
          service.download(
            release(
              hash: mode == 'hash'
                  ? '0' * 64
                  : mode == 'missing-hash'
                  ? ''
                  : null,
            ),
            onProgress: (_, _) {},
          ),
          throwsA(isA<UpdateException>()),
        );
        if (await root.exists()) expect(await root.list().toList(), isEmpty);
      },
    );
  }
  test(
    'idle network timeout is reported and incomplete file removed',
    () async {
      final stream = StreamController<List<int>>();
      final service = UpdateService(
        temporaryDirectory: () async => root,
        idleTimeout: const Duration(milliseconds: 20),
        client: MockClient.streaming(
          (_, _) async => http.StreamedResponse(stream.stream, 200),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.download(release(), onProgress: (_, _) {}),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'timeout',
            contains('超时'),
          ),
        ),
      );
      await stream.close();
      expect(await root.exists(), false);
    },
  );
  test('cancel during streaming cannot produce a verified installer', () async {
    final stream = StreamController<List<int>>();
    final service = UpdateService(
      temporaryDirectory: () async => root,
      client: MockClient.streaming(
        (_, _) async => http.StreamedResponse(stream.stream, 200),
      ),
    );
    final started = Completer<void>();
    final pending = service.download(
      release(),
      onProgress: (_, _) {
        if (!started.isCompleted) started.complete();
      },
    );
    final expectation = expectLater(pending, throwsA(isA<UpdateCancelled>()));
    await started.future;
    service.cancel();
    stream.add(payload);
    await stream.close();
    await expectation;
    expect(await root.exists(), false);
  });
  for (final location in [
    'http://github.com/unsafe',
    'https://evil.example/a.exe',
    'https://github.com:444/a.exe',
    'https://user@github.com/a.exe',
  ]) {
    test('rejects an untrusted redirect $location', () async {
      final service = UpdateService(
        temporaryDirectory: () async => root,
        client: MockClient(
          (_) async => http.Response('', 302, headers: {'location': location}),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.download(release(), onProgress: (_, _) {}),
        throwsA(isA<UpdateException>()),
      );
    });
  }
  test(
    'follows an official release CDN redirect and still checks hash',
    () async {
      var calls = 0;
      final service = UpdateService(
        temporaryDirectory: () async => root,
        client: MockClient((request) async {
          if (calls++ == 0) {
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://release-assets.githubusercontent.com/github-production-release-asset/test?token=public-signed',
              },
            );
          }
          expect(request.url.host, 'release-assets.githubusercontent.com');
          return http.Response.bytes(payload, 200);
        }),
      );
      addTearDown(service.close);
      final value = await service.download(release(), onProgress: (_, _) {});
      expect(calls, 2);
      await value.verify();
    },
  );
  for (final platform in ['windows', 'linux', 'macos']) {
    test(
      '$platform verifies again before invoking only the native installer',
      () async {
        final update = await artifact(root, platform: platform);
        final calls = <(String, List<String>, bool)>[];
        final installer = UpdateInstaller(
          platform: platform,
          executable: '${root.path}/SMT-CHECK.exe',
          command: (exe, args, detached) async {
            calls.add((exe, args, detached));
            return 0;
          },
        );
        if (platform == 'windows') {
          await File('${root.path}/unins000.exe')
              .writeAsString('test installed marker');
        }
        expect(await installer.install(update), platform == 'windows');
        expect(calls.length, 1);
        if (platform == 'windows') {
          expect(calls.single.$1, update.file.path);
          expect(
            calls.single.$2,
            containsAll([
              '/SMTFUSIONUPDATE=1',
              '/NOFORCECLOSEAPPLICATIONS',
              '/DIR=${root.path}',
            ]),
          );
          expect(calls.single.$3, true);
        } else if (platform == 'linux') {
          expect(calls.single.$1, '/usr/bin/pkexec');
          expect(calls.single.$2, ['/usr/bin/dpkg', '-i', update.file.path]);
        } else {
          expect(calls.single.$1, '/usr/bin/osascript');
          expect(calls.single.$2.last, update.file.path);
          expect(calls.single.$2[1], contains('quoted form'));
        }
        await update.file.writeAsBytes([8, ...payload.skip(1)]);
        await expectLater(
          installer.install(update),
          throwsA(isA<UpdateException>()),
        );
        expect(calls.length, 1);
      },
    );
  }
  test('a declined native installer never claims success', () async {
    final update = await artifact(root, platform: 'linux');
    final installer = UpdateInstaller(
      platform: 'linux',
      command: (_, _, _) async => 126,
    );
    await expectLater(
      installer.install(update),
      throwsA(
        isA<UpdateException>().having(
          (e) => e.message,
          'reason',
          contains('安装未完成'),
        ),
      ),
    );
    expect(await update.file.exists(), true);
  });
  test('Windows rename copies legacy settings once and retains original bytes', () async {
    final old = File(
      '${root.path}/com.smtcheck/SMT-CHECK/shared_preferences.json',
    );
    await old.parent.create(recursive: true);
    const saved =
        '{"flutter.language":"th","flutter.accent":"blue","flutter.aiModel":"deepseek-chat"}';
    await old.writeAsString(saved);
    await migrateWindowsPreferences(roamingDirectory: root.path);
    final fresh = File(
      '${root.path}/com.smtcheck/SMT Fusion/shared_preferences.json',
    );
    expect(await fresh.readAsString(), saved);
    expect(await old.readAsString(), saved);
    await fresh.writeAsString('{"flutter.language":"en"}');
    await migrateWindowsPreferences(roamingDirectory: root.path);
    expect(await fresh.readAsString(), '{"flutter.language":"en"}');
  });
  test('invalid legacy preferences are retained and reported, never silently overwritten', () async {
    final old = File(
      '${root.path}/com.smtcheck/SMT-CHECK/shared_preferences.json',
    );
    await old.parent.create(recursive: true);
    await old.writeAsString('invalid JSON');
    await expectLater(
      migrateWindowsPreferences(roamingDirectory: root.path),
      throwsA(isA<FormatException>()),
    );
    expect(await old.readAsString(), 'invalid JSON');
    expect(
      await File('${root.path}/com.smtcheck/SMT Fusion/shared_preferences.json')
          .exists(),
      false,
    );
  });
}
