import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/core/config.dart';
import 'package:oman_agri/features/admin/admin_repository.dart';
import 'package:oman_agri/features/calendar/omani_hijri.dart';
import 'package:oman_agri/features/store/store_repository.dart';
import 'package:oman_agri/features/crops/ui/labels.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

enum _Phase { checking, signedOut, notAdmin, admin }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  _Phase _phase = _Phase.checking;
  bool _busy = false;
  bool _signInFailed = false;
  bool _countsFailed = false;
  Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    if (ref.read(hasBackendProvider)) _resume();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  /// Reuse an existing session if there is one.
  Future<void> _resume() async {
    try {
      if (await _repo.isAdmin()) {
        await _enterAdmin();
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _phase = _Phase.signedOut);
  }

  Future<void> _enterAdmin() async {
    await _loadCounts();
    if (mounted) setState(() => _phase = _Phase.admin);
  }

  Future<void> _loadCounts() async {
    try {
      final list = await _repo.counts();
      _counts = {for (final c in list) '${c.table}|${c.status.name}': c.n};
      _countsFailed = false;
    } catch (_) {
      _countsFailed = true;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _signInFailed = false;
    });
    try {
      final ok = await _repo.signIn(_email.text.trim(), _password.text);
      if (!ok) {
        if (mounted) setState(() => _signInFailed = true);
      } else if (await _repo.isAdmin()) {
        await _enterAdmin();
      } else if (mounted) {
        setState(() => _phase = _Phase.notAdmin);
      }
    } catch (_) {
      if (mounted) setState(() => _signInFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _phase = _Phase.signedOut;
        _counts = {};
      });
    }
  }

  Future<void> _publish(String table, String label) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.publishConfirmTitle),
        content: Text(l10n.publishConfirmBody(label)),
        actions: [
          TextButton(
              key: const ValueKey('publish-cancel'),
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancel)),
          FilledButton(
              key: const ValueKey('publish-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.confirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final n = await _repo.publishReviewed(table);
      // Newly published rows should appear in the crop screens right away.
      ref.invalidate(knowledgeProvider);
      await _loadCounts();
      _snack(l10n.publishedRows(n));
    } catch (_) {
      _snack(l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (!ref.watch(hasBackendProvider)) {
      body = _message(l10n.adminNeedsBackend);
    } else {
      body = switch (_phase) {
        _Phase.checking => const Center(child: CircularProgressIndicator()),
        _Phase.signedOut => _signInForm(l10n),
        _Phase.notAdmin => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _message(l10n.adminNotAuthorized),
              TextButton(onPressed: _signOut, child: Text(l10n.signOut)),
            ],
          ),
        _Phase.admin => _panel(l10n),
      };
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admin),
        actions: [
          if (_phase == _Phase.admin)
            IconButton(
                tooltip: l10n.signOut,
                onPressed: _signOut,
                icon: const Icon(Icons.logout)),
        ],
      ),
      body: body,
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
        ),
      );

  Widget _signInForm(AppLocalizations l10n) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: const ValueKey('admin-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.email),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('admin-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: l10n.password),
                onSubmitted: (_) => _busy ? null : _signIn(),
              ),
              if (_signInFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(l10n.signInFailed,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('admin-signin'),
                onPressed: _busy ? null : _signIn,
                child: Text(l10n.signIn),
              ),
            ],
          ),
        ),
      );

  Future<void> _setShop(Shop shop, ShopStatus status, AppLocalizations l10n) async {
    setState(() => _busy = true);
    try {
      await ref.read(storeRepositoryProvider).setShopStatus(shop.id, status);
      ref.invalidate(pendingShopsProvider);
      ref.invalidate(approvedShopsProvider);
      _snack(l10n.saved);
    } catch (_) {
      _snack(l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addHijriStart(AppLocalizations l10n) async {
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final guess = omaniHijri(now, const []);
    final year = TextEditingController(text: '${guess.year}');
    final source = TextEditingController();
    var month = guess.month;
    var date = DateTime(now.year, now.month, now.day);
    final saved = await showDialog<HijriStart>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(l10n.hijriAdminTitle),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.hijriYear),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: month,
                decoration: InputDecoration(labelText: l10n.hijriMonth),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(value: m, child: Text(hijriMonthName(m, lang))),
                ],
                onChanged: (v) => set(() => month = v ?? month),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.hijriStartsOn),
                subtitle: Text(date.toIso8601String().substring(0, 10)),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final d = await showDatePicker(
                      context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2040));
                  if (d != null) set(() => date = d);
                },
              ),
              TextField(controller: source, decoration: InputDecoration(labelText: l10n.hijriSource)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
            FilledButton(
              key: const ValueKey('hijri-save'),
              onPressed: () {
                final y = int.tryParse(year.text.trim());
                if (y == null || source.text.trim().length < 3) return;
                Navigator.pop(c, HijriStart(year: y, month: month, startsOn: date, source: source.text.trim()));
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (saved == null) return;
    setState(() => _busy = true);
    try {
      await _repo.saveHijriStart(saved);
      ref.invalidate(hijriStartsProvider);
      _snack(l10n.hijriSaved(hijriMonthName(saved.month, lang), saved.year));
    } catch (_) {
      _snack(l10n.operationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _tableLabel(AppLocalizations l10n, String t) => switch (t) {
        'governorates' => l10n.tableGovernorates,
        'wilayats' => l10n.tableWilayats,
        'crops' => l10n.tableCrops,
        'crop_requirements' => l10n.tableCropRequirements,
        'crop_stages' => l10n.tableCropStages,
        'crop_kc_monthly' => l10n.tableCropKcMonthly,
        _ => t,
      };

  String _statusLabel(AppLocalizations l10n, KnowledgeStatus s) =>
      switch (s) {
        KnowledgeStatus.draft => l10n.statusDraft,
        KnowledgeStatus.reviewed => l10n.statusReviewed,
        KnowledgeStatus.published => l10n.statusPublished,
      };

  Widget _panel(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_countsFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.loadError,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        for (final t in adminTables)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tableLabel(l10n, t), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final s in KnowledgeStatus.values)
                        Expanded(
                          child: Column(
                            children: [
                              Text(_statusLabel(l10n, s),
                                  style: theme.textTheme.labelMedium),
                              Text('${_counts['$t|${s.name}'] ?? 0}',
                                  key: ValueKey('count-$t-${s.name}'),
                                  style: theme.textTheme.titleLarge),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      key: ValueKey('publish-$t'),
                      onPressed:
                          _busy ? null : () => _publish(t, _tableLabel(l10n, t)),
                      child: Text(l10n.publishReviewed),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.hijriAdminTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.hijriAdminHelp, style: theme.textTheme.bodySmall),
              for (final h in (ref.watch(hijriStartsProvider).asData?.value ?? const <HijriStart>[])
                  .reversed
                  .take(3))
                Text('${hijriMonthName(h.month, Localizations.localeOf(context).languageCode)} ${h.year}: '
                    '${h.startsOn.toIso8601String().substring(0, 10)}',
                    style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonal(
                  key: const ValueKey('hijri-add'),
                  onPressed: _busy ? null : () => _addHijriStart(l10n),
                  child: Text(l10n.hijriAdminAdd),
                ),
              ),
            ]),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.pendingShops, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...ref.watch(pendingShopsProvider).when(
                    loading: () => [const LinearProgressIndicator()],
                    error: (_, _) => [Text(l10n.loadError)],
                    data: (list) => list.isEmpty
                        ? [Text(l10n.noPendingShops, style: theme.textTheme.bodySmall)]
                        : [
                            for (final shop in list)
                              ListTile(
                                key: ValueKey('pending-${shop.id}'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(shop.name),
                                subtitle: Text(shop.phone, textDirection: TextDirection.ltr),
                                trailing: Wrap(spacing: 4, children: [
                                  TextButton(
                                    onPressed: _busy ? null : () => _setShop(shop, ShopStatus.suspended, l10n),
                                    child: Text(l10n.suspendShop),
                                  ),
                                  FilledButton(
                                    onPressed: _busy ? null : () => _setShop(shop, ShopStatus.approved, l10n),
                                    child: Text(l10n.approveShop),
                                  ),
                                ]),
                              ),
                          ],
                  ),
            ]),
          ),
        ),
      ],
    );
  }
}
