import 'dart:convert';
import 'dart:io';

/// ProductName is used by path_provider_windows. Copy the legacy store only
/// when no Fusion store exists; never overwrite preferences from a newer run.
Future<void> migrateWindowsPreferences({String? roamingDirectory}) async {
  if (!Platform.isWindows && roamingDirectory == null) return;
  final roaming = roamingDirectory ?? Platform.environment['APPDATA'];
  if (roaming == null || roaming.isEmpty) return;
  final company = Directory('$roaming${Platform.pathSeparator}com.smtcheck');
  final old = File(
    '${company.path}${Platform.pathSeparator}SMT-CHECK${Platform.pathSeparator}shared_preferences.json',
  );
  final target = File(
    '${company.path}${Platform.pathSeparator}SMT Fusion${Platform.pathSeparator}shared_preferences.json',
  );
  if (await target.exists() || !await old.exists()) return;
  await target.parent.create(recursive: true);
  final lock = await File(
    '${target.parent.path}${Platform.pathSeparator}.migration.lock',
  ).open(mode: FileMode.append);
  File? staged;
  try {
    await lock.lock(FileLock.exclusive);
    if (await target.exists()) return;
    if (await old.length() > 1024 * 1024) {
      throw const FormatException('Legacy settings exceed the allowed size.');
    }
    final bytes = await old.readAsBytes();
    if (jsonDecode(utf8.decode(bytes)) is! Map<String, dynamic>) {
      throw const FormatException('Legacy settings are invalid.');
    }
    staged = File(
      '${target.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await staged.create(exclusive: true);
    await staged.writeAsBytes(bytes, flush: true);
    await staged.rename(target.path);
  } finally {
    if (staged != null && await staged.exists()) await staged.delete();
    await lock.close();
  }
}
