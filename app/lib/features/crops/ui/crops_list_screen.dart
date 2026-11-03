import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/arabic_normalize.dart';
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
    final shown = [
      for (final c in all)
        if ((_category == null || c.categories.contains(_category)) &&
            cropMatches(c, _query))
          c
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchCrops,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip(l10n.allCategories, _category == null,
                  () => setState(() => _category = null)),
              for (final c in CropCategory.values)
                _chip(categoryLabel(l10n, c), _category == c,
                    () => setState(() => _category = _category == c ? null : c)),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(l10n.noMatches,
                      style: Theme.of(context).textTheme.titleMedium))
              : ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = shown[i];
                    final isAr = locale.languageCode == 'ar';
                    return ListTile(
                      minVerticalPadding: 12,
                      title: Text(c.localizedName(locale),
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Directionality(
                        textDirection: isAr ? TextDirection.ltr : TextDirection.rtl,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(isAr ? c.nameEn : c.nameAr),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/crops/${c.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
