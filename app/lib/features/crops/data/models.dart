import 'package:flutter/widgets.dart';

enum KnowledgeStatus {
  draft,
  reviewed,
  published;

  /// Unknown values map to [draft] so they stay hidden.
  static KnowledgeStatus parse(Object? v) => KnowledgeStatus.values
      .firstWhere((e) => e.name == v, orElse: () => KnowledgeStatus.draft);
}

enum CropCategory {
  vegetable('vegetable'),
  fruit('fruit'),
  legume('legume'),
  cereal('cereal'),
  forage('forage'),
  ornamental('ornamental'),
  medicinalAromatic('medicinal_aromatic'),
  tree('tree');

  const CropCategory(this.wire);
  final String wire;

  static CropCategory? tryParse(Object? v) {
    for (final c in values) {
      if (c.wire == v) return c;
    }
    return null;
  }
}

double? _d(Object? v) => (v as num?)?.toDouble();
int? _i(Object? v) => (v as num?)?.toInt();
List<String> _strs(Object? v) =>
    ((v as List?) ?? const []).map((e) => e.toString()).toList();

@immutable
class KnowledgeMeta {
  const KnowledgeMeta({
    required this.status,
    required this.sourceId,
    this.sourcePage,
    this.reviewedBy,
    this.reviewedAt,
  });

  final KnowledgeStatus status;
  final String sourceId;
  final String? sourcePage;
  final String? reviewedBy;
  final String? reviewedAt;

  factory KnowledgeMeta.fromJson(Map<String, dynamic> j) => KnowledgeMeta(
        status: KnowledgeStatus.parse(j['status']),
        sourceId: j['source_id'] as String? ?? '',
        sourcePage: j['source_page'] as String?,
        reviewedBy: j['reviewed_by'] as String?,
        reviewedAt: j['reviewed_at']?.toString(),
      );

  bool get isPublished => status == KnowledgeStatus.published;
}

@immutable
class Source {
  const Source({
    required this.id,
    required this.title,
    required this.publisher,
    this.year,
    this.url,
    this.type,
    this.reliability,
  });

  final String id;
  final String title;
  final String publisher;
  final int? year;
  final String? url;
  final String? type;
  final int? reliability;

  factory Source.fromJson(Map<String, dynamic> j) => Source(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        publisher: j['publisher'] as String? ?? '',
        year: _i(j['year']),
        url: j['url'] as String?,
        type: j['type'] as String?,
        reliability: _i(j['reliability']),
      );
}

/// Governorate or wilayat (parent is null for governorates).
@immutable
class Region {
  const Region({
    required this.id,
    this.parentId,
    required this.nameAr,
    required this.nameEn,
    required this.meta,
  });

  final String id;
  final String? parentId;
  final String nameAr;
  final String nameEn;
  final KnowledgeMeta meta;

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        parentId: j['governorate_id'] as String?,
        nameAr: j['name_ar'] as String? ?? '',
        nameEn: j['name_en'] as String? ?? '',
        meta: KnowledgeMeta.fromJson(j),
      );
}

@immutable
class CropRequirements {
  const CropRequirements({
    this.tMin,
    this.tOptLow,
    this.tOptHigh,
    this.tMax,
    this.chillHoursMin,
    this.eceThreshold,
    this.eceSlope,
    this.phMin,
    this.phMax,
    this.textures = const [],
    this.altMin,
    this.altMax,
    this.seasonDaysMin,
    this.seasonDaysMax,
    required this.meta,
  });

  final double? tMin, tOptLow, tOptHigh, tMax;
  final int? chillHoursMin;
  final double? eceThreshold, eceSlope, phMin, phMax;
  final List<String> textures;
  final int? altMin, altMax, seasonDaysMin, seasonDaysMax;
  final KnowledgeMeta meta;

  factory CropRequirements.fromJson(Map<String, dynamic> j) => CropRequirements(
        tMin: _d(j['t_min']),
        tOptLow: _d(j['t_opt_low']),
        tOptHigh: _d(j['t_opt_high']),
        tMax: _d(j['t_max']),
        chillHoursMin: _i(j['chill_hours_min']),
        eceThreshold: _d(j['ece_threshold']),
        eceSlope: _d(j['ece_slope']),
        phMin: _d(j['ph_min']),
        phMax: _d(j['ph_max']),
        textures: _strs(j['textures']),
        altMin: _i(j['alt_min']),
        altMax: _i(j['alt_max']),
        seasonDaysMin: _i(j['season_days_min']),
        seasonDaysMax: _i(j['season_days_max']),
        meta: KnowledgeMeta.fromJson(j),
      );
}

@immutable
class CropStage {
  const CropStage({
    required this.seq,
    required this.stage,
    required this.durationDays,
    required this.kc,
    required this.meta,
  });

