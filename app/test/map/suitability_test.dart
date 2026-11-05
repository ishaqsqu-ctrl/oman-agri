import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/map/suitability.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

// Tomato requirements from the seed: 7 / 20–27 / 35 °C, ≤2400 m, season 70–150 days.
const tomato = CropRequirements(
    tMin: 7, tOptLow: 20, tOptHigh: 27, tMax: 35, altMax: 2400, seasonDaysMin: 70, seasonDaysMax: 150, meta: _m);

EnvCell cell({double tavg = 24, double tmin = 18, double tmax = 30, int elev = 50, Map<int, double>? hot}) {
  final avg = List<double>.filled(12, tavg), lo = List<double>.filled(12, tmin), hi = List<double>.filled(12, tmax);
  hot?.forEach((m, t) {
    avg[m - 1] = t;
    hi[m - 1] = t + 8;
  });
  return EnvCell(col: 0, row: 0, elev: elev, tavg: avg, tmin: lo, tmax: hi);
}

void main() {
  test('temperature response: zero outside limits, one in the optimum, linear between', () {
    expect(tempResponse(tomato, 7), 0);
    expect(tempResponse(tomato, 13.5), closeTo(0.5, 1e-9));
    expect(tempResponse(tomato, 24), 1);
    expect(tempResponse(tomato, 31), closeTo(0.5, 1e-9));
    expect(tempResponse(tomato, 35), 0);
  });

  test('ideal place all year scores 100 with no limiting factor', () {
    final s = suitabilityOf(tomato, cell(), plantMonth: 11)!;
    expect(s.score, 100);
    expect(s.limit, Limit.none);
  });

  test('the season covers ceil(70/30)=3 months; the weakest month decides', () {
    // July too hot: planting in May (May–Jul) fails, planting in Oct (Oct–Dec) is fine.
    final c = cell(hot: {7: 36});
    final may = suitabilityOf(tomato, c, plantMonth: 5)!;
    expect(may.score, 0);
    expect(may.limit, Limit.heat);
    expect(may.month, 7);
    expect(suitabilityOf(tomato, c, plantMonth: 10)!.score, 100);
  });

  test('monthly mean maximum above the limit is too hot even when the average is fine', () {
    final s = suitabilityOf(tomato, cell(tavg: 27, tmax: 36), plantMonth: 1)!;
    expect((s.score, s.limit), (0, Limit.heat));
  });

  test('monthly mean minimum below the limit is too cold', () {
    final s = suitabilityOf(tomato, cell(tavg: 20, tmin: 6), plantMonth: 1)!;
    expect((s.score, s.limit), (0, Limit.cold));
  });

  test('altitude above the limit rules the place out', () {
    final s = suitabilityOf(tomato, cell(elev: 2500), plantMonth: 1)!;
    expect((s.score, s.limit), (0, Limit.altitude));
  });

  test('season wraps across the new year', () {
    final c = cell(hot: {1: 36});
    expect(suitabilityOf(tomato, c, plantMonth: 12)!.month, 1);
  });

  test('perennials and trees must cope with every month', () {
    const palm = CropRequirements(tMin: 10, tOptLow: 26, tOptHigh: 45, tMax: 52, seasonDaysMin: 365, meta: _m);
    final s = suitabilityOf(palm, cell(tavg: 30, tmin: 9, tmax: 40), plantMonth: 3)!;
    expect(s.limit, Limit.cold);
  });

  test('missing temperature requirements give no estimate', () {
    expect(suitabilityOf(const CropRequirements(meta: _m), cell(), plantMonth: 1), isNull);
  });
}
