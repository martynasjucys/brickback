import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'brick_image_store.dart';

/// Fetches the bytes for an image [url]. Injected in tests (an unreachable URL /
/// a throwing stub) so the disk-first path can be proven without a network.
typedef HttpGet = Future<Uint8List> Function(String url);

final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);

/// Default network fetch (pure `dart:io`, no Flutter binding). Reuses one
/// [HttpClient]. Throws on non-200 so callers can fall back / leave uncached.
Future<Uint8List> defaultHttpGet(String url) async {
  final uri = Uri.parse(url);
  final req = await _client.getUrl(uri);
  final resp = await req.close();
  if (resp.statusCode != 200) {
    throw HttpException('HTTP ${resp.statusCode}', uri: uri);
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in resp) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

/// Disk-first byte resolution — the **single** source of truth shared by the
/// image provider and the prefetcher. Returns cached bytes if the store already
/// has them (no network); otherwise fetches, write-throughs into the store, and
/// returns. Centralizing this keeps the cache key aligned: everything hashes the
/// same URL via [BrickImageStore.hash].
Future<Uint8List> resolveImageBytes(
  String url, {
  required BrickImageStore? store,
  HttpGet? httpGet,
}) async {
  final cached = store?.data(url);
  if (cached != null) return cached;
  final bytes = await (httpGet ?? defaultHttpGet)(url);
  if (store != null) {
    // Fire-and-forget the write; the bytes are already in hand to return.
    unawaited(store.store(bytes, url));
  }
  return bytes;
}
