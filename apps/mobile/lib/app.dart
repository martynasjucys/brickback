import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/locale.dart';
import 'core/sync/sync_service.dart';
import 'l10n/l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Root widget. Owns the app lifecycle hooks that flush/resume sync (no-ops until
/// premium sync is enabled in Phase 5).
class BrickBackApp extends ConsumerStatefulWidget {
  const BrickBackApp({super.key});
  @override
  ConsumerState<BrickBackApp> createState() => _BrickBackAppState();
}

class _BrickBackAppState extends ConsumerState<BrickBackApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Instantiate the sync controller at startup so its auth + premium listeners
    // are live from launch — otherwise they only wire up on the first lifecycle
    // callback and could miss the initial session restore or an early premium
    // flip.
    ref.read(syncControllerProvider);
  }

  @override
  void dispose() {
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
