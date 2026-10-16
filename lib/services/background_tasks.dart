import 'dart:isolate';

import '../core/checker.dart';
import '../core/models.dart';
import '../core/xlsx_reader.dart';

// Keep isolate closures out of State methods: their shared closure context can
// capture a Flutter element tree even when only local input names are used.
Future<ImportedFile> readWorkbookInBackground(
  String path,
  InputKind kind,
  String side,
) => Isolate.run(() => XlsxReader().read(path, kind, side: side));

Future<CheckReport> checkInBackground(
  ImportedFile bom,
  List<ImportedFile> stations,
  CheckRules rules,
) => Isolate.run(() => Checker().run(bom, stations, rules));
