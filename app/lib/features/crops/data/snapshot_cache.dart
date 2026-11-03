import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const snapshotPrefKey = 'knowledge_snapshot';

/// Persists the last good snapshot. Corrupt content is a cache miss (null).
abstract class SnapshotCache {
  Future<KnowledgeSnapshot?> read();
  Future<void> write(KnowledgeSnapshot snapshot);
}

KnowledgeSnapshot? _decode(String text) {
  try {
    final j = jsonDecode(text);
    if (j is! Map<String, dynamic>) return null;
    return KnowledgeSnapshot.fromJson(j);
  } catch (_) {
    return null;
  }
}

String? _encode(KnowledgeSnapshot s) => s.raw == null ? null : jsonEncode(s.raw);

class PrefsSnapshotCache implements SnapshotCache {
  PrefsSnapshotCache(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<KnowledgeSnapshot?> read() async {
    final t = _prefs.getString(snapshotPrefKey);
    return t == null ? null : _decode(t);
  }

  @override
  Future<void> write(KnowledgeSnapshot snapshot) async {
    final t = _encode(snapshot);
    if (t != null) await _prefs.setString(snapshotPrefKey, t);
  }
}

class FileSnapshotCache implements SnapshotCache {
  FileSnapshotCache(this._file);
  final File _file;

  @override
  Future<KnowledgeSnapshot?> read() async {
    try {
      if (!await _file.exists()) return null;
      return _decode(await _file.readAsString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(KnowledgeSnapshot snapshot) async {
    final t = _encode(snapshot);
    if (t == null) return;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(t, flush: true);
  }
}

/// File in the app documents dir on native, shared_preferences on web.
Future<SnapshotCache> createSnapshotCache(SharedPreferences prefs) async {
  if (kIsWeb) return PrefsSnapshotCache(prefs);
  final dir = await getApplicationDocumentsDirectory();
  return FileSnapshotCache(File('${dir.path}/knowledge_snapshot.json'));
}
