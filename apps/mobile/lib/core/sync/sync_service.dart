import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/database_provider.dart';
import '../entitlement.dart';
import '../supabase.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/rebuild/rebuild_repository.dart';
import 'sync_remote.dart';

/// Local ⇄ cloud sync engine — **premium only** (Phase 5).
///
/// Strategy (lifted from whatabrick, the sanctioned v1): push every `dirty` local
/// row up (upsert keyed on the shared id, so the cloud owns identity), then pull
/// the full cloud state down and apply it — cloud is authoritative after the
/// push, giving convergence with no duplicates. Pulls **skip locally-dirty rows**
/// so an edit made mid-sync is never clobbered (it re-pushes next round). The
/// cloud payload is catalog-independent: only ids + `have_qty` sync, and part /
/// minifig metadata is re-derived from the catalog on pull
/// ([RebuildRepository.importFromCloud]).
///
/// Only runs for signed-in premium users; free/guest users never touch the
/// network for user data. See docs/phases/05-auth-and-cloud-sync.md.
class SyncService {
  SyncService(this._db, this._rebuild, this._remote);
  final AppDatabase _db;
  final RebuildRepository _rebuild;
  final SyncRemote _remote;

  bool get signedIn => _remote.uid != null;

  String _ts(DateTime t) => t.toUtc().toIso8601String();

  // ── Push ────────────────────────────────────────────────────────────────

  /// Upsert all dirty local rows. Parents (sets) before children (parts /
  /// minifigs / verifications) so FKs resolve. Cheap; safe to call after writes.
  Future<void> pushDirty() async {
    final uid = _remote.uid;
    if (uid == null) return;
    await _pushSets(uid);
    await _pushParts();
    await _pushMinifigs();
    await _pushVerifications(uid);
  }

  Future<void> _pushSets(String uid) async {
    final dirty =
        await (_db.select(_db.rebuildSets)..where((t) => t.dirty.equals(true))).get();
    if (dirty.isEmpty) return;
    await _remote.upsertSets([
      for (final r in dirty)
        {
          'id': r.id,
          'user_id': uid,
          'set_item_id': r.setItemId,
          'total_parts': r.totalParts,
          'verified_at': r.verifiedAt == null ? null : _ts(r.verifiedAt!),
          'updated_at': _ts(r.updatedAt),
          'deleted': r.deleted,
        },
    ]);
    await _db.batch((b) {
      for (final r in dirty) {
        b.update(
          _db.rebuildSets,
          const RebuildSetsCompanion(dirty: Value(false)),
          where: (t) => t.id.equals(r.id) & t.updatedAt.equals(r.updatedAt),
        );
      }
    });
  }

  Future<void> _pushParts() async {
    final dirty =
        await (_db.select(_db.rebuildParts)..where((t) => t.dirty.equals(true))).get();
    if (dirty.isEmpty) return;
    await _remote.upsertParts([
      for (final p in dirty)
        {
          'rebuild_set_id': p.rebuildSetId,
          'part_item_id': p.partItemId,
          'color_id': p.colorId,
          'have_qty': p.haveQty,
          'updated_at': _ts(p.updatedAt),
          'deleted': p.deleted,
        },
    ]);
    await _db.batch((b) {
      for (final p in dirty) {
        b.update(
          _db.rebuildParts,
          const RebuildPartsCompanion(dirty: Value(false)),
          where: (t) =>
              t.rebuildSetId.equals(p.rebuildSetId) &
              t.partItemId.equals(p.partItemId) &
              t.colorId.equals(p.colorId) &
              t.updatedAt.equals(p.updatedAt),
        );
      }
    });
  }

