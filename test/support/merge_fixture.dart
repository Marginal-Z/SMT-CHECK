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

CheckReport singleReport({bool allPass = false}) {
  final pass = sourceRow('00123', '1', 'R1');
  final ng = sourceRow('NG', '2', 'C1', line: 3);
  final excluded = sourceRow('PASTE', '.5', '', description: '锡膏', line: 4);
  final candidate = sourceRow('ALT', '', '', line: 5);
  final rows = [
    pass,
    if (!allPass) ...[ng, excluded, candidate],
  ];
  CheckItem item(CheckStatus status, MaterialRow row) => CheckItem(
    part: row.part,
    status: status,
    bom: [],
    smt: [row],
    reasons: ['复核'],
  );
  return CheckReport(
    [
      item(CheckStatus.pass, pass),
      if (!allPass) ...[
        item(CheckStatus.error, ng),
        item(CheckStatus.excluded, excluded),
        item(CheckStatus.candidate, candidate),
        CheckItem(
          part: 'OTHER-SIDE',
          status: CheckStatus.error,
          bom: [sourceRow('OTHER-SIDE', '1', 'U1')],
          smt: [],
          reasons: ['另一面未覆盖'],
        ),
      ],
    ],
    const CheckRules(),
    false,
    [
      const ImportedFile('BOM.xlsx', InputKind.bom, [], [], []),
      ImportedFile('A.xlsx', InputKind.station, rows, [], []),
    ],
  );
}
