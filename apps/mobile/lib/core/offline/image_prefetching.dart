import 'dart:async';

import 'brick_image_store.dart';
import 'image_fetch.dart';

/// Downloads image URLs into the durable [BrickImageStore] ahead of need.
///
/// Protocol-first seam (mirrors the Swift `ImagePrefetching`): the real
/// implementation is network-backed ([StoreImagePrefetcher]); tests inject
/// [NoopImagePrefetcher] to stay deterministic and offline. `prefetch` resolves
/// once the batch settles (success or failure) so `OfflineImageService` can
/// re-check completeness afterwards.
abstract interface class ImagePrefetching {
  Future<void> prefetch(List<String> urls);
}

/// No-op prefetcher — the default in tests and any context without a network.
/// Every set stays "incomplete" (nothing cached), the correct behaviour when
/// there's no loader.
class NoopImagePrefetcher implements ImagePrefetching {
  const NoopImagePrefetcher();

  @override
  Future<void> prefetch(List<String> urls) async {}
}

/// Fetches a batch of URLs into the store with **bounded concurrency** (default
/// 6, matching the Swift Nuke prefetcher). Network I/O overlaps across workers;
/// each worker's [BrickImageStore.store] write is serialized by the store's
/// mutex. Already-cached URLs are skipped, and a failed fetch is swallowed so
/// the set simply stays unstamped and is retried by `resumeIncomplete`.
class StoreImagePrefetcher implements ImagePrefetching {
  StoreImagePrefetcher(this._store, {this.concurrency = 6, HttpGet? httpGet})
      : _httpGet = httpGet ?? defaultHttpGet;

  /// The store may still be resolving its directory at construction time
  /// (path_provider is async), so it's a [FutureOr] awaited on first use.
  final FutureOr<BrickImageStore> _store;
  final int concurrency;
  final HttpGet _httpGet;

  @override
  Future<void> prefetch(List<String> urls) async {
    if (urls.isEmpty) return;
    final store = await _store;
    final queue = List<String>.of(urls);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final url = queue.removeLast();
        if (store.contains(url)) continue;
        try {
          final bytes = await _httpGet(url);
          await store.store(bytes, url);
        } catch (_) {
          // Transient (offline / 404) — leave uncached; resumeIncomplete retries.
        }
      }
    }

    final workers = <Future<void>>[
      for (var i = 0; i < concurrency && i < urls.length; i++) worker(),
    ];
    await Future.wait(workers);
  }
}
