import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/draft_banner.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/crops/ui/source_button.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

String _n(num? v) {
  if (v == null) return '';
  final d = v.toDouble();
  return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

String? _range(num? a, num? b) {
  if (a == null && b == null) return null;
  if (a == null || b == null || a == b) return _n(a ?? b);
  return '${_n(a)} – ${_n(b)}';
}

class CropDetailScreen extends ConsumerWidget {
  const CropDetailScreen({super.key, required this.cropId});

  final String cropId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(knowledgeProvider);
    final locale = Localizations.localeOf(context);
    final crop = snap.asData?.value.crops.where((c) => c.id == cropId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(crop?.localizedName(locale) ?? '')),
      body: Column(children: [
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
            error: (e, _) => Center(child: Text(l10n.loadError)),
            data: (_) => crop == null
                ? Center(child: Text(l10n.noData))
                : _Body(crop: crop),
          ),
        ),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';
    final notes = isAr ? crop.notesAr : crop.notesEn;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Crop-level facts (names, categories, notes) cite the crop row's source.
        Row(children: [
          Expanded(
            child: Text(crop.nameAr, style: theme.textTheme.headlineSmall),
          ),
          SourceButton(
              key: const ValueKey('crop-source'),
              sourceId: crop.meta.sourceId,
              page: crop.meta.sourcePage),
        ]),
        const SizedBox(height: 4),
        // Start-aligned like the rest of the screen, but laid out LTR.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(crop.nameEn, style: theme.textTheme.titleMedium),
          ),
        ),
        if (crop.scientificName != null && crop.scientificName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${l10n.scientificName}: '),
            Flexible(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(crop.scientificName!,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          ]),
        ],
        if (crop.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in crop.categories) Chip(label: Text(categoryLabel(l10n, c))),
          ]),
        ],
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(notes),
        ],
        const SizedBox(height: 24),
        Text(l10n.requirements, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ..._requirementRows(l10n, crop.requirements, isAr),
        const SizedBox(height: 24),
        Text(l10n.growthStages, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        _stages(context, l10n),
      ],
    );
  }

  List<Widget> _requirementRows(
      AppLocalizations l10n, CropRequirements? r, bool isAr) {
    if (r == null) return [_NoData(l10n.noData)];
    final m = r.meta;
    Widget row(String label, String? value) =>
        _FactRow(label: label, value: value, meta: m, noData: l10n.noData);
    return [
      row(l10n.tMin, r.tMin == null ? null : _n(r.tMin)),
      row(l10n.tOptLow, r.tOptLow == null ? null : _n(r.tOptLow)),
      row(l10n.tOptHigh, r.tOptHigh == null ? null : _n(r.tOptHigh)),
      row(l10n.tMax, r.tMax == null ? null : _n(r.tMax)),
      row(l10n.chillHours, r.chillHoursMin == null ? null : _n(r.chillHoursMin)),
      row(l10n.eceThreshold, r.eceThreshold == null ? null : _n(r.eceThreshold)),
      row(l10n.phRange, _range(r.phMin, r.phMax)),
      row(l10n.soilTexture,
          r.textures.isEmpty ? null : r.textures
              .map((t) => textureLabel(l10n, t))
              .join(isAr ? '، ' : ', ')),
      row(l10n.altitude, _range(r.altMin, r.altMax)),
      row(l10n.seasonLength, _range(r.seasonDaysMin, r.seasonDaysMax)),
    ];
  }

  Widget _stages(BuildContext context, AppLocalizations l10n) {
    if (crop.stages.isEmpty) return _NoData(l10n.noData);
    final head = Theme.of(context).textTheme.labelLarge;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FixedColumnWidth(48),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          Text(l10n.stageName, style: head),
          Text(l10n.stageDays, style: head),
          Text(l10n.stageKc, style: head),
          const SizedBox.shrink(),
        ]),
        for (final s in crop.stages)
          TableRow(children: [
            Text(stageLabel(l10n, s.stage)),
            Text('${s.durationDays}'),
            Text(_n(s.kc)),
            SourceButton(sourceId: s.meta.sourceId, page: s.meta.sourcePage),
          ]),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: Theme.of(context).hintColor)),
      );
}

class _FactRow extends StatelessWidget {
  const _FactRow(
      {required this.label,
      required this.value,
      required this.meta,
      required this.noData});

  final String label;
  final String? value;
  final KnowledgeMeta meta;
  final String noData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = value != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label)),
        Expanded(
          flex: 2,
          child: Text(has ? value! : noData,
              style: has
                  ? theme.textTheme.titleMedium
                  : TextStyle(color: theme.hintColor)),
        ),
        SizedBox(
          width: 48,
          child: has
              ? SourceButton(sourceId: meta.sourceId, page: meta.sourcePage)
              : null,
        ),
      ]),
    );
  }
}