  final int seq;
  final String stage;
  final int durationDays;
  final double kc;
  final KnowledgeMeta meta;

  factory CropStage.fromJson(Map<String, dynamic> j) => CropStage(
        seq: _i(j['seq']) ?? 0,
        stage: j['stage'] as String? ?? '',
        durationDays: _i(j['duration_days']) ?? 0,
        kc: _d(j['kc']) ?? 0,
        meta: KnowledgeMeta.fromJson(j),
      );
}

/// Crop coefficient for one calendar month (perennials; see crop_kc_monthly).
@immutable
class CropKcMonth {
  const CropKcMonth({required this.month, required this.kc, required this.meta});

  /// 1 = January … 12 = December.
  final int month;
  final double kc;
  final KnowledgeMeta meta;

  factory CropKcMonth.fromJson(Map<String, dynamic> j) => CropKcMonth(
        month: _i(j['month']) ?? 0,
        kc: _d(j['kc']) ?? 0,
        meta: KnowledgeMeta.fromJson(j),
      );
}

@immutable
class Crop {
  const Crop({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.scientificName,
    this.categories = const [],
    this.lifecycle,
    this.notesAr,
    this.notesEn,
    this.requirements,
    this.stages = const [],
    this.kcMonthly = const [],
    required this.meta,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? scientificName;
  final List<CropCategory> categories;
  final String? lifecycle;
  final String? notesAr;
  final String? notesEn;
  final CropRequirements? requirements;
  final List<CropStage> stages;

  /// Sorted by month; may cover only some months.
  final List<CropKcMonth> kcMonthly;
  final KnowledgeMeta meta;

  String localizedName(Locale l) => l.languageCode == 'ar' ? nameAr : nameEn;

  factory Crop.fromJson(Map<String, dynamic> j) {
    final req = j['requirements'];
    return Crop(
      id: j['id'] as String,
      nameAr: j['name_ar'] as String? ?? '',
      nameEn: j['name_en'] as String? ?? '',
      scientificName: j['scientific_name'] as String?,
      categories: [
        for (final c in (j['categories'] as List? ?? const []))
          ?CropCategory.tryParse(c)
      ],
      lifecycle: j['lifecycle'] as String?,
      notesAr: j['notes_ar'] as String?,
      notesEn: j['notes_en'] as String?,
      requirements: req is Map<String, dynamic> ? CropRequirements.fromJson(req) : null,
      stages: [
        for (final s in (j['stages'] as List? ?? const []))
          CropStage.fromJson(s as Map<String, dynamic>)
      ]..sort((a, b) => a.seq.compareTo(b.seq)),
      kcMonthly: [
        for (final m in (j['kc_monthly'] as List? ?? const []))
          CropKcMonth.fromJson(m as Map<String, dynamic>)
      ]..sort((a, b) => a.month.compareTo(b.month)),
      meta: KnowledgeMeta.fromJson(j),
    );
  }

  Crop copyWith(
          {CropRequirements? Function()? requirements,
          List<CropStage>? stages,
          List<CropKcMonth>? kcMonthly}) =>
      Crop(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        scientificName: scientificName,
        categories: categories,
        lifecycle: lifecycle,
        notesAr: notesAr,
        notesEn: notesEn,
        requirements: requirements != null ? requirements() : this.requirements,
        stages: stages ?? this.stages,
        kcMonthly: kcMonthly ?? this.kcMonthly,
        meta: meta,
      );
}

@immutable
class KnowledgeSnapshot {
  const KnowledgeSnapshot({
    required this.generatedAt,
    required this.sources,
    required this.crops,
    this.governorates = const [],
    this.wilayats = const [],
    this.raw,
  });

  final DateTime generatedAt;
  final Map<String, Source> sources;
  final List<Crop> crops;
  final List<Region> governorates;
  final List<Region> wilayats;

  /// The JSON this snapshot was parsed from (used by the cache to persist it).
  /// Null on filtered copies.
  final Map<String, dynamic>? raw;

  factory KnowledgeSnapshot.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        [for (final e in (j[k] as List? ?? const [])) f(e as Map<String, dynamic>)];
    return KnowledgeSnapshot(
      generatedAt: DateTime.tryParse(j['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sources: {for (final s in list('sources', Source.fromJson)) s.id: s},
      crops: list('crops', Crop.fromJson),
      governorates: list('governorates', Region.fromJson),
      wilayats: list('wilayats', Region.fromJson),
      raw: j,
    );
  }

  KnowledgeSnapshot withContent({
    required List<Crop> crops,
    required List<Region> governorates,
    required List<Region> wilayats,
  }) =>
      KnowledgeSnapshot(
        generatedAt: generatedAt,
        sources: sources,
        crops: crops,
        governorates: governorates,
        wilayats: wilayats,
      );
}
