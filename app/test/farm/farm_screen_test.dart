import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/farm_screen.dart';
import 'package:oman_agri/features/farm/farm_store.dart';
import 'package:oman_agri/features/farm/water_quality.dart';
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
      requirements: const CropRequirements(eceThreshold: 2.5, eceSlope: 9.9, meta: _m),
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

Future<SharedPreferences> _pump(WidgetTester tester, {Map<String, Object> prefs = const {}, double width = 420}) async {
  tester.view.physicalSize = Size(width, 900);
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

  testWidgets('a water test in µS/cm shows its quality and the yield effect on tomato', (tester) async {
    final sp = await _pump(tester, prefs: {
      farmPrefKey: '[{"id":"a","crop_id":"tomato","planted_on":"2026-11-01"},{"id":"b","crop_id":"henna","planted_on":"2026-11-01"}]',
    });
    await tester.scrollUntilVisible(find.byKey(const ValueKey('water-add')), 200);
    await tester.tap(find.byKey(const ValueKey('water-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('water-save')));
    await tester.pumpAndSettle();
    expect(find.text('أدخل الملوحة بالوحدة المكتوبة في ورقة الفحص'), findsOneWidget);
    await tester.tap(find.text('µS/cm'));
    await tester.enterText(find.byKey(const ValueKey('water-ec')), '٣٠٠٠'); // Arabic digits
    await tester.ensureVisible(find.byKey(const ValueKey('water-b')));
    await tester.enterText(find.byKey(const ValueKey('water-b')), '0.5');
    await tester.pump();
    expect(find.text('0.5'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('water-save')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('الإنتاج المتوقع نحو \u206680%\u2069'), 200);
    expect(find.text('صالح للري مع الحذر'), findsOneWidget);
    expect(find.text('\u20663\u00A0dS/m\u2069'), findsOneWidget);
    expect(find.text('الإنتاج المتوقع نحو \u206680%\u2069'), findsOneWidget);
    expect(find.text('لا يوجد حد ملوحة موثّق'), findsOneWidget); // henna
    final saved = WaterTest.tryParse((jsonDecode(sp.getString(waterPrefKey)!) as List).single)!;
    expect(saved.ec, 3.0);
    expect(saved.boron, 0.5);
  });

  testWidgets('an out-of-range pH is refused', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('water-add')), 200);
    await tester.tap(find.byKey(const ValueKey('water-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('water-ec')), '1.2');
    await tester.ensureVisible(find.byKey(const ValueKey('water-ph')));
    await tester.enterText(find.byKey(const ValueKey('water-ph')), '19');
    await tester.pump();
    expect(find.text('19'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('water-save')));
    await tester.pumpAndSettle();
    expect(find.text('قيمة غير صحيحة'), findsOneWidget);
  });

  testWidgets('water card fits 320 px at double text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, width: 320, prefs: {
      farmPrefKey: '[{"id":"a","crop_id":"tomato","planted_on":"2026-11-01"}]',
      waterPrefKey: '[{"id":"w","date":"2026-11-02","source":"desalinated","ec":3.2,"ph":9,"sar":25,"cl":12,"b":4,"sprinkler":true},'
          '{"id":"v","date":"2025-01-02","source":"falaj","ec":0.4}]',
    });
    await tester.scrollUntilVisible(find.text('الفحوصات السابقة'), 300);
    expect(tester.takeException(), isNull);
  });
}
