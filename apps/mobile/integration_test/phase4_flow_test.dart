import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Phase 4 end-to-end on a real simulator: add a set, open the review screen from
/// the counting screen, and record a verification → the report renders. Exercises
/// the whole review/verification path on the real iOS build (share/PDF plugins
/// linked; we stop before invoking the native share sheet).
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

  testWidgets('count → review → mark verified → report', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Add a small known set (3931-1 Emma's Splash Pool, 43 parts).
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3931');
    await pumpUntil(tester, find.textContaining("Emma's Splash Pool"));
    await tester.tap(find.textContaining("Emma's Splash Pool").first);
    await pumpUntil(tester, find.text('Start sorting'));
    await tester.tap(find.text('Start sorting'));
    await pumpUntil(tester, find.text('Remaining only'));

    // Open the review screen from the counting header.
    await tester.tap(find.text('Review'));
    await pumpUntil(tester, find.text('Mark as verified'));
    // The missing-parts view is populated (nothing counted yet → everything short).
    expect(find.text('Missing parts'), findsWidgets);

    // Record a verification: open the flags sheet, tick a flag, save.
    await tester.tap(find.text('Mark as verified'));
    await pumpUntil(tester, find.text('Save verification'));
    await tester.tap(find.text('Box included'));
    await tester.pump();
    await tester.tap(find.text('Save verification'));

    // The report / certificate renders (we do NOT tap Share — it opens a native
    // sheet the test can't dismiss).
    await pumpUntil(tester, find.text('INVENTORY VERIFICATION'));
    expect(find.text('Verified with BrickBack'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
  });
}
