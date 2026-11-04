import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/draft_banner.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/crops/ui/source_button.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class CropDetailScreen extends ConsumerWidget {
  const CropDetailScreen({super.key, required this.cropId});

  final String cropId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(knowledgeProvider);
    final crop = snap.asData?.value.crops.where((c) => c.id == cropId).firstOrNull;
    return Scaffold(
      appBar: AppBar(),
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final notes = isAr ? crop.notesAr : crop.notesEn;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _Header(crop: crop),
        if (crop.requirements != null) _Glance(r: crop.requirements!),
        if (notes != null && notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(notes, style: theme.textTheme.bodyLarge),
          ),
        _Section(
          title: l10n.waterNeedTitle,
          child: crop.stages.isNotEmpty
              ? _StagesBlock(stages: crop.stages)
              : crop.kcMonthly.isNotEmpty
                  ? _MonthlyBlock(months: crop.kcMonthly)
                  : _NoData(l10n.noData),
        ),
        if (crop.stages.isNotEmpty && crop.kcMonthly.isNotEmpty)
          _Section(title: l10n.monthlyKc, child: _MonthlyBlock(months: crop.kcMonthly)),
        _Section(
          title: l10n.requirements,
          child: _Requirements(r: crop.requirements, isAr: isAr),
        ),
      ],
    );
  }
}

/// Names, scientific name and categories on the app bar's green.
class _Header extends StatelessWidget {
  const _Header({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final fg = dark ? theme.colorScheme.onSurface : Colors.white;
    final soft = fg.withValues(alpha: 0.82);
    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Crop-level facts (names, categories, notes) cite the crop row's source.
        Row(children: [
          Expanded(
            child: Text(crop.nameAr,
                style: theme.textTheme.headlineMedium?.copyWith(color: fg)),
          ),
          SourceButton(
              key: const ValueKey('crop-source'),
              sourceId: crop.meta.sourceId,
              page: crop.meta.sourcePage,
              color: soft),
        ]),
        // Start-aligned like the rest of the screen, but laid out LTR.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(crop.nameEn, style: theme.textTheme.titleMedium?.copyWith(color: soft)),
          ),
        ),
        if (crop.scientificName != null && crop.scientificName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l10n.scientificName}: ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: soft)),
              Flexible(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(crop.scientificName!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: fg, fontStyle: FontStyle.italic)),
                ),
              ),
            ]),
          ),
        ],
        if (crop.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in crop.categories)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fg.withValues(alpha: 0.28)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(categoryIcon(c), size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(categoryLabel(l10n, c),
                      style: theme.textTheme.labelMedium?.copyWith(color: fg)),
                ]),
              ),
          ]),
        ],
      ]),
    );
  }
}

/// The three facts a farmer weighs first, side by side.
class _Glance extends StatelessWidget {
  const _Glance({required this.r});
  final CropRequirements r;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = DataColors.of(context);
    final temp = fmtRange(r.tOptLow, r.tOptHigh);
    final season = fmtRange(r.seasonDaysMin, r.seasonDaysMax);
    final ece = r.eceThreshold == null ? null : fmtNum(r.eceThreshold);
    Widget tile(IconData icon, Color color, String? value, String unit, String label) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(value ?? '—',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 2),
              Text('$label ($unit)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
            ]),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          tile(Icons.thermostat, data.heat, temp, l10n.unitCelsius, l10n.glanceOptTemp),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          tile(Icons.event_outlined, theme.colorScheme.primary, season, l10n.unitDays,
              l10n.glanceSeason),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          tile(Icons.water_drop_outlined, data.water, ece, l10n.unitSalinity,
              l10n.glanceSalinity),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ]),
      );
}

/// The crop's water curve (FAO-56 Fig. 25 shape) and its stage rows.
class _StagesBlock extends StatelessWidget {
  const _StagesBlock({required this.stages});
  final List<CropStage> stages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = DataColors.of(context);
    final total = stages.fold<int>(0, (a, s) => a + s.durationDays);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        decoration: BoxDecoration(
          color: data.waterSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _KcCurvePainter(
                stages: stages,
                line: data.water,
                grid: data.water.withValues(alpha: 0.18),
                labelStyle: theme.textTheme.labelSmall!.copyWith(color: data.water),
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.seasonTotal(total),
              style: theme.textTheme.labelMedium?.copyWith(color: data.water)),
        ]),
      ),
      const SizedBox(height: 8),
      Text(l10n.waterNeedHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 8),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FixedColumnWidth(48),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            _Head(l10n.stageName),
            _Head(l10n.stageDays),
            const _Head('Kc'),
            const SizedBox.shrink(),
          ]),
          for (final s in stages)
            TableRow(children: [
              Text(stageLabel(l10n, s.stage), style: theme.textTheme.bodyMedium),
              Text('${s.durationDays}', style: theme.textTheme.titleSmall),
              Text(fmtNum(s.kc),
                  style: theme.textTheme.titleSmall?.copyWith(color: data.water)),
              SourceButton(sourceId: s.meta.sourceId, page: s.meta.sourcePage),
            ]),
        ],
      ),
    ]);
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      );
}

/// Kc against days. Each stored kc is the value at the end of its stage, so
/// the curve is flat through the first stage and straight between stage ends.
/// Time runs in reading direction (right to left in Arabic).
class _KcCurvePainter extends CustomPainter {
  _KcCurvePainter({
    required this.stages,
    required this.line,
    required this.grid,
    required this.labelStyle,
    required this.rtl,
  });

