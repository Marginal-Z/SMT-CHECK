import 'dart:isolate';
import 'dart:typed_data';

import '../core/checker.dart';
import '../core/models.dart';
import '../core/station_merge.dart';
import '../core/xlsx_reader.dart';
import 'merged_workbook_export.dart';
import 'source_analysis.dart';

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

Future<Uint8List> encodeMergedWorkbookInBackground(MergedStationFile file) =>
    Isolate.run(() => MergedWorkbookExport.encode(file));

Future<SourceAnalysisPlan> prepareSourceAnalysisInBackground(
  ImportedFile bom,
  List<ImportedFile> stations,
  CheckRules rules,
  int limit,
) => Isolate.run(() => prepareSourceAnalysis(bom, stations, rules, limit));