  Future<void> _pushMinifigs() async {
    final dirty =
        await (_db.select(_db.rebuildMinifigs)..where((t) => t.dirty.equals(true))).get();
    if (dirty.isEmpty) return;
    await _remote.upsertMinifigs([
      for (final m in dirty)
        {
          'rebuild_set_id': m.rebuildSetId,
          'minifig_item_id': m.minifigItemId,
          'have_qty': m.haveQty,
          'updated_at': _ts(m.updatedAt),
          'deleted': m.deleted,
        },
    ]);
    await _db.batch((b) {
      for (final m in dirty) {
        b.update(
          _db.rebuildMinifigs,
          const RebuildMinifigsCompanion(dirty: Value(false)),
          where: (t) =>
              t.rebuildSetId.equals(m.rebuildSetId) &
              t.minifigItemId.equals(m.minifigItemId) &
              t.updatedAt.equals(m.updatedAt),
        );
      }
    });
  }

  Future<void> _pushVerifications(String uid) async {
    final dirty =
        await (_db.select(_db.verifications)..where((t) => t.dirty.equals(true))).get();
    if (dirty.isEmpty) return;
    await _remote.upsertVerifications([
      for (final v in dirty)
        {
          'id': v.id,
          'user_id': uid,
          'rebuild_set_id': v.rebuildSetId,
          'set_item_id': v.setItemId,
          'completion_pct': v.completionPct,
          'parts_needed': v.partsNeeded,
          'parts_found': v.partsFound,
          'minifigs_needed': v.minifigsNeeded,
          'minifigs_found': v.minifigsFound,
          'flags': jsonDecode(v.flags),
          'notes': v.notes,
          'verified_at': _ts(v.verifiedAt),
          'updated_at': _ts(v.updatedAt),
          'deleted': v.deleted,
        },
    ]);
    await _db.batch((b) {
      for (final v in dirty) {
        b.update(
          _db.verifications,
          const VerificationsCompanion(dirty: Value(false)),
          where: (t) => t.id.equals(v.id) & t.updatedAt.equals(v.updatedAt),
        );
      }
    });
  }

  // ── Pull ────────────────────────────────────────────────────────────────

  /// Push dirty, then pull the full cloud state and apply it (cloud authoritative
  /// post-push). Re-derives catalog metadata for sets new to this device.
  Future<void> fullSync() async {
    final uid = _remote.uid;
    if (uid == null) return;
    await pushDirty();
    await _pullSets();
    await _pullParts();
    await _pullMinifigs();
    await _pullVerifications();
  }

  Future<void> _pullSets() async {
    final cloud = await _remote.fetchSets();
    for (final s in cloud) {
      final id = s['id'] as String;
      final setItemId = (s['set_item_id'] as num).toInt();
      final totalParts = (s['total_parts'] as num?)?.toInt() ?? 0;
      final deleted = (s['deleted'] as bool?) ?? false;
      final updatedAt = DateTime.parse(s['updated_at'] as String).toLocal();
      final verifiedAt =
          s['verified_at'] == null ? null : DateTime.parse(s['verified_at'] as String).toLocal();

      final local =
          await (_db.select(_db.rebuildSets)..where((t) => t.id.equals(id))).getSingleOrNull();

      if (local == null) {
        if (deleted) continue; // tombstone for a set we never had — nothing to do
        await _rebuild.importFromCloud(id, setItemId, totalParts);
      } else if (local.dirty) {
        continue; // unpushed local edit — don't clobber; it re-pushes next round
      }
      await (_db.update(_db.rebuildSets)..where((t) => t.id.equals(id))).write(
        RebuildSetsCompanion(
          totalParts: Value(totalParts),
          verifiedAt: Value(verifiedAt),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          dirty: const Value(false),
        ),
      );
    }
  }

