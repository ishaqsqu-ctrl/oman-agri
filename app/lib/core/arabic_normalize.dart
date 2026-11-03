import '../features/crops/data/models.dart';

final _tashkeel = RegExp('[ً-ْٰـ]');
final _whitespace = RegExp(r'\s+');
// "ال" at the start of a word, followed by at least two more letters.
final _article = RegExp(r'(^| )ال(?=\S{2})');

/// Folds Arabic letter variants and strips diacritics so searches match
/// regardless of how a farmer (or the data) spells a word. A leading
/// definite article "ال" is dropped from each word (when at least two letters
/// remain), so "الطماطم" matches "طماطم".
String normalizeArabic(String s) {
  final out = s
      .toLowerCase()
      .replaceAll(_tashkeel, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(_whitespace, ' ')
      .trim()
      .replaceAllMapped(_article, (m) => m[1]!);
  return out;
}

/// True when [query] (normalized) occurs in the Arabic, English or scientific
/// name. An empty query matches everything.
bool cropMatches(Crop c, String query) {
  final q = normalizeArabic(query);
  if (q.isEmpty) return true;
  return [c.nameAr, c.nameEn, c.scientificName ?? '']
      .any((n) => normalizeArabic(n).contains(q));
}
