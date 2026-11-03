import 'package:flutter/material.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen(this.featureKey, {super.key});

  final String featureKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: ValueKey('coming-soon-$featureKey'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 48),
          const SizedBox(height: 12),
          Text(l10n.comingSoon, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
