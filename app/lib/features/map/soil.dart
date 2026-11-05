import 'package:flutter/foundation.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/map/suitability.dart';

/// FAO three-class soil texture (as in the FAO Soil Map of the World / HWSD),
/// mapped to the app's texture names: coarse → sand, medium → loam, fine → clay.
/// [sand] and [clay] are percentages; null when unknown.
String? textureClass(double? sand, double? clay) {
  if (sand == null || clay == null) return null;
  if (clay > 35) return 'clay';
  if (clay < 18 && sand > 65) return 'sand';
  return 'loam';
}

enum SoilIssue { texture, phLow, phHigh, salinity }

/// FAO salinity classes of soil ECe (dS/m): 0 non-saline (<2), 1 slightly
/// (2–4), 2 moderately (4–8), 3 strongly (8–16), 4 very strongly (>16).
int? salinityClass(double? ec) {
  if (ec == null) return null;
  if (ec < 2) return 0;
  if (ec < 4) return 1;
  if (ec < 8) return 2;
  if (ec < 16) return 3;
  return 4;
}

/// A soil property outside the crop's documented range: shown as a condition
/// beside the climate score, not folded into it.
@immutable
class SoilCondition {
  const SoilCondition(this.issue, this.value, this.limit);
  final SoilIssue issue;

  /// The place's pH or ECe (dS/m); null for texture.
  final double? value;

  /// The crop's pH limit or ECe threshold that is crossed; null for texture.
  final double? limit;

  @override
  bool operator ==(Object other) =>
      other is SoilCondition && other.issue == issue && other.value == value && other.limit == limit;
  @override
  int get hashCode => Object.hash(issue, value, limit);
}

List<SoilCondition> soilConditions(CropRequirements r, EnvCell c) {
  final out = <SoilCondition>[];
  final tex = textureClass(c.sand, c.clay);
  if (tex != null && r.textures.isNotEmpty && !r.textures.contains(tex)) {
    out.add(const SoilCondition(SoilIssue.texture, null, null));
  }
  final ph = c.ph;
  if (ph != null) {
    if (r.phMax != null && ph > r.phMax!) out.add(SoilCondition(SoilIssue.phHigh, ph, r.phMax));
    if (r.phMin != null && ph < r.phMin!) out.add(SoilCondition(SoilIssue.phLow, ph, r.phMin));
  }
  final ec = c.ec;
  if (ec != null && r.eceThreshold != null && ec > r.eceThreshold!) {
    out.add(SoilCondition(SoilIssue.salinity, ec, r.eceThreshold));
  }
  return out;
}
