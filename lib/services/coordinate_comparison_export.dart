import 'dart:convert';

import '../core/cad_coordinates.dart';
import '../core/coordinate_comparison.dart';

Map<String, Object?> coordinateComparisonJson(CoordinateComparison r) {
  Map<String, Object?> source(CoordinateRecord row) => {
    'ref': row.reference,
    'board': row.board,
    'layer': row.layer,
    'x': row.xText,
    'y': row.yText,
    'angle': row.angleText,
    'partType': row.partType,
    'partDecal': row.decal,
    'pins': row.pins,
    'file': row.file,
    'sheet': row.sheet,
    'row': row.row,
    'raw': row.raw,
  };
  return {
    'version': 1,
    'a': r.a.path,
    'b': r.b.path,
    'unitA': r.unitA?.name,
    'unitB': r.unitB?.name,
    'frameConfirmed': r.frameConfirmed,
    'settings': jsonDecode(r.settings.encode()),
    'countA': r.a.totalCount,
    'countB': r.b.totalCount,
    'matched': r.matched,
    'missing': r.missing,
    'added': r.added,
    'orderChanged': r.orderChanged,
    'repeatedReferencesA': r.repeatedReferences(true),
    'repeatedReferencesB': r.repeatedReferences(false),
    'decisionHistory': [
      for (final (item, decision) in r.decisionHistory)
        {
          'reference': item.reference,
          'sourcesA': item.a.map(source).toList(),
          'sourcesB': item.b.map(source).toList(),
          'excluded': decision.excluded,
          'reason': decision.reason,
          'at': decision.at.toIso8601String(),
        },
    ],
    'items': [
      for (final item in r.items)
        {
          'reference': item.reference,
          'status': item.status,
          'special': item.special,
          'a': item.a.map(source).toList(),
          'b': item.b.map(source).toList(),
          'differences': [
            for (final d in item.differences)
              {
                'type': d.type.name,
                'field': d.field,
                'a': d.a,
                'b': d.b,
                'delta': d.delta,
                'messageMask': d.messageMask,
              },
          ],
          'issues': [
            for (final i in item.issues)
              {
                'reason': i.reason,
                'blocking': i.blocking,
                'file': i.file,
                'sheet': i.sheet,
                'row': i.row,
                'raw': i.raw,
              },
          ],
          if (r.decisions[item] case final decision?)
            'decision': {
              'excluded': decision.excluded,
              'reason': decision.reason,
              'at': decision.at.toIso8601String(),
            },
        },
    ],
  };
}
