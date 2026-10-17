import 'dart:convert';

import 'cad_coordinates.dart';
import 'cad_decimal.dart';
import 'special_pattern.dart';

final _specialPatterns = Expando<Map<String, SpecialPattern>>();

enum SpecialAction { retain, exclude, review }

enum CadDifferenceType {
  missing('文件 B 缺失'),
  added('文件 B 新增'),
  duplicate('重复或歧义'),
  quality('数据质量'),
  coordinate('坐标异常'),
  angle('角度异常'),
  layer('层别异常'),
  attribute('属性不一致'),
  precision('容差内差异');

  final String label;
  const CadDifferenceType(this.label);
}

/// All populated predicates must match the entire field. No contains heuristic.
class SpecialRule {
  final String category, reference, partType, decal;
  final SpecialAction action;
  const SpecialRule(
    this.category, {
    this.reference = '',
    this.partType = '',
    this.decal = '',
    this.action = SpecialAction.retain,
  });
  void validate() {
    if (category.trim().isEmpty ||
        [reference, partType, decal].every((v) => v.isEmpty)) {
      throw const FormatException('特殊元件规则需要类别和至少一个匹配条件');
    }
    for (final pattern in [
      reference,
      partType,
      decal,
    ].where((p) => p.isNotEmpty)) {
      final compiled = _specialPatterns[this] ??= {};
      compiled.putIfAbsent(pattern, () => SpecialPattern(pattern));
    }
  }

  bool matches(CoordinateRecord r) {
    bool match(String pattern, String value) {
      if (pattern.isEmpty) return true;
      final compiled = _specialPatterns[this] ??= {};
      return compiled
          .putIfAbsent(pattern, () => SpecialPattern(pattern))
          .matches(value.trim());
    }

    return match(reference, r.reference) &&
        match(partType, r.partType) &&
        match(decal, r.decal);
  }

  Map<String, String> toJson() => {
    'category': category,
    'reference': reference,
    'partType': partType,
    'decal': decal,
    'action': action.name,
  };
  static SpecialRule fromJson(Map<String, dynamic> j) {
    final r = SpecialRule(
      j['category'] as String,
      reference: j['reference'] as String? ?? '',
      partType: j['partType'] as String? ?? '',
      decal: j['decal'] as String? ?? '',
      action: SpecialAction.values.byName(j['action'] as String? ?? 'retain'),
    );
    r.validate();
    return r;
  }
}

const defaultSpecialRules = [
  SpecialRule('TP', reference: r'[0-9]*TP[0-9]+[_0-9A-Z]*'),
  SpecialRule('TP', partType: r'TP|TESTPOINT|TEST_POINT|TEST-POINT'),
  SpecialRule('FID', reference: r'[0-9]*FID[0-9]+[_0-9A-Z]*'),
  SpecialRule('FID', partType: r'FID|FIDUCIAL|MARK'),
  SpecialRule('MH', reference: r'[0-9]*MH[0-9]+[_0-9A-Z]*'),
  SpecialRule('MH', partType: r'MH|MOUNTING_HOLE'),
  SpecialRule('NPTH', reference: r'[0-9]*NPTH[0-9]+[_0-9A-Z]*'),
  SpecialRule('NPTH', decal: r'NPTH|NPTH_[0-9.]+'),
];

class CoordinateCompareSettings {
  final String xyTolerance, angleTolerance;
  final List<SpecialRule> specialRules;
  const CoordinateCompareSettings({
    this.xyTolerance = '0.001',
    this.angleTolerance = '0.001',
    this.specialRules = defaultSpecialRules,
  });
  void validate() {
    for (final value in [xyTolerance, angleTolerance]) {
      final n = CadDecimal.parse(value);
      if (n.compareTo(CadDecimal.parse('0')) < 0 ||
          n.compareTo(CadDecimal.parse('1000000')) > 0) {
        throw const FormatException('比较容差必须为 0 至 1000000 的有限数值');
      }
    }
    if (specialRules.length > 100) {
      throw const FormatException('特殊元件规则最多 100 条');
    }
    for (final r in specialRules) {
      r.validate();
    }
  }

