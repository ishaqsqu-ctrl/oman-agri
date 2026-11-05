import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:oman_agri/core/arabic_normalize.dart';
import 'package:oman_agri/core/motion.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_art.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/farm/farm_store.dart';
import 'package:oman_agri/features/farm/season.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// Today's date; tests override it.
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

class FarmScreen extends ConsumerWidget {
  const FarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plantings = ref.watch(farmProvider);
    final crops = {
      for (final c in ref.watch(knowledgeProvider).asData?.value.crops ?? const <Crop>[]) c.id: c
    };
    final shown = [for (final p in plantings) if (crops[p.cropId] != null) p];
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: shown.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddPlanting(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.farmAdd),
            ),
      body: shown.isEmpty
          ? _Empty(onAdd: () => showAddPlanting(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(l10n.farmTitle,
                      style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
                ),
                for (final p in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PlantingCard(planting: p, crop: crops[p.cropId]!),
                  ),
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const CropArt('assets/emoji/u1f331.png', size: 64),
            ),
            const SizedBox(height: 20),
            Text(l10n.farmEmptyTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.farmEmptyBody, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.farmAdd),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One planting: picture, name, where it stands in its season, today's water need.
class PlantingCard extends ConsumerWidget {
  const PlantingCard({super.key, required this.planting, required this.crop});
  final Planting planting;
  final Crop crop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final tint = cropTint(crop, dark: theme.brightness == Brightness.dark);
    final today = ref.watch(todayProvider);
    final day = dayOfSeason(planting.plantedOn, today);
    final pos = SeasonPosition.of(crop.stages, day: day);
    final date = DateFormat.yMMMd(locale.toLanguageTag()).format(planting.plantedOn);
    final monthKc = crop.kcMonthly.where((m) => m.month == today.month).firstOrNull;

    String headline;
    switch (pos.status) {
      case SeasonStatus.notStarted:
        headline = l10n.farmNotStarted(date);
      case SeasonStatus.finished:
        headline = l10n.farmFinished;
      case SeasonStatus.growing:
        headline = stageLabel(l10n, crop.stages[pos.stageIndex!].stage);
      case SeasonStatus.unknownStages:
        headline = l10n.farmDaysSince(day == 0 ? 0 : day - 1);
    }

    return Pressable(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          onTap: () => context.push('/crops/${crop.id}'),
          onLongPress: () => _confirmRemove(context, ref),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 6, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: tint.soft, borderRadius: BorderRadius.circular(18)),
                  alignment: Alignment.center,
                  child: CropArt(cropArtAsset(crop), size: 38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(crop.localizedName(locale), style: theme.textTheme.titleMedium),
                    Text(headline,
                        style: theme.textTheme.labelLarge?.copyWith(color: tint.deep)),
                    Text(l10n.farmPlantedOn(date),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ]),
                ),
                PopupMenuButton<void>(
                  icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
                  itemBuilder: (_) => [
                    PopupMenuItem(onTap: () => _confirmRemove(context, ref), child: Text(l10n.farmRemove)),
                  ],
                ),
              ]),
              if (pos.status == SeasonStatus.growing || pos.status == SeasonStatus.finished) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _StageBar(stages: crop.stages, fraction: pos.fraction, color: tint.deep, soft: tint.soft),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(l10n.farmDayOf(pos.day.clamp(1, pos.totalDays), pos.totalDays),
                          style: theme.textTheme.bodySmall),
                      Text(l10n.farmDaysToHarvest(pos.daysToHarvest), style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ],
              if (pos.kc != null || (pos.status == SeasonStatus.unknownStages && monthKc != null)) ...[
                const SizedBox(height: 10),
                _KcPill(
                  label: pos.kc != null ? l10n.farmKcToday : l10n.farmKcMonth,
                  kc: pos.kc ?? monthKc!.kc,
                ),
              ] else if (pos.status == SeasonStatus.unknownStages) ...[
                const SizedBox(height: 8),
                Text(l10n.farmNoStageData,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = crop.localizedName(Localizations.localeOf(context));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l10n.farmRemoveConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.farmRemove)),
        ],
      ),
    );
    if (ok == true) await ref.read(farmProvider.notifier).remove(planting.id);
  }
}

