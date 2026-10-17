import 'dart:io';

import 'update_service.dart';

typedef InstallerCommand = Future<int> Function(
  String executable,
  List<String> arguments,
  bool detached,
);

/// Uses the platform installer. Download/verification never opens a web page.
/// Package IDs, executable names and preferences retain their upgrade identity.
class UpdateInstaller {
  final String platform;
  final String executable;
  final InstallerCommand? command;
  UpdateInstaller({String? platform, String? executable, this.command})
    : platform = platform ?? Platform.operatingSystem,
      executable = executable ?? Platform.resolvedExecutable;

  Future<int> _run(
    String binary,
    List<String> args, {
    bool detached = false,
  }) async {
    if (command != null) return command!(binary, args, detached);
    if (detached) {
      await Process.start(binary, args, mode: ProcessStartMode.detached);
      return 0;
    }
    final result = await Process.run(binary, args);
    return result.exitCode;
  }

  /// Windows hands off to Setup and quits; Linux/macOS wait for the system's
  /// authorization and installer, then offer an explicit restart.
  Future<bool> install(DownloadedUpdate update) async {
    try {
      await update.verify(); // Recheck immediately before execution (TOCTOU).
      final path = update.file.path;
      final name = update.release.installer!.pathSegments.last;
      int status;
      switch (platform) {
        case 'windows':
          if (!name.endsWith('.exe')) {
            throw const UpdateException('安装包与当前平台不匹配。');
          }
          final installedDir = File(executable).parent;
          final installed = await File(
            '${installedDir.path}${Platform.pathSeparator}unins000.exe',
          ).exists();
          status = await _run(path, [
            '/SILENT',
            '/NORESTART',
            '/NOCLOSEAPPLICATIONS',
            '/NOFORCECLOSEAPPLICATIONS',
            '/SMTFUSIONUPDATE=1',
            '/LOG=${update.file.parent.path}${Platform.pathSeparator}install.log',
            if (installed) '/DIR=${installedDir.path}',
          ], detached: true);
        case 'linux':
          if (!name.endsWith('.deb')) {
            throw const UpdateException('安装包与当前平台不匹配。');
          }
          status = await _run('/usr/bin/pkexec', ['/usr/bin/dpkg', '-i', path]);
        case 'macos':
          if (!name.endsWith('.pkg')) {
            throw const UpdateException('安装包与当前平台不匹配。');
          }
          // AppleScript quotes the path as data; no interpolation into shell code.
          status = await _run('/usr/bin/osascript', [
            '-e',
            'on run argv\n do shell script "/usr/sbin/installer -pkg " & quoted form of (item 1 of argv) & " -target /" with administrator privileges\nend run',
            path,
          ]);
        default:
          throw const UpdateException('当前平台暂不支持应用内安装。');
      }
      if (status != 0) throw const UpdateException('安装未完成或已取消，请重试并允许系统安装授权。');
      return platform == 'windows';
    } on UpdateException {
      rethrow;
    } on FileSystemException {
      throw const UpdateException('安装包已丢失或无法读取，请重新下载。');
    } on ProcessException {
      throw const UpdateException('无法启动系统安装程序，请检查系统权限和安装服务。');
    }
  }

  Future<void> restart() async {
    try {
      final code = switch (platform) {
        'macos' => await _run('/usr/bin/open', [
          '-n',
          '/Applications/SMT-CHECK.app',
        ], detached: true),
        'linux' => await _run('/opt/smt-check/SMT-CHECK', [], detached: true),
        _ => throw const UpdateException('当前平台暂不支持应用内安装。'),
      };
      if (code != 0) {
        throw const UpdateException('无法重新启动应用，请从系统菜单打开 SMT Fusion。');
      }
    } on ProcessException {
      throw const UpdateException('无法重新启动应用，请从系统菜单打开 SMT Fusion。');
    }
  }
}
