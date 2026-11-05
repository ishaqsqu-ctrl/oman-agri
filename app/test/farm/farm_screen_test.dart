import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/farm_screen.dart';
import 'package:oman_agri/features/farm/farm_store.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _m = KnowledgeMeta(
    status: KnowledgeStatus.published, sourceId: 's', reviewedBy: 'r', reviewedAt: '2026-11-04');

final _snap = KnowledgeSnapshot(
  generatedAt: DateTime.utc(2026, 11, 5),
  sources: const {},
  crops: [
    Crop(
      id: 'tomato',
      nameAr: 'طماطم',
      nameEn: 'Tomato',
      categories: const [CropCategory.vegetable],
      stages: [
        CropStage(seq: 1, stage: 'initial', durationDays: 30, kc: 0.6, meta: _m),
        CropStage(seq: 2, stage: 'development', durationDays: 40, kc: 1.15, meta: _m),
        CropStage(seq: 3, stage: 'mid', durationDays: 40, kc: 1.15, meta: _m),
        CropStage(seq: 4, stage: 'late', durationDays: 25, kc: 0.8, meta: _m),
      ],
      meta: _m,
    ),
    Crop(id: 'henna', nameAr: 'حناء', nameEn: 'Henna', categories: const [CropCategory.ornamental], meta: _m),
  ],
);

Future<SharedPreferences> _pump(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({localePrefKey: 'ar', ...prefs});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      knowledgeProvider.overrideWith((ref) async => _snap),
      todayProvider.overrideWithValue(DateTime(2026, 11, 14)),
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
      home: const FarmScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return sp;
}

void main() {
  testWidgets('empty farm invites the first crop', (tester) async {
    await _pump(tester);
    expect(find.text('لم تضف محاصيل بعد'), findsOneWidget);
    expect(find.text('أضف محصولاً'), findsOneWidget);
  });

  testWidgets('adding tomato shows its stage, day, harvest countdown and Kc; it persists', (tester) async {
    final sp = await _pump(tester);
    await tester.tap(find.text('أضف محصولاً'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    // Planted on day 1 of November; today is the 14th -> day 14, initial stage.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف إلى مزرعتي'));
    await tester.pumpAndSettle();
    expect(find.text('أولية'), findsOneWidget);
    expect(find.text('اليوم 14 من 135'), findsOneWidget);
    expect(find.text('الحصاد بعد 121 يومًا'), findsOneWidget);
    expect(find.text('Kc 0.60'), findsOneWidget);
    expect(sp.getString(farmPrefKey), contains('"planted_on":"2026-11-01"'));
  });

  testWidgets('crop without stage data says so instead of guessing', (tester) async {
    await _pump(tester, prefs: {
      farmPrefKey: '[{"id":"a","crop_id":"henna","planted_on":"2026-11-04"}]',
    });
    expect(find.text('حناء'), findsOneWidget);
    expect(find.text('منذ 10 يوم'), findsNothing); // Arabic plural: 10 -> few
    expect(find.text('منذ 10 أيام'), findsOneWidget);
    expect(find.text('لا توجد بعد بيانات مراحل نمو لهذا المحصول'), findsOneWidget);
  });

  testWidgets('removing asks first, then removes', (tester) async {
    final sp = await _pump(tester, prefs: {
      farmPrefKey: '[{"id":"a","crop_id":"tomato","planted_on":"2026-11-01"}]',
    });
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('احذف من مزرعتي').first);
    await tester.pumpAndSettle();
    expect(find.text('هل تريد حذف طماطم من مزرعتي؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'احذف من مزرعتي'));
    await tester.pumpAndSettle();
    expect(find.text('طماطم'), findsNothing);
    expect(sp.getString(farmPrefKey), '[]');
  });

  testWidgets('a corrupt saved farm does not crash', (tester) async {
    await _pump(tester, prefs: {farmPrefKey: '{not json'});
    expect(find.text('لم تضف محاصيل بعد'), findsOneWidget);
  });
}
