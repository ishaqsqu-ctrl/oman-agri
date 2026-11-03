import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/data/snapshot_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fixtureText() => File('test/fixtures/knowledge_min.json').readAsStringSync();
Map<String, dynamic> fixtureJson() => jsonDecode(fixtureText()) as Map<String, dynamic>;

class FakeSource implements SnapshotSource {
  FakeSource(this.snap, {this.fail = false});
  final KnowledgeSnapshot snap;
  final bool fail;
  int calls = 0;
  @override
  Future<KnowledgeSnapshot> load() async {
    calls++;
    if (fail) throw Exception('network down');
    return snap;
  }
}

class FakeBundled extends BundledSnapshotSource {
  FakeBundled(this.snap);
  final KnowledgeSnapshot snap;
  @override
  Future<KnowledgeSnapshot> load() async => snap;
}

class HangingSource implements SnapshotSource {
  @override
  Future<KnowledgeSnapshot> load() => Completer<KnowledgeSnapshot>().future;
}

class MemCache implements SnapshotCache {
  KnowledgeSnapshot? stored;
  int writes = 0;
  @override
  Future<KnowledgeSnapshot?> read() async => stored;
  @override
  Future<void> write(KnowledgeSnapshot s) async {
    writes++;
    stored = s;
  }
}

KnowledgeSnapshot snapWith(List<String> cropIds, {String stamp = '2026-11-03T00:00:00+00:00'}) {
  final j = fixtureJson();
  j['generated_at'] = stamp;
  j['crops'] = [
    for (final id in cropIds)
      {...(j['crops'] as List).first as Map<String, dynamic>, 'id': id}
  ];
  return KnowledgeSnapshot.fromJson(j);
}

