import 'dart:async';
import 'dart:io';

const officialWebsite =
    'https://smt-fusion-desktop.yy19273767397472432.chatgpt.site';

Future<void> repairDesktopIcons() async {
  if (!Platform.isWindows) throw const FormatException('此功能仅适用于 Windows。');
  final process = await Process.start(Platform.resolvedExecutable, [
    '--repair-icons',
  ]);
  unawaited(process.stdout.drain<void>());
  unawaited(process.stderr.drain<void>());
  final result = await process.exitCode.timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      process.kill();
      throw const FormatException('图标刷新超时，请重试。');
    },
  );
  if (result != 0) throw const FormatException('部分图标无法刷新，请检查快捷方式权限。');
}

Future<void> openDocumentation({
  bool guide = false,
  String language = 'zh',
}) async {
  final locale = const ['zh', 'en', 'th'].contains(language) ? language : 'zh';
  final url = '$officialWebsite${guide ? '/guide.html' : '/'}?lang=$locale';
  final (command, args) = Platform.isWindows
      ? (
          '${Platform.environment['SystemRoot'] ?? r'C:\Windows'}\\System32\\rundll32.exe',
          ['url.dll,FileProtocolHandler', url],
        )
      : Platform.isMacOS
      ? ('/usr/bin/open', [url])
      : ('/usr/bin/xdg-open', [url]);
  final result = await Process.run(
    command,
    args,
  ).timeout(const Duration(seconds: 15));
  if (result.exitCode != 0) {
    throw const FormatException('无法打开浏览器，请检查系统默认浏览器设置。');
  }
}
