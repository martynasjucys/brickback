import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences instance, loaded once in main() and injected here.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// App languages the UI can resolve to. English is the source; Lithuanian is fully translated.
const supportedLanguageCodes = ['en', 'lt'];

/// The three language choices surfaced in Profile → Language. `system` follows the device locale
/// (the first-launch default — auto-detect); `en` / `lt` force one. Mirrors Swift `AppLanguage`.
enum AppLanguage {
  system,
  en,
  lt;

  /// The choice a persisted [Locale] represents (null Locale ⇒ System).
  static AppLanguage fromLocale(Locale? locale) => switch (locale?.languageCode) {
        'en' => AppLanguage.en,
        'lt' => AppLanguage.lt,
        _ => AppLanguage.system,
      };
}

/// The active UI override, or `null` to follow the device locale. On first launch (no stored
/// choice) it is `null`, so `MaterialApp.locale = null` lets `basicLocaleListResolution` pick the
/// best of `[en, lt]` for the device — a Lithuanian device comes up Lithuanian with no manual
/// switch. The user's explicit choice persists across launches; "System" clears it. Mirrors the
/// Swift `LocaleController` (adds the first-launch auto-detect the Flutter app had deferred).
class LocaleController extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() {
    // Follow the device (no persistence) when prefs aren't injected — e.g. in widget/integration
    // tests that pump the app without overriding the provider.
    try {
      return _localeFor(ref.read(sharedPreferencesProvider).getString(_prefsKey));
    } catch (_) {
      return null;
    }
  }

  /// Set the language by [AppLanguage]. "System" clears the stored choice (null Locale ⇒ device
  /// auto-detect); `en` / `lt` persist.
  Future<void> setLanguage(AppLanguage lang) async {
    state = switch (lang) {
      AppLanguage.system => null,
      AppLanguage.en => const Locale('en'),
      AppLanguage.lt => const Locale('lt'),
    };
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (state == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, state!.languageCode);
      }
    } catch (_) {
      // No persistence available (tests); the in-memory switch still applies.
    }
  }

  static Locale? _localeFor(String? code) => switch (code) {
        'en' => const Locale('en'),
        'lt' => const Locale('lt'),
        _ => null, // 'system' / absent / unknown → follow the device
      };
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
