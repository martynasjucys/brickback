import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Phase 6 on a real simulator: the party surfaces build & render on the real iOS
/// binary (proving qr_flutter and the new party screens link and lay out). It
/// does NOT complete a live realtime round-trip — creating/joining a party needs
/// a real auth session (Supabase dashboard OAuth/SMTP config), the same external
/// gap as Phase 5. Here we verify: the Profile party entry gates correctly (guest
/// → paywall) and the join screen renders on the device.
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

  Future<void> hold(WidgetTester tester, {int seconds = 6}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('profile party entry + join screen render on device', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Profile tab shows the Party mode card + Join entry.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Party mode'), findsOneWidget);
    expect(find.text('Join a party'), findsOneWidget);

    // A guest tapping Join a party bounces to the paywall (premium + account gate).
    await tester.tap(find.text('Join a party'));
    await pumpUntil(tester, find.text('Sync across devices'));

    // Navigate straight to the (unguarded) join screen to prove the party UI
    // renders on the real build — qr_flutter is linked because the invite screen
    // is compiled into the router even if we don't open it here.
    final ctx = tester.element(find.text('Sync across devices'));
    GoRouter.of(ctx).push('/party/join');
    await pumpUntil(tester, find.text('Enter the code the host shared with you.'));
    expect(find.byType(TextField), findsOneWidget); // the code input
    expect(find.text('Join'), findsWidgets); // the CTA

    await hold(tester); // hold for an external screenshot
  });
}
