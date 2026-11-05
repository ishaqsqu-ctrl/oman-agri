import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/config.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/store/store_repository.dart';
import 'package:oman_agri/features/store/store_screens.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _m = KnowledgeMeta(status: KnowledgeStatus.published, sourceId: 's', reviewedBy: 'r', reviewedAt: '2026-11-04');
final _snap = KnowledgeSnapshot(
  generatedAt: DateTime.utc(2026, 11, 5),
  sources: const {},
  crops: const [],
  governorates: const [Region(id: 'muscat', nameAr: 'مسقط', nameEn: 'Muscat', meta: _m)],
  wilayats: const [Region(id: 'seeb', parentId: 'muscat', nameAr: 'السيب', nameEn: 'As Seeb', meta: _m)],
);

class FakeStore implements StoreRepository {
  final shops = <Shop>[];
  final items = <ShopProduct>[];
  String? uid;

  @override
  Future<List<Shop>> approvedShops() async => [for (final s in shops) if (s.status == ShopStatus.approved) s];
  @override
  Future<List<ShopProduct>> products(String shopId) async => [for (final p in items) if (p.shopId == shopId) p];
  @override
  String? get currentUserId => uid;
  @override
  Future<void> signIn(String email, String password) async => uid = 'u1';
  @override
  Future<bool> signUp(String email, String password) async => true;
  @override
  Future<void> signOut() async => uid = null;
  @override
  Future<Shop?> myShop() async => shops.where((s) => s.ownerId == uid).firstOrNull;
  @override
  Future<void> registerShop(ShopDraft d) async => shops.add(Shop(
      id: 's${shops.length}', ownerId: uid!, name: d.name, wilayatId: d.wilayatId, phone: d.phone, whatsapp: d.whatsapp));
  @override
  Future<void> updateShop(String id, ShopDraft d) async {}
  @override
  Future<void> saveProduct(String shopId, ProductDraft d, {String? id}) async => items.add(ShopProduct(
      id: 'p${items.length}', shopId: shopId, name: d.name, category: d.category, priceOmr: d.priceOmr, unit: d.unit));
  @override
  Future<void> deleteProduct(String id) async => items.removeWhere((p) => p.id == id);
  @override
  Future<List<Shop>> shopsByStatus(ShopStatus s) async => [for (final x in shops) if (x.status == s) x];
  @override
  Future<void> setShopStatus(String id, ShopStatus s) async {}
}

Future<void> _pump(WidgetTester tester, Widget home, FakeStore store) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({localePrefKey: 'ar'});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      knowledgeProvider.overrideWith((ref) async => _snap),
      hasBackendProvider.overrideWithValue(true),
      storeRepositoryProvider.overrideWithValue(store),
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
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty store says so and invites shop owners', (tester) async {
    await _pump(tester, const Scaffold(body: StoreScreen()), FakeStore());
    expect(find.text('لا توجد محلات معتمدة بعد'), findsOneWidget);
    expect(find.text('سجّل محلك'), findsOneWidget);
  });

  testWidgets('only approved shops are listed, with their wilayat and governorate', (tester) async {
    final store = FakeStore()
      ..shops.addAll(const [
        Shop(id: 'a', ownerId: 'o', name: 'محل الخير', wilayatId: 'seeb', phone: '91234567', status: ShopStatus.approved),
        Shop(id: 'b', ownerId: 'p', name: 'محل معلّق', wilayatId: 'seeb', phone: '91234568'),
      ]);
    await _pump(tester, const Scaffold(body: StoreScreen()), store);
    expect(find.text('محل الخير'), findsOneWidget);
    expect(find.text('السيب، مسقط'), findsOneWidget);
    expect(find.text('محل معلّق'), findsNothing);
  });

  testWidgets('shop page shows products, prices and contact buttons', (tester) async {
    const shop = Shop(
        id: 'a', ownerId: 'o', name: 'محل الخير', wilayatId: 'seeb', phone: '9123 4567', whatsapp: '91234567',
        status: ShopStatus.approved);
    final store = FakeStore()
      ..items.addAll(const [
        ShopProduct(id: 'p', shopId: 'a', name: 'بذور طماطم', category: ProductCategory.seeds, priceOmr: 1.5, unit: 'علبة'),
        ShopProduct(id: 'q', shopId: 'a', name: 'سماد عضوي', category: ProductCategory.fertilizer, available: false),
      ]);
    await _pump(tester, const ShopScreen(shop: shop), store);
    expect(find.text('بذور طماطم'), findsOneWidget);
    expect(find.text('1.500 ر.ع.'), findsOneWidget);
    expect(find.text('السعر عند الاتصال'), findsOneWidget);
    expect(find.textContaining('غير متوفر حالياً'), findsOneWidget);
    expect(find.text('اتصل'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(waNumber('9123 4567'), '96891234567');
  });

  testWidgets('owner signs in, registers (pending), and adds a product', (tester) async {
    final store = FakeStore();
    await _pump(tester, const MyShopScreen(), store);
    await tester.enterText(find.byKey(const ValueKey('store-email')), 'a@b.c');
    await tester.enterText(find.byKey(const ValueKey('store-password')), 'secret123');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('shop-name')), 'محل البركة');
    await tester.enterText(find.byKey(const ValueKey('shop-phone')), 'call me');
    await tester.tap(find.byKey(const ValueKey('shop-submit')));
    await tester.pumpAndSettle();
    expect(find.text('اكتب رقماً صحيحاً، مثل 9123 4567'), findsOneWidget);
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget); // wilayat
    expect(store.shops, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('shop-phone')), '9123 4567');
    await tester.tap(find.byKey(const ValueKey('shop-wilayat')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السيب (مسقط)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-submit')));
    await tester.pumpAndSettle();
    expect(store.shops.single.status, ShopStatus.pending);
    expect(find.byKey(const ValueKey('shop-status-pending')), findsOneWidget);

    await tester.tap(find.text('أضف منتجاً'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('product-name')), 'بذور خيار');
    await tester.enterText(find.byKey(const ValueKey('product-price')), '2.25');
    await tester.tap(find.byKey(const ValueKey('product-save')));
    await tester.pumpAndSettle();
    expect(store.items.single.priceOmr, 2.25);
    expect(find.text('بذور خيار'), findsOneWidget);
  });
}
