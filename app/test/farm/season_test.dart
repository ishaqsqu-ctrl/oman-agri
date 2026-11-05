import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/season.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

// Tomato from the seed: 30/40/40/25 days, end-of-stage Kc 0.6/1.15/1.15/0.8.
final tomato = [
  CropStage(seq: 1, stage: 'initial', durationDays: 30, kc: 0.6, meta: _m),
  CropStage(seq: 2, stage: 'development', durationDays: 40, kc: 1.15, meta: _m),
  CropStage(seq: 3, stage: 'mid', durationDays: 40, kc: 1.15, meta: _m),
  CropStage(seq: 4, stage: 'late', durationDays: 25, kc: 0.8, meta: _m),
];

void main() {
  final planted = DateTime(2026, 10, 1);

  test('day of season counts planting day as day 1', () {
    expect(dayOfSeason(planted, DateTime(2026, 10, 1)), 1);
    expect(dayOfSeason(planted, DateTime(2026, 10, 31)), 31);
    expect(dayOfSeason(planted, DateTime(2026, 9, 30)), 0); // not planted yet
  });

  test('season position: stage, progress, days left', () {
    final p = SeasonPosition.of(tomato, day: 45);
    expect(p.totalDays, 135);
    expect(p.stageIndex, 1); // development: days 31..70
    expect(p.daysToHarvest, 90);
    expect(p.fraction, closeTo(45 / 135, 1e-9));
    expect(SeasonPosition.of(tomato, day: 30).stageIndex, 0);
    expect(SeasonPosition.of(tomato, day: 31).stageIndex, 1);
  });

  test('Kc follows FAO-56: flat initial, linear rise, flat mid, linear fall', () {
    double kc(int d) => SeasonPosition.of(tomato, day: d).kc!;
    expect(kc(1), 0.6);
    expect(kc(30), 0.6);
    expect(kc(50), closeTo(0.6 + (1.15 - 0.6) * 20 / 40, 1e-9)); // halfway up
    expect(kc(70), closeTo(1.15, 1e-9));
    expect(kc(90), 1.15);
    expect(kc(135), closeTo(0.8, 1e-9));
  });

  test('before planting and after harvest', () {
    final before = SeasonPosition.of(tomato, day: 0);
    expect(before.status, SeasonStatus.notStarted);
    expect(before.kc, isNull);
    final after = SeasonPosition.of(tomato, day: 140);
    expect(after.status, SeasonStatus.finished);
    expect(after.daysToHarvest, 0);
    expect(after.kc, isNull);
  });

  test('no stages: only the day count is known', () {
    final p = SeasonPosition.of(const [], day: 12);
    expect(p.status, SeasonStatus.unknownStages);
    expect(p.kc, isNull);
    expect(p.stageIndex, isNull);
  });
}
