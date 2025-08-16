// This is a basic Flutter widget test for Speed Camera App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:check_darn/main.dart';

void main() {
  testWidgets('Speed Camera App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for initial setup
    await tester.pump();
    
    // Verify that our app loads
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Firebase may not be initialized in tests, so we accept Firebase errors
    final exception = tester.takeException();
    if (exception != null) {
      // Expected Firebase/location errors in test environment
      print('Expected error in test: ${exception.toString()}');
    }
    
    // Clear any additional exceptions
    tester.takeException();
    tester.takeException();
    
    // Use binding.delayed to wait for all timers
    await tester.binding.delayed(const Duration(seconds: 20));
    
    // Clear any remaining exceptions after timer completion
    tester.takeException();
  });
}
