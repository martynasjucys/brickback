import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale.dart' show sharedPreferencesProvider;

/// Owns the chosen appearance, persists it to SharedPreferences, and exposes the
/// [ThemeMode] the app root hands to `MaterialApp.themeMode`. Mirrors
/// [LocaleController] (and the Swift `ThemeController` oracle): `system` follows
/// the device (the default); `light` / `dark` force one.
///
/// The Profile appearance-picker row that drives this is an F5 item — F2 only
/// builds the controller + wiring so `themeMode` works and defaults to system.
class ThemeController extends Notifier<ThemeMode> {
  static const _prefsKey = 'app_theme';

  @override
  ThemeMode build() {
    // Degrade to system (no persistence) when prefs aren't injected — e.g. in
    // widget/integration tests that pump the app without overriding the provider.
    try {
      return _modeFor(ref.read(sharedPreferencesProvider).getString(_prefsKey));
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (mode == ThemeMode.system) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, mode.name);
      }
    } catch (_) {
      // No persistence available (tests); the in-memory switch still applies.
    }
  }

  static ThemeMode _modeFor(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