  String encode() => jsonEncode({
    'xy': xyTolerance,
    'angle': angleTolerance,
    'rules': specialRules.map((r) => r.toJson()).toList(),
  });
  static CoordinateCompareSettings decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    final s = CoordinateCompareSettings(
      xyTolerance: j['xy'] as String,
      angleTolerance: j['angle'] as String,
      specialRules: (j['rules'] as List)
          .map((r) => SpecialRule.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
    s.validate();
    return s;
  }

  List<SpecialRule> classify(CoordinateRecord r) =>
      specialRules.where((rule) => rule.matches(r)).toList();
}

class CadDifference {
  final CadDifferenceType type;
  final String field, a, b, delta;
  // Bit 1/2 marks generated A/B messages; raw Excel values are never translated.
  final int messageMask;
  const CadDifference(
    this.type,
    this.field,
    this.a,
    this.b, [
    this.delta = '',
    this.messageMask = 0,
  ]);
}

class CoordinateDifferenceItem {
  final List<CoordinateRecord> a, b;
  final List<CadDifference> differences;
  final List<CadIssue> issues;
  final List<String> special;
  final String referenceHint;
  final bool numericPending;
  const CoordinateDifferenceItem(
    this.a,
    this.b,
    this.differences, {
    this.issues = const [],
    this.special = const [],
    this.referenceHint = '',
    this.numericPending = false,
  });
  String get reference =>
      a.firstOrNull?.reference ??
      b.firstOrNull?.reference ??
      issues.firstOrNull?.reference ??
      referenceHint;
  bool get isError =>
      issues.any((i) => i.blocking) ||
      differences.any((d) => d.type != CadDifferenceType.precision);
  bool get paired =>
      a.length == 1 &&
      b.length == 1 &&
      !differences.any((d) => d.type == CadDifferenceType.duplicate);
  String get status => isError
      ? 'NG'
      : numericPending
      ? '待确认'
      : 'PASS';
}

class SpecialDecision {
  final bool excluded;
  final String reason;
  final DateTime at;
  SpecialDecision(this.excluded, this.reason) : at = DateTime.now();
}

class CoordinateComparison {
  final CoordinateImport a, b;
  final List<CoordinateDifferenceItem> items;
  final bool frameConfirmed, orderChanged;
  final CadUnit? unitA, unitB;
  final CoordinateCompareSettings settings;
  // Explicit session decisions retain original differences and source records.
  final Map<CoordinateDifferenceItem, SpecialDecision> decisions = {};
  final List<(CoordinateDifferenceItem, SpecialDecision)> decisionHistory = [];
  CoordinateComparison(
    this.a,
    this.b,
    this.items,
    this.frameConfirmed,
    this.orderChanged,
    this.unitA,
    this.unitB,
    this.settings,
  );
  int get matched => items.where((i) => i.paired).length;
  int get missing => items
      .where(
        (i) => i.differences.any((d) => d.type == CadDifferenceType.missing),
      )
      .fold(0, (n, i) => n + i.a.length);
  int get added => items
      .where((i) => i.differences.any((d) => d.type == CadDifferenceType.added))
      .fold(0, (n, i) => n + i.b.length);
  int count(CadDifferenceType type) =>
      items.where((i) => i.differences.any((d) => d.type == type)).length;
  bool reviewPending(CoordinateDifferenceItem item) =>
      !decisions.containsKey(item) &&
      [...item.a, ...item.b]
          .expand(settings.classify)
          .any((rule) => rule.action != SpecialAction.retain);
  String displayStatus(CoordinateDifferenceItem item) =>
      decisions[item]?.excluded == true
      ? '已排除物料'
      : reviewPending(item)
      ? '待人工确认'
      : item.status;
  int specialCount(bool sideA) => (sideA ? a : b).records
      .where((r) => settings.classify(r).isNotEmpty)
      .length;
  int repeatedReferences(bool sideA) {
    final sources = <String, Set<String>>{};
    final input = sideA ? a : b;
    for (final row in input.records) {
      sources
          .putIfAbsent(row.reference.trim().toUpperCase(), () => {})
          .add('${row.sheet}:${row.row}');
    }
    for (final issue in input.issues.where((i) => i.reference.isNotEmpty)) {
      sources
          .putIfAbsent(issue.reference.trim().toUpperCase(), () => {})
          .add('${issue.sheet}:${issue.row}');
    }
    return sources.values.where((s) => s.length > 1).length;
  }

