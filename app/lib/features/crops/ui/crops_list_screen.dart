import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/arabic_normalize.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/draft_banner.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class CropsListScreen extends ConsumerStatefulWidget {
  const CropsListScreen({super.key});

  @override
  ConsumerState<CropsListScreen> createState() => _CropsListScreenState();
}

class _CropsListScreenState extends ConsumerState<CropsListScreen> {
  String _query = '';
  CropCategory? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(knowledgeProvider);
    return Column(
      children: [
        const DraftBanner(),
        Expanded(
          child: snap.when(
            loading: () => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.loading),
              ]),
            ),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.loadError),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(knowledgeProvider),
                ),
              ]),
            ),
            data: (s) => _body(context, l10n, s.crops),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, List<Crop> all) {
    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.emptyCrops,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
        ),
      );
    }
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final shown = [
      for (final c in all)
        if ((_category == null || c.categories.contains(_category)) &&
            cropMatches(c, _query))
          c
    ];
    return Column(
      children: [
        // Continues the app bar's green: one header holding the tagline and search.
        Container(
          width: double.infinity,
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.homeTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: dark ? theme.colorScheme.onSurface : Colors.white.withValues(alpha: 0.88))),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: l10n.searchCrops,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ]),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _chip(l10n.allCategories, null, _category == null,
                  () => setState(() => _category = null)),
              for (final c in CropCategory.values)
                _chip(categoryLabel(l10n, c), categoryIcon(c), _category == c,
                    () => setState(() => _category = _category == c ? null : c)),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off, size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(l10n.noMatches, style: theme.textTheme.titleMedium),
                  ]))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 76, endIndent: 16),
                  itemBuilder: (context, i) => _CropRow(crop: shown[i], locale: locale),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, IconData? icon, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(
          avatar: icon == null ? null : Icon(icon, size: 18),
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

/// One crop: category glyph, both names, and the two facts a farmer weighs
/// first (best temperature, salinity tolerance) when the source gives them.
class _CropRow extends StatelessWidget {
  const _CropRow({required this.crop, required this.locale});
  final Crop crop;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = DataColors.of(context);
    final isAr = locale.languageCode == 'ar';
    final r = crop.requirements;
    final temp = fmtRange(r?.tOptLow, r?.tOptHigh);
    final ece = r?.eceThreshold;
    Widget fact(IconData icon, Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(text, style: theme.textTheme.labelMedium),
          ],
        );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minVerticalPadding: 10,
      leading: Container(
        width: 44,
        height: 44,
        decoration:
            BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
        child: Icon(
            crop.categories.isEmpty ? Icons.eco_outlined : categoryIcon(crop.categories.first),
            color: theme.colorScheme.primary,
            size: 22),
      ),
      title: Text(crop.localizedName(locale), style: theme.textTheme.titleMedium),
      subtitle: Directionality(
        textDirection: isAr ? TextDirection.ltr : TextDirection.rtl,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(isAr ? crop.nameEn : crop.nameAr,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ),
      ),
      trailing: (temp == null && ece == null)
          ? Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: theme.colorScheme.outline)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (temp != null)
                  fact(Icons.thermostat, data.heat, '$temp°'),
                if (temp != null && ece != null) const SizedBox(height: 4),
                if (ece != null) fact(Icons.water_drop_outlined, data.water, '${l10n.salinityShort} ${fmtNum(ece)}'),
              ],
            ),
      onTap: () => context.push('/crops/${crop.id}'),
    );
  }
}
