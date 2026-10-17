import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smt_check/services/update_service.dart';

Map<String, dynamic> releaseData({String tag = 'v1.10.0'}) => {
  'tag_name': tag,
  'draft': false,
  'prerelease': false,
  'body': '更新说明',
  'assets': [
    for (final name in [
      'SMT-CHECK-Setup-x64.exe',
      'SMT-CHECK-Setup-arm64.exe',
      'SMT-CHECK-linux-amd64.deb',
      'SMT-CHECK-linux-arm64.deb',
      'SMT-CHECK-macos-universal.dmg',
    ])
      <String, dynamic>{
        'name': name,
        'state': 'uploaded',
        'size': 1234,
        'browser_download_url':
            '$releaseRepository/releases/download/$tag/$name',
      },
  ],
};

UpdateService serviceFor(Map<String, dynamic> data) => UpdateService(
  client: MockClient(
    (_) async => http.Response.bytes(utf8.encode(jsonEncode(data)), 200),
  ),
);

void main() {
  test('Fusion release retains legacy Windows name and prefers native macOS PKG with SHA-256', () async {
    final data = releaseData(tag: 'v1.13.0');
    for (final asset in data['assets'] as List) {
      asset['digest'] = 'sha256:${'a' * 64}';
    }
    (data['assets'] as List).add({
      'name': 'SMT-Fusion-macos-universal.pkg',
      'state': 'uploaded',
      'size': 2345,
      'digest': 'sha256:${'b' * 64}',
      'browser_download_url':
          '$releaseRepository/releases/download/v1.13.0/SMT-Fusion-macos-universal.pkg',
    });
    final service = serviceFor(data);
    addTearDown(service.close);
    final windows = await service.check(
      currentVersion: '1.12.0',
      platform: 'windows',
      architecture: 'x64',
    );
    expect(windows.installer!.pathSegments.last, 'SMT-CHECK-Setup-x64.exe');
    expect(windows.canInstall, true);
    expect(windows.sha256, 'a' * 64);
    final mac = await service.check(
      currentVersion: '1.12.0',
      platform: 'macos',
      architecture: 'arm64',
    );
    expect(mac.installer!.pathSegments.last, 'SMT-Fusion-macos-universal.pkg');
    expect(mac.canInstall, true);
    expect(mac.installerSize, 2345);
    expect(mac.sha256, 'b' * 64);
  });
  test('missing or malformed hash disables in-app execution but still reports the new version', () async {
    for (final digest in [null, '', 'sha256:invalid', 'sha256:${'x' * 64}']) {
      final data = releaseData();
      (data['assets'] as List).first['digest'] = digest;
      final service = serviceFor(data);
      addTearDown(service.close);
      final value = await service.check(
        currentVersion: '1.0.0',
        platform: 'windows',
        architecture: 'x64',
      );
      expect(value.hasUpdate, true);
      expect(value.canInstall, false);
    }
  });
  test(
    'installed local 1.11.0 can discover the published 1.11.1 installer',
    () async {
      final service = serviceFor(releaseData(tag: 'v1.11.1'));
      addTearDown(service.close);
      final release = await service.check(
        currentVersion: '1.11.0+16',
        platform: 'windows',
        architecture: 'x64',
      );
      expect(release.hasUpdate, isTrue);
      expect(release.latest.toString(), '1.11.1');
      expect(
        release.installer.toString(),
        '$releaseRepository/releases/download/v1.11.1/SMT-CHECK-Setup-x64.exe',
      );
    },
  );
  for (final (platform, arch, file) in [
    ('windows', 'x64', 'SMT-CHECK-Setup-x64.exe'),
    ('windows', 'arm64', 'SMT-CHECK-Setup-arm64.exe'),
    ('linux', 'x64', 'SMT-CHECK-linux-amd64.deb'),
    ('linux', 'arm64', 'SMT-CHECK-linux-arm64.deb'),
    ('macos', 'x64', 'SMT-CHECK-macos-universal.dmg'),
    ('macos', 'arm64', 'SMT-CHECK-macos-universal.dmg'),
    ('windows', 'x86', null),
    ('linux', 'unknown', null),
  ]) {
    test('update installer matches $platform / $arch', () async {
      final service = serviceFor(releaseData());
      addTearDown(service.close);
      final release = await service.check(
        currentVersion: '1.0.0',
        platform: platform,
        architecture: arch,
      );
      expect(release.installer?.pathSegments.last, file);
    });
  }
  test('ARM64 update never falls back to an x64-only release', () async {
    final data = releaseData();
    (data['assets'] as List).removeWhere(
      (a) => (a['name'] as String).contains('arm64'),
    );
    final service = serviceFor(data);
    addTearDown(service.close);
    expect(
      (await service.check(
        currentVersion: '1.0.0',
        platform: 'windows',
        architecture: 'arm64',
      )).installer,
      isNull,
    );
    expect(
      (await service.check(
        currentVersion: '1.0.0',
        platform: 'linux',
        architecture: 'arm64',
      )).installer,
      isNull,
    );
  });
  test(
    'uses a separate public request and selects the correct platform installer',
    () async {
      final requests = <http.Request>[];
      final service = UpdateService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(
            utf8.encode(jsonEncode(releaseData())),
            200,
          );
        }),
      );
      addTearDown(service.close);
      for (final (platform, filename) in [
        ('windows', 'SMT-CHECK-Setup-x64.exe'),
        ('linux', 'SMT-CHECK-linux-amd64.deb'),
      ]) {
        final release = await service.check(
          currentVersion: '1.9.9',
          platform: platform,
          architecture: 'x64',
        );
        expect(release.hasUpdate, true);
        expect(release.latest.toString(), '1.10.0');
        expect(release.installer!.pathSegments.last, filename);
        expect(release.notes, '更新说明');
      }
      for (final request in requests) {
        expect(
          request.url.toString(),
          'https://api.github.com/repos/Marginal-Z/SMT-CHECK/releases/latest',
        );
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(request.body, isEmpty);
      }
    },
  );
  for (final current in ['1.10.0', '1.10.0+20', '1.11.0']) {
    test('does not downgrade or confuse build metadata for $current', () async {
      final service = serviceFor(releaseData());
      addTearDown(service.close);
      expect(
        (await service.check(
          currentVersion: current,
          platform: 'windows',
          architecture: 'x64',
        )).hasUpdate,
        false,
      );
    });
  }
  test('a stable release updates a prerelease of the same version', () async {
    final service = serviceFor(releaseData());
    addTearDown(service.close);
    expect(
      (await service.check(
        currentVersion: '1.10.0-beta.1',
        platform: 'windows',
        architecture: 'x64',
      )).hasUpdate,
      true,
    );
  });
  test('remote build metadata alone does not trigger an update', () async {
    final service = serviceFor(releaseData(tag: 'v1.10.0+21'));
    addTearDown(service.close);
    expect(
      (await service.check(
        currentVersion: '1.10.0',
        platform: 'windows',
        architecture: 'x64',
      )).hasUpdate,
      false,
    );
  });
  for (final assetCase in [
    'missing',
    'foreign-host',
    'foreign-repo',
    'unfinished',
    'empty',
  ]) {
    test('no direct installer button for $assetCase assets', () async {
      final data = releaseData();
      final asset = (data['assets'] as List).first as Map<String, dynamic>;
      switch (assetCase) {
        case 'missing':
          data['assets'] = [];
        case 'foreign-host':
          asset['browser_download_url'] = 'https://example.com/SMT-CHECK.exe';
        case 'foreign-repo':
          asset['browser_download_url'] = 'https://github.com/another/repo/releases/download/v1.10.0/SMT-CHECK-Setup-x64.exe';
        case 'unfinished':
          asset['state'] = 'new';
        case 'empty':
          asset['size'] = 0;
      }
      final service = serviceFor(data);
      addTearDown(service.close);
      final release = await service.check(
        currentVersion: '1.0.0',
        platform: 'windows',
        architecture: 'x64',
      );
      expect(release.installer, null);
      expect(
        release.page.toString(),
        '$releaseRepository/releases/tag/v1.10.0',
      );
      expect(release.hasUpdate, true);
    });
  }
  for (final status in [403, 429, 404, 500]) {
    test('HTTP $status never reports up to date', () async {
      final service = UpdateService(
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(service.close);
      await expectLater(
        service.check(currentVersion: '1.0.0', platform: 'linux'),
        throwsA(isA<UpdateException>()),
      );
    });
  }
  for (final invalid in [
    {'prerelease': true},
    {'draft': true},
    {'tag_name': 'v1.11.0-beta.1'},
    {'tag_name': 'latest'},
    {'assets': null},
    {'body': 12},
  ]) {
    test('rejects invalid or unstable release metadata $invalid', () async {
      final service = serviceFor({...releaseData(), ...invalid});
      addTearDown(service.close);
      await expectLater(
        service.check(currentVersion: '1.0.0', platform: 'windows'),
        throwsA(isA<UpdateException>()),
      );
    });
  }
  test(
    'malformed JSON and unknown installed versions are explicit failures',
    () async {
      final service = UpdateService(
        client: MockClient((_) async => http.Response('not JSON', 200)),
      );
      addTearDown(service.close);
      for (final current in ['1.0.0', '']) {
        await expectLater(
          service.check(currentVersion: current, platform: 'windows'),
          throwsA(isA<UpdateException>()),
        );
      }
    },
  );
  test('slow and offline requests report actionable errors', () async {
    final pending = Completer<http.Response>();
    final slow = UpdateService(
      client: MockClient((_) => pending.future),
      timeout: const Duration(milliseconds: 10),
    );
    addTearDown(slow.close);
    await expectLater(
      slow.check(currentVersion: '1.0.0', platform: 'windows'),
      throwsA(
        isA<UpdateException>().having(
          (e) => e.message,
          'timeout',
          contains('超时'),
        ),
      ),
    );
    pending.complete(http.Response('{}', 200));
    final offline = UpdateService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(offline.close);
    await expectLater(
      offline.check(currentVersion: '1.0.0', platform: 'linux'),
      throwsA(
        isA<UpdateException>().having(
          (e) => e.message,
          'connection',
          contains('网络'),
        ),
      ),
    );
  });
}
