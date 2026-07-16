import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';
import 'package:brickback/router/app_router.dart';

/// F2 verification capture: walk the reachable screens on a real iOS build and
/// emit a screenshot at each, in **light** and then a **dark** pass. Run with the
/// paired driver (writes into docs/flutter-migration/baseline/flutter-f2/):
///
///     flutter drive \
///       --driver=test_driver/screenshot_driver.dart \
///       --target=integration_test/screenshot_capture.dart -d `sim`
///
/// Compared side-by-side against the Swift branded oracle in baseline/swift/ and
/// the pre-F2 wireframe in baseline/flutter/.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pump for a fixed span (never pumpAndSettle — perpetual anims/spinners would hang).
  Future<void> settle(WidgetTester tester, [int ms = 900]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for: $finder');
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, 700);
    await binding.takeScreenshot(name);
  }

  testWidgets('capture F2 screenshots', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await settle(tester, 1200);

    // iOS: enable pixel readback for screenshots (once, before the first shot).
    await binding.convertFlutterSurfaceToImage();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BrickBackApp)),
      listen: false,
    );
    final router = container.read(routerProvider);

    // ── LIGHT pass ─────────────────────────────────────────────────────────────
    await shot(tester, 'light-10-home-empty');

    await tester.tap(find.text('Profile'));
    await shot(tester, 'light-20-profile');

    router.go('/design');
    await shot(tester, 'light-80-design-gallery');

    router.go('/paywall');
    await shot(tester, 'light-60-paywall');

    router.go('/sign-in');
    await shot(tester, 'light-61-signin');

    router.go('/party/join');
    await shot(tester, 'light-70-party-join');

    router.go('/');
    await settle(tester);
    await tester.tap(find.text('Add set'));
    await settle(tester);
    await shot(tester, 'light-25-search-empty');

    await tester.enterText(find.byType(TextField), '3931');
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));
    await shot(tester, 'light-30-search-results');

    await tester.tap(find.textContaining("Emma's Splash Pool").first);
    await pumpUntil(tester, find.text('Start sorting'));
    await shot(tester, 'light-31-set-detail');

    await tester.tap(find.text('Start sorting'));
    await pumpUntil(tester, find.text('Remaining only'));
    await shot(tester, 'light-40-counting');

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await pumpUntil(tester, find.text('Mark as verified'));
    await shot(tester, 'light-50-review');

    if (find.text('View report').evaluate().isNotEmpty) {
      await tester.tap(find.text('View report'));
      await settle(tester, 1200);
      await shot(tester, 'light-51-report');
    }

    // ── DARK pass ──────────────────────────────────────────────────────────────
    // Flip the platform brightness; themeMode defaults to system, so the app
    // resolves to the dark ThemeData. The design gallery is the fully dark-aware
    // review surface (primitives + its dark preview island). Other screens still
    // reference the const light token snapshot directly — see F2-results for the
    // documented screen-migration follow-up.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await settle(tester, 600);

    router.go('/design');
    await shot(tester, 'dark-80-design-gallery');

    router.go('/');
    await shot(tester, 'dark-10-home');

    router.go('/paywall');
    await shot(tester, 'dark-60-paywall');

    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
