import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Premium entitlement — the source of truth for [isPremiumProvider], which gates
/// cloud sync + unlimited projects (Phase 5).
///
/// Backed by `profiles.is_premium` on the user project. That flag is set
/// server-side by a billing webhook / service role (RevenueCat is the intended
/// billing integration; deferred as its own sub-track). The app only READS its
/// own row. Everything stays fully usable when this is false — premium only adds
/// cross-device sync and lifts the free project cap.
class EntitlementService {
  EntitlementService(this._client);
  final SupabaseClient _client;

  /// Read the signed-in user's premium flag. Returns false when signed out or on
  /// any transient error — the app is local-first, so "unknown" degrades to free.
  Future<bool> fetchIsPremium() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _client
          .from('profiles')
          .select('is_premium')
          .eq('id', uid)
          .maybeSingle();
      return (row?['is_premium'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Free tier keeps up to this many concurrent rebuilds on-device; beyond it, the
/// add-a-set flow shows the paywall instead of creating another (D7 default).
const kFreeRebuildCap = 3;

final entitlementServiceProvider =
    Provider<EntitlementService>((ref) => EntitlementService(userClient));

/// Debug-only override so premium gating + sync can be exercised end-to-end
/// without a live billing integration. Toggled from the paywall in debug builds.
class DebugForcePremium extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final debugForcePremiumProvider =
    NotifierProvider<DebugForcePremium, bool>(DebugForcePremium.new);

/// Holds the last-fetched premium flag. Built lazily to `false` (no eager
/// network); [refresh] is called from the sync controller whenever auth changes.
class EntitlementController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> refresh() async {
    state = await ref.read(entitlementServiceProvider).fetchIsPremium();
  }
}

final entitlementControllerProvider =
    NotifierProvider<EntitlementController, bool>(EntitlementController.new);

/// Whether premium is unlocked. A synchronous `bool` (read by the sync gate and
/// the free-cap check): the real flag comes from [entitlementControllerProvider],
/// with the debug override forcing it on for testing.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(debugForcePremiumProvider) || ref.watch(entitlementControllerProvider),
);
