import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/features/category_access/stage_category_access.dart';
import 'package:mathworld_mobile/models/category.dart';

/// Regression for the initial 4 standards-aligned topic additions.
/// Dynamic counts are still supplied by the backend.
void main() {
  final stages = [
    (id: 1, first: 1, second: 2, newId: 21, nameAr: 'الكسور والأعداد العشرية', icon: 'fractions.svg'),
    (id: 2, first: 5, second: 6, newId: 22, nameAr: 'الإحصاء وتحليل البيانات', icon: 'statistics.svg'),
    (id: 3, first: 9, second: 10, newId: 23, nameAr: 'المتتاليات والمتسلسلات', icon: 'sequences.svg'),
    (id: 4, first: 13, second: 14, newId: 24, nameAr: 'المنطق والرياضيات المتقطعة', icon: 'discrete.svg'),
  ];

  for (final stage in stages) {
    test('stage ${stage.id}: fifth topic respects Free and Premium', () {
      final response = StageCategoryAccess.fromJson({
        'StageId': stage.id,
        'FreeCategoryIds': [stage.first, stage.second],
        'Categories': [
          for (var n = 0; n < 4; n++)
            {
              'Id': stage.first + n,
              'NameAr': 'فئة تجريبية ${n + 1}',
              'NameEn': 'Existing topic ${n + 1}',
              'Icon': 'https://math-world-frontend.vercel.app/category-icons/${stage.first + n}.svg',
              'Order': n + 1,
              'ProblemsCount': 24,
              'IsFree': n < 2,
            },
          {
            'Id': stage.newId,
            'NameAr': stage.nameAr,
            'NameEn': 'New coherent topic',
            'Icon': 'https://math-world-frontend.vercel.app/category-icons/${stage.icon}',
            'Order': 5,
            'ProblemsCount': 7,
            'IsFree': false,
          },
        ],
      });

      expect(response.stageId, stage.id);
      expect(response.categories, hasLength(5));
      expect(response.freeCategoryIds, [stage.first, stage.second]);
      expect(response.categories.where((c) => c.isFree), hasLength(2));
      final added = response.categories.singleWhere((c) => c.id == stage.newId);
      expect(added.nameAr, stage.nameAr);
      expect(added.icon.endsWith('/${stage.icon}'), isTrue);
      expect(added.problemsCount, greaterThan(0));
      expect(added.canOpen(isPremium: false), isFalse);
      expect(added.canOpen(isPremium: true), isTrue);
      expect(response.categories.first.canOpen(isPremium: false), isTrue);
      expect(response.categories[1].canOpen(isPremium: false), isTrue);
    });
  }

  test('bilingual category model retains SVG path and real progress', () {
    final category = Category.fromJson({
      'Id': 21,
      'NameAr': 'الكسور والأعداد العشرية',
      'NameEn': 'Fractions & Decimals',
      'DescriptionAr': 'مسائل الكسور والعلاقات العشرية',
      'DescriptionEn': 'Fractions and decimal relationships',
      'Icon': 'https://math-world-frontend.vercel.app/category-icons/fractions.svg',
      'StageId': 1,
      'Order': 5,
      'ProblemsCount': 9,
      'SolvedCount': 0,
    });
    expect(category.getName('ar'), 'الكسور والأعداد العشرية');
    expect(category.getName('en'), 'Fractions & Decimals');
    expect(category.icon, endsWith('/fractions.svg'));
    expect(category.progress, 0.0);
    expect(category.toJson()['Order'], 5);
  });
}
