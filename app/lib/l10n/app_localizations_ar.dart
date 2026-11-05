// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مزارع عُمان';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabMap => 'الخريطة';

  @override
  String get tabCalendar => 'التقويم';

  @override
  String get tabFarm => 'مزرعتي';

  @override
  String get tabStore => 'المتجر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get draftBanner => 'مسودة — قيد المراجعة';

  @override
  String get source => 'المصدر';

  @override
  String get emptyCrops => 'لا توجد محاصيل منشورة بعد';

  @override
  String get searchCrops => 'ابحث عن محصول';

  @override
  String get allCategories => 'الكل';

  @override
  String get categoryVegetable => 'خضروات';

  @override
  String get categoryFruit => 'فواكه';

  @override
  String get categoryLegume => 'بقوليات';

  @override
  String get categoryCereal => 'حبوب';

  @override
  String get categoryForage => 'أعلاف';

  @override
  String get categoryOrnamental => 'زينة';

  @override
  String get categoryMedicinalAromatic => 'نباتات طبية وعطرية';

  @override
  String get categoryTree => 'أشجار';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get loadError => 'تعذّر تحميل البيانات. حاول مرة أخرى.';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get noMatches => 'لا توجد نتائج مطابقة';

  @override
  String get scientificName => 'الاسم العلمي';

  @override
  String get categories => 'الفئات';

  @override
  String get requirements => 'متطلبات المحصول';

  @override
  String get tMin => 'درجة الحرارة الدنيا (°م)';

  @override
  String get tOptLow => 'درجة الحرارة المثلى الدنيا (°م)';

  @override
  String get tOptHigh => 'درجة الحرارة المثلى العليا (°م)';

  @override
  String get tMax => 'درجة الحرارة العظمى (°م)';

  @override
  String get chillHours => 'ساعات البرودة';

  @override
  String get eceThreshold => 'حد تحمّل الملوحة (dS/m)';

  @override
  String get phRange => 'درجة الحموضة (pH)';

  @override
  String get soilTexture => 'قوام التربة';

  @override
  String get textureSand => 'رملية';

  @override
  String get textureLoam => 'طميية';

  @override
  String get textureClay => 'طينية';

  @override
  String get altitude => 'الارتفاع (م)';

  @override
  String get seasonLength => 'طول الموسم (يوم)';

  @override
  String get growthStages => 'مراحل النمو';

  @override
  String get stageName => 'المرحلة';

  @override
  String get stageDays => 'المدة (يوم)';

  @override
  String get stageKc => 'معامل المحصول Kc';

  @override
  String get stageInitial => 'أولية';

  @override
  String get stageDevelopment => 'نمو خضري';

  @override
  String get stageMid => 'منتصف الموسم';

  @override
  String get stageLate => 'نهاية الموسم';

  @override
  String get sourcePublisher => 'الناشر';

  @override
  String get sourceYear => 'السنة';

  @override
  String get sourcePage => 'الصفحة';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  @override
  String get close => 'إغلاق';

  @override
  String get admin => 'المدير';

  @override
  String get adminNeedsBackend => 'لوحة المدير تتطلب الاتصال بالخادم';

  @override
  String get adminNotAuthorized => 'هذا الحساب ليس لديه صلاحية المدير';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInFailed => 'فشل تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get publishReviewed => 'نشر المراجَع';

  @override
  String get publishConfirmTitle => 'تأكيد النشر';

  @override
  String publishConfirmBody(String table) {
    return 'سيتم نشر جميع الصفوف التي تمت مراجعتها في «$table». هل تريد المتابعة؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String publishedRows(int count) {
    return 'تم نشر $count صفاً';
  }

  @override
  String get operationFailed => 'فشلت العملية. حاول مرة أخرى.';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusReviewed => 'تمت المراجعة';

  @override
  String get statusPublished => 'منشور';

  @override
  String get tableGovernorates => 'المحافظات';

  @override
  String get tableWilayats => 'الولايات';

  @override
  String get tableCrops => 'المحاصيل';

  @override
  String get tableCropRequirements => 'متطلبات المحاصيل';

  @override
  String get tableCropStages => 'مراحل النمو';

  @override
  String get tableLabel => 'الجدول';

  @override
  String get monthlyKc => 'معامل المحصول الشهري';

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'يناير',
      'm2': 'فبراير',
      'm3': 'مارس',
      'm4': 'أبريل',
      'm5': 'مايو',
      'm6': 'يونيو',
      'm7': 'يوليو',
      'm8': 'أغسطس',
      'm9': 'سبتمبر',
      'm10': 'أكتوبر',
      'm11': 'نوفمبر',
      'm12': 'ديسمبر',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get monthColumn => 'الشهر';

  @override
  String get kcMonthlyPartial => 'القيم متاحة لبعض الأشهر فقط';

  @override
  String get tableCropKcMonthly => 'معامل المحصول الشهري';

  @override
  String get homeTagline => 'دليل المحاصيل لمزارع عُمان، وكل معلومة بمصدرها';

  @override
  String get glanceOptTemp => 'الحرارة المثلى';

  @override
  String get glanceSeason => 'طول الموسم';

  @override
  String get glanceSalinity => 'تحمّل ملوحة التربة';

  @override
  String get unitDays => 'يوم';

  @override
  String get unitCelsius => '°م';

  @override
  String get unitSalinity => 'dS/m';

  @override
  String get waterNeedTitle => 'احتياج الماء خلال الموسم';

  @override
  String get waterNeedHelp =>
      'معامل المحصول Kc يبيّن كم يحتاج المحصول من الماء مقارنةً بعشب مرجعي: 1 يعني مثله، وأقل من 1 يعني أقل منه.';

  @override
  String seasonTotal(int days) {
    return 'مدة الموسم $days يوم';
  }

  @override
  String get groupTemperature => 'الحرارة';

  @override
  String get groupSoil => 'التربة والماء';

  @override
  String get groupPlace => 'الموقع والموسم';

  @override
  String get comingMap => 'أي المحاصيل تناسب ولايتك وأرضك.';

  @override
  String get comingCalendar => 'مواعيد الزراعة والري لكل محصول على مدار السنة.';

  @override
  String get comingFarm => 'سجّل محاصيلك واحصل على تذكير بمواعيد العناية بها.';

  @override
  String get comingStore => 'محلات البذور والأسمدة والمستلزمات القريبة منك.';

  @override
  String get salinityShort => 'ملوحة';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get homeHeadline => 'ماذا ستزرع اليوم؟';

  @override
  String get farmTitle => 'مزرعتي';

  @override
  String get farmEmptyTitle => 'لم تضف محاصيل بعد';

  @override
  String get farmEmptyBody =>
      'أضف ما زرعته وتاريخ زراعته، وسيخبرك التطبيق بمرحلته واحتياجه من الماء وموعد حصاده.';

  @override
  String get farmAdd => 'أضف محصولاً';

  @override
  String get farmPickCrop => 'ماذا زرعت؟';

  @override
  String get farmPickDate => 'متى زرعته؟';

  @override
  String get farmSave => 'أضف إلى مزرعتي';

  @override
  String get farmRemove => 'احذف من مزرعتي';

  @override
  String farmRemoveConfirm(String crop) {
    return 'هل تريد حذف $crop من مزرعتي؟';
  }

  @override
  String farmRemoved(String crop) {
    return 'حُذف $crop';
  }

  @override
  String farmPlantedOn(String date) {
    return 'زُرع في $date';
  }

  @override
  String farmDayOf(int day, int total) {
    return 'اليوم $day من $total';
  }

  @override
  String farmNotStarted(String date) {
    return 'يبدأ موسمه في $date';
  }

  @override
  String get farmFinished => 'انتهى الموسم: وقت الحصاد';

  @override
  String farmDaysToHarvest(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'الحصاد بعد $n يوم',
      many: 'الحصاد بعد $n يومًا',
      few: 'الحصاد بعد $n أيام',
      two: 'الحصاد بعد يومين',
      one: 'الحصاد بعد يوم واحد',
      zero: 'الحصاد اليوم',
    );
    return '$_temp0';
  }

  @override
  String get farmKcToday => 'حاجة الماء اليوم';

  @override
  String get farmKcMonth => 'حاجة الماء هذا الشهر';

  @override
  String farmDaysSince(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'منذ $n يوم',
      many: 'منذ $n يومًا',
      few: 'منذ $n أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
      zero: 'زُرع اليوم',
    );
    return '$_temp0';
  }

  @override
  String get farmNoStageData => 'لا توجد بعد بيانات مراحل نمو لهذا المحصول';

  @override
  String get undo => 'تراجع';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get calendarHijriNote =>
      'حسب تقويم أم القرى، وقد يختلف يوماً عن رؤية الهلال في عُمان، إلى أن يُدخل المدير بداية الشهر المعلنة رسمياً.';

  @override
  String get calendarHijriSuffix => 'هـ';

  @override
  String get calendarUpcoming => 'القادم في مزرعتي';

  @override
  String get calendarDayEvents => 'في هذا اليوم';

  @override
  String get calendarNoEventsDay => 'لا مواعيد في هذا اليوم';

  @override
  String get calendarEmptyFarm =>
      'أضف محاصيلك في «مزرعتي» لترى هنا مواعيد مراحل نموها وحصادها.';

  @override
  String get calendarGoToFarm => 'اذهب إلى مزرعتي';

  @override
  String get calendarPlantNowLater =>
      '«ماذا أزرع هذا الشهر في منطقتي» يُضاف عند اعتماد مصدر موثّق لمواعيد الزراعة في كل منطقة.';

  @override
  String eventPlanted(String crop) {
    return 'زراعة $crop';
  }

  @override
  String eventStageStarts(String crop, String stage) {
    return '$crop: تبدأ مرحلة $stage';
  }

  @override
  String eventHarvest(String crop) {
    return '$crop: موعد الحصاد';
  }

  @override
  String inDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'بعد $n يوم',
      many: 'بعد $n يومًا',
      few: 'بعد $n أيام',
      two: 'بعد يومين',
      one: 'غداً',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get calendarHijriOfficial =>
      'حسب الإعلان الرسمي لبداية الشهر في سلطنة عُمان.';

  @override
  String get hijriAdminTitle => 'بداية الشهر الهجري في عُمان';

  @override
  String get hijriAdminHelp =>
      'أدخل بداية كل شهر كما أُعلنت رسمياً في عُمان، ليظهر التاريخ الهجري الصحيح في التقويم.';

  @override
  String get hijriAdminAdd => 'أدخل بداية شهر';

  @override
  String get hijriYear => 'السنة الهجرية';

  @override
  String get hijriMonth => 'الشهر الهجري';

  @override
  String get hijriStartsOn => 'أول أيامه (ميلادي)';

  @override
  String get hijriSource => 'مصدر الإعلان';

  @override
  String hijriSaved(String month, int year) {
    return 'حُفظت بداية $month $year';
  }

  @override
  String get save => 'احفظ';
}
