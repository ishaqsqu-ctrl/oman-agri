import 'package:flutter/material.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

/// Placeholder; Task 8 replaces this with the crops list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('home-placeholder'),
      child: Text(AppLocalizations.of(context).emptyCrops),
    );
  }
}
