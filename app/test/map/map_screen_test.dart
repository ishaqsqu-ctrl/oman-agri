import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/farm/farm_screen.dart' show todayProvider;
import 'package:oman_agri/features/map/map_screen.dart';
import 'package:oman_agri/features/map/suitability.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's', reviewedBy: 'r', reviewedAt: '2026-11-04');

EnvCell _cell(int col, {double t = 24, int elev = 50}) => EnvCell(
    col: col, row: 0, elev: elev, tavg: List.filled(12, t), tmin: List.filled(12, t - 6), tmax: List.filled(12, t + 6),
    sand: 52, silt: 28, clay: 20, ph: 8.2, ec: 3.4);

final _map = MapData(
  originLon: 56, originLat: 24, cellDeg: 1, cols: 3, rows: 1,
  cells: [_cell(0), _cell(1, t: 33), _cell(2, elev: 3000)],
  outline: const [],
);

Future<void> _pump(WidgetTester tester, {List<Crop>? crops}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({localePrefKey: 'ar'});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      todayProvider.overrideWithValue(DateTime(2026, 11, 5)),
      mapDataProvider.overrideWith((ref) async => _map),
      knowledgeProvider.overrideWith((ref) async => KnowledgeSnapshot(
            generatedAt: DateTime.utc(2026),
            sources: const {},
            crops: crops ??
                [
                  Crop(
                    id: 'tomato',
                    nameAr: 'طماطم',
                    nameEn: 'Tomato',
                    categories: const [CropCategory.vegetable],
                    requirements: const CropRequirements(
                        tMin: 7, tOptLow: 20, tOptHigh: 27, tMax: 35, altMax: 2400, seasonDaysMin: 70,
                        phMin: 5, phMax: 7.5, eceThreshold: 2.5, textures: ['sand', 'loam', 'clay'], meta: _m),
                    meta: _m,
                  ),
                ],
          )),
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
      home: const Scaffold(body: MapScreen()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a place shows its score, reason and environment', (tester) async {
    await _pump(tester);
    final map = tester.getRect(find.byType(CustomPaint).last);
    // Left cell (ideal), middle cell (too hot in Nov: tmax 39 > 35), right cell (3000 m).
    await tester.tapAt(Offset(map.left + map.width / 6, map.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('مناسب'), findsWidgets);
    expect(find.text('الحرارة مناسبة طوال الموسم'), findsOneWidget);

    await tester.tapAt(Offset(map.center.dx, map.center.dy));
    await tester.pumpAndSettle();
    expect(find.textContaining('حار جداً في نوفمبر'), findsOneWidget);

    await tester.tapAt(Offset(map.right - map.width / 6, map.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('الارتفاع 3000 م أعلى من حد المحصول'), findsOneWidget);
    expect(find.textContaining('تقدير بالنموذج'), findsOneWidget);
  });

  testWidgets('a crop without temperature requirements says the estimate is impossible', (tester) async {
    await _pump(tester, crops: [
      const Crop(id: 'tomato', nameAr: 'ورد', nameEn: 'Rose', requirements: CropRequirements(meta: _m), meta: _m),
    ]);
    expect(find.text('لا توجد بعد متطلبات حرارة موثّقة لهذا المحصول، فلا يمكن حساب ملاءمته.'), findsOneWidget);
  });

  testWidgets('place card shows the soil and its conditions for the crop', (tester) async {
    await _pump(tester);
    final map = tester.getRect(find.byType(CustomPaint).last);
    await tester.tapAt(Offset(map.left + map.width / 6, map.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('التربة (أعلى 30 سم)'), findsOneWidget);
    expect(find.text('طميية'), findsOneWidget);
    expect(find.text('8.2'), findsOneWidget);
    expect(find.text('رمل 52% · طين 20%'), findsOneWidget);
    expect(find.text('التربة قلوية: pH 8.2 أعلى من حد المحصول 7.5'), findsOneWidget);
    expect(find.text('3.4 dS/m'), findsOneWidget);
    expect(find.text('ملوحة التربة \u20663.4 dS/m\u2069 أعلى من حد تحمّل المحصول \u20662.5 dS/m\u2069، فيُتوقع نقص في الإنتاج'), findsOneWidget);
  });

  testWidgets('soil layers switch the legend', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('القوام'));
    await tester.pumpAndSettle();
    expect(find.text('رملية'), findsOneWidget);
    expect(find.text('طينية'), findsOneWidget);
    await tester.tap(find.text('الحموضة'));
    await tester.pumpAndSettle();
    expect(find.text('أعلى من 8.0'), findsOneWidget);
    await tester.tap(find.text('الملوحة'));
    await tester.pumpAndSettle();
    expect(find.text('خفيفة (2–4)'), findsOneWidget);
    expect(find.text('شديدة جدًا (أكثر من 16)'), findsOneWidget);
  });
}
