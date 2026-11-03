import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oman_agri/core/locale_controller.dart';
import 'package:oman_agri/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider).languageCode;
    final controller = ref.read(localeControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: RadioGroup<String>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) controller.setLocale(Locale(v));
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.language,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioListTile<String>(value: 'ar', title: Text(l10n.arabic)),
            RadioListTile<String>(value: 'en', title: Text(l10n.english)),
            const Divider(),
            ListTile(
              key: const ValueKey('settings-admin'),
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(l10n.admin),
              onTap: () => context.push('/admin'),
            ),
          ],
        ),
      ),
    );
  }
}
