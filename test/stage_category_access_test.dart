import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/features/category_access/stage_category_access.dart';

void main() {
  final catalog = StageCategoryAccess.fromJson({
    'stageId': 1,
    'freeCategoryIds': [2, 3],
    'categories': [
      {'id': 2, 'nameAr': 'الجمع', 'nameEn': 'Addition', 'icon': '➕', 'isFree': true},
      {'id': 4, 'nameAr': 'الضرب', 'nameEn': 'Multiplication', 'icon': '✖️', 'isFree': false},
    ],
  });

  test('Free and Premium access follow server-provided category flags', () {
    expect(catalog.stageId, 1);
    expect(catalog.categories.first.canOpen(isPremium: false), isTrue);
    expect(catalog.categories.last.canOpen(isPremium: false), isFalse);
    expect(catalog.categories.last.canOpen(isPremium: true), isTrue);
  });

  testWidgets('Free category chooser locks paid categories and supports RTL', (tester) async {
    final opened = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StageCategoryAccessGrid(
          catalog: catalog,
          isPremium: false,
          isArabic: true,
          onOpenCategory: opened.add,
        ),
      ),
    ));
    expect(find.text('الجمع'), findsOneWidget);
    expect(find.text('الضرب'), findsOneWidget);
    expect(find.text('مقفلة'), findsOneWidget);
    await tester.tap(find.text('ابدأ الحل'));
    expect(opened, [2]);
    final direction = tester.widget<Directionality>(
      find.ancestor(of: find.text('الجمع'), matching: find.byType(Directionality)).first,
    );
    expect(direction.textDirection, TextDirection.rtl);
  });

  testWidgets('Premium category chooser opens all categories', (tester) async {
    final opened = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StageCategoryAccessGrid(
          catalog: catalog,
          isPremium: true,
          isArabic: false,
          onOpenCategory: opened.add,
        ),
      ),
    ));
    expect(find.text('Locked'), findsNothing);
    await tester.tap(find.text('Start solving').last);
    expect(opened, [4]);
  });
}
