import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/config.dart';
import 'package:oman_agri/core/motion.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/store/store_repository.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

String categoryName(AppLocalizations l, ProductCategory c) => switch (c) {
      ProductCategory.seeds => l.catSeeds,
      ProductCategory.seedlings => l.catSeedlings,
      ProductCategory.fertilizer => l.catFertilizer,
      ProductCategory.pesticide => l.catPesticide,
      ProductCategory.irrigation => l.catIrrigation,
      ProductCategory.tools => l.catTools,
      ProductCategory.other => l.catOther,
    };

/// Region names from the knowledge snapshot, by id.
Map<String, Region> _regions(WidgetRef ref) {
  final s = ref.watch(knowledgeProvider).asData?.value;
  return {for (final r in [...?s?.governorates, ...?s?.wilayats]) r.id: r};
}

String _regionName(Region? r, Locale l) => r == null ? '' : (l.languageCode == 'ar' ? r.nameAr : r.nameEn);

/// Digits only, with Oman's country code for local 8-digit numbers.
String waNumber(String raw) {
  final d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  return d.length == 8 ? '968$d' : d;
}

Future<void> _open(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

// ---------------------------------------------------------------- shop list

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String? _governorate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(l10n.storeTitle, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
    );
    if (!ref.watch(hasBackendProvider)) {
      return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        title,
        _Notice(icon: Icons.wifi_off, text: l10n.storeNeedsInternet),
      ]);
    }
    final regions = _regions(ref);
    final shops = ref.watch(approvedShopsProvider);
    final govs = ref.watch(knowledgeProvider).asData?.value.governorates ?? const <Region>[];
    return RefreshIndicator(
      onRefresh: () => ref.refresh(approvedShopsProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          title,
          _OwnerCta(),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: FilterChip(
                  label: Text(l10n.allCategories,
                      style: _governorate == null ? TextStyle(color: theme.colorScheme.onPrimary) : null),
                  selected: _governorate == null,
                  onSelected: (_) => setState(() => _governorate = null),
                ),
              ),
              for (final g in govs)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FilterChip(
                    label: Text(_regionName(g, locale),
                        style: _governorate == g.id ? TextStyle(color: theme.colorScheme.onPrimary) : null),
                    selected: _governorate == g.id,
                    onSelected: (_) => setState(() => _governorate = _governorate == g.id ? null : g.id),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          ...shops.when(
            loading: () => [const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))],
            error: (_, _) => [_Notice(icon: Icons.cloud_off, text: l10n.loadError)],
            data: (list) {
              final shown = [
                for (final s in list)
                  if (_governorate == null || regions[s.wilayatId]?.parentId == _governorate) s
              ];
              if (shown.isEmpty) {
                return [
                  _Notice(icon: Icons.storefront_outlined, title: l10n.storeEmpty, text: l10n.storeEmptyBody),
                ];
              }
              return [
                for (final s in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopCard(shop: s, place: _place(regions, s, locale)),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }

  String _place(Map<String, Region> regions, Shop s, Locale l) {
    final w = regions[s.wilayatId];
    final g = w?.parentId == null ? null : regions[w!.parentId];
    return [_regionName(w, l), _regionName(g, l)].where((x) => x.isNotEmpty).join(l.languageCode == 'ar' ? '، ' : ', ');
  }
}

class _OwnerCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Expanded(child: Text(l10n.storeOwnerCta, style: theme.textTheme.titleSmall)),
        const SizedBox(width: 8),
        FilledButton(onPressed: () => context.push('/store/mine'), child: Text(l10n.storeRegisterButton)),
      ]),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.place});
  final Shop shop;
  final String place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          onTap: () => context.push('/store/shop/${shop.id}', extra: shop),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.storefront, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shop.name, style: theme.textTheme.titleMedium),
                  if (place.isNotEmpty)
                    Text(place, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.title});
  final IconData icon;
  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(children: [
        Icon(icon, size: 44, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        if (title != null) Text(title!, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(text, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ---------------------------------------------------------------- shop page

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final regions = _regions(ref);
    final w = regions[shop.wilayatId];
    final products = ref.watch(shopProductsProvider(shop.id));
    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        Text(shop.name, style: theme.textTheme.headlineMedium),
        Text([_regionName(w, locale), ?shop.address].where((x) => x.isNotEmpty).join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _open(Uri(scheme: 'tel', path: shop.phone.replaceAll(' ', ''))),
              icon: const Icon(Icons.call),
              label: Text(l10n.shopCall),
            ),
          ),
          if (shop.whatsapp != null && shop.whatsapp!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _open(Uri.parse('https://wa.me/${waNumber(shop.whatsapp!)}')),
                icon: const Icon(Icons.chat_outlined),
                label: Text(l10n.shopWhatsapp),
              ),
            ),
          ],
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(shop.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ),
        const SizedBox(height: 20),
        Text(l10n.productsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ...products.when(
          loading: () => [const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))],
          error: (_, _) => [Text(l10n.loadError)],
          data: (list) => list.isEmpty
              ? [Text(l10n.shopNoProducts, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline))]
              : [for (final p in list) _ProductRow(product: p)],
        ),
      ]),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, this.onTap});
  final ShopProduct product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final price = product.priceOmr == null
        ? l10n.priceOnRequest
        : l10n.priceOmr(product.priceOmr!.toStringAsFixed(3));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: softShadow(context)),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        onTap: onTap,
        title: Text(product.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          [categoryName(l10n, product.category), ?product.unit, if (!product.available) l10n.productUnavailable]
              .where((x) => x.isNotEmpty)
              .join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(price,
            style: theme.textTheme.titleSmall?.copyWith(
                color: product.available ? theme.colorScheme.primary : theme.colorScheme.outline)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- my shop

class MyShopScreen extends ConsumerStatefulWidget {
  const MyShopScreen({super.key});

  @override
  ConsumerState<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends ConsumerState<MyShopScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  StoreRepository get _repo => ref.read(storeRepositoryProvider);

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _auth({required bool create}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (create) {
        final needsConfirm = await _repo.signUp(_email.text.trim(), _password.text);
        if (needsConfirm) _message = l10n.confirmEmailSent;
      } else {
        await _repo.signIn(_email.text.trim(), _password.text);
      }
      ref.invalidate(myShopProvider);
    } catch (_) {
      _message = l10n.signInFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signedIn = _repo.currentUserId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myShopTitle),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: l10n.signOut,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _repo.signOut();
                ref.invalidate(myShopProvider);
                setState(() {});
              },
            ),
        ],
      ),
      body: !ref.watch(hasBackendProvider)
          ? _Notice(icon: Icons.wifi_off, text: l10n.storeNeedsInternet)
          : !signedIn
              ? _authForm(l10n)
              : ref.watch(myShopProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => _Notice(icon: Icons.cloud_off, text: l10n.loadError),
                    data: (shop) => shop == null
                        ? _ShopForm(onSubmit: (d) async {
                            await _repo.registerShop(d);
                            ref.invalidate(myShopProvider);
                          })
                        : _OwnShop(shop: shop, snack: _snack),
                  ),
    );
  }

  Widget _authForm(AppLocalizations l10n) => ListView(padding: const EdgeInsets.all(24), children: [
        Text(l10n.signInToRegister, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('store-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l10n.email),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('store-password'),
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.password),
        ),
        if (_message != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : () => _auth(create: false), child: Text(l10n.signIn)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _busy ? null : () => _auth(create: true), child: Text(l10n.createAccount)),
      ]);
}

