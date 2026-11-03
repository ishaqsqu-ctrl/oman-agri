import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localePrefKey = 'locale';

/// Overridden in main() (and tests) with the loaded SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  static const supported = ['ar', 'en'];

  @override
  Locale build() {
    final saved = ref.read(sharedPreferencesProvider).getString(localePrefKey);
    return Locale(supported.contains(saved) ? saved! : 'ar');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(localePrefKey, locale.languageCode);
  }
}
