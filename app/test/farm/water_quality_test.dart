import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/water_quality.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

void main() {
  test('FAO 29 salinity bands', () {
    expect([0.5, 0.7, 3.0, 3.1].map(salinitySeverity),
        [Severity.none, Severity.slight, Severity.slight, Severity.severe]);
  });

  test('infiltration combines SAR and ECw', () {
    expect(infiltrationSeverity(2, 1.0), Severity.none);
    expect(infiltrationSeverity(2, 0.5), Severity.slight);
    expect(infiltrationSeverity(2, 0.1), Severity.severe);
    expect(infiltrationSeverity(15, 2.0), Severity.slight); // 12–20: none above 2.9
    expect(infiltrationSeverity(25, 6.0), Severity.none);
  });

  test('chloride limits are lower under sprinklers', () {
    expect(chlorideSeverity(5, sprinkler: false), Severity.slight);
    expect(chlorideSeverity(2, sprinkler: true), Severity.none);
    expect(chlorideSeverity(3.5, sprinkler: true), Severity.slight);
    expect(chlorideSeverity(11, sprinkler: false), Severity.severe);
  });

  test('boron, sodium and pH', () {
    expect(boronSeverity(0.5), Severity.none);
    expect(boronSeverity(3.5), Severity.severe);
    expect(sodiumSeverity(10), Severity.severe);
    expect(phSeverity(7.8), Severity.none);
    expect(phSeverity(8.6), Severity.slight);
  });

  test('unit conversions', () {
    expect(ecFromTds(1280), 2.0);
    expect(chlorideMeq(354.5), closeTo(10, 1e-9));
  });

  test('assessment lists only measured parameters and takes the worst', () {
    final t = WaterTest(id: 'a', date: DateTime(2026, 11, 5), source: WaterSource.well, ec: 3.5, boron: 0.4);
    final f = assessWater(t);
    expect(f.map((e) => e.param), [WaterParam.salinity, WaterParam.boron]);
    expect(overallSeverity(f), Severity.severe);
  });

  test('Maas–Hoffman yield with ECe = 1.5 × ECw', () {
    const tomato = CropRequirements(eceThreshold: 2.5, eceSlope: 9.9, meta: _m);
    final e = cropWaterEffect(tomato, 3.0); // ECe 4.5 → 100 − 9.9 × 2 = 80.2
    expect(e.ece, 4.5);
    expect(e.yieldPct, 80);
    expect(e.exceeds, isTrue);
    expect(e.maxEcw, closeTo(1.67, 0.01));
    expect(cropWaterEffect(tomato, 1.0).yieldPct, 100);
    expect(cropWaterEffect(const CropRequirements(eceThreshold: 1, meta: _m), 2).yieldPct, isNull);
    expect(cropWaterEffect(null, 2).known, isFalse);
  });

  test('round-trips through JSON and survives junk', () {
    final t = WaterTest(
        id: 'a', date: DateTime(2026, 11, 5), source: WaterSource.falaj, ec: 1.2, ph: 7.6, sar: 4, chloride: 6, boron: 0.8, sprinkler: true);
    final back = WaterTest.tryParse(t.toJson())!;
    expect([back.source, back.ec, back.ph, back.sar, back.chloride, back.boron, back.sprinkler],
        [WaterSource.falaj, 1.2, 7.6, 4.0, 6.0, 0.8, true]);
    expect(WaterTest.tryParse({'id': 'x'}), isNull);
    expect(WaterTest.tryParse('junk'), isNull);
  });
}
