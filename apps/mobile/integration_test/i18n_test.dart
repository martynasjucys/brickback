import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:brickback/app.dart';
import 'package:brickback/core/env.dart';
import 'package:brickback/core/supabase.dart';

/// Localization end-to-end on a real simulator: switch the app language to
/// Lithuanian from Profile and confirm the UI re-renders in Lithuanian, then
/// switch back to English.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> hold(WidgetTester tester, {int seconds = 6}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('switch language to Lithuanian and back', (tester) async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(url: Env.userSupabaseUrl, publishableKey: Env.userSupabaseAnonKey);
    initCatalogClient();

    await tester.pumpWidget(const ProviderScope(child: BrickBackApp()));
    await tester.pumpAndSettle();

    // Starts in English.
    expect(find.text('Rebuilds'), findsWidgets);

    // Profile tab → language switcher.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    // Switch to Lithuanian.
    await tester.tap(find.text('Lietuvių'));
    await tester.pumpAndSettle();

    // The whole UI is now Lithuanian (header + nav tab both read "Profilis").
    expect(find.text('Profilis'), findsWidgets);
    expect(find.text('Kalba'), findsOneWidget); // language card
    expect(find.text('Surinkimai'), findsWidgets); // bottom-nav tab
    await hold(tester); // screenshot: Lithuanian profile

    // Switch back to English.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
  });
}
