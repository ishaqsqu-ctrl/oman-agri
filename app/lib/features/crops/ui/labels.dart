import 'package:flutter/material.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

String categoryLabel(AppLocalizations l, CropCategory c) => switch (c) {
      CropCategory.vegetable => l.categoryVegetable,
      CropCategory.fruit => l.categoryFruit,
      CropCategory.legume => l.categoryLegume,
      CropCategory.cereal => l.categoryCereal,
      CropCategory.forage => l.categoryForage,
      CropCategory.ornamental => l.categoryOrnamental,
      CropCategory.medicinalAromatic => l.categoryMedicinalAromatic,
      CropCategory.tree => l.categoryTree,
    };

String stageLabel(AppLocalizations l, String stage) => switch (stage) {
      'initial' => l.stageInitial,
      'development' => l.stageDevelopment,
      'mid' => l.stageMid,
      'late' => l.stageLate,
      _ => stage,
    };

String textureLabel(AppLocalizations l, String t) => switch (t) {
      'sand' => l.textureSand,
      'loam' => l.textureLoam,
      'clay' => l.textureClay,
      _ => t,
    };

IconData categoryIcon(CropCategory c) => switch (c) {
      CropCategory.vegetable => Icons.eco_outlined,
      CropCategory.fruit => Icons.spa_outlined,
      CropCategory.legume => Icons.grass,
      CropCategory.cereal => Icons.grain,
      CropCategory.forage => Icons.agriculture_outlined,
      CropCategory.ornamental => Icons.local_florist_outlined,
      CropCategory.medicinalAromatic => Icons.local_pharmacy_outlined,
      CropCategory.tree => Icons.park_outlined,
    };

/// 20 -> "20", 27.5 -> "27.5".
String fmtNum(num? v) {
  if (v == null) return '';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

/// "20 – 27", or one value when both ends agree or one is missing; null if none.
String? fmtRange(num? a, num? b) {
  if (a == null && b == null) return null;
  if (a == null || b == null || a == b) return fmtNum(a ?? b);
  return '${fmtNum(a)} – ${fmtNum(b)}';
}

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// The app writes numbers with 0–9 everywhere; date formatting for Arabic would
/// otherwise switch to Arabic-Indic digits in a few places only.
String latinDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final i = _arabicIndic.indexOf(String.fromCharCode(r));
    b.write(i >= 0 ? '$i' : String.fromCharCode(r));
  }
  return b.toString();
}

const _hijriMonthsAr = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];
const _hijriMonthsEn = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Akhir', 'Jumada al-Ula', 'Jumada al-Akhirah',
  'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhu al-Qadah', 'Dhu al-Hijjah',
];

String hijriMonthName(int month, String lang) =>
    (lang == 'ar' ? _hijriMonthsAr : _hijriMonthsEn)[(month - 1).clamp(0, 11)];
