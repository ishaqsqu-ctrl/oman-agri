import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/arabic_normalize.dart';
import 'package:oman_agri/core/motion.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_art.dart';
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.loading),
                ],
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.loadError),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.invalidate(knowledgeProvider),
                  ),
                ],
              ),
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
          child: Text(
            l10n.emptyCrops,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final shown = [
      for (final c in all)
        if ((_category == null || c.categories.contains(_category)) &&
            cropMatches(c, _query))
          c,
    ];
    final hour = DateTime.now().hour;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hour < 12 ? l10n.greetingMorning : l10n.greetingEvening,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  l10n.homeHeadline,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: softShadow(context),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchCrops,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _chip(
                  l10n.allCategories,
                  null,
                  _category == null,
                  () => setState(() => _category = null),
                ),
                for (final c in CropCategory.values)
                  _chip(
                    categoryLabel(l10n, c),
                    categoryArtAsset(c),
                    _category == c,
                    () => setState(() => _category = _category == c ? null : c),
                  ),
              ],
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 40,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.noMatches, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              // Picture and padding are fixed; the two name lines grow with the
              // phone's text size, so the tile does too.
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 98 + MediaQuery.textScalerOf(context).scale(74),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => CropTile(crop: shown[i], locale: locale),
                childCount: shown.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, String? art, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(
          avatar: art == null ? null : CropArt(art, size: 20),
          label: Text(label,
              style: selected
                  ? TextStyle(color: Theme.of(context).colorScheme.onPrimary)
                  : null),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

/// A crop as a pastel tile: picture, both names, and its best temperature.
class CropTile extends StatelessWidget {
  const CropTile({super.key, required this.crop, required this.locale});
  final Crop crop;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = cropTint(crop, dark: theme.brightness == Brightness.dark);
    final isAr = locale.languageCode == 'ar';
    final r = crop.requirements;
    final temp = fmtRange(r?.tOptLow, r?.tOptHigh);
    return Pressable(
      child: Material(
      color: tint.soft,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () => context.push('/crops/${crop.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CropArt(cropArtAsset(crop), size: 56),
                  const SizedBox(width: 6),
                  if (temp != null)
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.75,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$temp°',
                              textDirection: TextDirection.ltr,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                crop.localizedName(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
              ),
              Text(
                isAr ? crop.nameEn : crop.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: isAr ? TextDirection.ltr : TextDirection.rtl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
