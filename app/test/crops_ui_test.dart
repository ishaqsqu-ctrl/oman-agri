import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/app.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/router.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crops_list_screen.dart';
import 'package:oman_agri/features/crops/ui/draft_banner.dart';
import 'package:oman_agri/features/crops/ui/source_button.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

KnowledgeMeta _m(KnowledgeStatus s, [String page = 'Table 12']) => KnowledgeMeta(
    status: s,
    sourceId: 'src_a',
    sourcePage: page,
    reviewedBy: s == KnowledgeStatus.published ? 'test-reviewer' : null,
    reviewedAt: s == KnowledgeStatus.published ? '2026-10-01' : null);

KnowledgeSnapshot snapshot(
    {KnowledgeStatus status = KnowledgeStatus.published,
    String sourceTitle = 'Test fixture source',
    String? sourceUrl = 'https://example.invalid/x',
    String? scientificName = 'Solanum lycopersicum',
    List<int> lemonKcMonths = const []}) {
  final m = _m(status);
  return KnowledgeSnapshot(
    generatedAt: DateTime.utc(2026, 11, 3),
    sources: {
      'src_a': Source(
          id: 'src_a',
          title: sourceTitle,
          publisher: 'Test publisher',
          year: 1998,
          url: sourceUrl),
    },
    crops: [
      Crop(
        id: 'tomato',
        nameAr: 'طماطم',
        nameEn: 'Tomato',
        scientificName: scientificName,
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
        meta: _m(status, 'Crop page 7'),
      ),
      Crop(
          id: 'lemon',
          nameAr: 'ليمون عُماني',
          nameEn: 'Omani lime',
          scientificName: 'Citrus aurantiifolia',
          categories: const [CropCategory.fruit, CropCategory.tree],
          kcMonthly: [
            for (final mo in lemonKcMonths)
              CropKcMonth(month: mo, kc: 0.7 + mo / 100, meta: _m(status, 'Table 4'))
          ],
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

class FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final launched = <String>[];
  bool result = true;
  Object? error;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    if (error != null) throw error!;
    return result;
  }
}

FakeLauncher installFakeLauncher() {
  final previous = UrlLauncherPlatform.instance;
  final fake = FakeLauncher();
  UrlLauncherPlatform.instance = fake;
  addTearDown(() => UrlLauncherPlatform.instance = previous);
  return fake;
}

Future<void> openTomatoSource(WidgetTester tester) async {
  await tester.tap(find.text('طماطم'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SourceButton).first);
  await tester.pumpAndSettle();
}

class _Src implements SnapshotSource {
  _Src(this.s);
  final KnowledgeSnapshot s;
  @override
  Future<KnowledgeSnapshot> load() async => s;
}

Future<void> pumpApp(WidgetTester tester,
    {required KnowledgeSnapshot snap,
    bool includeDrafts = false,
    String locale = 'ar',
    double width = 800}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({localePrefKey: locale});
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
    expect(find.widgetWithText(CropTile, 'طماطم'), findsOneWidget);
    expect(find.widgetWithText(CropTile, 'عدس'), findsNothing);
    expect(find.widgetWithText(CropTile, 'ليمون عُماني'), findsNothing);
    await tester.enterText(find.byType(TextField), 'ليمون');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CropTile, 'ليمون عُماني'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'الطماطم');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CropTile, 'طماطم'), findsOneWidget);
    expect(find.widgetWithText(CropTile, 'ليمون عُماني'), findsNothing);
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
    expect(find.text('Test fixture source'), findsOneWidget);
    expect(find.textContaining('Test publisher'), findsWidgets);
    expect(find.textContaining('1998'), findsWidgets);
    expect(find.textContaining('https://example.invalid/x'), findsOneWidget);
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

  testWidgets('source link opens through the launcher', (tester) async {
    final launcher = installFakeLauncher();
    await pumpApp(tester, snap: snapshot());
    await openTomatoSource(tester);
    await tester.tap(find.text('فتح الرابط'));
    await tester.pumpAndSettle();
    expect(launcher.launched, ['https://example.invalid/x']);
    expect(find.text('تعذّر فتح الرابط'), findsNothing);
  });

  testWidgets('launcher returning false shows a snackbar', (tester) async {
    final launcher = installFakeLauncher()..result = false;
    await pumpApp(tester, snap: snapshot());
    await openTomatoSource(tester);
    await tester.tap(find.text('فتح الرابط'));
    await tester.pumpAndSettle();
    expect(launcher.launched, hasLength(1));
    expect(find.text('تعذّر فتح الرابط'), findsOneWidget);
  });

  testWidgets('launcher throwing shows a snackbar', (tester) async {
    installFakeLauncher().error = Exception('no browser');
    await pumpApp(tester, snap: snapshot());
    await openTomatoSource(tester);
    await tester.tap(find.text('فتح الرابط'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('تعذّر فتح الرابط'), findsOneWidget);
  });

  for (final bad in ['javascript:alert(1)', 'file:///etc/passwd', 'example.invalid/x']) {
    testWidgets('non-http(s) source url "$bad" is not offered', (tester) async {
      final launcher = installFakeLauncher();
      await pumpApp(tester, snap: snapshot(sourceUrl: bad));
      await openTomatoSource(tester);
      expect(find.text('Test fixture source'), findsOneWidget);
      expect(find.text('فتح الرابط'), findsNothing);
      expect(find.textContaining(bad), findsNothing);
      expect(launcher.launched, isEmpty);
    });
  }

  testWidgets('source title direction follows its content', (tester) async {
    const ar = 'بيانات تجريبية — ليست حقيقية / SAMPLE DATA — not real';
    await pumpApp(tester, snap: snapshot(sourceTitle: ar));
    await openTomatoSource(tester);
    expect(tester.widget<Text>(find.text(ar)).textDirection, TextDirection.rtl);
  });

  testWidgets('Latin source title stays LTR', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await openTomatoSource(tester);
    expect(tester.widget<Text>(find.text('Test fixture source')).textDirection,
        TextDirection.ltr);
  });

  testWidgets('crop-level facts have their own source button', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    final cropSource = find.byKey(const ValueKey('crop-source'));
    expect(cropSource, findsOneWidget);
    await tester.tap(cropSource);
    await tester.pumpAndSettle();
    expect(find.text('Test fixture source'), findsOneWidget);
    expect(find.textContaining('Crop page 7'), findsOneWidget);
  });

  testWidgets('crop names are centred together under the picture', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    final ar = tester.getRect(find.descendant(
        of: find.byType(ListView), matching: find.text('طماطم')));
    final en = tester.getRect(find.text('Tomato'));
    expect(en.center.dx, moreOrLessEquals(400, epsilon: 2));
    expect(ar.center.dx, moreOrLessEquals(400, epsilon: 2));
    expect(en.top, greaterThan(ar.bottom - 1));
  });

  testWidgets('long scientific name wraps at 320 px without overflow', (tester) async {
    const long = 'Solanum lycopersicum var. cerasiforme (Dunal) Spooner, G.J.Anderson & R.K.Jansen';
    await pumpApp(tester, snap: snapshot(scientificName: long), width: 320);
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(long), findsOneWidget);
    expect(tester.getRect(find.text(long)).right, lessThanOrEqualTo(320));
  });

  testWidgets('texture list uses the locale separator', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    expect(find.text('رملية، طميية'), findsOneWidget);

    await pumpApp(tester, snap: snapshot(), locale: 'en');
    await tester.tap(find.text('Tomato'));
    await tester.pumpAndSettle();
    expect(find.text('Sandy, Loamy'), findsOneWidget);
  });

  testWidgets('detail shows monthly Kc with month names and sources', (tester) async {
    await pumpApp(tester, snap: snapshot(lemonKcMonths: [for (var i = 1; i <= 12; i++) i]));
    await tester.tap(find.text('ليمون عُماني'));
    await tester.pumpAndSettle();
    // No growth stages: the monthly values fill the water-need section.
    expect(find.text('احتياج الماء خلال الموسم'), findsOneWidget);
    expect(find.text('معامل المحصول الشهري'), findsNothing);
    expect(find.text('يناير'), findsOneWidget);
    expect(find.text('ديسمبر'), findsOneWidget);
    expect(find.text('0.71'), findsOneWidget);
    expect(find.text('0.82'), findsOneWidget);
    expect(find.byKey(const ValueKey('kc-month-12-source')), findsOneWidget);
    expect(find.text('القيم متاحة لبعض الأشهر فقط'), findsNothing);
  });

  testWidgets('partial monthly Kc lists only known months and says so', (tester) async {
    await pumpApp(tester, snap: snapshot(lemonKcMonths: [5, 6]), locale: 'en');
    await tester.tap(find.text('Omani lime'));
    await tester.pumpAndSettle();
    expect(find.text('Water need through the season'), findsOneWidget);
    expect(find.text('May'), findsOneWidget);
    expect(find.text('June'), findsOneWidget);
    expect(find.text('July'), findsNothing);
    expect(find.text('Values are available for some months only'), findsOneWidget);
  });

  testWidgets('crop without monthly Kc has no monthly section', (tester) async {
    await pumpApp(tester, snap: snapshot());
    await tester.tap(find.text('طماطم'));
    await tester.pumpAndSettle();
    expect(find.text('معامل المحصول الشهري'), findsNothing);
  });
}