  final List<CropStage> stages;
  final Color line, grid;
  final TextStyle labelStyle;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (stages.isEmpty) return;
    final total = stages.fold<int>(0, (a, s) => a + s.durationDays);
    if (total <= 0) return;
    final maxKc = math.max(1.2, stages.map((s) => s.kc).reduce(math.max) + 0.1);
    const top = 18.0, bottom = 4.0;
    final h = size.height - top - bottom;
    double x(double day) {
      final f = day / total;
      return (rtl ? 1 - f : f) * size.width;
    }

    double y(double kc) => top + h * (1 - kc / maxKc);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final g in [0.5, 1.0]) {
      if (g >= maxKc) continue;
      canvas.drawLine(Offset(0, y(g)), Offset(size.width, y(g)), gridPaint);
    }

    // Starts at the first stage's kc, so the first stage is flat.
    final pts = <Offset>[Offset(x(0), y(stages.first.kc))];
    var day = 0.0;
    for (final s in stages) {
      day += s.durationDays;
      pts.add(Offset(x(day), y(s.kc)));
    }

    final area = Path()..moveTo(pts.first.dx, y(0));
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, y(0))
      ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.16));

    final stroke = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      stroke.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        stroke,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);

    // Stage boundaries and their end values.
    day = 0;
    for (var i = 0; i < stages.length; i++) {
      day += stages[i].durationDays;
      final px = x(day);
      final py = y(stages[i].kc);
      if (i < stages.length - 1) {
        _dashed(canvas, Offset(px, py), Offset(px, y(0)));
      }
      canvas.drawCircle(Offset(px, py), 4, Paint()..color = line);
      canvas.drawCircle(Offset(px, py), 2, Paint()..color = Colors.white);
      final showLabel = i == 0 || stages[i].kc != stages[i - 1].kc;
      if (showLabel) {
        _text(canvas, fmtNum(stages[i].kc), Offset(px, py - 18), center: true);
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b) {
    final p = Paint()
      ..color = grid
      ..strokeWidth = 1;
    const dash = 4.0, gap = 4.0;
    var yy = a.dy;
    while (yy < b.dy) {
      canvas.drawLine(Offset(a.dx, yy), Offset(a.dx, math.min(yy + dash, b.dy)), p);
      yy += dash + gap;
    }
  }

  void _text(Canvas canvas, String s, Offset at, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _KcCurvePainter old) =>
      old.stages != stages || old.line != line || old.rtl != rtl;
}

/// Twelve month slots as bars (empty where the source has no value), then rows.
class _MonthlyBlock extends StatelessWidget {
  const _MonthlyBlock({required this.months});
  final List<CropKcMonth> months;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = DataColors.of(context);
    final byMonth = {for (final m in months) m.month: m};
    final maxKc = math.max(1.2, months.map((m) => m.kc).reduce(math.max));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
        decoration: BoxDecoration(color: data.waterSoft, borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var mo = 1; mo <= 12; mo++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: byMonth[mo] == null
                          ? Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: data.water.withValues(alpha: 0.2))
                          : FractionallySizedBox(
                              heightFactor: byMonth[mo]!.kc / maxKc,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: data.water,
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$mo',
                      style: theme.textTheme.labelSmall?.copyWith(color: data.water)),
                ]),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(48),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            _Head(l10n.monthColumn),
            const _Head('Kc'),
            const SizedBox.shrink(),
          ]),
          for (final m in months)
            TableRow(children: [
              Text(l10n.monthName('m${m.month}'), style: theme.textTheme.bodyMedium),
              Text(fmtNum(m.kc),
                  style: theme.textTheme.titleSmall?.copyWith(color: data.water)),
              SourceButton(
                  key: ValueKey('kc-month-${m.month}-source'),
                  sourceId: m.meta.sourceId,
                  page: m.meta.sourcePage),
            ]),
        ],
      ),
      if (months.length < 12) _NoData(l10n.kcMonthlyPartial),
    ]);
  }
}

/// Requirements grouped the way a farmer thinks about them.
class _Requirements extends StatelessWidget {
  const _Requirements({required this.r, required this.isAr});
  final CropRequirements? r;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = this.r;
    if (r == null) return _NoData(l10n.noData);
    final m = r.meta;
    Widget row(String label, String? value) =>
        _FactRow(label: label, value: value, meta: m, noData: l10n.noData);
    String? v(num? x) => x == null ? null : fmtNum(x);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Group(title: l10n.groupTemperature, icon: Icons.thermostat, children: [
        row(l10n.tMin, v(r.tMin)),
        row(l10n.tOptLow, v(r.tOptLow)),
        row(l10n.tOptHigh, v(r.tOptHigh)),
        row(l10n.tMax, v(r.tMax)),
        row(l10n.chillHours, v(r.chillHoursMin)),
      ]),
      _Group(title: l10n.groupSoil, icon: Icons.landscape_outlined, children: [
        row(l10n.eceThreshold, v(r.eceThreshold)),
        row(l10n.phRange, fmtRange(r.phMin, r.phMax)),
        row(
            l10n.soilTexture,
            r.textures.isEmpty
                ? null
                : r.textures.map((t) => textureLabel(l10n, t)).join(isAr ? '، ' : ', ')),
      ]),
      _Group(title: l10n.groupPlace, icon: Icons.terrain_outlined, children: [
        row(l10n.altitude, fmtRange(r.altMin, r.altMax)),
        row(l10n.seasonLength, fmtRange(r.seasonDaysMin, r.seasonDaysMax)),
      ]),
    ]);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        ]),
        ...children,
      ]),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
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
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label, style: theme.textTheme.bodyMedium)),
        Expanded(
          flex: 2,
          child: Text(has ? value! : noData,
              style: has
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ),
        SizedBox(
          width: 48,
          child: has ? SourceButton(sourceId: meta.sourceId, page: meta.sourcePage) : null,
        ),
      ]),
    );
  }
}
