import 'package:flutter_test/flutter_test.dart';
import 'package:smt_check/core/checker.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/positions.dart';
import 'package:smt_check/services/report_export.dart';

MaterialRow row(
  String part,
  String qty,
  String positions, {
  String desc = '电阻 10K',
  int line = 2,
  String file = 'input.xlsx',
  bool candidate = false,
  List<String> importIssues = const [],
}) => MaterialRow(
  part: part,
  description: desc,
  quantityText: qty,
  positionsText: positions,
  file: file,
  sheet: 'Sheet',
  row: line,
  candidate: candidate,
  importIssues: importIssues,
);
ImportedFile input(
  List<MaterialRow> rows, {
  bool bom = false,
  String path = 'a.xlsx',
}) => ImportedFile(path, bom ? InputKind.bom : InputKind.station, rows, [], []);
CheckReport check(
  List<MaterialRow> b,
  List<MaterialRow> s, {
  CheckRules rules = const CheckRules(),
}) => Checker().run(input(b, bom: true), [input(s)], rules);

void main() {
  test('part counts use the BOM/SMT union, deduplicate A+B and include audited rows', () {
    final report = Checker().run(
      input([
        row(' a ', '1', 'R1'),
        row('A', '1', 'R2'),
        row('BOM-ONLY', '1', 'C1'),
        row('PASTE', '0', '', desc: '锡膏'),
        row('  ', '1', 'C2'),
      ], bom: true),
      [
        input([
          row('A', '1', 'R1'),
          row('ALT', '', '', candidate: true),
          row('SMT-ONLY', '1', 'R3'),
        ], path: 'a.xlsx'),
        input([
          row('a', '1', 'R2'),
          row('ALT', '', '', candidate: true),
          row('PASTE', '.5', '', desc: '锡膏'),
        ], path: 'b.xlsx'),
      ],
      const CheckRules(),
    );
    expect(report.bomPartCount, 3);
    expect(report.smtPartCount, 4);
    expect(report.totalPartCount, 5);
    expect(report.count(CheckStatus.excluded), 2);
    expect(report.count(CheckStatus.candidate), 2);
    final item = report.items.firstWhere((i) => i.part == 'A');
    expect(item.bomPositions, 'R1\nR2');
    expect(item.smtPositions, 'R1\nR2');
    final summary = report.toJson()['summary'] as Map;
    expect(summary['totalPartCount'], 5);
    expect(summary['bomPartCount'], 3);
    expect(summary['smtPartCount'], 4);
    expect(
      ReportExport.csv(report),
      contains('"料号总数量","5","BOM料号数量","3","SMT站位表料号数量","4"'),
    );
  });
  test('keyword exclusions take priority and preserve all matches and import issues on both sources', () {
    final report = check(
      [
        row(
          'BOARD',
          '',
          '原始位号',
          desc: 'P C B 包装材料',
          importIssues: ['数量 含 Excel 错误值 #VALUE!'],
        ),
      ],
      [row('BOARD', '0', '', desc: 'pcb 包装材料', candidate: true)],
    );
    expect(report.errors, isEmpty);
    expect(report.count(CheckStatus.excluded), 2);
    expect(report.count(CheckStatus.candidate), 0);
    for (final item in report.items) {
      expect(item.excludedKeywords, ['PCB', '包装材料']);
      expect(item.reasons.first, contains('PCB、包装材料'));
    }
    final bom = report.items.firstWhere((i) => i.bom.isNotEmpty);
    expect(
      bom.reasons.last,
      contains('input.xlsx 第 2 行：数量 含 Excel 错误值 #VALUE!'),
    );
    expect(bom.bomPositions, '原始位号');
    expect(bom.toJson()['excludedKeywords'], ['PCB', '包装材料']);
    final disabled = check(
      bom.bom,
      [],
      rules: const CheckRules(excludeEnabled: false),
    );
    expect(disabled.errors, hasLength(1));
    expect(disabled.count(CheckStatus.excluded), 0);
  });
  test(
    'A+B aggregates shared parts and positions without counting candidates',
    () {
      final report = Checker().run(
        input([row('K1', '3', 'R1,R2,R3')], bom: true),
        [
          input([
            row('K1', '1', 'R1'),
            row('ALT', '', '', candidate: true),
          ], path: 'a.xlsx'),
          input([row('K1', '2', 'R3 R2')], path: 'b.xlsx'),
        ],
        const CheckRules(),
      );
      expect(report.count(CheckStatus.pass), 1);
      expect(report.count(CheckStatus.candidate), 1);
      expect(report.errors, isEmpty);
    },
  );
  test('bidirectional missing and extra material with source reasons', () {
    final report = check([row('A', '1', 'R1')], [row('B', '1', 'R2')]);
    expect(report.errors.length, 2);
    expect(report.errors.first.reasons.join(), contains('单站位表未覆盖'));
    expect(report.errors.last.reasons.join(), contains('站位表多料'));
  });
  test('same quantity but wrong positions fails', () {
    final item = check(
      [row('A', '2', 'R1 R2')],
      [row('A', '2', 'R1 R3')],
    ).errors.single;
    expect(item.missingPositions, ['R2']);
    expect(item.extraPositions, ['R3']);
  });
  test('same global positions owned by different parts fails both', () {
    final report = check(
      [row('A', '1', 'R1'), row('B', '1', 'R2')],
      [row('A', '1', 'R2'), row('B', '1', 'R1')],
    );
    expect(report.count(CheckStatus.pass), 0);
    expect(report.errors.length, 2);
  });
  test(
    'duplicate position across A+B cannot pass even when quantity sum matches',
    () {
      final report = Checker().run(input([row('A', '2', 'R1,R2')], bom: true), [
        input([row('A', '1', 'R1')], path: 'a'),
        input([row('A', '1', 'R1', line: 3)], path: 'b'),
      ], const CheckRules());
      expect(report.errors.single.reasons.join(), contains('跨行重复'));
    },
  );
  test('duplicate within row and row quantity mismatch are reported', () {
    final report = check([row('A', '2', 'R1 R2')], [row('A', '3', 'R1 R1')]);
    expect(report.errors.single.reasons.join(), contains('同一行重复'));
    expect(report.errors.single.reasons.join(), contains('与位号数'));
  });
  test('BOM shared designator flags both owners', () {
    final report = check(
      [row('A', '1', '4U1'), row('B', '1', '4U1', line: 3)],
      [row('A', '1', '4U1')],
    );
    expect(report.errors.length, 2);
    expect(report.errors.first.reasons.join(), contains('BOM 位号 4U1'));
  });
  test('normalizes whitespace and case but preserves tolerance and package differences', () {
    expect(
      check(
        [row('a', '1', 'R1', desc: 'RT0201\n10K ±5%')],
        [row('A', '1', 'R1', desc: 'rt0201 10k ±5%')],
      ).errors,
      isEmpty,
    );
    expect(
      check(
        [row('A', '1', 'R1', desc: 'RT0201 10K ±5%')],
        [row('A', '1', 'R1', desc: 'RT0201 10K +5%')],
      ).errors,
      hasLength(1),
    );
    expect(
      check(
        [row('A', '1', 'R1', desc: '1UH UR0420')],
        [row('A', '1', 'R1', desc: '1UH 4040')],
      ).errors,
      hasLength(1),
    );
  });
  test('exclusion keyword is editable and documented on each source', () {
    final r = check(
      [row('A', '.2', '', desc: '树脂碳带'), row('B', '1', 'R1')],
      [row('B', '1', 'R1')],
    );
    expect(r.count(CheckStatus.excluded), 1);
    expect(r.count(CheckStatus.pass), 1);
    expect(
      r.items
          .firstWhere((i) => i.status == CheckStatus.excluded)
          .reasons
          .single,
      contains('碳带'),
    );
    expect(
      check(
        [row('A', '.2', '', desc: '树脂碳带')],
        [],
        rules: const CheckRules(excludeEnabled: false),
      ).errors,
      hasLength(1),
    );
    expect(
      check(
        [row('A', '1', 'R1')],
        [],
        rules: const CheckRules(keywords: ['电阻']),
      ).count(CheckStatus.excluded),
      1,
    );
  });
  test('zero quantity placeholder only excludes when positions empty', () {
    expect(check([row('A', '0', '')], []).count(CheckStatus.excluded), 1);
    expect(
      check([row('A', '0', 'R1')], [row('A', '1', 'R1')]).errors,
      hasLength(1),
    );
  });
  test('candidate never silently replaces BOM primary part', () {
    final r = check(
      [row('A', '1', 'R1')],
      [row('A', '', '', candidate: true), row('B', '1', 'R1')],
    );
    expect(r.errors, hasLength(2));
    expect(r.count(CheckStatus.candidate), 1);
  });
  for (final qty in ['', 'NaN', 'Infinity', '-1', '一', '1,5']) {
    test('invalid quantity $qty remains an error and exports JSON', () {
      final r = check([row('A', '1', 'R1')], [row('A', qty, 'R1')]);
      expect(r.errors, hasLength(1));
      expect(() => ReportExport.json(r), returnsNormally);
    });
  }
  test('same file A+B blocked', () {
    final a = input([row('A', '1', 'R1')]);
    expect(
      () => Checker().run(input([], bom: true), [a, a], const CheckRules()),
      throwsArgumentError,
    );
  });
  test('CSV neutralizes formulas and retains original evidence in JSON', () {
    final r = check([row('=SUM(1)', '1', 'R1', desc: '@formula')], []);
    expect(ReportExport.csv(r), contains("'=SUM(1)"));
    expect(ReportExport.json(r), contains('=SUM(1)'));
  });
  test('T100 hard wraps reconstruct numeric and prefix continuations', () {
    final p = parsePositions('10C7,15C23,1\nC39,8R\n23,9C2\n0', bom: true);
    expect(p.values, ['10C7', '15C23', '1C39', '8R23', '9C20']);
    expect(p.issues, isEmpty);
    expect(parsePositions('R1\nR2', bom: true).values, ['R1', 'R2']);
  });
  test('designator suffixes, delimiters and ranges', () {
    final p = parsePositions('TP10_1，R1~R3；2R4-2R5、C1 C2');
    expect(p.values, ['TP10_1', 'R1', 'R2', 'R3', '2R4', '2R5', 'C1', 'C2']);
    expect(p.issues, isEmpty);
    expect(parsePositions('R4-R1').issues, isNotEmpty);
    expect(parsePositions('R1-C5').issues, isNotEmpty);
    expect(parsePositions('R1-R99999').issues, isNotEmpty);
    expect(parsePositions('未知').issues, isNotEmpty);
  });
}
