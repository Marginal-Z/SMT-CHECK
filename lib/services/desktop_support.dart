import 'dart:io';

const officialWebsite =
    'https://marginal-z.github.io/SMT-CHECK';

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
