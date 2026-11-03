import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config.dart';
import '../../../core/locale_controller.dart';
import 'models.dart';
import 'snapshot_cache.dart';

abstract class SnapshotSource {
  Future<KnowledgeSnapshot> load();
}

class CachedSnapshotSource implements SnapshotSource {
  CachedSnapshotSource(this.cache);
  final SnapshotCache cache;

  @override
  Future<KnowledgeSnapshot> load() async {
    final s = await cache.read();
    if (s == null) throw StateError('no cached snapshot');
    return s;
  }
}

class BundledSnapshotSource implements SnapshotSource {
  BundledSnapshotSource({this.assetPath = 'assets/seed/knowledge.json'});
  final String assetPath;

  @override
  Future<KnowledgeSnapshot> load() async {
    final text = await rootBundle.loadString(assetPath);
    return KnowledgeSnapshot.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}

class SupabaseSnapshotSource implements SnapshotSource {
  SupabaseSnapshotSource(this.client);
  final SupabaseClient client;

  // TODO: PostgREST returns at most 1000 rows per request by default; page
  // with .range() once any table can exceed that.
  Future<List<Map<String, dynamic>>> _all(String table) async =>
      List<Map<String, dynamic>>.from(await client.from(table).select());

  @override
  Future<KnowledgeSnapshot> load() async {
    final results = await Future.wait([
      _all('sources'),
      _all('governorates'),
      _all('wilayats'),
      _all('crops'),
      _all('crop_requirements'),
      _all('crop_stages'),
    ]);
    return assembleSnapshot(
      sources: results[0],
      governorates: results[1],
      wilayats: results[2],
      crops: results[3],
      cropRequirements: results[4],
      cropStages: results[5],
    );
  }
}

/// Joins the six table row-sets into a snapshot (stages sorted by seq).
/// generatedAt is the fetch time: server data is authoritative at that moment.
KnowledgeSnapshot assembleSnapshot({
  required List<Map<String, dynamic>> sources,
  required List<Map<String, dynamic>> governorates,
  required List<Map<String, dynamic>> wilayats,
  required List<Map<String, dynamic>> crops,
  required List<Map<String, dynamic>> cropRequirements,
  required List<Map<String, dynamic>> cropStages,
  DateTime? now,
}) {
  final reqs = {for (final r in cropRequirements) r['crop_id'] as String: r};
  final stages = <String, List<Map<String, dynamic>>>{};
  for (final s in cropStages) {
    stages.putIfAbsent(s['crop_id'] as String, () => []).add(s);
  }
  for (final l in stages.values) {
    l.sort((a, b) => (a['seq'] as num).compareTo(b['seq'] as num));
  }
  return KnowledgeSnapshot.fromJson({
    'schema_version': 1,
    'generated_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
    'sources': sources,
    'governorates': governorates,
    'wilayats': wilayats,
    'crops': [
      for (final c in crops)
        {...c, 'requirements': reqs[c['id']], 'stages': stages[c['id']] ?? const []}
    ],
  });
}

class KnowledgeRepository {
  KnowledgeRepository({
    required this.chain,
    required this.includeDrafts,
    this.cache,
    this.networkTimeout = const Duration(seconds: 8),
  });

  final List<SnapshotSource> chain;
  final bool includeDrafts;
  final SnapshotCache? cache;
  final Duration networkTimeout;

  static bool _isLocal(SnapshotSource s) =>
      s is CachedSnapshotSource || s is BundledSnapshotSource;

  /// Network sources are tried first (with a timeout). If they all fail, the
  /// cached and bundled snapshots are both loaded and the later generatedAt
  /// wins (tie goes to the cache), so an app update's newer bundle beats a
  /// stale cache.
  Future<KnowledgeSnapshot> load() async {
    Object? lastError;
    for (final source in chain.where((s) => !_isLocal(s))) {
      try {
        final snap = await source.load().timeout(networkTimeout);
        await _maybeWriteCache(snap);
        return _filter(snap);
      } catch (e) {
        lastError = e;
      }
    }
    KnowledgeSnapshot? cached, bundled;
    for (final source in chain.where(_isLocal)) {
      try {
        final snap = await source.load();
        if (source is CachedSnapshotSource) {
          cached ??= snap;
        } else {
          bundled ??= snap;
        }
      } catch (e) {
        lastError = e;
      }
    }
    final best = (cached != null && bundled != null)
        ? (bundled.generatedAt.isAfter(cached.generatedAt) ? bundled : cached)
        : (cached ?? bundled);
    if (best == null) throw Exception('No knowledge source available: $lastError');
    return _filter(best);
  }

  Future<void> _maybeWriteCache(KnowledgeSnapshot snap) async {
    final c = cache;
    if (c == null) return;
    try {
      if (snap.crops.isEmpty) {
        final existing = await c.read();
        if (existing != null && existing.crops.isNotEmpty) return;
      }
      await c.write(snap);
    } catch (_) {
      // A failing cache must not break loading.
    }
  }

  KnowledgeSnapshot _filter(KnowledgeSnapshot s) {
    if (includeDrafts) return s;
    bool ok(KnowledgeMeta m) => m.isPublished;
    return s.withContent(
      crops: [
        for (final c in s.crops)
          if (ok(c.meta))
            c.copyWith(
              requirements: () =>
                  c.requirements != null && ok(c.requirements!.meta) ? c.requirements : null,
              // A partial Kc curve misstates water needs: all or nothing.
              stages: c.stages.every((x) => ok(x.meta)) ? c.stages : const [],
            )
      ],
      governorates: s.governorates.where((r) => ok(r.meta)).toList(),
      wilayats: s.wilayats.where((r) => ok(r.meta)).toList(),
    );
  }
}

final snapshotCacheProvider = FutureProvider<SnapshotCache>(
    (ref) => createSnapshotCache(ref.watch(sharedPreferencesProvider)));

/// Whether this build shows draft rows (and the draft banner). Tests override.
final includeDraftsProvider = Provider<bool>((ref) => showDrafts);

final knowledgeProvider = FutureProvider<KnowledgeSnapshot>((ref) async {
  final cache = await ref.watch(snapshotCacheProvider.future);
  final repo = KnowledgeRepository(
    chain: [
      if (hasBackend) SupabaseSnapshotSource(Supabase.instance.client),
      CachedSnapshotSource(cache),
      BundledSnapshotSource(),
    ],
    includeDrafts: ref.watch(includeDraftsProvider),
    cache: cache,
  );
  return repo.load();
});
