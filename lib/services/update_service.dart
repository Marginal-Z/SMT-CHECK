import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const releaseRepository = 'https://github.com/Marginal-Z/SMT-CHECK';
final releasesPage = Uri.parse('$releaseRepository/releases/latest');

String get currentArchitecture => switch (Abi.current()) {
  Abi.windowsX64 || Abi.linuxX64 || Abi.macosX64 => 'x64',
  Abi.windowsArm64 || Abi.linuxArm64 || Abi.macosArm64 => 'arm64',
  _ => 'unknown',
};

String? installerFilename(String platform, String architecture) =>
    switch ((platform, architecture)) {
      ('windows', 'x64') => 'SMT-CHECK-Setup-x64.exe',
      ('windows', 'arm64') => 'SMT-CHECK-Setup-arm64.exe',
      ('linux', 'x64') => 'SMT-CHECK-linux-amd64.deb',
      ('linux', 'arm64') => 'SMT-CHECK-linux-arm64.deb',
      ('macos', 'x64' || 'arm64') => 'SMT-CHECK-macos-universal.dmg',
      _ => null,
    };

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

class AppRelease {
  final Version current, latest;
  final String notes;
  final Uri page;
  final Uri? installer;
  const AppRelease({
    required this.current,
    required this.latest,
    required this.notes,
    required this.page,
    required this.installer,
  });
  // Release precedence ignores build numbers; prereleases still compare correctly.
  bool get hasUpdate =>
      Version.parse(latest.toString().split('+').first) >
      Version.parse(current.toString().split('+').first);
}

class UpdateService {
  final http.Client client;
  final Duration timeout;
  UpdateService({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : client = client ?? http.Client();

  Future<AppRelease> check({
    required String currentVersion,
    required String platform,
    String? architecture,
  }) async {
    final Version current;
    try {
      current = Version.parse(currentVersion);
    } on FormatException {
      throw const UpdateException('无法读取当前应用版本，请查看发布页面。');
    }
    try {
      final response = await client
          .get(
            Uri.parse(
              'https://api.github.com/repos/Marginal-Z/SMT-CHECK/releases/latest',
            ),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'SMT-CHECK/$currentVersion',
              'X-GitHub-Api-Version': '2026-03-10',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 403 || response.statusCode == 429) {
        throw const UpdateException('更新检查暂时受限，请稍后重试或查看发布页面。');
      }
      if (response.statusCode == 404) {
        throw const UpdateException('暂未找到正式发布版本，请稍后重试。');
      }
      if (response.statusCode != 200) {
        throw const UpdateException('更新服务器暂时不可用，请稍后重试。');
      }
      if (response.bodyBytes.length > 2 * 1024 * 1024) {
        throw const FormatException('oversized release response');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> ||
          data['draft'] != false ||
          data['prerelease'] != false) {
        throw const FormatException('not a stable release');
      }
      final tag = data['tag_name'] as String;
      final latest = Version.parse(
        tag.startsWith('v') ? tag.substring(1) : tag,
      );
      if (latest.isPreRelease) {
        throw const FormatException('not a stable version');
      }
      final page = Uri.parse(
        '$releaseRepository/releases/tag/${Uri.encodeComponent(tag)}',
      );
      final filename = installerFilename(
        platform,
        architecture ?? currentArchitecture,
      );
      Uri? installer;
      if (filename != null) {
        final expected = Uri.parse(
          '$releaseRepository/releases/download/${Uri.encodeComponent(tag)}/$filename',
        );
        for (final asset in data['assets'] as List<dynamic>) {
          if (asset is Map<String, dynamic> &&
              asset['name'] == filename &&
              asset['state'] == 'uploaded' &&
              asset['size'] is num &&
              asset['size'] > 0 &&
              asset['browser_download_url'] == expected.toString()) {
            installer = expected;
            break;
          }
        }
      }
      final body = data['body'];
      if (body != null && body is! String) {
        throw const FormatException('invalid release notes');
      }
      return AppRelease(
        current: current,
        latest: latest,
        notes: (body as String? ?? '').trim(),
        page: page,
        installer: installer,
      );
    } on TimeoutException {
      throw const UpdateException('检查更新超时，请检查网络后重试。');
    } on http.ClientException {
      throw const UpdateException('无法连接更新服务器，请检查网络后重试。');
    } on FormatException {
      throw const UpdateException('更新服务器返回的数据无效，请稍后重试。');
    } on TypeError {
      throw const UpdateException('更新服务器返回的数据无效，请稍后重试。');
    }
  }

  void close() => client.close();
}
