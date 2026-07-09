import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Phase 5 end-to-end on a real simulator: the auth + premium surfaces render on
/// the real iOS build. Profile (signed out) → paywall → sign-in (three
/// providers). Does not complete an OAuth round-trip (that needs Supabase
/// dashboard provider config); it verifies the screens build and route.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for: $finder');
  }

  Future<void> hold(WidgetTester tester, {int seconds = 8}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('profile → paywall → sign-in render on device', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Profile tab: signed-out state.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Local-first · not signed in'), findsOneWidget);

    // Turn on Cloud Sync → paywall.
    await tester.tap(find.text('Turn on Cloud Sync'));
    await pumpUntil(tester, find.text('BrickBack Premium'));
    expect(find.text('Sync across devices'), findsOneWidget);
    expect(find.text('Unlimited projects'), findsOneWidget);

    // Paywall CTA → sign-in (three providers). The profile button underneath
    // shares the label; the paywall was pushed last, so target the last match.
    await tester.tap(find.text('Turn on Cloud Sync').last);
    await pumpUntil(tester, find.text('Continue with Google'));
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Email me a sign-in link'), findsOneWidget);

    await hold(tester); // hold on sign-in for an external screenshot
  });
}
