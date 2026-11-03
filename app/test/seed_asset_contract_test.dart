import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';

/// The bundled snapshot (written by `python -m data.export_snapshot`) must
/// parse with the app's models, and must ship all-draft (no fabricated data
/// is ever shown in a default build).
void main() {
  test('assets/seed/knowledge.json parses and is all draft', () {
    final j = jsonDecode(File('assets/seed/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    final s = KnowledgeSnapshot.fromJson(j);
    expect(s.crops, isNotEmpty);
    final metas = [
      for (final c in s.crops) ...[
        c.meta,
        if (c.requirements != null) c.requirements!.meta,
        for (final st in c.stages) st.meta,
      ],
    ];
    expect(metas.map((m) => m.status).toSet(), {KnowledgeStatus.draft});
    for (final m in metas) {
      expect(s.sources.containsKey(m.sourceId), isTrue,
          reason: 'unknown source ${m.sourceId}');
    }
    // Raw JSON too: an unknown status string would also parse as draft.
    for (final c in j['crops'] as List) {
      expect((c as Map)['status'], 'draft');
    }
  });
}
