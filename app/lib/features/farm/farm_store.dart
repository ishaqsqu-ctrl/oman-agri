import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/core/locale_controller.dart';

/// One crop the farmer has planted. Kept on the device (works offline).
@immutable
class Planting {
  const Planting({required this.id, required this.cropId, required this.plantedOn});

  final String id;
  final String cropId;
  final DateTime plantedOn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop_id': cropId,
        'planted_on': plantedOn.toIso8601String().substring(0, 10),
      };

  static Planting? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], crop = j['crop_id'], on = DateTime.tryParse('${j['planted_on']}');
    if (id is! String || crop is! String || on == null) return null;
    return Planting(id: id, cropId: crop, plantedOn: on);
  }
}

const farmPrefKey = 'farm.plantings.v1';

final farmProvider = NotifierProvider<FarmController, List<Planting>>(FarmController.new);

class FarmController extends Notifier<List<Planting>> {
  @override
  List<Planting> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(farmPrefKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final e in list) ?Planting.tryParse(e)]
        ..sort((a, b) => b.plantedOn.compareTo(a.plantedOn));
    } catch (_) {
      return const []; // a corrupt entry must not lock the farmer out
    }
  }

  Future<void> add(String cropId, DateTime plantedOn) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    state = [Planting(id: id, cropId: cropId, plantedOn: plantedOn), ...state]
      ..sort((a, b) => b.plantedOn.compareTo(a.plantedOn));
    await _save();
  }

  Future<void> remove(String id) async {
    state = [for (final p in state) if (p.id != id) p];
    await _save();
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(farmPrefKey, jsonEncode([for (final p in state) p.toJson()]));
}
