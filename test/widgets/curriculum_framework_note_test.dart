import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/curriculum_framework_note.dart';

void main() {
  testWidgets('Arabic methodology avoids fixed quotas and false accreditation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      home: Scaffold(body: SingleChildScrollView(
        child: CurriculumFrameworkNote(),
      )),
    ));
    expect(find.textContaining('كيف ننظّم'), findsOneWidget);
    expect(find.textContaining('بدون عدد ثابت'), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cambridge'), findsWidgets);
    expect(find.textContaining('شراكة رسمية'), findsOneWidget);
  });

  testWidgets('English methodology disclaims endorsement',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      home: Scaffold(body: SingleChildScrollView(
        child: CurriculumFrameworkNote(),
      )),
    ));
    expect(find.textContaining('How do we organize'), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('official endorsement'), findsOneWidget);
  });
}
