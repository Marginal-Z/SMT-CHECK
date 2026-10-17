import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const releaseRepository = 'https://github.com/Marginal-Z/SMT-CHECK';
final releasesPage = Uri.parse('$releaseRepository/releases/latest');
const maxInstallerBytes = 512 * 1024 * 1024;

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
  final int installerSize;
  final String sha256;
  const AppRelease({
    required this.current,
    required this.latest,
    required this.notes,
    required this.page,
    required this.installer,
    this.installerSize = 0,
    this.sha256 = '',
  });
  bool get canInstall =>
      installer != null &&
      installerSize > 0 &&
      installerSize <= maxInstallerBytes &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256) &&
      ['.exe', '.deb', '.pkg'].any(installer!.path.endsWith);
  // Release precedence ignores build numbers; prereleases still compare correctly.
  bool get hasUpdate =>
      Version.parse(latest.toString().split('+').first) >
      Version.parse(current.toString().split('+').first);
}

class UpdateCancelled implements Exception {
  const UpdateCancelled();
}

class UpdateVerificationException extends UpdateException {
  const UpdateVerificationException(super.message);
}

class DownloadedUpdate {
  final File file;
  final AppRelease release;
  const DownloadedUpdate(this.file, this.release);

  Future<void> verify() async {
    try {
      if (!release.canInstall ||
          await file.length() != release.installerSize ||
          (await crypto.sha256.bind(file.openRead()).first).toString() !=
              release.sha256) {
        throw const UpdateVerificationException('安装包校验失败，请重新下载。');
      }
    } on FileSystemException {
      throw const UpdateVerificationException('安装包已丢失或无法读取，请重新下载。');
    }
  }

  Future<void> delete() async {
    // Delete only the two files owned by this operation, never a recursive tree.
    for (final entry in [file, File('${file.path}.partial')]) {
      if (await entry.exists()) await entry.delete();
    }
    try {
      await file.parent.delete();
    } on FileSystemException {
      /* Installer log may remain. */
    }
  }
}

