import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ShopStatus { pending, approved, suspended }

enum ProductCategory { seeds, seedlings, fertilizer, pesticide, irrigation, tools, other }

@immutable
class Shop {
  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.wilayatId,
    required this.phone,
    this.whatsapp,
    this.address,
    this.status = ShopStatus.pending,
  });

  final String id, ownerId, name, wilayatId, phone;
  final String? whatsapp, address;
  final ShopStatus status;

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        name: j['name'] as String,
        wilayatId: j['wilayat_id'] as String,
        phone: j['phone'] as String,
        whatsapp: j['whatsapp'] as String?,
        address: j['address'] as String?,
        status: ShopStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => ShopStatus.pending),
      );
}

@immutable
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    this.priceOmr,
    this.unit,
    this.available = true,
  });

  final String id, shopId, name;
  final ProductCategory category;
  final double? priceOmr;
  final String? unit;
  final bool available;

  factory ShopProduct.fromJson(Map<String, dynamic> j) => ShopProduct(
        id: j['id'] as String,
        shopId: j['shop_id'] as String,
        name: j['name'] as String,
        category: ProductCategory.values
            .firstWhere((c) => c.name == j['category'], orElse: () => ProductCategory.other),
        priceOmr: (j['price_omr'] as num?)?.toDouble(),
        unit: j['unit'] as String?,
        available: j['available'] as bool? ?? true,
      );
}

/// New or edited shop details (owner and status are set by the server rules).
@immutable
class ShopDraft {
  const ShopDraft({required this.name, required this.wilayatId, required this.phone, this.whatsapp, this.address});
  final String name, wilayatId, phone;
  final String? whatsapp, address;

  Map<String, dynamic> toJson() => {
        'name': name,
        'wilayat_id': wilayatId,
        'phone': phone,
        'whatsapp': whatsapp,
        'address': address,
      };
}

@immutable
class ProductDraft {
  const ProductDraft({required this.name, required this.category, this.priceOmr, this.unit, this.available = true});
  final String name;
  final ProductCategory category;
  final double? priceOmr;
  final String? unit;
  final bool available;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.name,
        'price_omr': priceOmr,
        'unit': unit,
        'available': available,
      };
}

abstract class StoreRepository {
  Future<List<Shop>> approvedShops();
  Future<List<ShopProduct>> products(String shopId);

  String? get currentUserId;
  Future<void> signIn(String email, String password);

  /// Returns true when the account still needs its email confirmed.
  Future<bool> signUp(String email, String password);
  Future<void> signOut();

  Future<Shop?> myShop();
  Future<void> registerShop(ShopDraft d);
  Future<void> updateShop(String id, ShopDraft d);
  Future<void> saveProduct(String shopId, ProductDraft d, {String? id});
  Future<void> deleteProduct(String id);

  // Admin.
  Future<List<Shop>> shopsByStatus(ShopStatus s);
  Future<void> setShopStatus(String id, ShopStatus s);
}

class SupabaseStoreRepository implements StoreRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<List<Shop>> approvedShops() async => [
        for (final r in await _c.from('shops').select().eq('status', 'approved').order('name'))
          Shop.fromJson(r),
      ];

  @override
  Future<List<ShopProduct>> products(String shopId) async => [
        for (final r in await _c.from('shop_products').select().eq('shop_id', shopId).order('name'))
          ShopProduct.fromJson(r),
      ];

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Future<void> signIn(String email, String password) async {
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final res = await _c.auth.signUp(email: email, password: password);
    return res.session == null;
  }

  @override
  Future<void> signOut() => _c.auth.signOut();

  @override
  Future<Shop?> myShop() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final r = await _c.from('shops').select().eq('owner_id', uid).maybeSingle();
    return r == null ? null : Shop.fromJson(r);
  }

  @override
  Future<void> registerShop(ShopDraft d) =>
      _c.from('shops').insert({...d.toJson(), 'owner_id': currentUserId});

  @override
  Future<void> updateShop(String id, ShopDraft d) => _c.from('shops').update(d.toJson()).eq('id', id);

  @override
  Future<void> saveProduct(String shopId, ProductDraft d, {String? id}) => id == null
      ? _c.from('shop_products').insert({...d.toJson(), 'shop_id': shopId})
      : _c.from('shop_products').update(d.toJson()).eq('id', id);

  @override
  Future<void> deleteProduct(String id) => _c.from('shop_products').delete().eq('id', id);

  @override
  Future<List<Shop>> shopsByStatus(ShopStatus s) async => [
        for (final r in await _c.from('shops').select().eq('status', s.name).order('created_at'))
          Shop.fromJson(r),
      ];

  @override
  Future<void> setShopStatus(String id, ShopStatus s) =>
      _c.from('shops').update({'status': s.name}).eq('id', id);
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) => SupabaseStoreRepository());

final approvedShopsProvider = FutureProvider<List<Shop>>((ref) => ref.watch(storeRepositoryProvider).approvedShops());

final shopProductsProvider =
    FutureProvider.family<List<ShopProduct>, String>((ref, id) => ref.watch(storeRepositoryProvider).products(id));

final myShopProvider = FutureProvider<Shop?>((ref) => ref.watch(storeRepositoryProvider).myShop());

final pendingShopsProvider =
    FutureProvider<List<Shop>>((ref) => ref.watch(storeRepositoryProvider).shopsByStatus(ShopStatus.pending));
