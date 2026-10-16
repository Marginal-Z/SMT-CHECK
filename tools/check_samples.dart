import 'dart:io';
import 'dart:convert';

import 'package:smt_check/core/checker.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/xlsx_reader.dart';
import 'package:smt_check/services/report_export.dart';

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tools/check_samples.dart BOM.xlsx A.xlsx B.xlsx',
    );
    exitCode = 1;
    return;
  }
  final reader = XlsxReader();
  final bom = reader.read(args[0], InputKind.bom);
  final a = reader.read(args[1], InputKind.station, side: 'A');
  final b = reader.read(args[2], InputKind.station, side: 'B');
  final out = Directory('outputs')..createSync(recursive: true);
  for (final (name, stations) in [
    ('A+B', [a, b]),
    ('A', [a]),
    ('B', [b]),
  ]) {
    final report = Checker().run(bom, stations, const CheckRules());
    File('${out.path}/SMT-CHECK-$name.json')
        .writeAsStringSync(ReportExport.json(report));
    File('${out.path}/SMT-CHECK-$name.csv')
        .writeAsStringSync(ReportExport.csv(report));
    stdout.writeln(
      jsonEncode({
        'mode': name,
        'inputRows': [bom.rows.length, ...stations.map((s) => s.rows.length)],
        'summary': {
          for (final s in CheckStatus.values) s.name: report.count(s),
        },
        if (name == 'A+B')
          'errors': report.errors
              .map(
                (e) => {
                  'part': e.part,
                  'bom': e.bomQuantity,
                  'smt': e.smtQuantity,
                  'reasons': e.reasons,
                },
              )
              .toList(),
      }),
    );
  }
}
