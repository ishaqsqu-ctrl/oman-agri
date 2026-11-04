import 'package:flutter/material.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// Placeholder for a tab whose feature arrives in a later phase: says what is coming.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen(this.featureKey, {super.key});

  final String featureKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (IconData icon, String title, String body) = switch (featureKey) {
      'map' => (Icons.map_outlined, l10n.tabMap, l10n.comingMap),
      'calendar' => (Icons.calendar_month_outlined, l10n.tabCalendar, l10n.comingCalendar),
      'farm' => (Icons.agriculture_outlined, l10n.tabFarm, l10n.comingFarm),
      'store' => (Icons.storefront_outlined, l10n.tabStore, l10n.comingStore),
      _ => (Icons.schedule, '', ''),
    };
    return Center(
      key: ValueKey('coming-soon-$featureKey'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            if (title.isNotEmpty) Text(title, style: theme.textTheme.headlineSmall),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(l10n.comingSoon,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
            ),
          ]),
        ),
      ),
    );
  }
}
