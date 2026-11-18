import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/brand_logo.dart';

void main() {
  testWidgets('MathWorld lockup stays in Latin order in Arabic RTL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(child: BrandLogo(width: 190, height: 48)),
          ),
        ),
      ),
    );

    expect(find.text('MathWorld'), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
    final mark = tester.getRect(find.byType(BrandMark));
    final title = tester.getRect(find.text('MathWorld'));
    expect(mark.left, lessThan(title.left),
        reason: 'Cap/sigma mark must precede Latin text in RTL locales');
    expect(tester.takeException(), isNull);
  });

  testWidgets('MathWorld mark keeps its complete original geometry', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BrandMark(size: 64))),
    ));
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(image.width, 64);
    expect(image.height, 64);
    expect(tester.takeException(), isNull);
  });
}
