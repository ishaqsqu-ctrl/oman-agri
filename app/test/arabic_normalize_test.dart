import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/arabic_normalize.dart';
import 'package:oman_agri/features/crops/data/models.dart';

const _meta = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's');

void main() {
  test('tashkeel and tatweel are removed', () {
    expect(normalizeArabic('الطَّماطِم'), normalizeArabic('الطماطم'));
    expect(normalizeArabic('طــماطم'), 'طماطم');
  });
  test('letter variants unify', () {
    expect(normalizeArabic('أناناس'), normalizeArabic('اناناس'));
    expect(normalizeArabic('إبل'), 'ابل');
    expect(normalizeArabic('باميه'), normalizeArabic('بامية'));
    expect(normalizeArabic('مؤن'), normalizeArabic('مون'));
    expect(normalizeArabic('ذرى'), normalizeArabic('ذري'));
    expect(normalizeArabic('رئيس'), normalizeArabic('رييس'));
  });
  test('lowercases Latin and collapses whitespace', () {
    expect(normalizeArabic('  Solanum   Lycopersicum '), 'solanum lycopersicum');
  });

  const lemon = Crop(
      id: 'lemon',
      nameAr: 'ليمون عُماني',
      nameEn: 'Omani lime',
      scientificName: 'Citrus aurantiifolia',
      meta: _meta);
  const tomato = Crop(
      id: 'tomato',
      nameAr: 'طماطم',
      nameEn: 'Tomato',
      scientificName: 'Solanum lycopersicum',
      meta: _meta);

  test('cropMatches', () {
    expect(cropMatches(lemon, 'ليمون'), isTrue);
    expect(cropMatches(tomato, 'Solanum'), isTrue);
    expect(cropMatches(tomato, 'TOMATO'), isTrue);
    expect(cropMatches(tomato, 'ليمون'), isFalse);
    expect(cropMatches(tomato, ''), isTrue);
    expect(cropMatches(tomato, '   '), isTrue);
  });

  test('leading definite article "ال" is ignored', () {
    expect(normalizeArabic('الطماطم'), 'طماطم');
    expect(normalizeArabic('الليمون العماني'), 'ليمون عماني');
    // Too short to strip: the remainder would be under two letters.
    expect(normalizeArabic('ال'), 'ال');
    expect(normalizeArabic('الب'), 'الب');
    expect(normalizeArabic('الفل'), 'فل');
    expect(cropMatches(tomato, 'الطماطم'), isTrue);
    expect(cropMatches(tomato, 'الطَّماطِم'), isTrue);
    expect(cropMatches(lemon, 'الليمون'), isTrue);
    expect(cropMatches(lemon, 'ليمون'), isTrue);
    expect(cropMatches(lemon, 'الطماطم'), isFalse);
    const withArticle = Crop(
        id: 'x', nameAr: 'البامية', nameEn: 'Okra', meta: _meta);
    expect(cropMatches(withArticle, 'باميه'), isTrue);
  });
}