  Future<void> _pullParts() async {
    final setIds = await _localSetIds();
    if (setIds.isEmpty) return;
    final cloud = await _remote.fetchParts(setIds);
    await _db.batch((b) {
      for (final p in cloud) {
        b.update(
          _db.rebuildParts,
          RebuildPartsCompanion(
            haveQty: Value((p['have_qty'] as num).toInt()),
            deleted: Value((p['deleted'] as bool?) ?? false),
            dirty: const Value(false),
          ),
          where: (t) =>
              t.rebuildSetId.equals(p['rebuild_set_id'] as String) &
              t.partItemId.equals((p['part_item_id'] as num).toInt()) &
              t.colorId.equals((p['color_id'] as num).toInt()) &
              t.dirty.equals(false),
        );
      }
    });
  }

  Future<void> _pullMinifigs() async {
    final setIds = await _localSetIds();
    if (setIds.isEmpty) return;
    final cloud = await _remote.fetchMinifigs(setIds);
    await _db.batch((b) {
      for (final m in cloud) {
        b.update(
          _db.rebuildMinifigs,
          RebuildMinifigsCompanion(
            haveQty: Value((m['have_qty'] as num).toInt()),
            deleted: Value((m['deleted'] as bool?) ?? false),
            dirty: const Value(false),
          ),
          where: (t) =>
              t.rebuildSetId.equals(m['rebuild_set_id'] as String) &
              t.minifigItemId.equals((m['minifig_item_id'] as num).toInt()) &
              t.dirty.equals(false),
        );
      }
    });
  }

