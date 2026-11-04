import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.eco_outlined), selectedIcon: const Icon(Icons.eco), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: l10n.tabMap),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l10n.tabCalendar),
          NavigationDestination(
              icon: const Icon(Icons.agriculture_outlined), selectedIcon: const Icon(Icons.agriculture), label: l10n.tabFarm),
          NavigationDestination(
              icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: l10n.tabStore),
        ],
      ),
    );
  }
}
