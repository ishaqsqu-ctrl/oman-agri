import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// A soil profile dug, described and analysed for the 1990 General Soil Map
/// of Oman (Ministry of Agriculture and Fisheries with FAO). Only pedons whose
/// location agrees with their map sheet are shipped (data/soil_survey_1990).
@immutable
class Pedon {
  const Pedon({
    required this.n,
    required this.lat,
    required this.lon,
    required this.soilAr,
    required this.soilEn,
    required this.landAr,
    required this.landEn,
    required this.slope,
    required this.usda,
    required this.fao,
    required this.traits,
    required this.useAr,
    required this.useEn,
  });

  final int n;
  final double lat, lon;
  final String soilAr, soilEn, landAr, landEn, slope, usda, fao, useAr, useEn;

  /// saline, sodic, shallow, gravelly, gypsum_pan.
  final List<String> traits;

  factory Pedon.fromJson(Map<String, dynamic> j) => Pedon(
        n: j['n'] as int,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        soilAr: j['soil_ar'] as String,
        soilEn: j['soil_en'] as String,
        landAr: j['land_ar'] as String,
        landEn: j['land_en'] as String,
        slope: (j['slope'] as String?) ?? '',
        usda: j['usda'] as String,
        fao: j['fao'] as String,
        traits: [for (final t in j['traits'] as List) t as String],
        useAr: (j['use_ar'] as String?) ?? '',
        useEn: (j['use_en'] as String?) ?? '',
      );
}

final pedonsProvider = FutureProvider<List<Pedon>>((ref) async {
  try {
    final j = jsonDecode(await rootBundle.loadString('assets/map/pedons.json')) as Map<String, dynamic>;
    return [for (final p in j['pedons'] as List) Pedon.fromJson(p as Map<String, dynamic>)];
  } catch (_) {
    return const []; // the map works without them
  }
});

String pedonTrait(AppLocalizations l, String t) => switch (t) {
      'saline' => l.pedonSaline,
      'sodic' => l.pedonSodic,
      'shallow' => l.pedonShallow,
      'gravelly' => l.pedonGravelly,
      'gypsum_pan' => l.pedonGypsumPan,
      _ => t,
    };

const pedonColor = Color(0xFF3B2A1E);

class PedonCard extends StatelessWidget {
  const PedonCard({super.key, required this.pedon});
  final Pedon pedon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final p = pedon;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline);
    final land = ar ? p.landAr : p.landEn;
    final use = ar ? p.useAr : p.useEn;
    return Container(
      key: const ValueKey('map-pedon'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: pedonColor, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text('${p.n}', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.pedonTitle(p.n), style: theme.textTheme.titleMedium),
              Text(l10n.pedonMeasured, style: muted),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Text(ar ? p.soilAr : p.soilEn, style: theme.textTheme.titleLarge),
        Text(p.slope.isEmpty ? land : l10n.pedonLandSlope(land, '\u2066${p.slope}%\u2069'),
            style: theme.textTheme.bodyMedium),
        if (p.traits.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in p.traits)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (t == 'saline' || t == 'sodic')
                      ? const Color(0xFFC9583F).withValues(alpha: 0.14)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pedonTrait(l10n, t), style: theme.textTheme.labelMedium),
              ),
          ]),
        ],
        if (use.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.agriculture_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(use, style: theme.textTheme.bodyMedium)),
          ]),
        ],
        const SizedBox(height: 10),
        // Scientific names stay as printed, for specialists.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text('${p.usda}\nFAO: ${p.fao}', style: muted),
        ),
        const SizedBox(height: 6),
        Text(l10n.pedonSource, style: muted),
      ]),
    );
  }
}
