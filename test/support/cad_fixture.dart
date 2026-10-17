import 'package:smt_check/core/cad_coordinates.dart';
import 'package:smt_check/core/models.dart';
import 'package:smt_check/core/station_merge.dart';

MergedStationFile cadBom({
  String positions = 'R1',
  String quantity = '1',
  String part = 'P1',
}) => MergedStationFile(
  rows: [
    MergedStationRow(
      part: part,
      description: 'raw description',
      quantity: quantity,
      positions: positions,
      sources: [
        MaterialRow(
          part: part,
          description: 'raw description',
          quantityText: quantity,
          positionsText: positions,
          file: 'bom.xlsx',
          sheet: 'BOM',
          row: 2,
        ),
      ],
    ),
  ],
  includedSourceRows: 1,
  omittedSourceRows: 0,
  revision: 0,
  mode: MergeMode.summarize,
);

CoordinateRecord cadRecord(
  String ref,
  double x,
  double y, {
  double angle = 30,
  String layer = 'Bottom',
  int row = 2,
}) => CoordinateRecord(
  reference: ref,
  x: x,
  y: y,
  angle: angle,
  layer: layer,
  file: 'coords.xlsx',
  sheet: 'CAD',
  row: row,
  partType: 'RES',
  decal: 'R0402',
);

CoordinateImport cadCoordinates({
  double x = 10,
  double y = 30,
  double angle = 30,
  String layer = 'Bottom',
}) => CoordinateImport('coords.xlsx', [
  cadRecord('R1', x, y, angle: angle, layer: layer),
  cadRecord('MARK1', 0, 0, layer: 'Top', row: 3),
  cadRecord('MARK2', 0, 100, layer: 'Top', row: 4),
], const []);
