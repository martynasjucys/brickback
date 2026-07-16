import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/locale.dart';
import 'core/offline/offline_images.dart';
import 'core/sync/sync_service.dart';
import 'l10n/l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Root widget. Owns the app lifecycle hooks that flush/resume sync (no-ops until
/// premium sync is enabled in Phase 5) and the F4 offline-image wiring: launch
/// resume/GC and the connectivity-reconnect triggers.
class BrickBackApp extends ConsumerStatefulWidget {
  const BrickBackApp({super.key});
  @override
  ConsumerState<BrickBackApp> createState() => _BrickBackAppState();
}

class _BrickBackAppState extends ConsumerState<BrickBackApp> with WidgetsBindingObserver {
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Instantiate the sync controller at startup so its auth + premium listeners
    // are live from launch — otherwise they only wire up on the first lifecycle
    // callback and could miss the initial session restore or an early premium
    // flip.
    ref.read(syncControllerProvider);
    // F4: open the durable image store, then run launch-time housekeeping and
    // start listening for reconnects.
    _startOfflineImages();
  }

  /// Resolve the image store, finish caching any set left incomplete, prune
  /// unpinned files, and subscribe to connectivity transitions. On a `→ online`
  /// edge: promptly flush queued progress (`syncNow`) and resume interrupted
  /// prefetch (`resumeIncomplete`). Image caching/GC are NOT premium-gated —
  /// only the cloud progress sync inside `syncNow` is.
  Future<void> _startOfflineImages() async {
    await OfflineImages.init();
    final offline = ref.read(offlineImageServiceProvider);
    // Launch triggers (fire-and-forget; each is internally failure-tolerant).
    unawaited(offline.resumeIncomplete());
    unawaited(offline.gc());
    _connSub = ref.read(networkMonitorProvider).onlineTransitions().listen((online) {
      if (!online) return;
      ref.read(syncControllerProvider).syncNow();
      unawaited(offline.resumeIncomplete());
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sync = ref.read(syncControllerProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      sync.pushNow();
    } else if (state == AppLifecycleState.resumed) {
      sync.syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'BrickBack',
      debugShowCheckedModeBanner: false,
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ref.watch(themeControllerProvider),
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
