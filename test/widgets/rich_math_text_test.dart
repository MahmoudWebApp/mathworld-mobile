import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/rich_math_text.dart';

void main() {
  testWidgets('renders mixed text without displaying dollar delimiters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RichMathText(text: r'Find $f(4)$ when $f(x)=2x+3$.'),
        ),
      ),
    );

    expect(find.textContaining(r'$f(4)$'), findsNothing);
    expect(find.byType(RichMathText), findsOneWidget);
  });
}
