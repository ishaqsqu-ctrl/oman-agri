import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/app.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/router.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      knowledgeProvider.overrideWith((ref) async => KnowledgeSnapshot(
          generatedAt: DateTime.utc(2026), sources: const {}, crops: const [])),
    ],
    child: OmanAgriApp(router: buildRouter()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('default locale is Arabic and RTL', (tester) async {
    await pumpApp(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(find.text('مزارع عُمان'), findsOneWidget);
  });

  testWidgets('switching to English persists', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    var ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Oman Farmer'), findsOneWidget);

    // "Restart": fresh app, same stored prefs.
    await pumpApp(tester);
    ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);
    expect(find.text('Oman Farmer'), findsOneWidget);
  });

  testWidgets('five tabs in order', (tester) async {
    await pumpApp(tester);
    final labels = ['الرئيسية', 'الخريطة', 'التقويم', 'مزرعتي', 'المتجر'];
    final xs = [
      for (final l in labels) tester.getCenter(find.text(l)).dx,
    ];
    // RTL: first tab is rightmost.
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], lessThan(xs[i - 1]));
    }
    await tester.tap(find.text('الخريطة'));
    await tester.pumpAndSettle();
    expect(find.text('قريباً'), findsOneWidget);
  });
}
