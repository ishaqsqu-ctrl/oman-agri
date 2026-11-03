import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/app.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/router.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/draft_banner.dart';
import 'package:oman_agri/features/crops/ui/source_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

KnowledgeMeta _m(KnowledgeStatus s, [String page = 'Table 12']) => KnowledgeMeta(
    status: s,
    sourceId: 'fao56',
    sourcePage: page,
    reviewedBy: s == KnowledgeStatus.published ? 'Dr Ali' : null,
    reviewedAt: s == KnowledgeStatus.published ? '2026-10-01' : null);

KnowledgeSnapshot snapshot({KnowledgeStatus status = KnowledgeStatus.published}) {
  final m = _m(status);
  return KnowledgeSnapshot(
    generatedAt: DateTime.utc(2026, 11, 3),
    sources: const {
      'fao56': Source(
          id: 'fao56',
          title: 'Crop evapotranspiration',
          publisher: 'FAO',
          year: 1998,
          url: 'https://www.fao.org/x'),
    },
    crops: [
      Crop(
        id: 'tomato',
        nameAr: 'طماطم',
        nameEn: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        categories: const [CropCategory.vegetable],
        requirements: CropRequirements(
            tMin: 10,
            tOptLow: 18,
            tOptHigh: 27.5,
            tMax: 35,
            eceThreshold: 2.5,
            phMin: 5.5,
            phMax: 7.5,
            textures: const ['sand', 'loam'],
            altMin: 0,
            altMax: 1500,
            seasonDaysMin: 90,
            seasonDaysMax: 150,
            meta: m),
        stages: [
          CropStage(seq: 1, stage: 'initial', durationDays: 30, kc: 0.6, meta: m),
          CropStage(seq: 2, stage: 'mid', durationDays: 40, kc: 1.15, meta: m),
        ],
        meta: m,
      ),
      Crop(
          id: 'lemon',
          nameAr: 'ليمون عُماني',
          nameEn: 'Omani lime',
          scientificName: 'Citrus aurantiifolia',
          categories: const [CropCategory.fruit, CropCategory.tree],
          meta: m),
      Crop(
          id: 'lentil',
          nameAr: 'عدس',
          nameEn: 'Lentil',
          categories: const [CropCategory.legume],
          meta: m),
    ],
  );
}

class _Src implements SnapshotSource {
  _Src(this.s);
  final KnowledgeSnapshot s;
  @override
  Future<KnowledgeSnapshot> load() async => s;
}

Future<void> pumpApp(WidgetTester tester,
    {required KnowledgeSnapshot snap, bool includeDrafts = false}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = KnowledgeRepository(chain: [_Src(snap)], includeDrafts: includeDrafts);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      includeDraftsProvider.overrideWithValue(includeDrafts),
      knowledgeProvider.overrideWith((ref) => repo.load()),
    ],
    child: OmanAgriApp(router: buildRouter()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('list shows all fixture crops', (tester) async {
    await pumpApp(tester, snap: snapshot());
    expect(find.text('طماطم'), findsOneWidget);
    expect(find.text('ليمون عُماني'), findsOneWidget);
    expect(find.text('عدس'), findsOneWidget);
    expect(find.byType(DraftBanner), findsOneWidget);
    expect(find.text('مسودة — قيد المراجعة'), findsNothing);
  });

  testWidgets('search narrows list, ignoring diacritics', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.enterText(find.byType(TextField), 'طماطم');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'طماطم'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'عدس'), findsNothing);
    expect(find.widgetWithText(ListTile, 'ليمون عُماني'), findsNothing);
    await tester.enterText(find.byType(TextField), 'ليمون');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'ليمون عُماني'), findsOneWidget);
  });

  testWidgets('category chip filters; no results shows empty text', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.widgetWithText(FilterChip, 'بقوليات'));
    await tester.pumpAndSettle();
    expect(find.text('عدس'), findsOneWidget);
    expect(find.text('طماطم'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('عدس'), findsNothing);
    expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
  });

  testWidgets('detail opens and source sheet shows source title', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    expect(find.text('Solanum lycopersicum'), findsOneWidget);
    final sci = find.ancestor(
        of: find.text('Solanum lycopersicum'), matching: find.byType(Directionality));
    expect(
        tester.widget<Directionality>(sci.first).textDirection, TextDirection.ltr);
    expect(find.byType(SourceButton), findsWidgets);
    await tester.tap(find.byType(SourceButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Crop evapotranspiration'), findsOneWidget);
    expect(find.textContaining('FAO'), findsWidgets);
    expect(find.textContaining('1998'), findsWidgets);
    expect(find.textContaining('https://www.fao.org/x'), findsOneWidget);
  });

  testWidgets('detail with no requirements/stages shows no data', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('عدس'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد بيانات'), findsWidgets);
  });

  testWidgets('includeDrafts=true shows banner', (tester) async {
    await pumpApp(tester,
        snap: snapshot(status: KnowledgeStatus.draft), includeDrafts: true);
    expect(find.text('مسودة — قيد المراجعة'), findsOneWidget);
    expect(find.text('طماطم'), findsOneWidget);
  });

  testWidgets('all-draft data with drafts off shows empty state', (tester) async {
    await pumpApp(tester, snap: snapshot(status: KnowledgeStatus.draft));
    expect(find.text('لا توجد محاصيل منشورة بعد'), findsOneWidget);
    expect(find.text('طماطم'), findsNothing);
    expect(find.text('مسودة — قيد المراجعة'), findsNothing);
  });
}
