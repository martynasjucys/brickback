import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Live on-device check for the counting screen's view-settings feature. Also
/// exercises the real Drift v1 -> v2 migration (the on-device DB opens through
/// `onUpgrade` at boot) and the live catalog spares query. Adds a set, opens the
/// counting screen, and drives the settings sheet (group-by + show extras).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> hold(WidgetTester tester, {int seconds = 6}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('counting screen settings sheet: group-by + show extras', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    // Booting opens the Drift DB -> runs the v1->v2 migration if an old DB exists.
    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Add a set -> counting screen (may already have rebuilds from a prior run;
    // either the empty-state "Add a set" or the header "Add set" is present).
    final addBtn = find.text('Add set');
    await tester.tap(addBtn.first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3931');
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));
    await tester.tap(find.textContaining("Emma's Splash Pool").first);
    await pumpUntil(tester, find.text('Start sorting'));
    await tester.tap(find.text('Start sorting'));
    await pumpUntil(tester, find.text('Remaining only'));

    // Open the new settings/filter sheet (the 4th header button).
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await pumpUntil(tester, find.text('View settings'));
    expect(find.text('Group by'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('Show extra parts'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Switch grouping to Type and flip the extras switch — no crash, live update.
    await tester.tap(find.text('Type'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 300));

    await hold(tester); // hold on the settings sheet for a screenshot
  });
}