class UpdateService {
  final http.Client client;
  final Duration timeout;
  final Duration idleTimeout;
  final Future<Directory> Function()? temporaryDirectory;
  final _abort = Completer<void>();
  bool _closed = false;
  UpdateService({
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.idleTimeout = const Duration(seconds: 45),
    this.temporaryDirectory,
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
      throw const UpdateException('无法读取当前应用版本，请重新启动应用后重试。');
    }
    try {
      final response = await client
          .get(
            Uri.parse(
              'https://api.github.com/repos/Marginal-Z/SMT-CHECK/releases/latest',
            ),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'SMT-Fusion/$currentVersion',
              'X-GitHub-Api-Version': '2026-03-10',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 403 || response.statusCode == 429) {
        throw const UpdateException('更新检查暂时受限，请稍后重试。');
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
      var size = 0;
      var digest = '';
      final assets = data['assets'] as List<dynamic>;
      // Keep legacy filenames discoverable by installed SMT-CHECK versions.
      for (final name in [
        if (platform == 'macos' && filename != null)
          'SMT-Fusion-macos-universal.pkg',
        ?filename,
      ]) {
        final expected = Uri.parse(
          '$releaseRepository/releases/download/${Uri.encodeComponent(tag)}/$name',
        );
        for (final asset in assets) {
          if (asset is Map<String, dynamic> &&
              asset['name'] == name &&
              asset['state'] == 'uploaded' &&
              asset['size'] is int &&
              asset['size'] > 0 &&
              asset['size'] <= maxInstallerBytes &&
              asset['browser_download_url'] == expected.toString()) {
            installer = expected;
            size = asset['size'] as int;
            final hash = asset['digest'];
            if (hash is String &&
                RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(hash)) {
              digest = hash.substring(7);
            }
            break;
          }
        }
        if (installer != null) break;
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
        installerSize: size,
        sha256: digest,
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

  void cancel() {
    if (!_abort.isCompleted) _abort.complete();
    close();
  }

  /// Streams into a private temporary file, validates length and SHA-256, then
  /// renames. No partial file can be passed to the native installer.
  Future<DownloadedUpdate> download(
    AppRelease release, {
    required void Function(int received, int total) onProgress,
    void Function()? onVerify,
  }) async {
    if (!release.canInstall) {
      throw const UpdateException('此安装包缺少有效校验信息或不支持应用内安装，请稍后重试。');
    }
    final uri = release.installer!;
    final name = uri.pathSegments.last;
    final tag = release.page.pathSegments.last;
    if (uri.toString() !=
            '$releaseRepository/releases/download/${Uri.encodeComponent(tag)}/$name' ||
        ![
          'SMT-CHECK-Setup-x64.exe',
          'SMT-CHECK-Setup-arm64.exe',
          'SMT-CHECK-linux-amd64.deb',
          'SMT-CHECK-linux-arm64.deb',
          'SMT-Fusion-macos-universal.pkg',
        ].contains(name)) {
      throw const UpdateException('更新服务器返回的数据无效，请稍后重试。');
    }
    DownloadedUpdate? result;
    IOSink? sink;
    try {
      if (_closed) throw const UpdateCancelled();
      final dir =
          await (temporaryDirectory?.call() ??
              Directory.systemTemp.createTemp('smt-fusion-update-'));
      result = DownloadedUpdate(
        File('${dir.path}${Platform.pathSeparator}$name'),
        release,
      );
      sink = File('${result.file.path}.partial').openWrite();
      var target = uri;
      http.StreamedResponse? response;
      for (var hop = 0; hop < 6; hop++) {
        if (_closed) throw const UpdateCancelled();
        final request =
            http.AbortableRequest('GET', target, abortTrigger: _abort.future)
              ..followRedirects = false
              ..headers['User-Agent'] = 'SMT-Fusion-Updater';
        response = await client.send(request).timeout(timeout);
        if (![301, 302, 303, 307, 308].contains(response.statusCode)) break;
        final location = response.headers['location'];
        await response.stream.listen(null).cancel();
        if (location == null) throw const FormatException();
        target = target.resolve(location);
        if (target.scheme != 'https' ||
            target.userInfo.isNotEmpty ||
            target.port != 443 ||
            ![
              'github.com',
              'release-assets.githubusercontent.com',
              'objects.githubusercontent.com',
            ].contains(target.host)) {
          throw const FormatException();
        }
        response = null;
      }
      if (response == null || response.statusCode != 200) {
        throw const UpdateException('安装包下载失败，请检查网络后重试。');
      }
      if (response.contentLength != null &&
          response.contentLength != release.installerSize) {
        throw const UpdateException('安装包大小不符，请重新下载。');
      }
      var received = 0;
      var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
      onProgress(0, release.installerSize);
      await for (final chunk in response.stream.timeout(idleTimeout)) {
        if (_closed) throw const UpdateCancelled();
        received += chunk.length;
        if (received > release.installerSize) {
          throw const UpdateException('安装包大小不符，请重新下载。');
        }
        sink.add(chunk);
        await sink.flush();
        if (DateTime.now().difference(lastNotify).inMilliseconds >= 100 ||
            received == release.installerSize) {
          onProgress(received, release.installerSize);
          lastNotify = DateTime.now();
        }
      }
      await sink.close();
      sink = null;
      if (_closed) throw const UpdateCancelled();
      if (received != release.installerSize) {
        throw const UpdateException('安装包大小不符，请重新下载。');
      }
      final partial = File('${result.file.path}.partial');
      onVerify?.call();
      if ((await crypto.sha256.bind(partial.openRead()).first).toString() !=
          release.sha256) {
        throw const UpdateException('安装包校验失败，请重新下载。');
      }
      if (_closed) throw const UpdateCancelled();
      await partial.rename(result.file.path);
      return result;
    } catch (error) {
      try {
        await sink?.close();
      } catch (_) {
        /* Keep the original error. */
      }
      try {
        await result?.delete();
      } on FileSystemException {
        /* OS may still hold an aborted file briefly. */
      }
      if (_closed || error is http.RequestAbortedException) {
        throw const UpdateCancelled();
      }
      if (error is UpdateException) rethrow;
      if (error is FileSystemException) {
        throw const UpdateException('无法写入更新文件，请检查磁盘空间和权限。');
      }
      if (error is TimeoutException) {
        throw const UpdateException('安装包下载超时，请检查网络后重试。');
      }
      throw const UpdateException('安装包下载失败，请检查网络后重试。');
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (!_abort.isCompleted) _abort.complete();
    client.close();
  }
}
