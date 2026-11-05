import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/map/soil.dart';
import 'package:oman_agri/features/map/suitability.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

EnvCell cell({double? sand, double? clay, double? ph, double? ec}) => EnvCell(
    col: 0, row: 0, elev: 0,
    tavg: List.filled(12, 24), tmin: List.filled(12, 18), tmax: List.filled(12, 30),
    sand: sand, clay: clay, silt: sand == null || clay == null ? null : 100 - sand - clay, ph: ph, ec: ec);

void main() {
  test('FAO three texture classes from sand and clay percent', () {
    expect(textureClass(80, 10), 'sand'); // coarse: clay < 18 and sand > 65
    expect(textureClass(52, 20), 'loam'); // medium
    expect(textureClass(66, 18), 'loam'); // clay not below 18
    expect(textureClass(30, 40), 'clay'); // fine: clay > 35
    expect(textureClass(null, 20), isNull);
  });

  const tomato = CropRequirements(phMin: 5, phMax: 7.5, textures: ['sand', 'loam', 'clay'], meta: _m);
  const sandOnly = CropRequirements(textures: ['sand'], meta: _m);

  test('alkaline soil above the crop pH maximum is a condition', () {
    final c = soilConditions(tomato, cell(sand: 52, clay: 20, ph: 8.2));
    expect(c, [const SoilCondition(SoilIssue.phHigh, 8.2, 7.5)]);
  });

  test('acid soil below the minimum is a condition', () {
    expect(soilConditions(tomato, cell(sand: 52, clay: 20, ph: 4.5)).single.issue, SoilIssue.phLow);
  });

  test('texture outside the crop list is a condition', () {
    expect(soilConditions(sandOnly, cell(sand: 52, clay: 20, ph: 7)).single.issue, SoilIssue.texture);
  });

  test('suitable soil, or no soil data, gives no conditions', () {
    expect(soilConditions(tomato, cell(sand: 52, clay: 20, ph: 7)), isEmpty);
    expect(soilConditions(tomato, cell()), isEmpty);
  });

  test('FAO salinity classes', () {
    expect([1.9, 2.0, 4.0, 8.0, 16.0].map(salinityClass), [0, 1, 2, 3, 4]);
    expect(salinityClass(null), isNull);
  });

  test('salinity above the crop ECe threshold is a condition', () {
    const beans = CropRequirements(eceThreshold: 1.0, meta: _m);
    expect(soilConditions(beans, cell(ec: 2.3)), [const SoilCondition(SoilIssue.salinity, 2.3, 1.0)]);
    expect(soilConditions(beans, cell(ec: 0.8)), isEmpty);
    expect(soilConditions(const CropRequirements(meta: _m), cell(ec: 9)), isEmpty);
  });
}
