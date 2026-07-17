import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic application shell renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('MathWorld')),
      ),
    );

    expect(find.text('MathWorld'), findsOneWidget);
  });
}