  Future<void> _pullVerifications() async {
    final cloud = await _remote.fetchVerifications();
    for (final v in cloud) {
      final id = v['id'] as String;
      final local =
          await (_db.select(_db.verifications)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local != null && local.dirty) continue; // unpushed local edit wins
      await _db.into(_db.verifications).insert(
            VerificationsCompanion.insert(
              id: id,
              rebuildSetId: v['rebuild_set_id'] as String,
              setItemId: (v['set_item_id'] as num).toInt(),
              completionPct: Value((v['completion_pct'] as num?)?.toDouble() ?? 0),
              partsNeeded: Value((v['parts_needed'] as num?)?.toInt()),
              partsFound: Value((v['parts_found'] as num?)?.toInt()),
              minifigsNeeded: Value((v['minifigs_needed'] as num?)?.toInt()),
              minifigsFound: Value((v['minifigs_found'] as num?)?.toInt()),
              flags: Value(jsonEncode(v['flags'] ?? const <String, dynamic>{})),
              notes: Value(v['notes'] as String?),
              verifiedAt: Value(DateTime.parse(v['verified_at'] as String).toLocal()),
              updatedAt: Value(DateTime.parse(v['updated_at'] as String).toLocal()),
              deleted: Value((v['deleted'] as bool?) ?? false),
              dirty: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  Future<List<String>> _localSetIds() async {
    final rows = await _db.select(_db.rebuildSets).get();
    return [for (final r in rows) r.id];
  }

  // ── First-premium migration ───────────────────────────────────────────────

  /// Mark every local row dirty so the next push uploads all existing work. Used
  /// once when a free user first turns on premium sync.
  Future<void> markAllDirty() async {
    await _db.update(_db.rebuildSets).write(const RebuildSetsCompanion(dirty: Value(true)));
    await _db.update(_db.rebuildParts).write(const RebuildPartsCompanion(dirty: Value(true)));
    await _db.update(_db.rebuildMinifigs).write(const RebuildMinifigsCompanion(dirty: Value(true)));
    await _db.update(_db.verifications).write(const VerificationsCompanion(dirty: Value(true)));
  }
}

/// Drives the sync engine from app lifecycle + local edits, gated on
/// `signedIn && isPremium`. The live wiring (30s safety timer, auth-change
/// listener) lives in [syncControllerProvider], not the constructor, so tests
/// can subclass this without pulling in Supabase.
class SyncController {
  SyncController(this._ref, {SyncService? service, bool Function()? isSignedIn})
      : _service = service,
        _isSignedIn = isSignedIn;
  final Ref _ref;
  Timer? _debounce;
  Timer? _periodic;
  bool _running = false;
  bool _pendingEnable = false;
  SyncService? _service;

  // Test seam (the class is intentionally driveable without Supabase): overrides
  // the live session check so the gating + trigger logic can be exercised without
  // an authenticated client.
  final bool Function()? _isSignedIn;

  bool get _signedIn => (_isSignedIn ?? _defaultSignedIn)();
  // A transparent guest (anonymous) session does NOT count as signed in — only a real account
  // unlocks cloud sync.
  static bool _defaultSignedIn() {
    final user = userClient.auth.currentUser;
    return user != null && user.isAnonymous != true;
  }
  bool get _enabled => _signedIn && _ref.read(isPremiumProvider);

  SyncService _sync() => _service ??= SyncService(
        _ref.read(databaseProvider),
        _ref.read(rebuildRepositoryProvider),
        SupabaseSyncRemote(userClient),
      );

  /// Called by the provider on auth changes. Refreshes entitlement, then (if
  /// premium) runs a full sync — uploading all local work the first time the user
  /// enables sync.
  Future<void> onAuthChanged() async {
    if (!_signedIn) return;
    await _ref.read(entitlementControllerProvider.notifier).refresh();
    if (!_ref.read(isPremiumProvider)) return;
    if (_pendingEnable) {
      _pendingEnable = false;
      await _guard(() => _sync().markAllDirty());
    }
    await syncNow();
  }

  /// Premium just turned ON (a purchase completing, or the debug unlock) while
  /// the user is ALREADY signed in. [onAuthChanged] only fires on auth changes,
  /// so without reacting to the entitlement flip here the first pull would wait
  /// for an app resume or a manual "Sync now". Uploads existing local work on a
  /// first enable, then pulls cloud state — so a returning user's sets appear on
  /// their own. No-op until signed-in + premium (idempotent; the `syncNow` guard
  /// coalesces with any concurrent auth-change sync).
  Future<void> onPremiumEnabled() async {
    if (!_enabled) return;
    if (_pendingEnable) {
      _pendingEnable = false;
      await _guard(() => _sync().markAllDirty());
    }
    await syncNow();
  }

  /// Mark the next sign-in as a "turn on sync" so existing local work uploads.
  void requestEnableSync() => _pendingEnable = true;

  /// Request a debounced push after a local edit.
  void nudge() {
    if (!_enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), pushNow);
  }

  /// Flush dirty rows to the cloud (push only). Used on pause + the safety timer.
  Future<void> pushNow() async {
    if (!_enabled || _running) return;
    _running = true;
    try {
      await _sync().pushDirty();
    } catch (e) {
      if (kDebugMode) debugPrint('sync push failed: $e');
    } finally {
      _running = false;
    }
  }

  /// Full push + pull + apply, then refresh anything reading local user tables.
  Future<void> syncNow() async {
    if (!_enabled || _running) return;
    _running = true;
    try {
      await _sync().fullSync();
      _ref.invalidate(rebuildListProvider);
    } catch (e) {
      if (kDebugMode) debugPrint('sync failed: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (kDebugMode) debugPrint('sync op failed: $e');
    }
  }

  void startPeriodic() {
    _periodic ??= Timer.periodic(const Duration(seconds: 30), (_) => pushNow());
  }

  void dispose() {
    _debounce?.cancel();
    _periodic?.cancel();
  }
}

final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  controller.startPeriodic();
  // Re-sync whenever auth flips (sign-in uploads local work; token refresh is a
  // cheap no-op when already synced).
  ref.listen(authStateProvider, (_, _) => controller.onAuthChanged());
  // Premium turning ON is itself a sync trigger. Enabling sync while already
  // signed in (a purchase completing, or the debug unlock) changes no auth
  // state, so without this the first pull would wait for a manual "Sync now" or
  // an app resume.
  ref.listen(isPremiumProvider, (prev, next) {
    if (next && prev != true) controller.onPremiumEnabled();
  });
  ref.onDispose(controller.dispose);
  return controller;
});
