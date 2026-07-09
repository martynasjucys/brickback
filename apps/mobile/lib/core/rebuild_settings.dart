import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale.dart' show sharedPreferencesProvider;

/// How the counting screen groups the parts list.
enum PartGrouping { color, category, status, none }

/// Per-user view preferences for the counting screen — set from its settings
/// sheet, persisted across launches.
class RebuildViewSettings {
  const RebuildViewSettings({this.grouping = PartGrouping.color, this.showExtras = false});

  /// How the parts list is sectioned.
  final PartGrouping grouping;

  /// Whether the set's spare / extra parts are shown (as a countable bonus,
  /// excluded from build completion).
  final bool showExtras;

  RebuildViewSettings copyWith({PartGrouping? grouping, bool? showExtras}) =>
      RebuildViewSettings(
        grouping: grouping ?? this.grouping,
        showExtras: showExtras ?? this.showExtras,
      );
}

/// Persists the counting-screen view settings. Degrades to defaults (no
/// persistence) when prefs aren't injected — e.g. widget/integration tests that
/// pump the app without overriding the provider, mirroring [LocaleController].
class RebuildSettingsController extends Notifier<RebuildViewSettings> {
  static const _groupingKey = 'rebuild_grouping';
  static const _showExtrasKey = 'rebuild_show_extras';

  @override
  RebuildViewSettings build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      return RebuildViewSettings(
        grouping: _groupingFor(prefs.getString(_groupingKey)),
        showExtras: prefs.getBool(_showExtrasKey) ?? false,
      );
    } catch (_) {
      return const RebuildViewSettings();
    }
  }

  void setGrouping(PartGrouping g) {
    state = state.copyWith(grouping: g);
    try {
      ref.read(sharedPreferencesProvider).setString(_groupingKey, g.name);
    } catch (_) {
      // No persistence available (tests); the in-memory change still applies.
    }
  }

  void setShowExtras(bool v) {
    state = state.copyWith(showExtras: v);
    try {
      ref.read(sharedPreferencesProvider).setBool(_showExtrasKey, v);
    } catch (_) {
      // No persistence available (tests); the in-memory change still applies.
    }
  }

  static PartGrouping _groupingFor(String? name) => PartGrouping.values
      .firstWhere((g) => g.name == name, orElse: () => PartGrouping.color);
}

final rebuildSettingsProvider = NotifierProvider<RebuildSettingsController, RebuildViewSettings>(
    RebuildSettingsController.new);
