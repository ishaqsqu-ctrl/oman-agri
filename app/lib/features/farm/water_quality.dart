import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/features/crops/data/models.dart';

/// Water-quality guidelines for irrigation from FAO Irrigation and Drainage
/// Paper 29 Rev.1 (Ayers & Westcot 1985), Table 1, and crop yield response to
/// salinity (Maas & Hoffman 1977, as tabulated in FAO 29 Table 4).

enum WaterSource { well, falaj, desalinated, other }

/// FAO 29 "degree of restriction on use".
enum Severity { none, slight, severe }

enum WaterParam { salinity, infiltration, sodium, chloride, boron, ph }

/// One laboratory result for the farm's irrigation water. Kept on the device.
@immutable
class WaterTest {
  const WaterTest({
    required this.id,
    required this.date,
    required this.source,
    required this.ec,
    this.ph,
    this.sar,
    this.chloride,
    this.boron,
    this.sprinkler = false,
  });

  final String id;
  final DateTime date;
  final WaterSource source;

  /// ECw, dS/m.
  final double ec;
  final double? ph;

  /// Sodium adsorption ratio.
  final double? sar;

  /// meq/L.
  final double? chloride;

  /// mg/L.
  final double? boron;

  /// Sprinkler irrigation wets the leaves: chloride limits are lower.
  final bool sprinkler;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'source': source.name,
        'ec': ec,
        'ph': ?ph,
        'sar': ?sar,
        'cl': ?chloride,
        'b': ?boron,
        'sprinkler': sprinkler,
      };

  static WaterTest? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], date = DateTime.tryParse('${j['date']}'), ec = j['ec'];
    if (id is! String || date == null || ec is! num) return null;
    double? d(Object? v) => v is num ? v.toDouble() : null;
    return WaterTest(
      id: id,
      date: date,
      source: WaterSource.values.asNameMap()[j['source']] ?? WaterSource.other,
      ec: ec.toDouble(),
      ph: d(j['ph']),
      sar: d(j['sar']),
      chloride: d(j['cl']),
      boron: d(j['b']),
      sprinkler: j['sprinkler'] == true,
    );
  }
}

/// TDS (mg/L) to ECw (dS/m): TDS ≈ 640 × ECw (FAO 29, Table 1 footnote).
double ecFromTds(double tdsMgL) => tdsMgL / 640;

/// Chloride mg/L to meq/L (equivalent weight 35.45).
double chlorideMeq(double mgL) => mgL / 35.45;

Severity _bands(double v, double slightFrom, double severeAbove) =>
    v < slightFrom ? Severity.none : (v <= severeAbove ? Severity.slight : Severity.severe);

Severity salinitySeverity(double ec) => _bands(ec, 0.7, 3.0);

/// Infiltration depends on SAR and ECw together: low-salt water with sodium
/// seals the soil surface (FAO 29 Table 1).
Severity infiltrationSeverity(double sar, double ec) {
  final (double hi, double lo) = sar < 3
      ? (0.7, 0.2)
      : sar < 6
          ? (1.2, 0.3)
          : sar < 12
              ? (1.9, 0.5)
              : sar < 20
                  ? (2.9, 1.3)
                  : (5.0, 2.9);
  if (ec > hi) return Severity.none;
  if (ec >= lo) return Severity.slight;
  return Severity.severe;
}

/// Sodium toxicity to roots (surface and drip), by SAR.
Severity sodiumSeverity(double sar) => _bands(sar, 3, 9);

Severity chlorideSeverity(double meq, {required bool sprinkler}) =>
    sprinkler ? (meq < 3 ? Severity.none : Severity.slight) : _bands(meq, 4, 10);

Severity boronSeverity(double mgL) => _bands(mgL, 0.7, 3.0);

/// Normal range 6.5–8.4; outside it the water needs a closer look.
Severity phSeverity(double ph) => ph < 6.5 || ph > 8.4 ? Severity.slight : Severity.none;

@immutable
class WaterFinding {
  const WaterFinding(this.param, this.severity, this.value);
  final WaterParam param;
  final Severity severity;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is WaterFinding && other.param == param && other.severity == severity && other.value == value;
  @override
  int get hashCode => Object.hash(param, severity, value);
}

/// Every parameter the test has, in the order FAO 29 lists them.
List<WaterFinding> assessWater(WaterTest t) => [
      WaterFinding(WaterParam.salinity, salinitySeverity(t.ec), t.ec),
      if (t.sar != null) WaterFinding(WaterParam.infiltration, infiltrationSeverity(t.sar!, t.ec), t.sar!),
      if (t.sar != null) WaterFinding(WaterParam.sodium, sodiumSeverity(t.sar!), t.sar!),
      if (t.chloride != null)
        WaterFinding(WaterParam.chloride, chlorideSeverity(t.chloride!, sprinkler: t.sprinkler), t.chloride!),
      if (t.boron != null) WaterFinding(WaterParam.boron, boronSeverity(t.boron!), t.boron!),
      if (t.ph != null) WaterFinding(WaterParam.ph, phSeverity(t.ph!), t.ph!),
    ];

Severity overallSeverity(List<WaterFinding> f) =>
    f.fold(Severity.none, (a, b) => b.severity.index > a.index ? b.severity : a);

/// Soil salinity reached with this water at the usual 15–20 % leaching
/// fraction: ECe ≈ 1.5 × ECw (FAO 29, section 2.4.3).
const eceFactor = 1.5;

@immutable
class CropWaterEffect {
  const CropWaterEffect({required this.ece, this.threshold, this.yieldPct});

  /// Expected soil salinity (dS/m).
  final double ece;

  /// The crop's ECe threshold; null when undocumented.
  final double? threshold;

  /// Expected relative yield (0–100) when the slope is documented.
  final int? yieldPct;

  bool get known => threshold != null;
  bool get exceeds => threshold != null && ece > threshold!;

  /// The highest ECw that keeps full yield.
  double? get maxEcw => threshold == null ? null : threshold! / eceFactor;
}

/// Maas–Hoffman: Y = 100 − b (ECe − a) above the threshold a.
CropWaterEffect cropWaterEffect(CropRequirements? r, double ecw) {
  final ece = ecw * eceFactor;
  final a = r?.eceThreshold, b = r?.eceSlope;
  if (a == null) return CropWaterEffect(ece: ece);
  final y = ece <= a ? 100 : (b == null ? null : (100 - b * (ece - a)).clamp(0, 100).round());
  return CropWaterEffect(ece: ece, threshold: a, yieldPct: y?.toInt());
}

const waterPrefKey = 'farm.water_tests.v1';

final waterTestsProvider = NotifierProvider<WaterTestsController, List<WaterTest>>(WaterTestsController.new);

/// Newest first.
class WaterTestsController extends Notifier<List<WaterTest>> {
  @override
  List<WaterTest> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(waterPrefKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final e in list) ?WaterTest.tryParse(e)]..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(WaterTest t) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    final saved = WaterTest(
        id: id,
        date: t.date,
        source: t.source,
        ec: t.ec,
        ph: t.ph,
        sar: t.sar,
        chloride: t.chloride,
        boron: t.boron,
        sprinkler: t.sprinkler);
    state = [saved, ...state]..sort((a, b) => b.date.compareTo(a.date));
    await _save();
  }

  Future<void> remove(String id) async {
    state = [for (final t in state) if (t.id != id) t];
    await _save();
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(waterPrefKey, jsonEncode([for (final t in state) t.toJson()]));
}
