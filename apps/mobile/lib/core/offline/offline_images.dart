import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../db/database_provider.dart';
import 'brick_image_store.dart';
import 'image_prefetching.dart';
import 'network_monitor.dart';
import 'offline_image_service.dart';

/// App-wide holder for the durable image store — the Flutter analogue of Swift's
/// `ImagePipeline.shared`. The store's directory is resolved asynchronously
/// (path_provider), so callers that need it before [init] completes await
/// [store]; the synchronous [storeOrNull] lets the image provider fall back to
/// the network for the (sub-second) window before init resolves, with no hang.
///
/// Kept SDK-injectable: nothing here is required for the pure [BrickImageStore]
/// unit tests, which construct the store directly over a temp directory.
class OfflineImages {
  OfflineImages._();

  static final Completer<BrickImageStore> _completer =
      Completer<BrickImageStore>();
  static BrickImageStore? _store;
  static bool _initStarted = false;

  /// Resolves once the store directory is ready.
  static Future<BrickImageStore> get store => _completer.future;

  /// The store if already initialized, else null (never blocks).
  static BrickImageStore? get storeOrNull => _store;

  /// Resolve `<app support>/Images/` and open the store. Idempotent. Call once
  /// at launch (from `app.dart`), before the launch-time resume/gc.
  static Future<BrickImageStore> init() async {
    if (_initStarted) return _completer.future;
    _initStarted = true;
    final base = await getApplicationSupportDirectory();
    final s = BrickImageStore(
        Directory('${base.path}${Platform.pathSeparator}Images'));
    _store = s;
    _completer.complete(s);
    return s;
  }
}

/// The app-wide durable image store (as a [FutureOr]; awaited by consumers).
final brickImageStoreProvider =
    Provider<FutureOr<BrickImageStore>>((ref) => OfflineImages.store);

/// The production prefetcher, bounded to ~6 concurrent fetches, writing straight
/// into the store. Overridden with a [NoopImagePrefetcher] in tests.
final imagePrefetcherProvider =
    Provider<ImagePrefetching>((ref) => StoreImagePrefetcher(OfflineImages.store));

/// Orchestrates prefetch / resume / GC over the store + the local DB.
final offlineImageServiceProvider = Provider<OfflineImageService>(
  (ref) => OfflineImageService(
    ref.read(databaseProvider),
    OfflineImages.store,
    ref.read(imagePrefetcherProvider),
  ),
);

/// Connectivity transitions (online/offline edges) for the reconnect triggers.
final networkMonitorProvider =
    Provider<NetworkMonitor>((ref) => const NetworkMonitor());
