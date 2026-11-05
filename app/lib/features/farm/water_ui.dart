import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:oman_agri/core/motion.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_art.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/farm/farm_screen.dart' show todayProvider;
import 'package:oman_agri/features/farm/water_quality.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// Keeps a number and its unit left-to-right inside Arabic text.
String ltr(String s) => '\u2066$s\u2069';

String _n(double v) => fmtNum(double.parse(v.toStringAsFixed(v.abs() < 10 ? 2 : 1)));

Color severityColor(Severity s, {required bool dark}) => switch (s) {
      Severity.none => dark ? const Color(0xFF7CC79A) : const Color(0xFF2E7D4F),
      Severity.slight => dark ? const Color(0xFFE5B85C) : const Color(0xFFB7791F),
      Severity.severe => dark ? const Color(0xFFF08A76) : const Color(0xFFB3402E),
    };

String severityLabel(AppLocalizations l, Severity s) => switch (s) {
      Severity.none => l.sevNone,
      Severity.slight => l.sevSlight,
      Severity.severe => l.sevSevere,
    };

String waterSourceLabel(AppLocalizations l, WaterSource s) => switch (s) {
      WaterSource.well => l.waterSourceWell,
      WaterSource.falaj => l.waterSourceFalaj,
      WaterSource.desalinated => l.waterSourceDesal,
      WaterSource.other => l.waterSourceOther,
    };

String paramLabel(AppLocalizations l, WaterParam p) => switch (p) {
      WaterParam.salinity => l.paramSalinity,
      WaterParam.infiltration => l.paramInfiltration,
      WaterParam.sodium => l.paramSodium,
      WaterParam.chloride => l.paramChloride,
      WaterParam.boron => l.paramBoron,
      WaterParam.ph => 'pH',
    };

String paramValue(WaterFinding f) => switch (f.param) {
      WaterParam.salinity => ltr('${_n(f.value)}\u00A0dS/m'),
      WaterParam.infiltration || WaterParam.sodium => ltr('SAR ${_n(f.value)}'),
      WaterParam.chloride => ltr('${_n(f.value)} meq/L'),
      WaterParam.boron => ltr('${_n(f.value)} mg/L'),
      WaterParam.ph => ltr(_n(f.value)),
    };

String paramAdvice(AppLocalizations l, WaterParam p) => switch (p) {
      WaterParam.salinity => l.adviceSalinity,
      WaterParam.infiltration => l.adviceInfiltration,
      WaterParam.sodium => l.adviceSodium,
      WaterParam.chloride => l.adviceChloride,
      WaterParam.boron => l.adviceBoron,
      WaterParam.ph => l.advicePh,
    };

/// The latest water test, what it means, and its effect on the farm's crops.
class WaterCard extends ConsumerWidget {
  const WaterCard({super.key, required this.crops});

  /// The crops on the farm, each once.
  final List<Crop> crops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final water = DataColors.of(context);
    final tests = ref.watch(waterTestsProvider);
    final locale = Localizations.localeOf(context);

    Widget shell(List<Widget> children) => Container(
          key: const ValueKey('water-card'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: softShadow(context),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );

    Widget badge(Color c, Color bg) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Icon(Icons.water_drop_rounded, color: c, size: 28),
        );

