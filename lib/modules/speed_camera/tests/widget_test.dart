// Speed Camera App Widget Tests
// Testing core widgets and utilities for the speed camera module

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/rolling_buffer.dart';

void main() {
  testWidgets('RollingBuffer Widget Integration Test',
      (WidgetTester tester) async {
    // Test that RollingBuffer can be used in widget context
    final buffer = RollingBuffer<String>(3);

    // Build a simple widget that uses RollingBuffer
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            buffer.push('Test Item 1');
            buffer.push('Test Item 2');

            return Column(
              children: [
                Text('Buffer Length: ${buffer.length}'),
                Text('Buffer Empty: ${buffer.isEmpty}'),
                Text('Buffer Full: ${buffer.isFull}'),
                if (buffer.isNotEmpty)
                  Text('First Item: ${buffer.firstOrNull}'),
                if (buffer.isNotEmpty) Text('Last Item: ${buffer.lastOrNull}'),
              ],
            );
          },
        ),
      ),
    ));

    // Verify that buffer information is displayed correctly
    expect(find.text('Buffer Length: 2'), findsOneWidget);
    expect(find.text('Buffer Empty: false'), findsOneWidget);
    expect(find.text('Buffer Full: false'), findsOneWidget);
    expect(find.text('First Item: Test Item 1'), findsOneWidget);
    expect(find.text('Last Item: Test Item 2'), findsOneWidget);
  });
}
