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
    final reqs = {for (final r in results[4]) r['crop_id'] as String: r};
    final stages = <String, List<Map<String, dynamic>>>{};
    for (final s in results[5]) {
      stages.putIfAbsent(s['crop_id'] as String, () => []).add(s);
    }
    for (final l in stages.values) {
      l.sort((a, b) => (a['seq'] as num).compareTo(b['seq'] as num));
    }
    return KnowledgeSnapshot.fromJson({
      'schema_version': 1,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'sources': results[0],
      'governorates': results[1],
      'wilayats': results[2],
      'crops': [
        for (final c in results[3])
          {...c, 'requirements': reqs[c['id']], 'stages': stages[c['id']] ?? const []}
      ],
    });
  }
}

class KnowledgeRepository {
  KnowledgeRepository({required this.chain, required this.includeDrafts, this.cache});

  final List<SnapshotSource> chain;
  final bool includeDrafts;
  final SnapshotCache? cache;

  Future<KnowledgeSnapshot> load() async {
    Object? lastError;
    for (final source in chain) {
      try {
        final snap = await source.load();
        if (cache != null && source is! CachedSnapshotSource && source is! BundledSnapshotSource) {
          try {
            await cache!.write(snap);
          } catch (_) {
            // A failing cache must not break loading.
          }
        }
        return _filter(snap);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('No knowledge source available: $lastError');
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
              stages: c.stages.where((x) => ok(x.meta)).toList(),
            )
      ],
      governorates: s.governorates.where((r) => ok(r.meta)).toList(),
      wilayats: s.wilayats.where((r) => ok(r.meta)).toList(),
    );
  }
}

final snapshotCacheProvider = FutureProvider<SnapshotCache>(
    (ref) => createSnapshotCache(ref.watch(sharedPreferencesProvider)));

final knowledgeProvider = FutureProvider<KnowledgeSnapshot>((ref) async {
  final cache = await ref.watch(snapshotCacheProvider.future);
  final repo = KnowledgeRepository(
    chain: [
      if (hasBackend) SupabaseSnapshotSource(Supabase.instance.client),
      CachedSnapshotSource(cache),
      BundledSnapshotSource(),
    ],
    includeDrafts: showDrafts,
    cache: cache,
  );
  return repo.load();
});
