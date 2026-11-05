import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/calendar/farm_events.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/farm_store.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

final tomato = Crop(id: 'tomato', nameAr: 'طماطم', nameEn: 'Tomato', meta: _m, stages: [
  CropStage(seq: 1, stage: 'initial', durationDays: 30, kc: 0.6, meta: _m),
  CropStage(seq: 2, stage: 'development', durationDays: 40, kc: 1.15, meta: _m),
  CropStage(seq: 3, stage: 'mid', durationDays: 40, kc: 1.15, meta: _m),
  CropStage(seq: 4, stage: 'late', durationDays: 25, kc: 0.8, meta: _m),
]);
final henna = Crop(id: 'henna', nameAr: 'حناء', nameEn: 'Henna', meta: _m);

void main() {
  final p = Planting(id: 'a', cropId: 'tomato', plantedOn: DateTime(2026, 10, 1));

  test('a planting yields planting, each stage start, and harvest on the right days', () {
    final e = farmEvents([p], {'tomato': tomato});
    expect(e.map((x) => (x.kind, x.date, x.stage)).toList(), [
      (FarmEventKind.planted, DateTime(2026, 10, 1), null),
      (FarmEventKind.stageStarts, DateTime(2026, 10, 31), 'development'), // day 31
      (FarmEventKind.stageStarts, DateTime(2026, 12, 10), 'mid'), // day 71
      (FarmEventKind.stageStarts, DateTime(2027, 1, 19), 'late'), // day 111
      (FarmEventKind.harvest, DateTime(2027, 2, 12), null), // day 135
    ]);
  });

  test('crops without stages only get their planting day; unknown crops are skipped', () {
    final e = farmEvents([
      Planting(id: 'b', cropId: 'henna', plantedOn: DateTime(2026, 11, 2)),
      Planting(id: 'c', cropId: 'ghost', plantedOn: DateTime(2026, 11, 2)),
    ], {'henna': henna});
    expect(e.single.kind, FarmEventKind.planted);
  });

  test('events are sorted by date across plantings', () {
    final e = farmEvents([
      p,
      Planting(id: 'b', cropId: 'henna', plantedOn: DateTime(2026, 10, 15)),
    ], {'tomato': tomato, 'henna': henna});
    final dates = e.map((x) => x.date).toList();
    expect(dates, [...dates]..sort());
  });

  test('upcoming from a day keeps that day and later only', () {
    final e = farmEvents([p], {'tomato': tomato});
    final up = upcoming(e, DateTime(2026, 11, 5));
    expect(up.first.stage, 'mid');
    expect(upcoming(e, DateTime(2026, 10, 31)).first.stage, 'development');
  });
}
