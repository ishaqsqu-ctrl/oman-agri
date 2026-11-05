// Worst-case check with the real seed data: the crop grid and every crop page
// at a narrow phone (320 px) and a normal one (390 px), at normal and doubled
// text size, in Arabic and English. The real data already holds the hard
// cases: the longest names, crops with no requirements, stages or monthly
// values, and crops in several categories.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/features/crops/ui/crop_detail_screen.dart';
import 'package:oman_agri/features/crops/ui/crops_list_screen.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _snap = KnowledgeSnapshot.fromJson(
    jsonDecode(File('assets/seed/knowledge.json').readAsStringSync()) as Map<String, dynamic>);

Future<List<String>> _render(WidgetTester tester, Widget screen,
    {required double width, required double scale, required String locale, required Type scrollable}) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (d) => errors.add('${d.exceptionAsString().split('\n').first} @ ${RegExp(r'lib/[^:]+:\d+').firstMatch(d.toString())?.group(0) ?? '?'}');
  try {
    tester.view.physicalSize = Size(width, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    SharedPreferences.setMockInitialValues({localePrefKey: locale});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        includeDraftsProvider.overrideWithValue(false),
        knowledgeProvider.overrideWith((ref) async => _snap),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: screen),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final s = find.byType(scrollable);
    for (var i = 0; i < 12 && s.evaluate().isNotEmpty; i++) {
      await tester.drag(s.first, const Offset(0, -600), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));
  } finally {
    FlutterError.onError = previous;
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.reset();
  }
  return errors;
}

void main() {
  final crops = [for (final c in _snap.crops) if (c.meta.isPublished) c];
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final locale in ['ar', 'en']) {
        final label = '${width.toInt()} px, text x$scale, $locale';
        testWidgets('real data grid: no layout errors at $label', (tester) async {
          final errors = await _render(tester, const CropsListScreen(),
              width: width, scale: scale, locale: locale, scrollable: CustomScrollView);
          expect(errors, isEmpty, reason: errors.toSet().join('\n'));
        });
        testWidgets('real data crop pages: no layout errors at $label', (tester) async {
          final broken = <String, Set<String>>{};
          for (final Crop c in crops) {
            final errors = await _render(tester, CropDetailScreen(cropId: c.id),
                width: width, scale: scale, locale: locale, scrollable: ListView);
            if (errors.isNotEmpty) broken[c.id] = errors.toSet();
          }
          expect(broken, isEmpty, reason: broken.entries.map((e) => '${e.key}: ${e.value.join(' | ')}').join('\n'));
        });
      }
    }
  }
}
