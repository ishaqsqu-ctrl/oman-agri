import 'dart:math' as math;

import 'package:oman_agri/features/crops/data/models.dart';

/// One map cell's environment: elevation and monthly mean temperatures (°C).
class EnvCell {
  const EnvCell({
    required this.col,
    required this.row,
    required this.elev,
    required this.tavg,
    required this.tmin,
    required this.tmax,
  });
  final int col, row, elev;
  final List<double> tavg, tmin, tmax; // index 0 = January
}

enum Limit { none, cold, heat, altitude }

/// A model estimate for planting [plantMonth] in one place.
class Suitability {
  const Suitability(this.score, this.limit, {this.month, this.value});

  /// 0 (unsuitable) to 100.
  final int score;
  final Limit limit;

  /// The month (1–12) that limits the season, for cold/heat.
  final int? month;

  /// The temperature (°C) or elevation (m) behind [limit].
  final double? value;
}

/// Response of a crop to a monthly mean temperature: 0 at or beyond the
/// absolute limits, 1 inside the optimum range, linear in between (the
/// EcoCrop temperature response, Hijmans et al. 2001).
double tempResponse(CropRequirements r, double t) {
  final lo = r.tMin!, ol = r.tOptLow!, oh = r.tOptHigh!, hi = r.tMax!;
  if (t <= lo || t >= hi) return 0;
  if (t < ol) return (t - lo) / (ol - lo);
  if (t > oh) return (hi - t) / (hi - oh);
  return 1;
}

/// Limiting-factor estimate (FAO land evaluation: the weakest factor decides)
/// for planting in [plantMonth]: every month of the minimum season must suit
/// the crop. Uses temperature and altitude only — not soil, salinity or water.
/// Returns null when the crop's temperature requirements are not known.
Suitability? suitabilityOf(CropRequirements r, EnvCell c, {required int plantMonth}) {
  if (r.tMin == null || r.tOptLow == null || r.tOptHigh == null || r.tMax == null) return null;
  if (r.altMax != null && c.elev > r.altMax!) {
    return Suitability(0, Limit.altitude, value: c.elev.toDouble());
  }
  final days = r.seasonDaysMin;
  final months = days == null ? 1 : math.min(12, math.max(1, (days / 30).ceil()));
  var best = 1.0;
  var limit = Limit.none;
  int? month;
  double? value;
  for (var k = 0; k < months; k++) {
    final i = (plantMonth - 1 + k) % 12;
    final avg = c.tavg[i];
    var s = tempResponse(r, avg);
    var why = avg < r.tOptLow! ? Limit.cold : Limit.heat;
    var v = avg;
    if (c.tmin[i] < r.tMin!) {
      s = 0;
      why = Limit.cold;
      v = c.tmin[i];
    } else if (c.tmax[i] > r.tMax!) {
      s = 0;
      why = Limit.heat;
      v = c.tmax[i];
    }
    if (s < best) {
      best = s;
      limit = why;
      month = i + 1;
      value = v;
    }
  }
  return Suitability((best * 100).round(), best >= 1 ? Limit.none : limit,
      month: best >= 1 ? null : month, value: best >= 1 ? null : value);
}
