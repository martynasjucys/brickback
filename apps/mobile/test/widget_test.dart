// Wireframe primitive smoke test. The full app boot needs the .env asset +
// Supabase init, so we test a self-contained widget instead.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brickback/widgets/primitives.dart';

void main() {
  testWidgets('AppButton renders its label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton('Start sorting', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Start sorting'), findsOneWidget);
  });
}
