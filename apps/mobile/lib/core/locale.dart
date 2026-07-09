import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences instance, loaded once in main() and injected here.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// App languages. English is the default; Lithuanian is user-selectable.
const supportedLanguageCodes = ['en', 'lt'];

/// The active UI locale. Defaults to English; the user's choice persists across
/// launches. Read by [BrickBackApp] to drive `MaterialApp.locale`.
class LocaleController extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() {
    // Degrade to English (no persistence) when prefs aren't injected — e.g. in
    // widget/integration tests that pump the app without overriding the provider.
    try {
      return _localeFor(ref.read(sharedPreferencesProvider).getString(_prefsKey));
    } catch (_) {
      return const Locale('en');
    }
  }

  Future<void> setLanguage(String code) async {
    state = _localeFor(code);
    try {
      await ref.read(sharedPreferencesProvider).setString(_prefsKey, state.languageCode);
    } catch (_) {
      // No persistence available (tests); the in-memory switch still applies.
    }
  }

  static Locale _localeFor(String? code) =>
      code == 'lt' ? const Locale('lt') : const Locale('en');
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
