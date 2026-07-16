import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'brick_image_store.dart';
import 'image_fetch.dart';
import 'offline_images.dart';

/// A disk-first [ImageProvider] backed by [BrickImageStore] — the single source
/// of truth for image bytes, mirroring the Swift Nuke `DataCaching` adapter.
///
/// Resolution order (see [resolveImageBytes]): the store, then the network
/// (writing through into the store). Once bytes are on disk the widget renders
/// offline with no per-call change. The provider carries **no processors** and
/// keys purely on the URL string, so the effective cache key equals the URL that
/// GC pins against — no key divergence (the F4 "cache-key alignment" risk).
///
/// Equality is by URL + scale only (never the store / fetch overrides) so
/// Flutter's [ImageCache] dedupes identical loads across widgets.
@immutable
class BrickImageProvider extends ImageProvider<BrickImageProvider> {
  const BrickImageProvider(this.url, {this.scale = 1.0, this.store, this.httpGet});

  final String url;
  final double scale;

  /// Test / call-site override. In production this is null and the provider
  /// reads the app-wide store via [OfflineImages.storeOrNull] (synchronous — no
  /// hang if the store is still initializing; it just falls back to network for
  /// that one early load).
  final BrickImageStore? store;

  /// Test seam: an alternate fetch (e.g. one that throws to prove the disk path
  /// never touches the network).
  final HttpGet? httpGet;

  @override
  Future<BrickImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<BrickImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
      BrickImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () =>
          <DiagnosticsNode>[ErrorDescription('Image URL: ${key.url}')],
    );
  }

  Future<ui.Codec> _loadCodec(
      BrickImageProvider key, ImageDecoderCallback decode) async {
    final bytes = await resolveImageBytes(
      key.url,
      store: key.store ?? OfflineImages.storeOrNull,
      httpGet: key.httpGet,
    );
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is BrickImageProvider && other.url == url && other.scale == scale;

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => 'BrickImageProvider("$url", scale: $scale)';
}
