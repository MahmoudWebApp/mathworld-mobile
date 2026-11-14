import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/glass_card.dart';

void main() {
  testWidgets('Interactive MathWorld card exposes tap with visible Ink',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassCard(
              onTap: () => taps++,
              child: const Text('Open math category'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Ink), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('Open math category'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Read-only card never introduces a false tap target',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GlassCard(child: Text('Your achievement')),
      ),
    ));
    expect(find.text('Your achievement'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
