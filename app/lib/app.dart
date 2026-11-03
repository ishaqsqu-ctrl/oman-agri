import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/core/router.dart';
import 'package:oman_agri/core/theme.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class OmanAgriApp extends ConsumerWidget {
  const OmanAgriApp({super.key, this.router});

  /// Defaults to the shared [appRouter]; tests pass a fresh one.
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: buildTheme(),
      darkTheme: buildTheme(brightness: Brightness.dark),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router ?? appRouter,
    );
  }
}
