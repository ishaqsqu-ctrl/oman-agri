import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:oman_agri/core/config.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// First day of a Hijri month as officially announced in Oman.
class HijriStart {
  const HijriStart({required this.year, required this.month, required this.startsOn, required this.source});
  final int year, month;
  final DateTime startsOn;
  final String source;

  Map<String, dynamic> toJson() => {
        'hijri_year': year,
        'hijri_month': month,
        'starts_on': startsOn.toIso8601String().substring(0, 10),
        'source': source,
      };

  static HijriStart? tryParse(Object? j) {
    if (j is! Map) return null;
    final y = j['hijri_year'], m = j['hijri_month'], d = DateTime.tryParse('${j['starts_on']}');
    if (y is! num || m is! num || d == null) return null;
    return HijriStart(year: y.toInt(), month: m.toInt(), startsOn: d, source: '${j['source'] ?? ''}');
  }
}

typedef OmaniHijriDate = ({int year, int month, int day, bool official});

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

/// The Hijri date in Oman: from the latest announced month start (a month
/// lasts until the next announced start, at most 30 days); Umm al-Qura when
/// no announcement covers the date (`official` is then false).
OmaniHijriDate omaniHijri(DateTime date, List<HijriStart> starts) {
  final day = _d(date);
  final sorted = [...starts]..sort((a, b) => a.startsOn.compareTo(b.startsOn));
  for (var i = sorted.length - 1; i >= 0; i--) {
    final s = sorted[i];
    final start = _d(s.startsOn);
    if (start.isAfter(day)) continue;
    final diff = day.difference(start).inDays;
    final next = i + 1 < sorted.length ? _d(sorted[i + 1].startsOn) : null;
    if (diff < 30 && (next == null || day.isBefore(next))) {
      return (year: s.year, month: s.month, day: diff + 1, official: true);
    }
    break;
  }
  final u = HijriCalendar.fromDate(day);
  return (year: u.hYear, month: u.hMonth, day: u.hDay, official: false);
}

const hijriCacheKey = 'hijri.month_starts.v1';

/// Announced month starts: from the server when there is one (and cached for
/// offline use), otherwise the last cached copy.
final hijriStartsProvider = FutureProvider<List<HijriStart>>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  List<HijriStart> parse(Object? list) =>
      list is List ? [for (final e in list) ?HijriStart.tryParse(e)] : const [];
  if (hasBackend) {
    try {
      final rows = await Supabase.instance.client
          .from('hijri_month_starts')
          .select()
          .timeout(const Duration(seconds: 8));
      final list = parse(rows);
      await prefs.setString(hijriCacheKey, jsonEncode([for (final s in list) s.toJson()]));
      return list;
    } catch (_) {
      // fall through to the cache
    }
  }
  try {
    return parse(jsonDecode(prefs.getString(hijriCacheKey) ?? '[]'));
  } catch (_) {
    return const [];
  }
});
