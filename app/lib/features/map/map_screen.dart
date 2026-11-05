import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_art.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/farm/farm_screen.dart' show todayProvider;
import 'package:oman_agri/features/map/soil.dart';
import 'package:oman_agri/features/map/suitability.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// The bundled environment grid (pipeline/build_map.py).
class MapData {
  MapData({
    required this.originLon,
    required this.originLat,
    required this.cellDeg,
    required this.cols,
    required this.rows,
    required this.cells,
    required this.outline,
  }) : _byPos = {for (final c in cells) c.row * 100000 + c.col: c};

  final double originLon, originLat, cellDeg;
  final int cols, rows;
  final List<EnvCell> cells;
  final List<List<Offset>> outline; // (lon, lat)
  final Map<int, EnvCell> _byPos;

  EnvCell? at(int col, int row) => _byPos[row * 100000 + col];

  static MapData parse(Map<String, dynamic> header, List<dynamic> outline) {
    final cells = <EnvCell>[];
    for (final r in header['cells'] as List) {
      final v = r as List;
      List<double> month(int from) => [for (var m = 0; m < 12; m++) (v[from + m] as num) / 10];
      // Soil (optional fields): g/kg -> percent, pH x10 -> pH; -1 = no value.
      double? soil(int k, double scale) => v.length > k && (v[k] as num) >= 0 ? (v[k] as num) / scale : null;
      cells.add(EnvCell(
          col: v[0] as int, row: v[1] as int, elev: v[2] as int, tavg: month(3), tmin: month(15), tmax: month(27),
          sand: soil(39, 10), silt: soil(40, 10), clay: soil(41, 10), ph: soil(42, 10)));
    }
    return MapData(
      originLon: (header['origin_lon'] as num).toDouble(),
      originLat: (header['origin_lat'] as num).toDouble(),
      cellDeg: (header['cell_deg'] as num).toDouble(),
      cols: header['cols'] as int,
      rows: header['rows'] as int,
      cells: cells,
      outline: [
        for (final ring in outline)
          [for (final p in ring as List) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())]
      ],
    );
  }
}

final mapDataProvider = FutureProvider<MapData>((ref) async {
  final header = jsonDecode(await rootBundle.loadString('assets/map/oman_env.json')) as Map<String, dynamic>;
  final outline = jsonDecode(await rootBundle.loadString('assets/map/oman_outline.json')) as List<dynamic>;
  return MapData.parse(header, outline);
});

Color suitColor(int score, {required bool dark}) {
  if (score >= 80) return dark ? const Color(0xFF6FCF8F) : const Color(0xFF1E7B45);
  if (score >= 50) return dark ? const Color(0xFF9BD8A9) : const Color(0xFF6DB37E);
  if (score > 0) return dark ? const Color(0xFFE0C27A) : const Color(0xFFE6C36A);
  return dark ? const Color(0xFF39433D) : const Color(0xFFE2E5E0);
}

enum MapLayer { suitability, texture, ph }

Color textureColor(String? t, {required bool dark}) => switch (t) {
      'sand' => const Color(0xFFE9D29A),
      'loam' => const Color(0xFFB88A5A),
      'clay' => const Color(0xFF7B4F2E),
      _ => dark ? const Color(0xFF39433D) : const Color(0xFFE2E5E0),
    };

Color phColor(double? ph, {required bool dark}) {
  if (ph == null) return dark ? const Color(0xFF39433D) : const Color(0xFFE2E5E0);
  if (ph <= 7.0) return const Color(0xFF6FA8DC);
  if (ph <= 7.5) return const Color(0xFF93C47D);
  if (ph <= 8.0) return const Color(0xFFE6C36A);
  return const Color(0xFFD9893D);
}

String suitLabel(AppLocalizations l, int score) => score >= 80
    ? l.suitHigh
    : score >= 50
        ? l.suitMedium
        : score > 0
            ? l.suitLow
            : l.suitNone;

String _monthName(int m, String lang) => latinDigits(DateFormat.MMMM(lang).format(DateTime(2026, m)));

