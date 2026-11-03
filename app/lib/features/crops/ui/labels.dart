import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

String categoryLabel(AppLocalizations l, CropCategory c) => switch (c) {
      CropCategory.vegetable => l.categoryVegetable,
      CropCategory.fruit => l.categoryFruit,
      CropCategory.legume => l.categoryLegume,
      CropCategory.cereal => l.categoryCereal,
      CropCategory.forage => l.categoryForage,
      CropCategory.ornamental => l.categoryOrnamental,
      CropCategory.medicinalAromatic => l.categoryMedicinalAromatic,
      CropCategory.tree => l.categoryTree,
    };

String stageLabel(AppLocalizations l, String stage) => switch (stage) {
      'initial' => l.stageInitial,
      'development' => l.stageDevelopment,
      'mid' => l.stageMid,
      'late' => l.stageLate,
      _ => stage,
    };

String textureLabel(AppLocalizations l, String t) => switch (t) {
      'sand' => l.textureSand,
      'loam' => l.textureLoam,
      'clay' => l.textureClay,
      _ => t,
    };
