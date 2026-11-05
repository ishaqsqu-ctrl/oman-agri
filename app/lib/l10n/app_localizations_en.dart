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

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeHeadline => 'What will you grow today?';

  @override
  String get farmTitle => 'My farm';

  @override
  String get farmEmptyTitle => 'No crops yet';

  @override
  String get farmEmptyBody =>
      'Add what you planted and when, and the app tells you its stage, its water need and when to harvest.';

  @override
  String get farmAdd => 'Add a crop';

  @override
  String get farmPickCrop => 'What did you plant?';

  @override
  String get farmPickDate => 'When did you plant it?';

  @override
  String get farmSave => 'Add to my farm';

  @override
  String get farmRemove => 'Remove from my farm';

  @override
  String farmRemoveConfirm(String crop) {
    return 'Remove $crop from your farm?';
  }

  @override
  String farmRemoved(String crop) {
    return '$crop removed';
  }

  @override
  String farmPlantedOn(String date) {
    return 'Planted on $date';
  }

  @override
  String farmDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String farmNotStarted(String date) {
    return 'Season starts on $date';
  }

  @override
  String get farmFinished => 'Season over: time to harvest';

  @override
  String farmDaysToHarvest(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Harvest in $n days',
      one: 'Harvest in 1 day',
      zero: 'Harvest today',
    );
    return '$_temp0';
  }

  @override
  String get farmKcToday => 'Water need today';

  @override
  String get farmKcMonth => 'Water need this month';

  @override
  String farmDaysSince(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
      zero: 'Planted today',
    );
    return '$_temp0';
  }

  @override
  String get farmNoStageData => 'No growth-stage data for this crop yet';

  @override
  String get undo => 'Undo';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarHijriNote =>
      'Umm al-Qura calendar; may differ by a day from moon sighting in Oman until the admin enters the officially announced month start.';

  @override
  String get calendarHijriSuffix => 'AH';

  @override
  String get calendarUpcoming => 'Coming up on my farm';

  @override
  String get calendarDayEvents => 'On this day';

  @override
  String get calendarNoEventsDay => 'Nothing on this day';

  @override
  String get calendarEmptyFarm =>
      'Add your crops in My farm to see their stage and harvest dates here.';

  @override
  String get calendarGoToFarm => 'Go to My farm';

  @override
  String get calendarPlantNowLater =>
      '\"What to plant this month in my area\" arrives once a documented source for planting dates by region is approved.';

  @override
  String eventPlanted(String crop) {
    return '$crop planted';
  }

  @override
  String eventStageStarts(String crop, String stage) {
    return '$crop: $stage begins';
  }

  @override
  String eventHarvest(String crop) {
    return '$crop: harvest';
  }

  @override
  String inDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In $n days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get calendarHijriOfficial =>
      'As officially announced in Oman for this month.';

  @override
  String get hijriAdminTitle => 'Hijri month start in Oman';

  @override
  String get hijriAdminHelp =>
      'Enter each month\'s start as officially announced in Oman, so the calendar shows the right Hijri date.';

  @override
  String get hijriAdminAdd => 'Enter a month start';

  @override
  String get hijriYear => 'Hijri year';

  @override
  String get hijriMonth => 'Hijri month';

  @override
  String get hijriStartsOn => 'First day (Gregorian)';

  @override
  String get hijriSource => 'Announcement source';

  @override
  String hijriSaved(String month, int year) {
    return 'Saved the start of $month $year';
  }

  @override
  String get save => 'Save';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeNeedsInternet =>
      'The store needs an internet connection to show shops and prices.';

  @override
  String get storeEmpty => 'No approved shops yet';

  @override
  String get storeEmptyBody =>
      'Once shops register and the admin approves them, they appear here with their products and prices.';

  @override
  String get storeOwnerCta => 'Do you run a farm-supply shop?';

  @override
  String get storeRegisterButton => 'Register your shop';

  @override
  String get storeMyShopButton => 'My shop';

  @override
  String get shopCall => 'Call';

  @override
  String get shopWhatsapp => 'WhatsApp';

  @override
  String get shopNoProducts => 'This shop has not added products yet';

  @override
  String get productUnavailable => 'Not available now';

  @override
  String priceOmr(String price) {
    return 'OMR $price';
  }

  @override
  String get priceOnRequest => 'Price on request';

  @override
  String get catSeeds => 'Seeds';

  @override
  String get catSeedlings => 'Seedlings';

  @override
  String get catFertilizer => 'Fertiliser';

  @override
  String get catPesticide => 'Pesticides';

  @override
  String get catIrrigation => 'Irrigation';

  @override
  String get catTools => 'Tools';

  @override
  String get catOther => 'Other';

  @override
  String get myShopTitle => 'My shop';

  @override
  String get signInToRegister =>
      'Sign in or create an account to register your shop.';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'I have an account';

  @override
  String get confirmEmailSent =>
      'We sent you an email. Open it to confirm your account, then sign in.';

  @override
  String get shopName => 'Shop name';

  @override
  String get shopWilayat => 'Wilayat';

  @override
  String get shopPhone => 'Phone number';

  @override
  String get shopWhatsappField => 'WhatsApp number (optional)';

  @override
  String get shopAddress => 'Address (optional)';

  @override
  String get registerShop => 'Send for approval';

  @override
  String get saveShop => 'Save changes';

  @override
  String get shopPendingNote =>
      'Your shop is waiting for the admin\'s approval. Add your products now; farmers see them once approved.';

  @override
  String get shopApprovedNote =>
      'Your shop is approved and visible to farmers.';

  @override
  String get shopSuspendedNote =>
      'The admin has hidden your shop. Contact them to find out why.';

  @override
  String get productsTitle => 'Products';

  @override
  String get addProduct => 'Add a product';

  @override
  String get productName => 'Product name';

  @override
  String get productCategory => 'Type';

  @override
  String get productPrice => 'Price (OMR)';

  @override
  String get productUnit => 'Unit, e.g. 50 kg bag';

  @override
  String get productAvailable => 'Available';

  @override
  String get delete => 'Delete';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidPhone => 'Enter a valid number, e.g. 9123 4567';

  @override
  String get invalidPrice => 'Enter a valid price';

  @override
  String get pendingShops => 'Shops waiting for approval';

  @override
  String get approveShop => 'Approve';

  @override
  String get suspendShop => 'Suspend';

  @override
  String get noPendingShops => 'No shops waiting for approval';

  @override
  String get saved => 'Saved';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapPickCrop => 'Pick a crop';

  @override
  String get mapPlantIn => 'Planting in';

  @override
  String get mapTapHint => 'Tap anywhere on the map to see details.';

  @override
  String get mapModelNote =>
      'Model estimate from monthly temperature and altitude only; soil, salinity and water are not included yet.';

  @override
  String get mapNoRequirements =>
      'This crop has no documented temperature requirements yet, so its suitability cannot be computed.';

  @override
  String get suitHigh => 'Suitable';

  @override
  String get suitMedium => 'Moderately suitable';

  @override
  String get suitLow => 'Marginal';

  @override
  String get suitNone => 'Unsuitable';

  @override
  String limitCold(String month, String value) {
    return 'Too cold in $month: $value° is below what the crop needs';
  }

  @override
  String limitHeat(String month, String value) {
    return 'Too hot in $month: $value° is above the crop\'s limit';
  }

  @override
  String limitAltitude(String value) {
    return 'Altitude $value m is above the crop\'s limit';
  }

  @override
  String get limitNone => 'Temperature suits the whole season';

  @override
  String get envElevation => 'Elevation';

  @override
  String get envTavg => 'Mean temperature';

  @override
  String get envTmin => 'Mean minimum';

  @override
  String get envTmax => 'Mean maximum';

  @override
  String get mapScore => 'Suitability';

  @override
  String get mapSources =>
      'Climate and elevation: WorldClim 2.1 (Fick & Hijmans 2017). Texture and pH: SoilGrids 2.0 (Poggio et al. 2021, ISRIC). Salinity: HWSD v2.0 (FAO & IIASA 2023, CC BY-NC-SA 3.0 IGO). Oman outline: © OpenStreetMap contributors.';

  @override
  String get mapLoading => 'Loading the map…';

  @override
  String get mapLayerSuit => 'Suitability';

  @override
  String get mapLayerTexture => 'Texture';

  @override
  String get mapLayerPh => 'pH';

  @override
  String get soilUnknown => 'No data';

  @override
  String get phUpTo7 => '7.0 or less';

  @override
  String get ph7to75 => '7.0 – 7.5';

  @override
  String get ph75to8 => '7.5 – 8.0';

  @override
  String get phAbove8 => 'Above 8.0';

  @override
  String get soilTitle => 'Soil (top 30 cm)';

  @override
  String soilSandClay(String sand, String clay) {
    return 'Sand $sand% · Clay $clay%';
  }

  @override
  String get soilConditionsTitle => 'Soil conditions for this crop';

  @override
  String condTexture(String texture) {
    return 'The soil here ($texture) is not among the crop\'s suitable textures';
  }

  @override
  String condPhHigh(String value, String limit) {
    return 'Alkaline soil: pH $value is above the crop\'s limit of $limit';
  }

  @override
  String condPhLow(String value, String limit) {
    return 'Acid soil: pH $value is below the crop\'s limit of $limit';
  }

  @override
  String get soilNoConditions => 'No soil conditions for this crop here';

  @override
  String get soilNote =>
      'Texture and pH are from SoilGrids (a global estimate at 5 km); salinity is from HWSD v2.0 (older, coarser maps, and salinity changes with irrigation and well water). They may not match your farm; test your soil and water before planting.';

  @override
  String get mapLayerSalinity => 'Salinity';

  @override
  String get soilSalinity => 'Salinity';

  @override
  String get salNone => 'Non-saline (below 2)';

  @override
  String get salSlight => 'Slight (2–4)';

  @override
  String get salModerate => 'Moderate (4–8)';

  @override
  String get salStrong => 'Strong (8–16)';

  @override
  String get salVeryStrong => 'Very strong (above 16)';

  @override
  String condSalinity(String value, String limit) {
    return 'Soil salinity $value is above the crop\'s tolerance of $limit, so yield loss is expected';
  }

  @override
  String get waterTitle => 'Irrigation water';

  @override
  String get waterEmptyBody =>
      'Enter the lab result for your well or falaj water, and the app will tell you its quality and its effect on your crops.';

  @override
  String get waterAddTest => 'Enter a water test';

  @override
  String get waterNewTest => 'New test';

  @override
  String get waterSheetTitle => 'Water test result';

  @override
  String get waterSourceLabel => 'Water source';

  @override
  String get waterSourceWell => 'Well';

  @override
  String get waterSourceFalaj => 'Falaj';

  @override
  String get waterSourceDesal => 'Desalinated';

  @override
  String get waterSourceOther => 'Other';

  @override
  String get waterDate => 'Test date';

  @override
  String get waterEcLabel => 'Salinity (the key value)';

  @override
  String get waterEcField => 'EC or TDS as on the lab sheet';

  @override
  String get waterEcRequired =>
      'Enter the salinity in the unit on your lab sheet';

  @override
  String get waterOptional => 'More values, if the test has them';

  @override
  String get waterInvalid => 'Invalid value';

  @override
  String get waterSprinkler => 'I irrigate by sprinkler';

  @override
  String get waterSprinklerHint =>
      'Sprinklers wet the leaves, so chloride limits are lower';

  @override
  String get waterSave => 'Save test';

  @override
  String get waterVerdictNone => 'Fit for irrigation, no restriction';

  @override
  String get waterVerdictSlight => 'Fit for irrigation with care';

  @override
  String get waterVerdictSevere => 'Severe restriction for irrigation';

  @override
  String get paramSalinity => 'Salinity';

  @override
  String get paramInfiltration => 'Infiltration';

  @override
  String get paramSodium => 'Sodium';

  @override
  String get paramChloride => 'Chloride';

  @override
  String get paramBoron => 'Boron';

  @override
  String get sevNone => 'No restriction';

  @override
  String get sevSlight => 'Slight to moderate';

  @override
  String get sevSevere => 'Severe';

  @override
  String get adviceSalinity =>
      'Apply extra water to leach salts below the roots, and choose salt-tolerant crops.';

  @override
  String get adviceInfiltration =>
      'A crust may form and stop water soaking in; gypsum improves infiltration.';

  @override
  String get adviceSodium =>
      'Risk of sodium toxicity to roots, especially in trees.';

  @override
  String get adviceChloride =>
      'May burn leaf tips, especially in citrus and grapes.';

  @override
  String get adviceBoron =>
      'Excess boron harms sensitive crops such as citrus and legumes.';

  @override
  String get advicePh =>
      'Outside the normal range (6.5–8.4); ask the lab for bicarbonate.';

  @override
  String get waterOnCrops => 'Effect on your crops';

  @override
  String waterYield(String pct) {
    return 'Expected yield about $pct';
  }

  @override
  String get waterWithinTolerance => 'Within tolerance';

  @override
  String get waterAboveTolerance => 'Above tolerance: yield loss expected';

  @override
  String get waterNoThreshold => 'No documented salinity limit';

  @override
  String waterCropMax(String ec) {
    return 'Tolerates up to $ec in irrigation water';
  }

  @override
  String get waterAddCropsHint =>
      'Add your crops to see this water\'s effect on them.';

  @override
  String get waterHistory => 'Earlier tests';

  @override
  String get waterDelete => 'Delete test';

  @override
  String get waterDeleteConfirm => 'Delete this test?';

  @override
  String get waterNote =>
      'Guidelines: FAO Irrigation and Drainage Paper 29 (Ayers & Westcot 1985). Yield follows Maas & Hoffman, assuming soil salinity reaches 1.5 × water salinity (15–20% leaching). The test stays on your device only.';
}
