import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/map/pedons.dart';

void main() {
  test('shipped pedons parse and fall inside the map grid on land', () {
    final env = jsonDecode(File('assets/map/oman_env.json').readAsStringSync()) as Map<String, dynamic>;
    final j = jsonDecode(File('assets/map/pedons.json').readAsStringSync()) as Map<String, dynamic>;
    final pedons = [for (final p in j['pedons'] as List) Pedon.fromJson(p as Map<String, dynamic>)];
    expect(pedons, isNotEmpty);
    final land = {for (final c in env['cells'] as List) '${c[0]},${c[1]}'};
    final o = (env['origin_lon'] as num).toDouble(), a = (env['origin_lat'] as num).toDouble();
    final d = (env['cell_deg'] as num).toDouble();
    for (final p in pedons) {
      final col = ((p.lon - o) / d).floor(), row = ((a - p.lat) / d).floor();
      final near = [
        for (var dr = -1; dr <= 1; dr++)
          for (var dc = -1; dc <= 1; dc++) '${col + dc},${row + dr}'
      ].any(land.contains);
      expect(near, isTrue, reason: 'pedon ${p.n} at ${p.lat}, ${p.lon}');
      expect(p.soilAr, isNotEmpty);
    }
    expect(pedons.map((p) => p.n).toSet().length, pedons.length);
  });
}
