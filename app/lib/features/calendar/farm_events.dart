import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/farm_store.dart';

enum FarmEventKind { planted, stageStarts, harvest }

/// A dated moment in the farmer's season, derived from their plantings and the
/// crop's documented growth stages (day 1 = planting day).
class FarmEvent {
  const FarmEvent({required this.date, required this.kind, required this.crop, this.stage});
  final DateTime date;
  final FarmEventKind kind;
  final Crop crop;

  /// The stage that starts, for [FarmEventKind.stageStarts].
  final String? stage;
}

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

List<FarmEvent> farmEvents(List<Planting> plantings, Map<String, Crop> crops) {
  final out = <FarmEvent>[];
  for (final p in plantings) {
    final c = crops[p.cropId];
    if (c == null) continue;
    final start = _d(p.plantedOn);
    out.add(FarmEvent(date: start, kind: FarmEventKind.planted, crop: c));
    var day = 0; // days before the current stage
    for (var i = 0; i < c.stages.length; i++) {
      if (i > 0) {
        out.add(FarmEvent(
            date: DateTime(start.year, start.month, start.day + day),
            kind: FarmEventKind.stageStarts,
            crop: c,
            stage: c.stages[i].stage));
      }
      day += c.stages[i].durationDays;
    }
    if (c.stages.isNotEmpty) {
      out.add(FarmEvent(
          date: DateTime(start.year, start.month, start.day + day - 1), kind: FarmEventKind.harvest, crop: c));
    }
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

List<FarmEvent> upcoming(List<FarmEvent> events, DateTime from) =>
    [for (final e in events) if (!e.date.isBefore(_d(from))) e];