  void decide(CoordinateDifferenceItem item, bool exclude, String reason) {
    if (!items.contains(item) ||
        item.special.isEmpty ||
        reason.trim().isEmpty) {
      throw const FormatException('特殊元件操作需要填写原因');
    }
    final decision = SpecialDecision(exclude, reason.trim());
    decisions[item] = decision;
    decisionHistory.add((item, decision));
  }
}

class CoordinateComparator {
  static CoordinateComparison compare(
    CoordinateImport a,
    CoordinateImport b,
    CoordinateCompareSettings settings, {
    CadUnit? unitA,
    CadUnit? unitB,
    bool frameConfirmed = false,
  }) {
    settings.validate();
    final ready =
        frameConfirmed &&
        unitA != null &&
        unitB != null &&
        ![...a.issues, ...b.issues].any((i) => i.code == 'unit');
    final items = <CoordinateDifferenceItem>[];
    String norm(String s) => s.trim().toUpperCase();
    List<String> special(List<CoordinateRecord> rows) =>
        rows.expand(settings.classify).map((r) => r.category).toSet().toList();
    void add(
      List<CoordinateRecord> aa,
      List<CoordinateRecord> bb, {
      bool ambiguous = false,
      String referenceHint = '',
    }) {
      final diffs = <CadDifference>[];
      if (ambiguous) {
        diffs.add(
          CadDifference(
            CadDifferenceType.duplicate,
            'RefDes / Board / Layer',
            '${aa.length}',
            '${bb.length}',
          ),
        );
      } else if (aa.isEmpty || bb.isEmpty) {
        diffs.add(
          CadDifference(
            aa.isEmpty ? CadDifferenceType.added : CadDifferenceType.missing,
            'RefDes',
            aa.firstOrNull?.reference ?? '',
            bb.firstOrNull?.reference ?? '',
          ),
        );
      } else {
        final x = aa.single, y = bb.single;
        if (norm(x.layer) != norm(y.layer)) {
          diffs.add(
            CadDifference(CadDifferenceType.layer, 'Layer', x.layer, y.layer),
          );
        }
        for (final (field, v1, v2) in [
          ('PartDecal', x.decal, y.decal),
          ('PartType', x.partType, y.partType),
          ('Pins', '${x.pins}', '${y.pins}'),
        ]) {
          final key = switch (field) {
            'PartDecal' => 'decal',
            'PartType' => 'type',
            _ => 'pins',
          };
          final hasA = a.fields.isEmpty || a.fields.contains(key),
              hasB = b.fields.isEmpty || b.fields.contains(key);
          if (!hasA || !hasB) {
            diffs.add(
              CadDifference(
                CadDifferenceType.quality,
                field,
                hasA ? v1 : '缺少字段',
                hasB ? v2 : '缺少字段',
                '',
                (hasA ? 0 : 1) | (hasB ? 0 : 2),
              ),
            );
          } else if (norm(v1) != norm(v2)) {
            diffs.add(
              CadDifference(CadDifferenceType.attribute, field, v1, v2),
            );
          }
        }
        if (ready) {
          try {
            CadDecimal mm(String value, CadUnit unit) =>
                CadDecimal.parse(value) *
                CadDecimal.parse(switch (unit) {
                  CadUnit.mm => '1',
                  CadUnit.mil => '0.0254',
                  CadUnit.inch => '25.4',
                });
            for (final (field, v1, v2) in [
              ('X', x.xText, y.xText),
              ('Y', x.yText, y.yText),
            ]) {
              final delta = mm(v2, unitB) - mm(v1, unitA);
              if (delta.abs.compareTo(CadDecimal.parse(settings.xyTolerance)) >
                  0) {
                diffs.add(
                  CadDifference(
                    CadDifferenceType.coordinate,
                    field,
                    v1,
                    v2,
                    '$delta mm',
                  ),
                );
              } else if (delta.value != BigInt.zero) {
                diffs.add(
                  CadDifference(
                    CadDifferenceType.precision,
                    field,
                    v1,
                    v2,
                    '$delta mm',
                  ),
                );
              }
            }
            final full = CadDecimal.parse('360');
            var delta =
                (CadDecimal.parse(y.angleText) - CadDecimal.parse(x.angleText))
                    .mod(full);
            if (delta.compareTo(CadDecimal.parse('180')) > 0) {
              delta = delta - full;
            }
            if (delta.abs.compareTo(CadDecimal.parse(settings.angleTolerance)) >
                0) {
              diffs.add(
                CadDifference(
                  CadDifferenceType.angle,
                  'Orient.',
                  x.angleText,
                  y.angleText,
                  '$delta°',
                ),
              );
            } else if (delta.value != BigInt.zero || x.angle != y.angle) {
              diffs.add(
                CadDifference(
                  CadDifferenceType.precision,
                  'Orient.',
                  x.angleText,
                  y.angleText,
                  '$delta°',
                ),
              );
            }
          } on FormatException catch (e) {
            diffs.add(
              CadDifference(CadDifferenceType.quality, e.message, '', ''),
            );
          }
        }
      }
      items.add(
        CoordinateDifferenceItem(
          List.unmodifiable(aa),
          List.unmodifiable(bb),
          List.unmodifiable(diffs),
          special: special([...aa, ...bb]),
          referenceHint: referenceHint,
          numericPending:
              !ready && !ambiguous && aa.isNotEmpty && bb.isNotEmpty,
        ),
      );
    }

    Map<String, List<CoordinateRecord>> group(
      Iterable<CoordinateRecord> rows,
      String Function(CoordinateRecord) key,
    ) {
      final groups = <String, List<CoordinateRecord>>{};
      for (final r in rows) {
        groups.putIfAbsent(key(r), () => []).add(r);
      }
      return groups;
    }

    final ga = group(a.records, (r) => norm(r.reference)),
        gb = group(b.records, (r) => norm(r.reference));
    final attachedIssues = <CadIssue>{};
    for (final ref in {
      ...ga.keys,
      ...gb.keys,
      ...[
        ...a.issues,
        ...b.issues,
      ].where((i) => i.reference.isNotEmpty).map((i) => norm(i.reference)),
    }.toList()..sort()) {
      final aa = ga[ref] ?? [], bb = gb[ref] ?? [];
      // Invalid rows must still prevent a valid row with that identity being
      // paired silently. Their raw source data remains in separate quality rows.
      if ([
        ...a.issues,
        ...b.issues,
      ].any((i) => i.code == 'duplicate' && norm(i.reference) == ref)) {
        add(aa, bb, ambiguous: true, referenceHint: ref);
        continue;
      }
      final invalidA = a.issues
          .where(
            (i) =>
                norm(i.reference) == ref && (aa.isEmpty || i.code == 'record'),
          )
          .toList();
      final invalidB = b.issues
          .where(
            (i) =>
                norm(i.reference) == ref && (bb.isEmpty || i.code == 'record'),
          )
          .toList();
      if (invalidA.isNotEmpty || invalidB.isNotEmpty) {
        final issues = [...invalidA, ...invalidB];
        attachedIssues.addAll(issues);
        items.add(
          CoordinateDifferenceItem(
            aa,
            bb,
            [
              CadDifference(
                CadDifferenceType.quality,
                'RefDes',
                invalidA.isNotEmpty ? '数据质量' : aa.firstOrNull?.reference ?? '',
                invalidB.isNotEmpty ? '数据质量' : bb.firstOrNull?.reference ?? '',
                '',
                (invalidA.isNotEmpty ? 1 : 0) | (invalidB.isNotEmpty ? 2 : 0),
              ),
            ],
            issues: issues,
            special: special([...aa, ...bb]),
            referenceHint: ref,
          ),
        );
        continue;
      }
      final boardsA = group(aa, (r) => norm(r.board)),
          boardsB = group(bb, (r) => norm(r.board));
      // Missing board metadata in a repeated/panel group must never be guessed.
      if ((aa.length > 1 || bb.length > 1) &&
          ((boardsA.containsKey('') && boardsB.keys.any((k) => k.isNotEmpty)) ||
              (boardsB.containsKey('') &&
                  boardsA.keys.any((k) => k.isNotEmpty)))) {
        add(aa, bb, ambiguous: true);
        continue;
      }
      if (aa.length == 1 &&
          bb.length == 1 &&
          norm(aa.single.board) != norm(bb.single.board) &&
          (aa.single.board.isEmpty || bb.single.board.isEmpty)) {
        add(aa, bb, ambiguous: true);
        continue;
      }
      for (final board in {...boardsA.keys, ...boardsB.keys}) {
        final ba = boardsA[board] ?? [], bc = boardsB[board] ?? [];
        if (ba.length <= 1 && bc.length <= 1) {
          add(ba, bc);
          continue;
        }
        final la = group(ba, (r) => norm(r.layer)),
            lb = group(bc, (r) => norm(r.layer));
        for (final layer in {...la.keys, ...lb.keys}) {
          final pa = la[layer] ?? [], pb = lb[layer] ?? [];
          add(pa, pb, ambiguous: pa.length > 1 || pb.length > 1);
        }
      }
    }
    for (final (input, side) in [(a, true), (b, false)]) {
      final groups = <String, List<CadIssue>>{};
      for (final issue in input.issues) {
        if (attachedIssues.contains(issue)) continue;
        groups.putIfAbsent('${issue.sheet}:${issue.row}', () => []).add(issue);
      }
      for (final issues in groups.values) {
        items.add(
          CoordinateDifferenceItem(const [], const [], [
            CadDifference(CadDifferenceType.quality, side ? 'A' : 'B', '', ''),
          ], issues: issues),
        );
      }
    }
    final seqA = a.records
        .map((r) => '${norm(r.reference)}|${norm(r.board)}|${norm(r.layer)}')
        .toList();
    final seqB = b.records
        .map((r) => '${norm(r.reference)}|${norm(r.board)}|${norm(r.layer)}')
        .toList();
    final shared = seqA.toSet().intersection(seqB.toSet());
    final orderA = seqA.where(shared.contains).join('\n'),
        orderB = seqB.where(shared.contains).join('\n');
    return CoordinateComparison(
      a,
      b,
      List.unmodifiable(items),
      ready,
      orderA != orderB,
      unitA,
      unitB,
      settings,
    );
  }
}
