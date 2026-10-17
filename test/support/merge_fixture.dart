import 'package:smt_check/core/models.dart';

MaterialRow sourceRow(
  String part,
  String quantity,
  String positions, {
  String description = '电阻 10K',
  String side = 'A',
  int line = 2,
}) => MaterialRow(
  part: part,
  description: description,
  quantityText: quantity,
  positionsText: positions,
  file: '$side.xlsx',
  sheet: 'SMT',
  row: line,
  side: side,
);

CheckReport mergeReport() {
  final passA = sourceRow('00123', '1', 'R1');
  final passB = sourceRow('00123', '1', 'R2', side: 'B');
  final ng = sourceRow('NG-PART', '2', 'C1', line: 3);
  final excluded = sourceRow('PASTE', '.5', '', description: '锡膏', line: 4);
  final candidate = sourceRow(
    'ALT',
    '',
    '',
    description: '备用电阻',
    side: 'B',
    line: 3,
  );
  CheckItem item(CheckStatus status, List<MaterialRow> rows, String reason) =>
      CheckItem(
        part: rows.first.part,
        status: status,
        bom: [],
        smt: rows,
        reasons: [reason],
      );
  return CheckReport(
    [
      item(CheckStatus.pass, [passA, passB], 'PASS'),
      item(CheckStatus.error, [ng], '数量 2 与位号数 1 不一致'),
      item(CheckStatus.excluded, [excluded], '命中排除关键词'),
      item(CheckStatus.candidate, [candidate], '候选替代料'),
    ],
    const CheckRules(),
    true,
    [
      const ImportedFile('BOM.xlsx', InputKind.bom, [], [], []),
      ImportedFile('A.xlsx', InputKind.station, [passA, ng, excluded], [], []),
      ImportedFile('B.xlsx', InputKind.station, [passB, candidate], [], []),
    ],
  );
}
