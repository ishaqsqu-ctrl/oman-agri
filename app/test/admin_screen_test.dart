import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_agri/features/admin/admin_repository.dart';
import 'package:oman_agri/features/admin/admin_screen.dart';
import 'package:oman_agri/core/config.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.admin = true, this.signInOk = true, this.publishError});
  bool admin;
  bool signInOk;
  Object? publishError;
  final published = <String>[];
  final signIns = <String>[];
  Completer<void>? gate;

  @override
  Future<bool> signIn(String email, String password) async {
    signIns.add('$email|$password');
    return signInOk;
  }

  // Not signed in until signIn is called.
  @override
  Future<bool> isAdmin() async => signIns.isNotEmpty && admin;

  @override
  Future<void> signOut() async {}

  @override
  Future<List<StatusCount>> counts() async => const [
        StatusCount('crops', KnowledgeStatus.draft, 3),
        StatusCount('crops', KnowledgeStatus.reviewed, 2),
        StatusCount('wilayats', KnowledgeStatus.published, 7),
      ];

  @override
  Future<int> publishReviewed(String table) async {
    published.add(table);
    if (gate != null) await gate!.future;
    if (publishError != null) throw publishError!;
    return 2;
  }
}

Future<void> pump(WidgetTester tester, AdminRepository repo,
    {bool backend = true, Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      adminRepositoryProvider.overrideWithValue(repo),
      hasBackendProvider.overrideWithValue(backend),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AdminScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('admin-email')), 'a@b.c');
  await tester.enterText(find.byKey(const ValueKey('admin-password')), 'pw');
  await tester.tap(find.byKey(const ValueKey('admin-signin')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no backend shows message', (tester) async {
    await pump(tester, FakeAdminRepository(), backend: false);
    expect(find.text('The admin panel requires a server connection'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('admin-signin')), findsNothing);
  });

  testWidgets('no backend message in Arabic', (tester) async {
    await pump(tester, FakeAdminRepository(),
        backend: false, locale: const Locale('ar'));
    expect(find.text('لوحة المدير تتطلب الاتصال بالخادم'), findsOneWidget);
  });

  testWidgets('non-admin sees not-authorized', (tester) async {
    await pump(tester, FakeAdminRepository(admin: false));
    await signIn(tester);
    expect(find.text('This account does not have admin permission'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('publish-crops')), findsNothing);
  });

  testWidgets('failed sign-in shows error', (tester) async {
    await pump(tester, FakeAdminRepository(signInOk: false));
    await signIn(tester);
    expect(find.text('Sign-in failed'), findsOneWidget);
  });

  testWidgets('counts grid renders with zero for missing combos',
      (tester) async {
    await pump(tester, FakeAdminRepository());
    await signIn(tester);
    expect(find.text('Crops'), findsOneWidget);
    expect(find.text('Wilayats'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
    expect(find.text('Reviewed'), findsWidgets);
    expect(find.text('Published'), findsWidgets);
    expect(find.byKey(const ValueKey('count-crops-draft')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('count-crops-draft'))).data,
        '3');
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('count-crops-published')))
            .data,
        '0');
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('count-wilayats-published')))
            .data,
        '7');
  });

  testWidgets('publish: confirm then snackbar with count', (tester) async {
    final repo = FakeAdminRepository();
    await pump(tester, repo);
    await signIn(tester);
    await tester.tap(find.byKey(const ValueKey('publish-crops')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repo.published, isEmpty);
    await tester.tap(find.byKey(const ValueKey('publish-confirm')));
    await tester.pumpAndSettle();
    expect(repo.published, ['crops']);
    expect(find.text('Published 2 rows'), findsOneWidget);
  });

  testWidgets('cancel does not publish', (tester) async {
    final repo = FakeAdminRepository();
    await pump(tester, repo);
    await signIn(tester);
    await tester.tap(find.byKey(const ValueKey('publish-crops')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('publish-cancel')));
    await tester.pumpAndSettle();
    expect(repo.published, isEmpty);
  });

  testWidgets('publish error shows localized snackbar, no crash',
      (tester) async {
    final repo = FakeAdminRepository(publishError: Exception('boom'));
    await pump(tester, repo);
    await signIn(tester);
    await tester.tap(find.byKey(const ValueKey('publish-crops')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('publish-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Could not load data. Please try again.'), findsNothing);
    expect(find.text('Operation failed. Please try again.'), findsOneWidget);
  });

  testWidgets('publish buttons disabled while in flight', (tester) async {
    final repo = FakeAdminRepository()..gate = Completer<void>();
    await pump(tester, repo);
    await signIn(tester);
    await tester.tap(find.byKey(const ValueKey('publish-crops')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('publish-confirm')));
    await tester.pump();
    final btn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('publish-wilayats')));
    expect(btn.onPressed, isNull);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('publish-wilayats')))
            .onPressed,
        isNotNull);
  });
}
