import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Set-detail lists on a real simulator: the "Unique parts" and "Minifigs" stat
/// blocks open their respective catalog lists; total parts shows as plain text.
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

  testWidgets('set detail → unique parts list + minifigs list', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Reach the set detail for 3931 (Emma's Splash Pool, 43 parts).
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3931');
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));
    await tester.tap(find.textContaining("Emma's Splash Pool").first);
    await pumpUntil(tester, find.text('Start sorting'));

    // The two stat blocks + total-parts-as-text.
    expect(find.text('Unique parts'), findsOneWidget);
    expect(find.text('Minifigs'), findsOneWidget);
    expect(find.text('43 parts'), findsOneWidget);
    await hold(tester); // screenshot: set detail

    // Unique parts block → the unique-parts list (count caption is unique to it).
    await tester.tap(find.text('Unique parts'));
    await pumpUntil(tester, find.textContaining('unique parts'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await hold(tester); // screenshot: parts list

    // Back to the set detail.
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
    await pumpUntil(tester, find.text('Start sorting'));

    // Minifigs block → the minifig list (resolves to rows or an empty state).
    await tester.tap(find.text('Minifigs'));
    await pumpUntil(tester, find.byType(Scaffold));
    // Wait until the minifig fetch settles (spinner gone).
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(end) &&
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await hold(tester); // screenshot: minifig list
  });
}