void main() {
  group('models', () {
    test('parses fixture', () {
      final s = KnowledgeSnapshot.fromJson(fixtureJson());
      final tomato = s.crops.firstWhere((c) => c.id == 'tomato');
      expect(tomato.stages, hasLength(4));
      expect(tomato.requirements!.tOptHigh, 27.5);
      expect(tomato.requirements!.textures, ['sand', 'loam']);
      expect(tomato.categories, [CropCategory.vegetable]);
      expect(tomato.meta.status, KnowledgeStatus.published);
      expect(tomato.meta.sourceId, 'fao56');
      expect(tomato.meta.sourcePage, 'Table 12');
      expect(s.sources['fao56']!.publisher, 'FAO');
      expect(tomato.localizedName(const Locale('ar')), 'طماطم');
      expect(tomato.localizedName(const Locale('en')), 'Tomato');
    });

    test('decimal field arriving as int parses', () {
      final s = KnowledgeSnapshot.fromJson(fixtureJson());
      final tomato = s.crops.firstWhere((c) => c.id == 'tomato');
      expect(tomato.stages.first.kc, 1.0);
      expect(tomato.requirements!.tMin, 10.0);
      expect(tomato.requirements!.altMax, 1500);
    });

    test('unknown category skipped, unknown status becomes draft', () {
      final s = KnowledgeSnapshot.fromJson(fixtureJson());
      final lime = s.crops.firstWhere((c) => c.id == 'lime');
      expect(lime.categories, [CropCategory.fruit, CropCategory.tree]);
      final okra = s.crops.firstWhere((c) => c.id == 'okra');
      expect(okra.meta.status, KnowledgeStatus.draft);
    });
  });

  group('KnowledgeRepository', () {
    test('falls back to bundled when network fails and no cache', () async {
      final bundled = snapWith(['bundled_crop']);
      final repo = KnowledgeRepository(
        chain: [FakeSource(bundled, fail: true), CachedSnapshotSource(MemCache()), FakeBundled(bundled)],
        includeDrafts: false,
      );
      final s = await repo.load();
      expect(s.crops.map((c) => c.id), ['bundled_crop']);
    });

    test('uses cache when network fails', () async {
      final cache = MemCache()..stored = snapWith(['cached_crop']);
      final repo = KnowledgeRepository(
        chain: [
          FakeSource(snapWith([]), fail: true),
          CachedSnapshotSource(cache),
          FakeBundled(snapWith(['bundled_crop'], stamp: '2020-01-01T00:00:00+00:00')),
        ],
        includeDrafts: false,
      );
      expect((await repo.load()).crops.map((c) => c.id), ['cached_crop']);
    });

    test('writes network result to cache, but not cache/bundle results', () async {
      final cache = MemCache();
      final net = FakeSource(snapWith(['net_crop']));
      final repo = KnowledgeRepository(
          chain: [net, FakeSource(snapWith(['b']))], includeDrafts: false, cache: cache);
      await repo.load();
      expect(cache.writes, 1);
      expect(cache.stored!.crops.single.id, 'net_crop');

      final cache2 = MemCache()..stored = snapWith(['c']);
      final repo2 = KnowledgeRepository(
          chain: [FakeSource(snapWith([]), fail: true), CachedSnapshotSource(cache2)],
          includeDrafts: false,
          cache: cache2);
      expect((await repo2.load()).crops.single.id, 'c');
      expect(cache2.writes, 0);
    });

    test('cache older than bundle -> bundle wins; newer -> cache wins; tie -> cache', () async {
      Future<String> run(String cacheStamp, String bundleStamp) async {
        final repo = KnowledgeRepository(
          chain: [
            FakeSource(snapWith([]), fail: true),
            CachedSnapshotSource(MemCache()..stored = snapWith(['cached'], stamp: cacheStamp)),
            FakeBundled(snapWith(['bundled'], stamp: bundleStamp)),
          ],
          includeDrafts: false,
        );
        return (await repo.load()).crops.single.id;
      }

      expect(await run('2026-01-01T00:00:00Z', '2026-06-01T00:00:00Z'), 'bundled');
      expect(await run('2026-06-01T00:00:00Z', '2026-01-01T00:00:00Z'), 'cached');
      expect(await run('2026-06-01T00:00:00Z', '2026-06-01T00:00:00Z'), 'cached');
    });

    test('hung network times out and falls through', () async {
      final repo = KnowledgeRepository(
        chain: [HangingSource(), FakeBundled(snapWith(['bundled']))],
        includeDrafts: false,
        networkTimeout: const Duration(milliseconds: 50),
      );
      expect((await repo.load()).crops.single.id, 'bundled');
    });

    test('empty network snapshot does not overwrite non-empty cache', () async {
      final cache = MemCache()..stored = snapWith(['cached']);
      final repo = KnowledgeRepository(
          chain: [FakeSource(snapWith([]))], includeDrafts: false, cache: cache);
      expect((await repo.load()).crops, isEmpty);
      expect(cache.writes, 0);
      expect(cache.stored!.crops.single.id, 'cached');
    });

    test('hides drafts by default', () async {
      final repo = KnowledgeRepository(
          chain: [FakeSource(KnowledgeSnapshot.fromJson(fixtureJson()))], includeDrafts: false);
      final s = await repo.load();
      expect(s.crops.map((c) => c.id), ['tomato']);
    });

    test('shows drafts when includeDrafts', () async {
      final repo = KnowledgeRepository(
          chain: [FakeSource(KnowledgeSnapshot.fromJson(fixtureJson()))], includeDrafts: true);
      expect((await repo.load()).crops, hasLength(3));
    });

    test('all-draft data yields empty crops by default (no draft leakage)', () async {
      final j = fixtureJson();
      for (final c in j['crops'] as List) {
        (c as Map<String, dynamic>)['status'] = 'draft';
      }
      final repo = KnowledgeRepository(
          chain: [FakeSource(KnowledgeSnapshot.fromJson(j))], includeDrafts: false);
      expect((await repo.load()).crops, isEmpty);
    });

    test('partial stages: any draft stage drops the whole curve', () async {
      final j = fixtureJson();
      (((j['crops'] as List).first as Map)['stages'] as List).last['status'] = 'draft';
      final repo = KnowledgeRepository(
          chain: [FakeSource(KnowledgeSnapshot.fromJson(j))], includeDrafts: false);
      expect((await repo.load()).crops.single.stages, isEmpty);
    });

    test('throws when every source fails', () async {
      final repo = KnowledgeRepository(
          chain: [FakeSource(snapWith([]), fail: true)], includeDrafts: false);
      expect(repo.load(), throwsA(isA<Exception>()));
    });
  });

  group('assembleSnapshot', () {
    test('joins requirements and stages by crop and sorts stages by seq', () {
      Map<String, dynamic> m(Map<String, dynamic> x) =>
          {'status': 'published', 'source_id': 'fao56', ...x};
      final s = assembleSnapshot(
        sources: [
          {'id': 'fao56', 'title': 't', 'publisher': 'FAO', 'type': 'fao'}
        ],
        governorates: [],
        wilayats: [],
        crops: [
          m({'id': 'a', 'name_ar': 'أ', 'name_en': 'A', 'categories': ['fruit']}),
          m({'id': 'b', 'name_ar': 'ب', 'name_en': 'B', 'categories': ['fruit']}),
        ],
        cropRequirements: [m({'crop_id': 'b', 't_min': 5})],
        cropStages: [
          m({'crop_id': 'a', 'seq': 2, 'stage': 'mid', 'duration_days': 5, 'kc': 1}),
          m({'crop_id': 'a', 'seq': 1, 'stage': 'initial', 'duration_days': 5, 'kc': 0.4}),
          m({'crop_id': 'b', 'seq': 1, 'stage': 'initial', 'duration_days': 5, 'kc': 0.5}),
        ],
        now: DateTime.utc(2026, 11, 3),
      );
      final a = s.crops.firstWhere((c) => c.id == 'a');
      final b = s.crops.firstWhere((c) => c.id == 'b');
      expect(a.stages.map((x) => x.seq), [1, 2]);
      expect(a.requirements, isNull);
      expect(b.requirements!.tMin, 5.0);
      expect(b.stages, hasLength(1));
      expect(s.generatedAt, DateTime.utc(2026, 11, 3));
    });
  });

  group('SnapshotCache', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('prefs cache round-trips', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = PrefsSnapshotCache(await SharedPreferences.getInstance());
      expect(await cache.read(), isNull);
      await cache.write(KnowledgeSnapshot.fromJson(fixtureJson()));
      final back = await cache.read();
      expect(back!.crops, hasLength(3));
      expect(back.crops.first.stages, hasLength(4));
    });

    test('corrupt prefs cache is a miss', () async {
      SharedPreferences.setMockInitialValues({'knowledge_snapshot': '{not json'});
      final cache = PrefsSnapshotCache(await SharedPreferences.getInstance());
      expect(await cache.read(), isNull);
    });

    test('file cache round-trips and corrupt file is a miss', () async {
      final dir = Directory.systemTemp.createTempSync('snap');
      final f = File('${dir.path}/knowledge_snapshot.json');
      final cache = FileSnapshotCache(f);
      expect(await cache.read(), isNull);
      await cache.write(KnowledgeSnapshot.fromJson(fixtureJson()));
      expect((await cache.read())!.crops, hasLength(3));
      f.writeAsStringSync('garbage');
      expect(await cache.read(), isNull);
      dir.deleteSync(recursive: true);
    });
  });
}
