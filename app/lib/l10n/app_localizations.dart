import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'مزارع عُمان'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabMap.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get tabMap;

  /// No description provided for @tabCalendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get tabCalendar;

  /// No description provided for @tabFarm.
  ///
  /// In ar, this message translates to:
  /// **'مزرعتي'**
  String get tabFarm;

  /// No description provided for @tabStore.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get tabStore;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get comingSoon;

  /// No description provided for @draftBanner.
  ///
  /// In ar, this message translates to:
  /// **'مسودة — قيد المراجعة'**
  String get draftBanner;

  /// No description provided for @source.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get source;

  /// No description provided for @emptyCrops.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محاصيل منشورة بعد'**
  String get emptyCrops;

  /// No description provided for @searchCrops.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن محصول'**
  String get searchCrops;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategories;

  /// No description provided for @categoryVegetable.
  ///
  /// In ar, this message translates to:
  /// **'خضروات'**
  String get categoryVegetable;

  /// No description provided for @categoryFruit.
  ///
  /// In ar, this message translates to:
  /// **'فواكه'**
  String get categoryFruit;

  /// No description provided for @categoryLegume.
  ///
  /// In ar, this message translates to:
  /// **'بقوليات'**
  String get categoryLegume;

  /// No description provided for @categoryCereal.
  ///
  /// In ar, this message translates to:
  /// **'حبوب'**
  String get categoryCereal;

  /// No description provided for @categoryForage.
  ///
  /// In ar, this message translates to:
  /// **'أعلاف'**
  String get categoryForage;

  /// No description provided for @categoryOrnamental.
  ///
  /// In ar, this message translates to:
  /// **'زينة'**
  String get categoryOrnamental;

  /// No description provided for @categoryMedicinalAromatic.
  ///
  /// In ar, this message translates to:
  /// **'نباتات طبية وعطرية'**
  String get categoryMedicinalAromatic;

  /// No description provided for @categoryTree.
  ///
  /// In ar, this message translates to:
  /// **'أشجار'**
  String get categoryTree;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get loading;

  /// No description provided for @loadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البيانات. حاول مرة أخرى.'**
  String get loadError;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @noMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noMatches;

  /// No description provided for @scientificName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم العلمي'**
  String get scientificName;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'الفئات'**
  String get categories;

  /// No description provided for @requirements.
  ///
  /// In ar, this message translates to:
  /// **'متطلبات المحصول'**
  String get requirements;

  /// No description provided for @tMin.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحرارة الدنيا (°م)'**
  String get tMin;

  /// No description provided for @tOptLow.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحرارة المثلى الدنيا (°م)'**
  String get tOptLow;

  /// No description provided for @tOptHigh.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحرارة المثلى العليا (°م)'**
  String get tOptHigh;

  /// No description provided for @tMax.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحرارة العظمى (°م)'**
  String get tMax;

  /// No description provided for @chillHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات البرودة'**
  String get chillHours;

  /// No description provided for @eceThreshold.
  ///
  /// In ar, this message translates to:
  /// **'حد تحمّل الملوحة (dS/m)'**
  String get eceThreshold;

  /// No description provided for @phRange.
  ///
  /// In ar, this message translates to:
  /// **'درجة الحموضة (pH)'**
  String get phRange;

  /// No description provided for @soilTexture.
  ///
  /// In ar, this message translates to:
  /// **'قوام التربة'**
  String get soilTexture;

  /// No description provided for @textureSand.
  ///
  /// In ar, this message translates to:
  /// **'رملية'**
  String get textureSand;

  /// No description provided for @textureLoam.
  ///
  /// In ar, this message translates to:
  /// **'طميية'**
  String get textureLoam;

  /// No description provided for @textureClay.
  ///
  /// In ar, this message translates to:
  /// **'طينية'**
  String get textureClay;

  /// No description provided for @altitude.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع (م)'**
  String get altitude;

  /// No description provided for @seasonLength.
  ///
  /// In ar, this message translates to:
  /// **'طول الموسم (يوم)'**
  String get seasonLength;

  /// No description provided for @growthStages.
  ///
  /// In ar, this message translates to:
  /// **'مراحل النمو'**
  String get growthStages;

  /// No description provided for @stageName.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة'**
  String get stageName;

  /// No description provided for @stageDays.
  ///
  /// In ar, this message translates to:
  /// **'المدة (يوم)'**
  String get stageDays;

  /// No description provided for @stageKc.
  ///
  /// In ar, this message translates to:
  /// **'معامل المحصول Kc'**
  String get stageKc;

  /// No description provided for @stageInitial.
  ///
  /// In ar, this message translates to:
  /// **'أولية'**
  String get stageInitial;

  /// No description provided for @stageDevelopment.
  ///
  /// In ar, this message translates to:
  /// **'نمو خضري'**
  String get stageDevelopment;

  /// No description provided for @stageMid.
  ///
  /// In ar, this message translates to:
  /// **'منتصف الموسم'**
  String get stageMid;

  /// No description provided for @stageLate.
  ///
  /// In ar, this message translates to:
  /// **'نهاية الموسم'**
  String get stageLate;

  /// No description provided for @sourcePublisher.
  ///
  /// In ar, this message translates to:
  /// **'الناشر'**
  String get sourcePublisher;

  /// No description provided for @sourceYear.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get sourceYear;

  /// No description provided for @sourcePage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة'**
  String get sourcePage;

  /// No description provided for @openLink.
  ///
  /// In ar, this message translates to:
  /// **'فتح الرابط'**
  String get openLink;

  /// No description provided for @linkOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الرابط'**
  String get linkOpenFailed;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @admin.
  ///
  /// In ar, this message translates to:
  /// **'المدير'**
  String get admin;

  /// No description provided for @adminNeedsBackend.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المدير تتطلب الاتصال بالخادم'**
  String get adminNeedsBackend;

  /// No description provided for @adminNotAuthorized.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب ليس لديه صلاحية المدير'**
  String get adminNotAuthorized;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signInFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get signInFailed;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @publishReviewed.
  ///
  /// In ar, this message translates to:
  /// **'نشر المراجَع'**
  String get publishReviewed;

  /// No description provided for @publishConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد النشر'**
  String get publishConfirmTitle;

  /// No description provided for @publishConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم نشر جميع الصفوف التي تمت مراجعتها في «{table}». هل تريد المتابعة؟'**
  String publishConfirmBody(String table);

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @publishedRows.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر {count} صفاً'**
  String publishedRows(int count);

  /// No description provided for @operationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت العملية. حاول مرة أخرى.'**
  String get operationFailed;

  /// No description provided for @statusDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get statusDraft;

  /// No description provided for @statusReviewed.
  ///
  /// In ar, this message translates to:
  /// **'تمت المراجعة'**
  String get statusReviewed;

  /// No description provided for @statusPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get statusPublished;

  /// No description provided for @tableGovernorates.
  ///
  /// In ar, this message translates to:
  /// **'المحافظات'**
  String get tableGovernorates;

  /// No description provided for @tableWilayats.
  ///
  /// In ar, this message translates to:
  /// **'الولايات'**
  String get tableWilayats;

  /// No description provided for @tableCrops.
  ///
  /// In ar, this message translates to:
  /// **'المحاصيل'**
  String get tableCrops;

  /// No description provided for @tableCropRequirements.
  ///
  /// In ar, this message translates to:
  /// **'متطلبات المحاصيل'**
  String get tableCropRequirements;

  /// No description provided for @tableCropStages.
  ///
  /// In ar, this message translates to:
  /// **'مراحل النمو'**
  String get tableCropStages;

  /// No description provided for @tableLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجدول'**
  String get tableLabel;

  /// No description provided for @monthlyKc.
  ///
  /// In ar, this message translates to:
  /// **'معامل المحصول الشهري'**
  String get monthlyKc;

  /// Calendar month name; month is m1..m12
  ///
  /// In ar, this message translates to:
  /// **'{month, select, m1{يناير} m2{فبراير} m3{مارس} m4{أبريل} m5{مايو} m6{يونيو} m7{يوليو} m8{أغسطس} m9{سبتمبر} m10{أكتوبر} m11{نوفمبر} m12{ديسمبر} other{}}'**
  String monthName(String month);

  /// No description provided for @monthColumn.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get monthColumn;

  /// No description provided for @kcMonthlyPartial.
  ///
  /// In ar, this message translates to:
  /// **'القيم متاحة لبعض الأشهر فقط'**
  String get kcMonthlyPartial;

  /// No description provided for @tableCropKcMonthly.
  ///
  /// In ar, this message translates to:
  /// **'معامل المحصول الشهري'**
  String get tableCropKcMonthly;

  /// No description provided for @homeTagline.
  ///
  /// In ar, this message translates to:
  /// **'دليل المحاصيل لمزارع عُمان، وكل معلومة بمصدرها'**
  String get homeTagline;

  /// No description provided for @glanceOptTemp.
  ///
  /// In ar, this message translates to:
  /// **'الحرارة المثلى'**
  String get glanceOptTemp;

  /// No description provided for @glanceSeason.
  ///
  /// In ar, this message translates to:
  /// **'طول الموسم'**
  String get glanceSeason;

  /// No description provided for @glanceSalinity.
  ///
  /// In ar, this message translates to:
  /// **'تحمّل ملوحة التربة'**
  String get glanceSalinity;

  /// No description provided for @unitDays.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get unitDays;

  /// No description provided for @unitCelsius.
  ///
  /// In ar, this message translates to:
  /// **'°م'**
  String get unitCelsius;

  /// No description provided for @unitSalinity.
  ///
  /// In ar, this message translates to:
  /// **'dS/m'**
  String get unitSalinity;

  /// No description provided for @waterNeedTitle.
  ///
  /// In ar, this message translates to:
  /// **'احتياج الماء خلال الموسم'**
  String get waterNeedTitle;

  /// No description provided for @waterNeedHelp.
  ///
  /// In ar, this message translates to:
  /// **'معامل المحصول Kc يبيّن كم يحتاج المحصول من الماء مقارنةً بعشب مرجعي: 1 يعني مثله، وأقل من 1 يعني أقل منه.'**
  String get waterNeedHelp;

  /// No description provided for @seasonTotal.
  ///
  /// In ar, this message translates to:
  /// **'مدة الموسم {days} يوم'**
  String seasonTotal(int days);

  /// No description provided for @groupTemperature.
  ///
  /// In ar, this message translates to:
  /// **'الحرارة'**
  String get groupTemperature;

  /// No description provided for @groupSoil.
  ///
  /// In ar, this message translates to:
  /// **'التربة والماء'**
  String get groupSoil;

  /// No description provided for @groupPlace.
  ///
  /// In ar, this message translates to:
  /// **'الموقع والموسم'**
  String get groupPlace;

  /// No description provided for @comingMap.
  ///
  /// In ar, this message translates to:
  /// **'أي المحاصيل تناسب ولايتك وأرضك.'**
  String get comingMap;

  /// No description provided for @comingCalendar.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الزراعة والري لكل محصول على مدار السنة.'**
  String get comingCalendar;

  /// No description provided for @comingFarm.
  ///
  /// In ar, this message translates to:
  /// **'سجّل محاصيلك واحصل على تذكير بمواعيد العناية بها.'**
  String get comingFarm;

  /// No description provided for @comingStore.
  ///
  /// In ar, this message translates to:
  /// **'محلات البذور والأسمدة والمستلزمات القريبة منك.'**
  String get comingStore;

  /// No description provided for @salinityShort.
  ///
  /// In ar, this message translates to:
  /// **'ملوحة'**
  String get salinityShort;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingEvening;

  /// No description provided for @homeHeadline.
  ///
  /// In ar, this message translates to:
  /// **'ماذا ستزرع اليوم؟'**
  String get homeHeadline;

  /// No description provided for @farmTitle.
  ///
  /// In ar, this message translates to:
  /// **'مزرعتي'**
  String get farmTitle;

  /// No description provided for @farmEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم تضف محاصيل بعد'**
  String get farmEmptyTitle;

  /// No description provided for @farmEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'أضف ما زرعته وتاريخ زراعته، وسيخبرك التطبيق بمرحلته واحتياجه من الماء وموعد حصاده.'**
  String get farmEmptyBody;

  /// No description provided for @farmAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف محصولاً'**
  String get farmAdd;

  /// No description provided for @farmPickCrop.
  ///
  /// In ar, this message translates to:
  /// **'ماذا زرعت؟'**
  String get farmPickCrop;

  /// No description provided for @farmPickDate.
  ///
  /// In ar, this message translates to:
  /// **'متى زرعته؟'**
  String get farmPickDate;

  /// No description provided for @farmSave.
  ///
  /// In ar, this message translates to:
  /// **'أضف إلى مزرعتي'**
  String get farmSave;

  /// No description provided for @farmRemove.
  ///
  /// In ar, this message translates to:
  /// **'احذف من مزرعتي'**
  String get farmRemove;

  /// No description provided for @farmRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف {crop} من مزرعتي؟'**
  String farmRemoveConfirm(String crop);

  /// No description provided for @farmRemoved.
  ///
  /// In ar, this message translates to:
  /// **'حُذف {crop}'**
  String farmRemoved(String crop);

  /// No description provided for @farmPlantedOn.
  ///
  /// In ar, this message translates to:
  /// **'زُرع في {date}'**
  String farmPlantedOn(String date);

  /// No description provided for @farmDayOf.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {day} من {total}'**
  String farmDayOf(int day, int total);

  /// No description provided for @farmNotStarted.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ موسمه في {date}'**
  String farmNotStarted(String date);

  /// No description provided for @farmFinished.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الموسم: وقت الحصاد'**
  String get farmFinished;

  /// No description provided for @farmDaysToHarvest.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{الحصاد اليوم} =1{الحصاد بعد يوم واحد} =2{الحصاد بعد يومين} few{الحصاد بعد {n} أيام} many{الحصاد بعد {n} يومًا} other{الحصاد بعد {n} يوم}}'**
  String farmDaysToHarvest(int n);

  /// No description provided for @farmKcToday.
  ///
  /// In ar, this message translates to:
  /// **'حاجة الماء اليوم'**
  String get farmKcToday;

  /// No description provided for @farmKcMonth.
  ///
  /// In ar, this message translates to:
  /// **'حاجة الماء هذا الشهر'**
  String get farmKcMonth;

  /// No description provided for @farmDaysSince.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{زُرع اليوم} =1{منذ يوم واحد} =2{منذ يومين} few{منذ {n} أيام} many{منذ {n} يومًا} other{منذ {n} يوم}}'**
  String farmDaysSince(int n);

  /// No description provided for @farmNoStageData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بعد بيانات مراحل نمو لهذا المحصول'**
  String get farmNoStageData;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @calendarTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get calendarTitle;

  /// No description provided for @calendarHijriNote.
  ///
  /// In ar, this message translates to:
  /// **'حسب تقويم أم القرى، وقد يختلف يوماً عن رؤية الهلال في عُمان، إلى أن يُدخل المدير بداية الشهر المعلنة رسمياً.'**
  String get calendarHijriNote;

  /// No description provided for @calendarHijriSuffix.
  ///
  /// In ar, this message translates to:
  /// **'هـ'**
  String get calendarHijriSuffix;

  /// No description provided for @calendarUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادم في مزرعتي'**
  String get calendarUpcoming;

  /// No description provided for @calendarDayEvents.
  ///
  /// In ar, this message translates to:
  /// **'في هذا اليوم'**
  String get calendarDayEvents;

  /// No description provided for @calendarNoEventsDay.
  ///
  /// In ar, this message translates to:
  /// **'لا مواعيد في هذا اليوم'**
  String get calendarNoEventsDay;

  /// No description provided for @calendarEmptyFarm.
  ///
  /// In ar, this message translates to:
  /// **'أضف محاصيلك في «مزرعتي» لترى هنا مواعيد مراحل نموها وحصادها.'**
  String get calendarEmptyFarm;

  /// No description provided for @calendarGoToFarm.
  ///
  /// In ar, this message translates to:
  /// **'اذهب إلى مزرعتي'**
  String get calendarGoToFarm;

  /// No description provided for @calendarPlantNowLater.
  ///
  /// In ar, this message translates to:
  /// **'«ماذا أزرع هذا الشهر في منطقتي» يُضاف عند اعتماد مصدر موثّق لمواعيد الزراعة في كل منطقة.'**
  String get calendarPlantNowLater;

  /// No description provided for @eventPlanted.
  ///
  /// In ar, this message translates to:
  /// **'زراعة {crop}'**
  String eventPlanted(String crop);

  /// No description provided for @eventStageStarts.
  ///
  /// In ar, this message translates to:
  /// **'{crop}: تبدأ مرحلة {stage}'**
  String eventStageStarts(String crop, String stage);

  /// No description provided for @eventHarvest.
  ///
  /// In ar, this message translates to:
  /// **'{crop}: موعد الحصاد'**
  String eventHarvest(String crop);

  /// No description provided for @inDays.
  ///
  /// In ar, this message translates to:
  /// **'{n, plural, =0{اليوم} =1{غداً} =2{بعد يومين} few{بعد {n} أيام} many{بعد {n} يومًا} other{بعد {n} يوم}}'**
  String inDays(int n);

  /// No description provided for @previousMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر التالي'**
  String get nextMonth;

  /// No description provided for @calendarHijriOfficial.
  ///
  /// In ar, this message translates to:
  /// **'حسب الإعلان الرسمي لبداية الشهر في سلطنة عُمان.'**
  String get calendarHijriOfficial;

  /// No description provided for @hijriAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'بداية الشهر الهجري في عُمان'**
  String get hijriAdminTitle;

  /// No description provided for @hijriAdminHelp.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بداية كل شهر كما أُعلنت رسمياً في عُمان، ليظهر التاريخ الهجري الصحيح في التقويم.'**
  String get hijriAdminHelp;

  /// No description provided for @hijriAdminAdd.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بداية شهر'**
  String get hijriAdminAdd;

  /// No description provided for @hijriYear.
  ///
  /// In ar, this message translates to:
  /// **'السنة الهجرية'**
  String get hijriYear;

  /// No description provided for @hijriMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر الهجري'**
  String get hijriMonth;

  /// No description provided for @hijriStartsOn.
  ///
  /// In ar, this message translates to:
  /// **'أول أيامه (ميلادي)'**
  String get hijriStartsOn;

  /// No description provided for @hijriSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الإعلان'**
  String get hijriSource;

  /// No description provided for @hijriSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت بداية {month} {year}'**
  String hijriSaved(String month, int year);

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get save;

  /// No description provided for @storeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get storeTitle;

  /// No description provided for @storeNeedsInternet.
  ///
  /// In ar, this message translates to:
  /// **'المتجر يحتاج اتصالاً بالإنترنت لعرض المحلات وأسعارها.'**
  String get storeNeedsInternet;

  /// No description provided for @storeEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محلات معتمدة بعد'**
  String get storeEmpty;

  /// No description provided for @storeEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'عندما تسجّل المحلات ويعتمدها المدير ستظهر هنا مع منتجاتها وأسعارها.'**
  String get storeEmptyBody;

  /// No description provided for @storeOwnerCta.
  ///
  /// In ar, this message translates to:
  /// **'هل لديك محل مستلزمات زراعية؟'**
  String get storeOwnerCta;

  /// No description provided for @storeRegisterButton.
  ///
  /// In ar, this message translates to:
  /// **'سجّل محلك'**
  String get storeRegisterButton;

  /// No description provided for @storeMyShopButton.
  ///
  /// In ar, this message translates to:
  /// **'محلي'**
  String get storeMyShopButton;

  /// No description provided for @shopCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصل'**
  String get shopCall;

  /// No description provided for @shopWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get shopWhatsapp;

  /// No description provided for @shopNoProducts.
  ///
  /// In ar, this message translates to:
  /// **'لم يضف المحل منتجات بعد'**
  String get shopNoProducts;

  /// No description provided for @productUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر حالياً'**
  String get productUnavailable;

  /// No description provided for @priceOmr.
  ///
  /// In ar, this message translates to:
  /// **'{price} ر.ع.'**
  String priceOmr(String price);

  /// No description provided for @priceOnRequest.
  ///
  /// In ar, this message translates to:
  /// **'السعر عند الاتصال'**
  String get priceOnRequest;

  /// No description provided for @catSeeds.
  ///
  /// In ar, this message translates to:
  /// **'بذور'**
  String get catSeeds;

  /// No description provided for @catSeedlings.
  ///
  /// In ar, this message translates to:
  /// **'شتلات'**
  String get catSeedlings;

  /// No description provided for @catFertilizer.
  ///
  /// In ar, this message translates to:
  /// **'أسمدة'**
  String get catFertilizer;

  /// No description provided for @catPesticide.
  ///
  /// In ar, this message translates to:
  /// **'مبيدات'**
  String get catPesticide;

  /// No description provided for @catIrrigation.
  ///
  /// In ar, this message translates to:
  /// **'ري'**
  String get catIrrigation;

  /// No description provided for @catTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات'**
  String get catTools;

  /// No description provided for @catOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get catOther;

  /// No description provided for @myShopTitle.
  ///
  /// In ar, this message translates to:
  /// **'محلي'**
  String get myShopTitle;

  /// No description provided for @signInToRegister.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حساباً لتسجيل محلك.'**
  String get signInToRegister;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لدي حساب'**
  String get haveAccount;

  /// No description provided for @confirmEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رسالة إلى بريدك. افتحها لتأكيد الحساب، ثم سجّل الدخول.'**
  String get confirmEmailSent;

  /// No description provided for @shopName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المحل'**
  String get shopName;

  /// No description provided for @shopWilayat.
  ///
  /// In ar, this message translates to:
  /// **'الولاية'**
  String get shopWilayat;

  /// No description provided for @shopPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get shopPhone;

  /// No description provided for @shopWhatsappField.
  ///
  /// In ar, this message translates to:
  /// **'رقم الواتساب (اختياري)'**
  String get shopWhatsappField;

  /// No description provided for @shopAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (اختياري)'**
  String get shopAddress;

  /// No description provided for @registerShop.
  ///
  /// In ar, this message translates to:
  /// **'أرسل للاعتماد'**
  String get registerShop;

  /// No description provided for @saveShop.
  ///
  /// In ar, this message translates to:
  /// **'احفظ التعديلات'**
  String get saveShop;

  /// No description provided for @shopPendingNote.
  ///
  /// In ar, this message translates to:
  /// **'محلك بانتظار اعتماد المدير. أضف منتجاتك الآن، وستظهر للمزارعين بعد الاعتماد.'**
  String get shopPendingNote;

  /// No description provided for @shopApprovedNote.
  ///
  /// In ar, this message translates to:
  /// **'محلك معتمد وظاهر للمزارعين.'**
  String get shopApprovedNote;

  /// No description provided for @shopSuspendedNote.
  ///
  /// In ar, this message translates to:
  /// **'أوقف المدير ظهور محلك. تواصل معه لمعرفة السبب.'**
  String get shopSuspendedNote;

  /// No description provided for @productsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get productsTitle;

  /// No description provided for @addProduct.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاً'**
  String get addProduct;

  /// No description provided for @productName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get productName;

  /// No description provided for @productCategory.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get productCategory;

  /// No description provided for @productPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر (ر.ع.)'**
  String get productPrice;

  /// No description provided for @productUnit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة، مثل: كيس 50 كغ'**
  String get productUnit;

  /// No description provided for @productAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get productAvailable;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get delete;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقماً صحيحاً، مثل 9123 4567'**
  String get invalidPhone;

  /// No description provided for @invalidPrice.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعراً صحيحاً'**
  String get invalidPrice;

  /// No description provided for @pendingShops.
  ///
  /// In ar, this message translates to:
  /// **'محلات بانتظار الاعتماد'**
  String get pendingShops;

  /// No description provided for @approveShop.
  ///
  /// In ar, this message translates to:
  /// **'اعتمد'**
  String get approveShop;

  /// No description provided for @suspendShop.
  ///
  /// In ar, this message translates to:
  /// **'أوقف'**
  String get suspendShop;

  /// No description provided for @noPendingShops.
  ///
  /// In ar, this message translates to:
  /// **'لا محلات بانتظار الاعتماد'**
  String get noPendingShops;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ'**
  String get saved;

  /// No description provided for @mapTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get mapTitle;

  /// No description provided for @mapPickCrop.
  ///
  /// In ar, this message translates to:
  /// **'اختر محصولاً'**
  String get mapPickCrop;

  /// No description provided for @mapPlantIn.
  ///
  /// In ar, this message translates to:
  /// **'الزراعة في'**
  String get mapPlantIn;

  /// No description provided for @mapTapHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على أي مكان في الخريطة لترى التفاصيل.'**
  String get mapTapHint;

  /// No description provided for @mapModelNote.
  ///
  /// In ar, this message translates to:
  /// **'تقدير بالنموذج من الحرارة الشهرية والارتفاع فقط، ولا يشمل التربة والملوحة والمياه بعد.'**
  String get mapModelNote;

  /// No description provided for @mapNoRequirements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بعد متطلبات حرارة موثّقة لهذا المحصول، فلا يمكن حساب ملاءمته.'**
  String get mapNoRequirements;

  /// No description provided for @suitHigh.
  ///
  /// In ar, this message translates to:
  /// **'مناسب'**
  String get suitHigh;

  /// No description provided for @suitMedium.
  ///
  /// In ar, this message translates to:
  /// **'مناسب بدرجة متوسطة'**
  String get suitMedium;

  /// No description provided for @suitLow.
  ///
  /// In ar, this message translates to:
  /// **'ضعيف الملاءمة'**
  String get suitLow;

  /// No description provided for @suitNone.
  ///
  /// In ar, this message translates to:
  /// **'غير مناسب'**
  String get suitNone;

  /// No description provided for @limitCold.
  ///
  /// In ar, this message translates to:
  /// **'بارد جداً في {month}: {value}° أقل من حاجة المحصول'**
  String limitCold(String month, String value);

  /// No description provided for @limitHeat.
  ///
  /// In ar, this message translates to:
  /// **'حار جداً في {month}: {value}° أعلى من حد المحصول'**
  String limitHeat(String month, String value);

  /// No description provided for @limitAltitude.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع {value} م أعلى من حد المحصول'**
  String limitAltitude(String value);

  /// No description provided for @limitNone.
  ///
  /// In ar, this message translates to:
  /// **'الحرارة مناسبة طوال الموسم'**
  String get limitNone;

  /// No description provided for @envElevation.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع'**
  String get envElevation;

  /// No description provided for @envTavg.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الحرارة'**
  String get envTavg;

  /// No description provided for @envTmin.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الصغرى'**
  String get envTmin;

  /// No description provided for @envTmax.
  ///
  /// In ar, this message translates to:
  /// **'متوسط العظمى'**
  String get envTmax;

  /// No description provided for @mapScore.
  ///
  /// In ar, this message translates to:
  /// **'درجة الملاءمة'**
  String get mapScore;

  /// No description provided for @mapSources.
  ///
  /// In ar, this message translates to:
  /// **'المناخ والارتفاع: WorldClim 2.1 (Fick & Hijmans 2017). القوام والحموضة: SoilGrids 2.0 (Poggio وآخرون 2021، ISRIC). الملوحة: HWSD v2.0 (FAO و IIASA 2023، CC BY-NC-SA 3.0 IGO). حدود عُمان: © مساهمو OpenStreetMap.'**
  String get mapSources;

  /// No description provided for @mapLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل الخريطة…'**
  String get mapLoading;

  /// No description provided for @mapLayerSuit.
  ///
  /// In ar, this message translates to:
  /// **'الملاءمة'**
  String get mapLayerSuit;

  /// No description provided for @mapLayerTexture.
  ///
  /// In ar, this message translates to:
  /// **'القوام'**
  String get mapLayerTexture;

  /// No description provided for @mapLayerPh.
  ///
  /// In ar, this message translates to:
  /// **'الحموضة'**
  String get mapLayerPh;

  /// No description provided for @soilUnknown.
  ///
  /// In ar, this message translates to:
  /// **'لا بيانات'**
  String get soilUnknown;

  /// No description provided for @phUpTo7.
  ///
  /// In ar, this message translates to:
  /// **'7.0 أو أقل'**
  String get phUpTo7;

  /// No description provided for @ph7to75.
  ///
  /// In ar, this message translates to:
  /// **'7.0 – 7.5'**
  String get ph7to75;

  /// No description provided for @ph75to8.
  ///
  /// In ar, this message translates to:
  /// **'7.5 – 8.0'**
  String get ph75to8;

  /// No description provided for @phAbove8.
  ///
  /// In ar, this message translates to:
  /// **'أعلى من 8.0'**
  String get phAbove8;

  /// No description provided for @soilTitle.
  ///
  /// In ar, this message translates to:
  /// **'التربة (أعلى 30 سم)'**
  String get soilTitle;

  /// No description provided for @soilSandClay.
  ///
  /// In ar, this message translates to:
  /// **'رمل {sand}% · طين {clay}%'**
  String soilSandClay(String sand, String clay);

  /// No description provided for @soilConditionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'شروط التربة لهذا المحصول'**
  String get soilConditionsTitle;

  /// No description provided for @condTexture.
  ///
  /// In ar, this message translates to:
  /// **'قوام التربة هنا ({texture}) ليس من الأنواع المناسبة للمحصول'**
  String condTexture(String texture);

  /// No description provided for @condPhHigh.
  ///
  /// In ar, this message translates to:
  /// **'التربة قلوية: pH {value} أعلى من حد المحصول {limit}'**
  String condPhHigh(String value, String limit);

  /// No description provided for @condPhLow.
  ///
  /// In ar, this message translates to:
  /// **'التربة حمضية: pH {value} أقل من حد المحصول {limit}'**
  String condPhLow(String value, String limit);

  /// No description provided for @soilNoConditions.
  ///
  /// In ar, this message translates to:
  /// **'لا شروط تربة لهذا المحصول هنا'**
  String get soilNoConditions;

  /// No description provided for @soilNote.
  ///
  /// In ar, this message translates to:
  /// **'القوام والحموضة من SoilGrids (تقدير عالمي بدقة 5 كم)، والملوحة من قاعدة HWSD v2.0 (خرائط أقدم وأخشن، والملوحة تتغير بالري ومياه الآبار). قد لا تمثّل تربة مزرعتك؛ افحص التربة والماء قبل الزراعة.'**
  String get soilNote;

  /// No description provided for @mapLayerSalinity.
  ///
  /// In ar, this message translates to:
  /// **'الملوحة'**
  String get mapLayerSalinity;

  /// No description provided for @soilSalinity.
  ///
  /// In ar, this message translates to:
  /// **'الملوحة'**
  String get soilSalinity;

  /// No description provided for @salNone.
  ///
  /// In ar, this message translates to:
  /// **'غير مالحة (أقل من 2)'**
  String get salNone;

  /// No description provided for @salSlight.
  ///
  /// In ar, this message translates to:
  /// **'خفيفة (2–4)'**
  String get salSlight;

  /// No description provided for @salModerate.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة (4–8)'**
  String get salModerate;

  /// No description provided for @salStrong.
  ///
  /// In ar, this message translates to:
  /// **'شديدة (8–16)'**
  String get salStrong;

  /// No description provided for @salVeryStrong.
  ///
  /// In ar, this message translates to:
  /// **'شديدة جدًا (أكثر من 16)'**
  String get salVeryStrong;

  /// No description provided for @condSalinity.
  ///
  /// In ar, this message translates to:
  /// **'ملوحة التربة {value} أعلى من حد تحمّل المحصول {limit}، فيُتوقع نقص في الإنتاج'**
  String condSalinity(String value, String limit);

  /// No description provided for @waterTitle.
  ///
  /// In ar, this message translates to:
  /// **'ماء الري'**
  String get waterTitle;

  /// No description provided for @waterEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'أدخل نتيجة فحص المختبر لماء البئر أو الفلج، وسيخبرك التطبيق بجودته وأثره على محاصيلك.'**
  String get waterEmptyBody;

  /// No description provided for @waterAddTest.
  ///
  /// In ar, this message translates to:
  /// **'أدخل نتيجة فحص الماء'**
  String get waterAddTest;

  /// No description provided for @waterNewTest.
  ///
  /// In ar, this message translates to:
  /// **'فحص جديد'**
  String get waterNewTest;

  /// No description provided for @waterSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة فحص الماء'**
  String get waterSheetTitle;

  /// No description provided for @waterSourceLabel.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الماء'**
  String get waterSourceLabel;

  /// No description provided for @waterSourceWell.
  ///
  /// In ar, this message translates to:
  /// **'بئر'**
  String get waterSourceWell;

  /// No description provided for @waterSourceFalaj.
  ///
  /// In ar, this message translates to:
  /// **'فلج'**
  String get waterSourceFalaj;

  /// No description provided for @waterSourceDesal.
  ///
  /// In ar, this message translates to:
  /// **'مياه محلاة'**
  String get waterSourceDesal;

  /// No description provided for @waterSourceOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get waterSourceOther;

  /// No description provided for @waterDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفحص'**
  String get waterDate;

  /// No description provided for @waterEcLabel.
  ///
  /// In ar, this message translates to:
  /// **'الملوحة (أهم قيمة في الفحص)'**
  String get waterEcLabel;

  /// No description provided for @waterEcField.
  ///
  /// In ar, this message translates to:
  /// **'EC أو TDS كما في ورقة المختبر'**
  String get waterEcField;

  /// No description provided for @waterEcRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الملوحة بالوحدة المكتوبة في ورقة الفحص'**
  String get waterEcRequired;

  /// No description provided for @waterOptional.
  ///
  /// In ar, this message translates to:
  /// **'قيم إضافية إن وُجدت في الفحص'**
  String get waterOptional;

  /// No description provided for @waterInvalid.
  ///
  /// In ar, this message translates to:
  /// **'قيمة غير صحيحة'**
  String get waterInvalid;

  /// No description provided for @waterSprinkler.
  ///
  /// In ar, this message translates to:
  /// **'أروي بالرش'**
  String get waterSprinkler;

  /// No description provided for @waterSprinklerHint.
  ///
  /// In ar, this message translates to:
  /// **'الرش يبلل الأوراق، فتنخفض حدود الكلوريد'**
  String get waterSprinklerHint;

  /// No description provided for @waterSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الفحص'**
  String get waterSave;

  /// No description provided for @waterVerdictNone.
  ///
  /// In ar, this message translates to:
  /// **'صالح للري دون قيود'**
  String get waterVerdictNone;

  /// No description provided for @waterVerdictSlight.
  ///
  /// In ar, this message translates to:
  /// **'صالح للري مع الحذر'**
  String get waterVerdictSlight;

  /// No description provided for @waterVerdictSevere.
  ///
  /// In ar, this message translates to:
  /// **'قيود شديدة على استخدامه للري'**
  String get waterVerdictSevere;

  /// No description provided for @paramSalinity.
  ///
  /// In ar, this message translates to:
  /// **'الملوحة'**
  String get paramSalinity;

  /// No description provided for @paramInfiltration.
  ///
  /// In ar, this message translates to:
  /// **'نفاذية التربة'**
  String get paramInfiltration;

  /// No description provided for @paramSodium.
  ///
  /// In ar, this message translates to:
  /// **'الصوديوم'**
  String get paramSodium;

  /// No description provided for @paramChloride.
  ///
  /// In ar, this message translates to:
  /// **'الكلوريد'**
  String get paramChloride;

  /// No description provided for @paramBoron.
  ///
  /// In ar, this message translates to:
  /// **'البورون'**
  String get paramBoron;

  /// No description provided for @sevNone.
  ///
  /// In ar, this message translates to:
  /// **'لا قيود'**
  String get sevNone;

  /// No description provided for @sevSlight.
  ///
  /// In ar, this message translates to:
  /// **'قيود خفيفة إلى متوسطة'**
  String get sevSlight;

  /// No description provided for @sevSevere.
  ///
  /// In ar, this message translates to:
  /// **'قيود شديدة'**
  String get sevSevere;

  /// No description provided for @adviceSalinity.
  ///
  /// In ar, this message translates to:
  /// **'أعطِ ماءً زائدًا لغسل الأملاح من منطقة الجذور، واختر محاصيل تتحمل الملوحة.'**
  String get adviceSalinity;

  /// No description provided for @adviceInfiltration.
  ///
  /// In ar, this message translates to:
  /// **'قد تتكوّن قشرة على سطح التربة تمنع تسرب الماء؛ الجبس الزراعي يحسّن النفاذية.'**
  String get adviceInfiltration;

  /// No description provided for @adviceSodium.
  ///
  /// In ar, this message translates to:
  /// **'خطر تسمم الجذور بالصوديوم، خاصة في الأشجار.'**
  String get adviceSodium;

  /// No description provided for @adviceChloride.
  ///
  /// In ar, this message translates to:
  /// **'قد يحرق أطراف الأوراق، خاصة في الحمضيات والعنب.'**
  String get adviceChloride;

  /// No description provided for @adviceBoron.
  ///
  /// In ar, this message translates to:
  /// **'البورون الزائد يضر المحاصيل الحساسة كالحمضيات والبقوليات.'**
  String get adviceBoron;

  /// No description provided for @advicePh.
  ///
  /// In ar, this message translates to:
  /// **'خارج المدى الطبيعي (6.5–8.4)؛ اطلب من المختبر فحص البيكربونات.'**
  String get advicePh;

  /// No description provided for @waterOnCrops.
  ///
  /// In ar, this message translates to:
  /// **'أثره على محاصيلك'**
  String get waterOnCrops;

  /// No description provided for @waterYield.
  ///
  /// In ar, this message translates to:
  /// **'الإنتاج المتوقع نحو {pct}'**
  String waterYield(String pct);

  /// No description provided for @waterWithinTolerance.
  ///
  /// In ar, this message translates to:
  /// **'ضمن تحمّله'**
  String get waterWithinTolerance;

  /// No description provided for @waterAboveTolerance.
  ///
  /// In ar, this message translates to:
  /// **'فوق تحمّله: يُتوقع نقص في الإنتاج'**
  String get waterAboveTolerance;

  /// No description provided for @waterNoThreshold.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حد ملوحة موثّق'**
  String get waterNoThreshold;

  /// No description provided for @waterCropMax.
  ///
  /// In ar, this message translates to:
  /// **'يتحمّل حتى {ec} في ماء الري'**
  String waterCropMax(String ec);

  /// No description provided for @waterAddCropsHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف محاصيلك لترى أثر هذا الماء عليها.'**
  String get waterAddCropsHint;

  /// No description provided for @waterHistory.
  ///
  /// In ar, this message translates to:
  /// **'الفحوصات السابقة'**
  String get waterHistory;

  /// No description provided for @waterDelete.
  ///
  /// In ar, this message translates to:
  /// **'احذف الفحص'**
  String get waterDelete;

  /// No description provided for @waterDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا الفحص؟'**
  String get waterDeleteConfirm;

  /// No description provided for @waterNote.
  ///
  /// In ar, this message translates to:
  /// **'المعايير: نشرة الفاو للري والصرف رقم 29 (أيرز وويستكوت، 1985). يُقدَّر الإنتاج بمعادلة ماس وهوفمان على افتراض أن ملوحة التربة تبلغ مرة ونصف ملوحة الماء (غسيل 15–20%). يبقى الفحص على جهازك فقط.'**
  String get waterNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