    if (tests.isEmpty) {
      return shell([
        Row(children: [
          badge(water.water, water.waterSoft),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.waterTitle, style: theme.textTheme.titleLarge)),
        ]),
        const SizedBox(height: 10),
        Text(l10n.waterEmptyBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          key: const ValueKey('water-add'),
          onPressed: () => showAddWaterTest(context),
          icon: const Icon(Icons.science_outlined),
          label: Text(l10n.waterAddTest),
        ),
      ]);
    }

    final t = tests.first;
    final findings = assessWater(t);
    final overall = overallSeverity(findings);
    final sc = severityColor(overall, dark: dark);
    final date = latinDigits(DateFormat.yMMMd(locale.toLanguageTag()).format(t.date));
    return shell([
      Row(children: [
        badge(sc, sc.withValues(alpha: 0.14)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.waterTitle, style: theme.textTheme.titleLarge),
            Text('${waterSourceLabel(l10n, t.source)} · $date',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ]),
        ),
        PopupMenuButton<void>(
          icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
          itemBuilder: (_) => [
            PopupMenuItem(onTap: () => showAddWaterTest(context), child: Text(l10n.waterNewTest)),
            PopupMenuItem(onTap: () => _confirmDelete(context, ref, t), child: Text(l10n.waterDelete)),
          ],
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Text(
          switch (overall) {
            Severity.none => l10n.waterVerdictNone,
            Severity.slight => l10n.waterVerdictSlight,
            Severity.severe => l10n.waterVerdictSevere,
          },
          style: theme.textTheme.titleMedium?.copyWith(color: sc),
        ),
      ),
      const SizedBox(height: 8),
      for (final f in findings) _FindingRow(finding: f),
      const Divider(height: 24),
      Text(l10n.waterOnCrops, style: theme.textTheme.titleSmall),
      const SizedBox(height: 6),
      if (crops.isEmpty)
        Text(l10n.waterAddCropsHint, style: theme.textTheme.bodyMedium)
      else
        for (final c in crops) _CropEffectRow(crop: c, ecw: t.ec),
      if (tests.length > 1) ...[
        const Divider(height: 24),
        Text(l10n.waterHistory, style: theme.textTheme.titleSmall),
        for (final old in tests.skip(1))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: severityColor(overallSeverity(assessWater(old)), dark: dark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${latinDigits(DateFormat.yMMMd(locale.toLanguageTag()).format(old.date))} · '
                    '${waterSourceLabel(l10n, old.source)} · ${ltr('${_n(old.ec)} dS/m')}',
                    style: theme.textTheme.bodySmall),
              ),
            ]),
          ),
      ],
      const SizedBox(height: 12),
      Text(l10n.waterNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
    ]);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, WaterTest t) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l10n.waterDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.waterDelete)),
        ],
      ),
    );
    if (ok == true) await ref.read(waterTestsProvider.notifier).remove(t.id);
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});
  final WaterFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = severityColor(finding.severity, dark: theme.brightness == Brightness.dark);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 10, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(paramLabel(l10n, finding.param), style: theme.textTheme.labelLarge),
              Text(paramValue(finding), style: theme.textTheme.bodyMedium),
              Text(severityLabel(l10n, finding.severity),
                  style: theme.textTheme.labelMedium?.copyWith(color: c)),
            ]),
            if (finding.severity != Severity.none)
              Text(paramAdvice(l10n, finding.param),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ]),
        ),
      ]),
    );
  }
}

class _CropEffectRow extends StatelessWidget {
  const _CropEffectRow({required this.crop, required this.ecw});
  final Crop crop;
  final double ecw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final e = cropWaterEffect(crop.requirements, ecw);
    final (String text, Color color) = !e.known
        ? (l10n.waterNoThreshold, theme.colorScheme.outline)
        : !e.exceeds
            ? (l10n.waterWithinTolerance, severityColor(Severity.none, dark: dark))
            : e.yieldPct != null
                ? (l10n.waterYield(ltr('${e.yieldPct}%')), severityColor(e.yieldPct! >= 75 ? Severity.slight : Severity.severe, dark: dark))
                : (l10n.waterAboveTolerance, severityColor(Severity.slight, dark: dark));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CropArt(cropArtAsset(crop), size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(crop.localizedName(Localizations.localeOf(context)), style: theme.textTheme.titleSmall),
            Text(text, style: theme.textTheme.labelLarge?.copyWith(color: color)),
            if (e.maxEcw != null)
              Text(l10n.waterCropMax(ltr('${_n(e.maxEcw!)}\u00A0dS/m')),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ]),
        ),
      ]),
    );
  }
}

Future<void> showAddWaterTest(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddWaterSheet(),
    );

enum _EcUnit { dsm, uscm, tds }

enum _ClUnit { meq, mgl }

/// Accepts Arabic-Indic digits and the Arabic decimal comma.
double? parseNum(String s) {
  final t = latinDigits(s.trim()).replaceAll('٫', '.').replaceAll(',', '.');
  return t.isEmpty ? null : double.tryParse(t);
}

class _AddWaterSheet extends ConsumerStatefulWidget {
  const _AddWaterSheet();

  @override
  ConsumerState<_AddWaterSheet> createState() => _AddWaterSheetState();
}

class _AddWaterSheetState extends ConsumerState<_AddWaterSheet> {
  WaterSource _source = WaterSource.well;
  late DateTime _date = ref.read(todayProvider);
  _EcUnit _ecUnit = _EcUnit.dsm;
  _ClUnit _clUnit = _ClUnit.meq;
  bool _sprinkler = false;
  bool _tried = false;
  final _ec = TextEditingController(), _ph = TextEditingController(), _sar = TextEditingController();
  final _cl = TextEditingController(), _b = TextEditingController();

