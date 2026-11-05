import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:oman_agri/features/calendar/omani_hijri.dart';

void main() {
  final starts = [
    HijriStart(year: 1448, month: 6, startsOn: DateTime(2026, 11, 11), source: 's'),
    HijriStart(year: 1448, month: 5, startsOn: DateTime(2026, 10, 12), source: 's'),
  ];

  test('official month start sets the day count', () {
    final h = omaniHijri(DateTime(2026, 11, 5), starts);
    expect((h.year, h.month, h.day, h.official), (1448, 5, 25, true));
    final first = omaniHijri(DateTime(2026, 11, 11), starts);
    expect((first.month, first.day, first.official), (6, 1, true));
  });

  test('a month ends where the next announced month begins', () {
    final h = omaniHijri(DateTime(2026, 11, 10), starts);
    expect((h.month, h.day), (5, 30));
  });

  test('without an announcement, Umm al-Qura is used and marked as such', () {
    final d = DateTime(2027, 3, 1);
    final h = omaniHijri(d, starts);
    final u = HijriCalendar.fromDate(d);
    expect((h.year, h.month, h.day, h.official), (u.hYear, u.hMonth, u.hDay, false));
    expect(omaniHijri(d, const []).official, isFalse);
  });

  test('an announcement older than 30 days does not stretch the month', () {
    final h = omaniHijri(DateTime(2026, 12, 20), starts);
    expect(h.official, isFalse);
  });
}
