import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Phase 2 end-to-end on a real device/simulator: search the live catalog, open
/// a set, "Start sorting" (snapshot into Drift), then confirm it lists on Home.
/// Exercises the two-client catalog path + the Drift snapshot for real.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Pump repeatedly (real async) until [finder] matches or we time out — needed
  // for debounced input and live network fetches that pumpAndSettle can't await.
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

  testWidgets('search → set detail → start sorting → lists on Home', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Home starts empty.
    expect(find.text('No sets yet'), findsOneWidget);

    // Open search.
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    expect(find.text('Search the catalog'), findsOneWidget);

    // Search a small known set by number (3931-1 Emma's Splash Pool, 43 parts).
    await tester.enterText(find.byType(TextField), '3931');
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));

    // Open its detail.
    await tester.tap(find.textContaining("Emma's Splash Pool").first);
    await pumpUntil(tester, find.text('Start sorting'));
    // Set-detail rendered for the chosen set. Assert its identity, not a
    // hardcoded part count — exact counts come from the live catalog and drift.
    expect(find.textContaining("Emma's Splash Pool"), findsWidgets);

    // Start sorting → snapshots into Drift and opens the interactive counting
    // screen, rendered entirely from the LOCAL snapshot.
    await tester.tap(find.text('Start sorting'));
    await pumpUntil(tester, find.text('Remaining only'));
    expect(find.textContaining('of 43 parts'), findsOneWidget);

    // Starting the build collapses the add-set flow (Search + Set-detail) out of
    // the back stack, so a SINGLE back from the counting screen returns to Home.
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // The rebuild now lists on Home with 0% progress (read from local Drift).
    await pumpUntil(tester, find.text('Rebuilds'));
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));
    expect(find.textContaining('0%'), findsWidgets);
  });
}
