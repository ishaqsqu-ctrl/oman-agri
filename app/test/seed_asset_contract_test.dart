import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/crops/data/models.dart';

/// The bundled snapshot (written by `python -m data.export_snapshot`) must
/// parse with the app's models; every non-draft row must carry a review
/// stamp (nothing unreviewed is ever shown in a default build).
void main() {
  test('assets/seed/knowledge.json parses and non-draft rows are reviewed', () {
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
    for (final m in metas) {
      expect(s.sources.containsKey(m.sourceId), isTrue,
          reason: 'unknown source ${m.sourceId}');
    }
    // Raw JSON too: an unknown status string would also parse as draft.
    final raw = [
      for (final c in j['crops'] as List) ...[
        c as Map,
        if (c['requirements'] != null) c['requirements'] as Map,
        for (final st in c['stages'] as List) st as Map,
      ],
    ];
    for (final r in raw) {
      expect(['draft', 'reviewed', 'published'], contains(r['status']));
      if (r['status'] == 'draft') {
        expect(r['reviewed_by'], isNull);
      } else {
        expect(r['reviewed_by'], isNotNull, reason: 'unstamped ${r['status']} row');
        expect(r['reviewed_at'], isNotNull, reason: 'unstamped ${r['status']} row');
      }
    }
  });
}
