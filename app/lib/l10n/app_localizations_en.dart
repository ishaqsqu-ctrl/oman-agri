// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oman Farmer';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMap => 'Map';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabFarm => 'My Farm';

  @override
  String get tabStore => 'Store';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get draftBanner => 'Draft — under review';

  @override
  String get source => 'Source';

  @override
  String get emptyCrops => 'No published crops yet';

  @override
  String get searchCrops => 'Search crops';

  @override
  String get allCategories => 'All';

  @override
  String get categoryVegetable => 'Vegetables';

  @override
  String get categoryFruit => 'Fruits';

  @override
  String get categoryLegume => 'Legumes';

  @override
  String get categoryCereal => 'Cereals';

  @override
  String get categoryForage => 'Forage';

  @override
  String get categoryOrnamental => 'Ornamentals';

  @override
  String get categoryMedicinalAromatic => 'Medicinal & aromatic';

  @override
  String get categoryTree => 'Trees';

  @override
  String get loading => 'Loading…';

  @override
  String get loadError => 'Could not load data. Please try again.';

  @override
  String get noData => 'No data';

  @override
  String get noMatches => 'No matching crops';

  @override
  String get scientificName => 'Scientific name';

  @override
  String get categories => 'Categories';

  @override
  String get requirements => 'Crop requirements';

  @override
  String get tMin => 'Minimum temperature (°C)';

  @override
  String get tOptLow => 'Optimum temperature, low (°C)';

  @override
  String get tOptHigh => 'Optimum temperature, high (°C)';

  @override
  String get tMax => 'Maximum temperature (°C)';

  @override
  String get chillHours => 'Chill hours';

  @override
  String get eceThreshold => 'Salinity threshold (dS/m)';

  @override
  String get phRange => 'Soil pH';

  @override
  String get soilTexture => 'Soil texture';

  @override
  String get textureSand => 'Sandy';

  @override
  String get textureLoam => 'Loamy';

  @override
  String get textureClay => 'Clay';

  @override
  String get altitude => 'Altitude (m)';

  @override
  String get seasonLength => 'Season length (days)';

  @override
  String get growthStages => 'Growth stages';

  @override
  String get stageName => 'Stage';

  @override
  String get stageDays => 'Duration (days)';

  @override
  String get stageKc => 'Crop coefficient Kc';

  @override
  String get stageInitial => 'Initial';

  @override
  String get stageDevelopment => 'Development';

  @override
  String get stageMid => 'Mid-season';

  @override
  String get stageLate => 'Late season';

  @override
  String get sourcePublisher => 'Publisher';

  @override
  String get sourceYear => 'Year';

  @override
  String get sourcePage => 'Page';

  @override
  String get openLink => 'Open link';

  @override
  String get linkOpenFailed => 'Could not open the link';

  @override
  String get close => 'Close';

  @override
  String get admin => 'Admin';

  @override
  String get adminNeedsBackend =>
      'The admin panel requires a server connection';

  @override
  String get adminNotAuthorized =>
      'This account does not have admin permission';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInFailed => 'Sign-in failed';

  @override
  String get signOut => 'Sign out';

  @override
  String get publishReviewed => 'Publish reviewed';

  @override
  String get publishConfirmTitle => 'Confirm publish';

  @override
  String publishConfirmBody(String table) {
    return 'All reviewed rows in \"$table\" will be published. Continue?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String publishedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Published $count rows',
      one: 'Published 1 row',
    );
    return '$_temp0';
  }

  @override
  String get operationFailed => 'Operation failed. Please try again.';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusReviewed => 'Reviewed';

  @override
  String get statusPublished => 'Published';

  @override
  String get tableGovernorates => 'Governorates';

  @override
  String get tableWilayats => 'Wilayats';

  @override
  String get tableCrops => 'Crops';

  @override
  String get tableCropRequirements => 'Crop requirements';

  @override
  String get tableCropStages => 'Growth stages';

  @override
  String get tableLabel => 'Table';

  @override
  String get monthlyKc => 'Monthly crop coefficient';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'January',
      'm2': 'February',
      'm3': 'March',
      'm4': 'April',
      'm5': 'May',
      'm6': 'June',
      'm7': 'July',
      'm8': 'August',
      'm9': 'September',
      'm10': 'October',
      'm11': 'November',
      'm12': 'December',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get monthColumn => 'Month';

  @override
  String get kcMonthlyPartial => 'Values are available for some months only';

  @override
  String get tableCropKcMonthly => 'Monthly crop coefficient';

  @override
  String get homeTagline =>
      'A crop guide for Omani farmers, with a source for every fact';

  @override
  String get glanceOptTemp => 'Best temperature';

  @override
  String get glanceSeason => 'Season length';

  @override
  String get glanceSalinity => 'Soil salinity tolerance';

  @override
  String get unitDays => 'days';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitSalinity => 'dS/m';

  @override
  String get waterNeedTitle => 'Water need through the season';

  @override
  String get waterNeedHelp =>
      'The crop coefficient Kc shows how much water the crop uses compared with a reference grass: 1 means the same, below 1 means less.';

  @override
  String seasonTotal(int days) {
    return 'Season of $days days';
  }

  @override
  String get groupTemperature => 'Temperature';

  @override
  String get groupSoil => 'Soil and water';

  @override
  String get groupPlace => 'Place and season';

  @override
  String get comingMap => 'Which crops suit your wilayat and your land.';

  @override
  String get comingCalendar =>
      'Planting and watering dates for each crop through the year.';

  @override
  String get comingFarm =>
      'Record your crops and get reminders when they need care.';

  @override
  String get comingStore => 'Seed, fertiliser and supply shops near you.';

  @override
  String get salinityShort => 'Salinity';
}
