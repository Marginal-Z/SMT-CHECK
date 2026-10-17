// PowerShell 7: dart run tools/verify_cad_samples.dart <A.xlsx> <B.xlsx> <report.json>
// Read-only real-data acceptance runner. Missing samples fail explicitly.
import 'dart:convert';
import 'dart:io';

import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/coordinate_comparison.dart';
import 'package:smt_check/core/coordinate_reader.dart';
import 'package:smt_check/services/coordinate_comparison_export.dart';

void main(List<String> args) {
  if (args.length != 3) {
    throw ArgumentError('Expected A.xlsx B.xlsx report.json');
  }
  final a = CoordinateReader().read(args[0], forComparison: true),
      b = CoordinateReader().read(args[1], forComparison: true);
  final r = CoordinateComparator.compare(
    a,
    b,
    const CoordinateCompareSettings(),
    unitA: CadUnit.mm,
    unitB: CadUnit.mm,
    frameConfirmed: true,
  );
  final shuffled = CoordinateComparator.compare(
    a,
    CoordinateImport(
      a.path,
      a.records.reversed.toList(),
      a.issues,
      unitHint: a.unitHint,
      sourceCount: a.sourceCount,
      fields: a.fields,
    ),
    const CoordinateCompareSettings(),
    unitA: CadUnit.mm,
    unitB: CadUnit.mm,
    frameConfirmed: true,
  );
  if (shuffled.items.any((i) => i.isError) ||
      shuffled.matched != a.records.length) {
    throw StateError('Order-independent self comparison failed');
  }
  if (a.totalCount != 447 ||
      b.totalCount != 446 ||
      r.matched != 446 ||
      r.missing != 1 ||
      r.added != 0 ||
      r.items.where((i) => i.isError).length != 1 ||
      r.items.singleWhere((i) => i.isError).reference != 'TP10_1') {
    throw StateError(
      'Unexpected real-sample differences: ${jsonEncode(coordinateComparisonJson(r))}',
    );
  }
  final tp = r.items.singleWhere((i) => i.reference == 'TP10_1');
  if (!tp.special.contains('TP')) {
    throw StateError('TP10_1 classification missing');
  }
  File(args[2]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(coordinateComparisonJson(r)),
  );
  stdout.writeln(
    'A=${a.totalCount}, B=${b.totalCount}, matched=${r.matched}, missing=${r.missing} (TP10_1), added=${r.added}; XY NG=${r.count(CadDifferenceType.coordinate)}, angle NG=${r.count(CadDifferenceType.angle)}, attributes NG=${r.count(CadDifferenceType.attribute)}; tolerance-only=${r.count(CadDifferenceType.precision)}; shuffled self-check PASS',
  );
}