class _OwnShop extends ConsumerWidget {
  const _OwnShop({required this.shop, required this.snack});
  final Shop shop;
  final void Function(String) snack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(storeRepositoryProvider);
    final products = ref.watch(shopProductsProvider(shop.id));
    final (note, color) = switch (shop.status) {
      ShopStatus.pending => (l10n.shopPendingNote, theme.colorScheme.tertiaryContainer),
      ShopStatus.approved => (l10n.shopApprovedNote, theme.colorScheme.primaryContainer),
      ShopStatus.suspended => (l10n.shopSuspendedNote, theme.colorScheme.errorContainer),
    };
    Future<void> edit([ShopProduct? p]) async {
      final d = await showDialog<ProductDraft>(context: context, builder: (_) => _ProductDialog(initial: p));
      if (d == null) return;
      try {
        await repo.saveProduct(shop.id, d, id: p?.id);
        ref.invalidate(shopProductsProvider(shop.id));
        snack(l10n.saved);
      } catch (_) {
        snack(l10n.operationFailed);
      }
    }

    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), children: [
      Container(
        key: ValueKey('shop-status-${shop.status.name}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Text(note, style: theme.textTheme.bodyMedium),
      ),
      const SizedBox(height: 16),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(shop.name, style: theme.textTheme.titleLarge),
        children: [
          _ShopForm(
            initial: shop,
            onSubmit: (d) async {
              await repo.updateShop(shop.id, d);
              ref.invalidate(myShopProvider);
              snack(l10n.saved);
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(l10n.productsTitle, style: theme.textTheme.titleLarge)),
        FilledButton.icon(onPressed: () => edit(), icon: const Icon(Icons.add), label: Text(l10n.addProduct)),
      ]),
      const SizedBox(height: 8),
      ...products.when(
        loading: () => [const Center(child: CircularProgressIndicator())],
        error: (_, _) => [Text(l10n.loadError)],
        data: (list) => [
          for (final p in list)
            Dismissible(
              key: ValueKey(p.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              ),
              confirmDismiss: (_) async {
                try {
                  await repo.deleteProduct(p.id);
                  ref.invalidate(shopProductsProvider(shop.id));
                  return true;
                } catch (_) {
                  snack(l10n.operationFailed);
                  return false;
                }
              },
              child: _ProductRow(product: p, onTap: () => edit(p)),
            ),
        ],
      ),
    ]);
  }
}

