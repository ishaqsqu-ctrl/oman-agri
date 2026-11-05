import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/calendar/calendar_screen.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/farm/farm_screen.dart' show todayProvider;
import 'package:oman_agri/features/farm/farm_store.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's', reviewedBy: 'r', reviewedAt: '2026-11-04');
final _snap = KnowledgeSnapshot(
  generatedAt: DateTime.utc(2026, 11, 5),
  sources: const {},
  crops: [
    Crop(id: 'tomato', nameAr: 'طماطم', nameEn: 'Tomato', categories: const [CropCategory.vegetable], meta: _m, stages: [
      CropStage(seq: 1, stage: 'initial', durationDays: 30, kc: 0.6, meta: _m),
      CropStage(seq: 2, stage: 'development', durationDays: 40, kc: 1.15, meta: _m),
      CropStage(seq: 3, stage: 'mid', durationDays: 40, kc: 1.15, meta: _m),
      CropStage(seq: 4, stage: 'late', durationDays: 25, kc: 0.8, meta: _m),
    ]),
  ],
);

Future<void> _pump(WidgetTester tester, {String? farm}) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({localePrefKey: 'ar', farmPrefKey: ?farm});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      knowledgeProvider.overrideWith((ref) async => _snap),
      todayProvider.overrideWithValue(DateTime(2026, 11, 5)),
    ],
    child: MaterialApp(
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: CalendarScreen()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('today shows Gregorian and Umm al-Qura dates, with the sighting note', (tester) async {
    await _pump(tester);
    final h = HijriCalendar.fromDate(DateTime(2026, 11, 5));
    expect(find.text('${h.hDay} ${hijriMonthName(h.hMonth, 'ar')} ${h.hYear} هـ'), findsOneWidget);
    expect(find.text('5 نوفمبر 2026'), findsOneWidget); // 0–9 digits, as in the rest of the app
    expect(find.textContaining('أم القرى'), findsOneWidget);
    expect(find.text('أضف محاصيلك في «مزرعتي» لترى هنا مواعيد مراحل نموها وحصادها.'), findsOneWidget);
  });

  testWidgets('farm plantings become dated events; tapping a day lists them', (tester) async {
    await _pump(tester, farm: '[{"id":"a","crop_id":"tomato","planted_on":"2026-10-01"}]');
    // Next event after 5 Nov: "mid" starts on 10 Dec (35 days away).
    expect(find.text('طماطم: تبدأ مرحلة منتصف الموسم'), findsOneWidget);
    expect(find.textContaining('بعد 35 يومًا'), findsOneWidget);
    // Previous month holds the development-stage start on 31 Oct.
    await tester.tap(find.byTooltip('الشهر السابق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('31').first);
    await tester.pumpAndSettle();
    expect(find.text('طماطم: تبدأ مرحلة نمو خضري'), findsOneWidget);
  });
}
