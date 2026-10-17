import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/preferences_migration.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  var migrationFailed = false;
  try {
    await migrateWindowsPreferences();
  } catch (_) {
    migrationFailed = true;
  }
  runApp(
    SmtFusionApp(arguments: arguments, settingsMigrationFailed: migrationFailed),
  );
}