String limitText(AppLocalizations l, Suitability s, String lang) => switch (s.limit) {
      Limit.none => l.limitNone,
      Limit.cold => l.limitCold(_monthName(s.month!, lang), fmtNum(s.value)),
      Limit.heat => l.limitHeat(_monthName(s.month!, lang), fmtNum(s.value)),
      Limit.altitude => l.limitAltitude(fmtNum(s.value)),
    };

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _cropId = 'tomato';
  late int _month = ref.read(todayProvider).month;
  EnvCell? _picked;
  MapLayer _layer = MapLayer.suitability;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final crops = ref.watch(knowledgeProvider).asData?.value.crops ?? const <Crop>[];
    final crop = crops.where((c) => c.id == _cropId).firstOrNull ?? crops.firstOrNull;
    final data = ref.watch(mapDataProvider);
    final req = crop?.requirements;
    final usable = req != null && req.tMin != null && req.tOptLow != null && req.tOptHigh != null && req.tMax != null;
    final picked = _picked;
    final pickedSuit = (picked != null && usable) ? suitabilityOf(req, picked, plantMonth: _month) : null;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: Text(l10n.mapTitle, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
      ),
      // Crop picker.
      if (crop != null)
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            key: const ValueKey('map-crop'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: CropArt(cropArtAsset(crop), size: 36),
            title: Text(crop.localizedName(locale), style: theme.textTheme.titleMedium),
            subtitle: Text(l10n.mapPickCrop, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.expand_more),
            onTap: () async {
              final id = await showModalBottomSheet<String>(
                context: context,
                useRootNavigator: true,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (c) => SizedBox(
                  height: MediaQuery.sizeOf(c).height * 0.7,
                  child: ListView(children: [
                    for (final x in crops)
                      ListTile(
                        leading: CropArt(cropArtAsset(x), size: 28),
                        title: Text(x.localizedName(locale)),
                        selected: x.id == crop.id,
                        onTap: () => Navigator.pop(c, x.id),
                      ),
                  ]),
                ),
              );
              if (id != null) setState(() => _cropId = id);
            },
          ),
        ),
      const SizedBox(height: 12),
      // Month strip.
      Text(l10n.mapPlantIn, style: theme.textTheme.labelLarge),
      const SizedBox(height: 6),
      // All twelve months at once, so the chosen one is always in view.
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.4,
        children: [
          for (var m = 1; m <= 12; m++)
            Material(
              key: ValueKey('map-month-$m'),
              color: m == _month ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _month = m),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(_monthName(m, lang),
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: m == _month ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      SegmentedButton<MapLayer>(
        key: const ValueKey('map-layer'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: MapLayer.suitability, label: Text(l10n.mapLayerSuit)),
          ButtonSegment(value: MapLayer.texture, label: Text(l10n.mapLayerTexture)),
          ButtonSegment(value: MapLayer.ph, label: Text(l10n.mapLayerPh)),
        ],
        selected: {_layer},
        onSelectionChanged: (v) => setState(() => _layer = v.first),
      ),
      const SizedBox(height: 12),
      if (!usable && _layer == MapLayer.suitability)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(l10n.mapNoRequirements, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        )
      else
        data.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 8), Text(l10n.mapLoading)]),
          ),
          error: (_, _) => Text(l10n.loadError),
          data: (d) => _MapCanvas(
            data: d,
            layer: _layer,
            req: usable ? req : null,
            month: _month,
            picked: picked,
            onPick: (c) => setState(() => _picked = c),
          ),
        ),
      const SizedBox(height: 8),
      if (usable || _layer != MapLayer.suitability) _Legend(layer: _layer),
      const SizedBox(height: 12),
      if (picked != null)
        _PlaceCard(cell: picked, suit: pickedSuit, req: req, month: _month, lang: lang)
      else if (usable || _layer != MapLayer.suitability)
        Text(l10n.mapTapHint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 12),
      Text(l10n.mapModelNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 4),
      Text(l10n.soilNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 4),
      Text(l10n.mapSources, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
    ]);
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas(
      {required this.data, required this.layer, required this.req, required this.month, required this.picked, required this.onPick});
  final MapData data;
  final MapLayer layer;
  final CropRequirements? req;
  final int month;
  final EnvCell? picked;
  final ValueChanged<EnvCell?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = <EnvCell, Color>{
      for (final c in data.cells)
        c: switch (layer) {
          MapLayer.suitability => suitColor(
              req == null ? 0 : (suitabilityOf(req!, c, plantMonth: month)?.score ?? 0), dark: dark),
          MapLayer.texture => textureColor(textureClass(c.sand, c.clay), dark: dark),
          MapLayer.ph => phColor(c.ph, dark: dark),
        },
    };
    // Geography never mirrors: keep north up and east on the right in Arabic too.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: data.cols / data.rows,
          child: LayoutBuilder(builder: (context, box) {
            final cw = box.maxWidth / data.cols, ch = box.maxHeight / data.rows;
            return InteractiveViewer(
              maxScale: 8,
              child: GestureDetector(
                onTapUp: (e) => onPick(data.at((e.localPosition.dx / cw).floor(), (e.localPosition.dy / ch).floor())),
                child: CustomPaint(
                  size: Size(box.maxWidth, box.maxHeight),
                  painter: _MapPainter(
                    data: data,
                    colors: colors,
                    picked: picked,
                    dark: dark,
                    outlineColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    pickColor: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.data,
    required this.colors,
    required this.picked,
    required this.dark,
    required this.outlineColor,
    required this.pickColor,
  });
  final MapData data;
  final Map<EnvCell, Color> colors;
  final EnvCell? picked;
  final bool dark;
  final Color outlineColor, pickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / data.cols, ch = size.height / data.rows;
    final paint = Paint()..isAntiAlias = false;
    colors.forEach((c, color) {
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(c.col * cw, c.row * ch, cw + 0.5, ch + 0.5), paint);
    });
    Offset toPx(Offset p) =>
        Offset((p.dx - data.originLon) / data.cellDeg * cw, (data.originLat - p.dy) / data.cellDeg * ch);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = outlineColor;
    for (final ring in data.outline) {
      if (ring.isEmpty) continue;
      final path = Path()..moveTo(toPx(ring.first).dx, toPx(ring.first).dy);
      for (final p in ring.skip(1)) {
        final q = toPx(p);
        path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(path..close(), stroke);
    }
    final p = picked;
    if (p != null) {
      final center = Offset((p.col + 0.5) * cw, (p.row + 0.5) * ch);
      canvas.drawCircle(center, 7, Paint()..color = Colors.white);
      canvas.drawCircle(center, 7, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = pickColor);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.colors != colors || old.picked != picked || old.dark != dark;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.layer});
  final MapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    Widget item(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: switch (layer) {
      MapLayer.suitability => [
          item(suitColor(100, dark: dark), l10n.suitHigh),
          item(suitColor(60, dark: dark), l10n.suitMedium),
          item(suitColor(20, dark: dark), l10n.suitLow),
          item(suitColor(0, dark: dark), l10n.suitNone),
        ],
      MapLayer.texture => [
          item(textureColor('sand', dark: dark), l10n.textureSand),
          item(textureColor('loam', dark: dark), l10n.textureLoam),
          item(textureColor('clay', dark: dark), l10n.textureClay),
          item(textureColor(null, dark: dark), l10n.soilUnknown),
        ],
      MapLayer.ph => [
          item(phColor(7.0, dark: dark), l10n.phUpTo7),
          item(phColor(7.4, dark: dark), l10n.ph7to75),
          item(phColor(7.9, dark: dark), l10n.ph75to8),
          item(phColor(8.2, dark: dark), l10n.phAbove8),
        ],
    });
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.cell, required this.suit, required this.req, required this.month, required this.lang});
  final EnvCell cell;
  final Suitability? suit;
  final CropRequirements? req;
  final int month;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final i = month - 1;
    Widget fact(String label, String value) => Expanded(
          child: Column(children: [
            Text(value, textDirection: TextDirection.ltr, style: theme.textTheme.titleMedium),
            Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          ]),
        );
    return Container(
      key: const ValueKey('map-place'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (suit != null) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: suitColor(suit!.score, dark: dark), borderRadius: BorderRadius.circular(12)),
              child: Text('${suit!.score}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: suit!.score >= 50 ? Colors.white : theme.colorScheme.onSurface)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(suitLabel(l10n, suit!.score), style: theme.textTheme.titleLarge)),
          ]),
          const SizedBox(height: 8),
          Text(limitText(l10n, suit!, lang), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        Row(children: [
          fact(l10n.envElevation, '${cell.elev} m'),
          fact('${l10n.envTavg} (${_monthName(month, lang)})', '${fmtNum(cell.tavg[i])}°'),
          fact(l10n.envTmin, '${fmtNum(cell.tmin[i])}°'),
          fact(l10n.envTmax, '${fmtNum(cell.tmax[i])}°'),
        ]),
        const Divider(height: 24),
        Text(l10n.soilTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (cell.ph == null && cell.sand == null)
          Text(l10n.soilUnknown, style: theme.textTheme.bodyMedium)
        else ...[
          Row(children: [
            fact(l10n.soilTexture, () {
              final t = textureClass(cell.sand, cell.clay);
              return t == null ? '—' : textureLabel(l10n, t);
            }()),
            fact('pH', cell.ph == null ? '—' : cell.ph!.toStringAsFixed(1)),
          ]),
          if (cell.sand != null && cell.clay != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.soilSandClay(cell.sand!.round().toString(), cell.clay!.round().toString()),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ),
          if (req != null) ...[
            const SizedBox(height: 8),
            ..._conditions(l10n, theme),
          ],
        ],
      ]),
    );
  }

  List<Widget> _conditions(AppLocalizations l10n, ThemeData theme) {
    final cs = soilConditions(req!, cell);
    if (cs.isEmpty) return [Text(l10n.soilNoConditions, style: theme.textTheme.bodySmall)];
    return [
      Text(l10n.soilConditionsTitle, style: theme.textTheme.labelLarge),
      for (final c in cs)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.tertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                switch (c.issue) {
                  SoilIssue.texture => l10n.condTexture(textureLabel(l10n, textureClass(cell.sand, cell.clay)!)),
                  SoilIssue.phHigh => l10n.condPhHigh(c.value!.toStringAsFixed(1), fmtNum(c.limit)),
                  SoilIssue.phLow => l10n.condPhLow(c.value!.toStringAsFixed(1), fmtNum(c.limit)),
                },
                style: theme.textTheme.bodySmall,
              ),
            ),
          ]),
        ),
    ];
  }
}
