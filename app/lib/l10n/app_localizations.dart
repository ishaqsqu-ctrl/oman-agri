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
