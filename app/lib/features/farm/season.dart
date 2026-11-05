import 'package:oman_agri/features/crops/data/models.dart';

/// Day of the season, counting the planting day as day 1 (0 = not planted yet).
int dayOfSeason(DateTime plantedOn, DateTime today) {
  final a = DateTime.utc(plantedOn.year, plantedOn.month, plantedOn.day);
  final b = DateTime.utc(today.year, today.month, today.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d + 1;
}

enum SeasonStatus { notStarted, growing, finished, unknownStages }

/// Where a planting stands in its crop's FAO-56 stage sequence on a given day.
///
/// Kc follows FAO-56 Fig. 25 (owner decision 10): flat through the first
/// stage, then a straight line to each stage's stored end-of-stage value.
class SeasonPosition {
  const SeasonPosition._({
    required this.day,
    required this.totalDays,
    required this.status,
    this.stageIndex,
    this.kc,
  });

  factory SeasonPosition.of(List<CropStage> stages, {required int day}) {
    final total = stages.fold<int>(0, (a, s) => a + s.durationDays);
    if (stages.isEmpty || total <= 0) {
      return SeasonPosition._(day: day, totalDays: 0, status: SeasonStatus.unknownStages);
    }
    if (day <= 0) {
      return SeasonPosition._(day: 0, totalDays: total, status: SeasonStatus.notStarted);
    }
    if (day > total) {
      return SeasonPosition._(day: day, totalDays: total, status: SeasonStatus.finished);
    }
    var start = 0;
    for (var i = 0; i < stages.length; i++) {
      final end = start + stages[i].durationDays;
      if (day <= end) {
        final from = i == 0 ? stages[0].kc : stages[i - 1].kc;
        final t = (day - start) / stages[i].durationDays;
        return SeasonPosition._(
          day: day,
          totalDays: total,
          status: SeasonStatus.growing,
          stageIndex: i,
          kc: i == 0 ? from : from + (stages[i].kc - from) * t,
        );
      }
      start = end;
    }
    return SeasonPosition._(day: day, totalDays: total, status: SeasonStatus.finished);
  }

  final int day;
  final int totalDays;
  final SeasonStatus status;

  /// Index into the stage list while growing; null otherwise.
  final int? stageIndex;

  /// Crop coefficient today while growing; null otherwise.
  final double? kc;

  int get daysToHarvest => totalDays == 0 ? 0 : (totalDays - day).clamp(0, totalDays);
  double get fraction => totalDays == 0 ? 0 : (day / totalDays).clamp(0, 1);
}