/// Register or edit the shop's details.
class _ShopForm extends ConsumerStatefulWidget {
  const _ShopForm({required this.onSubmit, this.initial});
  final Future<void> Function(ShopDraft) onSubmit;
  final Shop? initial;

  @override
  ConsumerState<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends ConsumerState<_ShopForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _wa = TextEditingController(text: widget.initial?.whatsapp);
  late final _address = TextEditingController(text: widget.initial?.address);
  late String? _wilayat = widget.initial?.wilayatId;
  bool _busy = false;

  static final _phoneRe = RegExp(r'^\+?[0-9 ]{7,16}$');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final s = ref.watch(knowledgeProvider).asData?.value;
    final govs = {for (final g in s?.governorates ?? const <Region>[]) g.id: g};
    final wilayats = [...?s?.wilayats]
      ..sort((a, b) => _regionName(a, locale).compareTo(_regionName(b, locale)));
    String? req(String? v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null;
    String? phone(String? v, {bool optional = false}) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return optional ? null : l10n.fieldRequired;
      return _phoneRe.hasMatch(t) ? null : l10n.invalidPhone;
    }

    return Form(
      key: _form,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            key: const ValueKey('shop-name'),
            controller: _name,
            maxLength: 80,
            decoration: InputDecoration(labelText: l10n.shopName),
            validator: (v) => req(v) ?? ((v!.trim().length < 2) ? l10n.fieldRequired : null),
          ),
          DropdownButtonFormField<String>(
            key: const ValueKey('shop-wilayat'),
            initialValue: _wilayat,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.shopWilayat),
            items: [
              for (final w in wilayats)
                DropdownMenuItem(
                  value: w.id,
                  child: Text('${_regionName(w, locale)} (${_regionName(govs[w.parentId], locale)})',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _wilayat = v),
            validator: (v) => v == null ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('shop-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l10n.shopPhone),
            validator: phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _wa,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l10n.shopWhatsappField),
            validator: (v) => phone(v, optional: true),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.shopAddress),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('shop-submit'),
            onPressed: _busy
                ? null
                : () async {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    setState(() => _busy = true);
                    try {
                      String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
                      await widget.onSubmit(ShopDraft(
                        name: _name.text.trim(),
                        wilayatId: _wilayat!,
                        phone: _phone.text.trim(),
                        whatsapp: opt(_wa),
                        address: opt(_address),
                      ));
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.operationFailed)));
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: Text(widget.initial == null ? l10n.registerShop : l10n.saveShop),
          ),
        ]),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.initial});
  final ShopProduct? initial;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _price = TextEditingController(text: widget.initial?.priceOmr?.toString());
  late final _unit = TextEditingController(text: widget.initial?.unit);
  late ProductCategory _cat = widget.initial?.category ?? ProductCategory.seeds;
  late bool _available = widget.initial?.available ?? true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.initial == null ? l10n.addProduct : widget.initial!.name),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              key: const ValueKey('product-name'),
              controller: _name,
              maxLength: 80,
              decoration: InputDecoration(labelText: l10n.productName),
              validator: (v) => (v == null || v.trim().length < 2) ? l10n.fieldRequired : null,
            ),
            DropdownButtonFormField<ProductCategory>(
              initialValue: _cat,
              decoration: InputDecoration(labelText: l10n.productCategory),
              items: [
                for (final c in ProductCategory.values) DropdownMenuItem(value: c, child: Text(categoryName(l10n, c))),
              ],
              onChanged: (v) => setState(() => _cat = v ?? _cat),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('product-price'),
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.productPrice),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final x = double.tryParse(t);
                return (x == null || x < 0) ? l10n.invalidPrice : null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _unit, maxLength: 30, decoration: InputDecoration(labelText: l10n.productUnit)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.productAvailable),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const ValueKey('product-save'),
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            final p = _price.text.trim();
            Navigator.pop(
              context,
              ProductDraft(
                name: _name.text.trim(),
                category: _cat,
                priceOmr: p.isEmpty ? null : double.parse(p),
                unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
                available: _available,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
