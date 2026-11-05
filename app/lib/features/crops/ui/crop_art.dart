import 'package:flutter/material.dart';
import 'package:oman_agri/features/crops/data/models.dart';

/// Pictures (Noto Color Emoji glyphs, see assets/emoji/README.md) and pastel
/// colours that give each crop a face. A crop without a faithful picture gets
/// a seedling rather than a lookalike of another plant.
const _cropCode = <String, String>{
  'tomato': '1f345', 'cucumber': '1f952', 'onion': '1f9c5', 'potato': '1f954',
  'watermelon': '1f349', 'garlic': '1f9c4', 'cowpea': '1fad8', 'wheat_omani': '1f33e',
  'alfalfa': '1f33f', 'date_palm': '1f334', 'lime_omani': '1f34b', 'banana': '1f34c',
  'damask_rose': '1f339', 'eggplant': '1f346', 'pepper': '1fad1', 'carrot': '1f955',
  'muskmelon': '1f348', 'faba_bean': '1fadb', 'fenugreek': '1f33f', 'sorghum': '1f33e',
  'rhodes_grass': '1f331', 'mango': '1f96d', 'coconut': '1f965', 'grape': '1f347',
  'frankincense': '1f333', 'henna': '1f33f',
};

const _categoryCode = <CropCategory, String>{
  CropCategory.vegetable: '1f96c', CropCategory.fruit: '1f34a', CropCategory.legume: '1fad8',
  CropCategory.cereal: '1f33e', CropCategory.forage: '1f33f', CropCategory.ornamental: '1f338',
  CropCategory.medicinalAromatic: '1f33f', CropCategory.tree: '1f334',
};

String _asset(String code) => 'assets/emoji/u$code.png';

String cropArtAsset(Crop c) => _asset(_cropCode[c.id] ?? '1f331');
String categoryArtAsset(CropCategory c) => _asset(_categoryCode[c]!);

/// Background tint and deep accent for a crop's tile and page, by its first category.
@immutable
class CropTint {
  const CropTint(this.soft, this.deep);
  final Color soft;
  final Color deep;
}

const _tints = <CropCategory, CropTint>{
  CropCategory.vegetable: CropTint(Color(0xFFFFE3DC), Color(0xFFB8402B)),
  CropCategory.fruit: CropTint(Color(0xFFFFF1C9), Color(0xFF9A6200)),
  CropCategory.legume: CropTint(Color(0xFFEAE5F7), Color(0xFF5B4BA3)),
  CropCategory.cereal: CropTint(Color(0xFFF4E8D2), Color(0xFF85561C)),
  CropCategory.forage: CropTint(Color(0xFFDDF0E4), Color(0xFF23704A)),
  CropCategory.ornamental: CropTint(Color(0xFFFBE1EC), Color(0xFFA23B6B)),
  CropCategory.medicinalAromatic: CropTint(Color(0xFFDFF0EF), Color(0xFF1F6E6E)),
  CropCategory.tree: CropTint(Color(0xFFE3EFD9), Color(0xFF2F6B3A)),
};

CropTint cropTint(Crop c, {required bool dark}) {
  final t = _tints[c.categories.isEmpty ? CropCategory.tree : c.categories.first]!;
  return dark ? CropTint(Color.lerp(t.deep, Colors.black, 0.62)!, Color.lerp(t.deep, Colors.white, 0.45)!) : t;
}

class CropArt extends StatelessWidget {
  const CropArt(this.asset, {super.key, required this.size});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(asset,
      width: size, height: size, filterQuality: FilterQuality.medium, excludeFromSemantics: true);
}