/// The season as segments sized by stage length, filled up to today.
class _StageBar extends StatelessWidget {
  const _StageBar({required this.stages, required this.fraction, required this.color, required this.soft});
  final List<CropStage> stages;
  final double fraction;
  final Color color, soft;

  @override
  Widget build(BuildContext context) {
    final total = stages.fold<int>(0, (a, s) => a + s.durationDays);
    var start = 0;
    return SizedBox(
      height: 8,
      child: Row(children: [
        for (var i = 0; i < stages.length; i++)
          Expanded(
            flex: stages[i].durationDays,
            child: Builder(builder: (_) {
              final from = start / total, to = (start + stages[i].durationDays) / total;
              start += stages[i].durationDays;
              final fill = ((fraction - from) / (to - from)).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsetsDirectional.only(end: i == stages.length - 1 ? 0 : 3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(color: soft),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fill,
                      child: ColoredBox(color: color),
                    ),
                  ]),
                ),
              );
            }),
          ),
      ]),
    );
  }
}

class _KcPill extends StatelessWidget {
  const _KcPill({required this.label, required this.kc});
  final String label;
  final double kc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = DataColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: data.waterSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.water_drop_outlined, size: 18, color: data.water),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: data.water))),
        const SizedBox(width: 8),
        Text('Kc ${kc.toStringAsFixed(2)}',
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleSmall?.copyWith(color: data.water)),
      ]),
    );
  }
}

/// Two steps in one sheet: pick the crop, then the planting date.
Future<void> showAddPlanting(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      // Above the bottom navigation bar, so the save button is never hidden.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddPlantingSheet(),
    );

class _AddPlantingSheet extends ConsumerStatefulWidget {
  const _AddPlantingSheet();

  @override
  ConsumerState<_AddPlantingSheet> createState() => _AddPlantingSheetState();
}

class _AddPlantingSheetState extends ConsumerState<_AddPlantingSheet> {
  String _query = '';
  Crop? _crop;
  late DateTime _date = ref.read(todayProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final crops = ref.watch(knowledgeProvider).asData?.value.crops ?? const <Crop>[];
    final shown = [for (final c in crops) if (cropMatches(c, _query)) c];
    final crop = _crop;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: crop == null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(l10n.farmPickCrop, style: theme.textTheme.headlineSmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchCrops,
                      prefixIcon: const Icon(Icons.search),
                      fillColor: theme.scaffoldBackgroundColor,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final c = shown[i];
                      final tint = cropTint(c, dark: theme.brightness == Brightness.dark);
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: tint.soft, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: CropArt(cropArtAsset(c), size: 28),
                        ),
                        title: Text(c.localizedName(locale), style: theme.textTheme.titleMedium),
                        onTap: () => setState(() => _crop = c),
                      );
                    },
                  ),
                ),
              ])
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    IconButton(
                      onPressed: () => setState(() => _crop = null),
                      icon: const BackButtonIcon(),
                    ),
                    CropArt(cropArtAsset(crop), size: 32),
                    const SizedBox(width: 8),
                    Expanded(child: Text(crop.localizedName(locale), style: theme.textTheme.titleLarge)),
                  ]),
                  const SizedBox(height: 8),
                  Text(l10n.farmPickDate, style: theme.textTheme.titleMedium),
                  Expanded(
                    child: CalendarDatePicker(
                      initialDate: _date,
                      firstDate: DateTime(_date.year - 3),
                      lastDate: DateTime(_date.year + 1, 12, 31),
                      onDateChanged: (d) => setState(() => _date = d),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await ref.read(farmProvider.notifier).add(crop.id, _date);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(l10n.farmSave),
                  ),
                ]),
              ),
      ),
    );
  }
}
