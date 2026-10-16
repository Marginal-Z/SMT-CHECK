import 'models.dart';
import 'positions.dart';

class Checker {
  CheckReport run(
    ImportedFile bom,
    List<ImportedFile> stations,
    CheckRules rules,
  ) {
    if (stations.isEmpty || stations.length > 2) {
      throw ArgumentError('需要一份或两份站位表');
    }
    if (stations
            .map((s) => s.path.replaceAll('\\', '/').toLowerCase())
            .toSet()
            .length !=
        stations.length) {
      throw ArgumentError('A、B 不可使用同一份文件，以免重复累计');
    }
    final b = <String, List<MaterialRow>>{},
        s = <String, List<MaterialRow>>{},
        items = <CheckItem>[];
    void collect(MaterialRow row, bool isBom) {
      final excluded = rules.exclusion(row);
      final matchedKeywords = rules.matchedKeywords(row);
      if (excluded != null &&
          (matchedKeywords.isNotEmpty || row.importIssues.isEmpty)) {
        items.add(
          CheckItem(
            part: row.part,
            status: CheckStatus.excluded,
            bom: isBom ? [row] : [],
            smt: isBom ? [] : [row],
            excludedKeywords: matchedKeywords,
            reasons: [
              excluded,
              ...row.importIssues.map(
                (issue) => '${row.file} 第 ${row.row} 行：$issue',
              ),
            ],
          ),
        );
      } else if (row.candidate) {
        items.add(
          CheckItem(
            part: row.part,
            status: CheckStatus.candidate,
            bom: [],
            smt: [row],
            reasons: ['无站位、数量和位号：候选替代料记录，不累计贴装数量；不自动认定为BOM料号替代。'],
          ),
        );
      } else {
        final key = normalizePart(row.part);
        (isBom ? b : s).putIfAbsent(key, () => []).add(row);
      }
    }

    for (final row in bom.rows) {
      collect(row, true);
    }
    for (final f in stations) {
      for (final row in f.rows) {
        collect(row, false);
      }
    }
    Map<String, List<MaterialRow>> owners(
      Iterable<MaterialRow> rows,
      bool bom,
    ) {
      final map = <String, List<MaterialRow>>{};
      for (final r in rows) {
        for (final p in parsePositions(r.positionsText, bom: bom).unique) {
          map.putIfAbsent(p, () => []).add(r);
        }
      }
      return map;
    }

    final bOwners = owners(b.values.expand((r) => r), true),
        sOwners = owners(s.values.expand((r) => r), false);
    for (final part in {...b.keys, ...s.keys}) {
      final br = b[part] ?? [], sr = s[part] ?? [], reasons = <String>[];
      if (part.isEmpty) {
        reasons.add('料号为空，无法关联核对');
      }
      if (br.isEmpty) {
        reasons.add('站位表多料：BOM 中没有该料号');
      }
      if (sr.isEmpty) {
        reasons.add(
          stations.length == 1
              ? '单站位表未覆盖此 BOM 料号；可能位于另一面，需完整站位资料确认'
              : 'BOM 有料，A+B 合并站位表缺少此料号',
        );
      }
      for (final group in [br, sr]) {
        for (final row in group) {
          final label = '${row.file} 第 ${row.row} 行';
          reasons.addAll(row.importIssues.map((i) => '$label：$i'));
          final qty = row.quantity;
          if (qty == null || !qty.isFinite || qty <= 0) {
            reasons.add('$label：数量「${row.quantityText}」不是有效正数');
          }
          if (row.description.trim().isEmpty) {
            reasons.add('$label：品名/物料描述为空');
          }
          final positions = parsePositions(row.positionsText, bom: group == br);
          reasons.addAll(positions.issues.map((i) => '$label：$i'));
          if (positions.values.isEmpty) {
            reasons.add('$label：没有有效位号，请确认是否为非贴片物料或资料缺失');
          }
          if (qty != null &&
              positions.values.isNotEmpty &&
              (qty - positions.values.length).abs() > 0.000001) {
            reasons.add(
              '$label：数量 ${numberText(qty)} 与位号数 ${positions.values.length} 不一致',
            );
          }
          for (final p in positions.unique) {
            final own = (group == br ? bOwners : sOwners)[p]!;
            if (own.length > 1) {
              reasons.add(
                '${group == br ? 'BOM' : 'SMT'} 位号 $p 跨行重复/冲突：${own.map((o) => '${o.part}（${o.side} ${o.sheet}:${o.row}）').join('、')}',
              );
            }
          }
        }
      }
      double? sum(List<MaterialRow> rows) =>
          rows.isEmpty || rows.any((r) => r.quantity == null)
          ? null
          : rows.fold<double>(0, (n, r) => n + r.quantity!);
      final bq = sum(br), sq = sum(sr);
      if (bq != null && sq != null && (bq - sq).abs() > 0.000001) {
        reasons.add(
          '数量不符：BOM ${numberText(bq)}，SMT ${numberText(sq)}，差额 ${numberText(sq - bq)}（SMT − BOM）',
        );
      }
      final bd = br.map((r) => normalizeDescription(r.description)).toSet();
      final sd = sr.map((r) => normalizeDescription(r.description)).toSet();
      if (br.isNotEmpty &&
          sr.isNotEmpty &&
          (bd.length != 1 || sd.length != 1 || bd.single != sd.single)) {
        reasons.add('品名/物料描述不一致（仅忽略大小写和空白，未自动认定规格或品牌等效）');
      }
      final bp = br
          .expand((r) => parsePositions(r.positionsText, bom: true).values)
          .toSet();
      final sp = sr
          .expand((r) => parsePositions(r.positionsText).values)
          .toSet();
      final missing = bp.difference(sp).toList()..sort(),
          extra = sp.difference(bp).toList()..sort();
      if (missing.isNotEmpty) {
        reasons.add('SMT 缺少位号：${missing.join('、')}');
      }
      if (extra.isNotEmpty) {
        reasons.add('SMT 多出位号：${extra.join('、')}');
      }
      items.add(
        CheckItem(
          part: part,
          status: reasons.isEmpty ? CheckStatus.pass : CheckStatus.error,
          bom: br,
          smt: sr,
          reasons: reasons.isEmpty
              ? ['料号、描述、汇总数量与位号集合全部一致']
              : reasons.toSet().toList(),
          missingPositions: missing,
          extraPositions: extra,
        ),
      );
    }
    items.sort(
      (a, b) => a.status != b.status
          ? a.status.displayOrder.compareTo(b.status.displayOrder)
          : a.part.compareTo(b.part),
    );
    return CheckReport(items, rules, stations.length == 2, [bom, ...stations]);
  }
}