  @override
  void dispose() {
    for (final c in [_ec, _ph, _sar, _cl, _b]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _ecDsm {
    final v = parseNum(_ec.text);
    if (v == null || v <= 0) return null;
    final d = switch (_ecUnit) { _EcUnit.dsm => v, _EcUnit.uscm => v / 1000, _EcUnit.tds => ecFromTds(v) };
    return d < 100 ? d : null;
  }

  /// Null when empty; NaN when present but out of range.
  double? _opt(TextEditingController c, double max) {
    final v = parseNum(c.text);
    if (c.text.trim().isEmpty) return null;
    return v == null || v < 0 || v > max ? double.nan : v;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final ph = _opt(_ph, 14), sar = _opt(_sar, 100), cl = _opt(_cl, 20000), b = _opt(_b, 100);
    String? err(double? v) => _tried && v != null && v.isNaN ? l10n.waterInvalid : null;

    InputDecoration deco(String label, {String? error, String? suffix}) => InputDecoration(
          labelText: label,
          errorText: error,
          suffixText: suffix,
          fillColor: theme.scaffoldBackgroundColor,
        );
    const numKb = TextInputType.numberWithOptions(decimal: true);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.waterSheetTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(l10n.waterSourceLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in WaterSource.values)
                ChoiceChip(
                  label: Text(waterSourceLabel(l10n, s)),
                  selected: _source == s,
                  onSelected: (_) => setState(() => _source = s),
                ),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                    context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: ref.read(todayProvider));
                if (d != null) setState(() => _date = d);
              },
              icon: const Icon(Icons.event_outlined),
              label: Text('${l10n.waterDate}: ${latinDigits(DateFormat.yMMMd(locale.toLanguageTag()).format(_date))}'),
            ),
            const SizedBox(height: 16),
            Text(l10n.waterEcLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            SegmentedButton<_EcUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _EcUnit.dsm, label: Text('dS/m')),
                ButtonSegment(value: _EcUnit.uscm, label: Text('µS/cm')),
                ButtonSegment(value: _EcUnit.tds, label: Text('TDS mg/L')),
              ],
              selected: {_ecUnit},
              onSelectionChanged: (v) => setState(() => _ecUnit = v.first),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('water-ec'),
              controller: _ec,
              keyboardType: numKb,
              decoration: deco(l10n.waterEcField,
                  error: _tried && _ecDsm == null ? l10n.waterEcRequired : null,
                  suffix: switch (_ecUnit) { _EcUnit.dsm => 'dS/m', _EcUnit.uscm => 'µS/cm', _EcUnit.tds => 'mg/L' }),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(l10n.waterOptional, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('water-ph'),
                  controller: _ph,
                  keyboardType: numKb,
                  decoration: deco('pH', error: err(ph)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('water-sar'),
                  controller: _sar,
                  keyboardType: numKb,
                  decoration: deco('SAR', error: err(sar)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('water-cl'),
                  controller: _cl,
                  keyboardType: numKb,
                  decoration: deco(l10n.paramChloride, error: err(cl)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<_ClUnit>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: _ClUnit.meq, label: Text('meq/L')),
                  ButtonSegment(value: _ClUnit.mgl, label: Text('mg/L')),
                ],
                selected: {_clUnit},
                onSelectionChanged: (v) => setState(() => _clUnit = v.first),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('water-b'),
              controller: _b,
              keyboardType: numKb,
              decoration: deco(l10n.paramBoron, error: err(b), suffix: 'mg/L'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sprinkler,
              onChanged: (v) => setState(() => _sprinkler = v),
              title: Text(l10n.waterSprinkler),
              subtitle: Text(l10n.waterSprinklerHint),
            ),
            const SizedBox(height: 12),
            Pressable(
              child: FilledButton(
                key: const ValueKey('water-save'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () async {
                  setState(() => _tried = true);
                  final ec = _ecDsm;
                  if (ec == null || [ph, sar, cl, b].any((v) => v != null && v.isNaN)) return;
                  await ref.read(waterTestsProvider.notifier).add(WaterTest(
                        id: '',
                        date: _date,
                        source: _source,
                        ec: ec,
                        ph: ph,
                        sar: sar,
                        chloride: cl == null ? null : (_clUnit == _ClUnit.mgl ? chlorideMeq(cl) : cl),
                        boron: b,
                        sprinkler: _sprinkler,
                      ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l10n.waterSave),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
