import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale.dart' show sharedPreferencesProvider;

/// A small brick-themed random name generator. Seeds a friendly display name for anyone who never
/// sets one, so the party roster/feed reads "Sunny Brick" instead of the server's "Builder"
/// fallback. Port of `NameGenerator` (DisplayNameController.swift:6-21).
class NameGenerator {
  NameGenerator._();

  static const _adjectives = [
    'Brave', 'Sunny', 'Clever', 'Golden', 'Mighty', 'Swift', 'Jolly', 'Cosmic',
    'Turbo', 'Nimble', 'Sparky', 'Lucky', 'Bold', 'Zippy', 'Cheery', 'Snappy',
  ];
  static const _nouns = [
    'Brick', 'Stud', 'Minifig', 'Baseplate', 'Builder', 'Plate', 'Tile', 'Sorter',
    'Block', 'Wrench', 'Cog', 'Piece', 'Bricklayer', 'Gearhead', 'Tinker',
  ];

  static final _rng = Random();

  static String random() {
    final a = _adjectives[_rng.nextInt(_adjectives.length)];
    final n = _nouns[_rng.nextInt(_nouns.length)];
    return '$a $n';
  }
}

/// Owns the user's display name — the label shown to others in party mode (`party_members`).
/// Persisted to SharedPreferences, mirrors [LocaleController]. **Never blank:** if the user hasn't
/// chosen one, a random brick-themed name is generated on first launch and kept. The chosen name
/// rides into the anonymous guest session's metadata (party join = guest). Port of
/// `DisplayNameController`.
class DisplayNameController extends Notifier<String> {
  static const _prefsKey = 'display_name';
  static const _maxLength = 24;

  @override
  String build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getString(_prefsKey)?.trim();
      if (stored != null && stored.isNotEmpty) return stored;
      // First launch (or a cleared name) → seed a random one and persist it.
      final generated = NameGenerator.random();
      prefs.setString(_prefsKey, generated);
      return generated;
    } catch (_) {
      // No prefs available (tests): a stable non-blank name without persistence.
      return 'Brave Brick';
    }
  }

  /// Set a user-entered name. Blank input falls back to a freshly generated random name so the
  /// field is never empty; anything longer than [_maxLength] is trimmed.
  Future<void> set(String newName) async {
    final trimmed = newName.trim();
    final value = trimmed.isEmpty
        ? NameGenerator.random()
        : (trimmed.length > _maxLength ? trimmed.substring(0, _maxLength) : trimmed);
    state = value;
    try {
      await ref.read(sharedPreferencesProvider).setString(_prefsKey, value);
    } catch (_) {
      // In-memory switch still applies (tests).
    }
  }
}

final displayNameProvider =
    NotifierProvider<DisplayNameController, String>(DisplayNameController.new);
