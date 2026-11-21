import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/utils/category_grid_layout.dart';
import 'package:mathworld_mobile/features/category_access/stage_category_access.dart';

void main() {
  test('category grid shows two compact columns on phones', () {
    expect(StageCategoryGridLayout.columns(320), 2);
    expect(StageCategoryGridLayout.columns(390), 2);
    expect(StageCategoryGridLayout.columns(430), 2);
    expect(StageCategoryGridLayout.cardExtent(2), 224);
  });

  test('larger layouts increase columns without overcrowding', () {
    expect(StageCategoryGridLayout.columns(440), 2);
    expect(StageCategoryGridLayout.columns(740), 3);
    expect(StageCategoryGridLayout.columns(1000), 4);
    expect(StageCategoryGridLayout.cardExtent(3), 224);
  });

  test('five stage categories keep Free at two and fifth Premium-only', () {
    final stage = StageCategoryAccess.fromJson({
      'StageId': 1,
      'FreeCategoryIds': [1, 2],
      'Categories': [
        for (var index = 0; index < 5; index++)
          {
            'Id': index < 4 ? index + 1 : 21,
            'NameAr': 'فئة',
            'NameEn': 'Topic',
            'Order': index + 1,
            'Icon': index == 4
                ? 'https://math-world-frontend.vercel.app/category-icons/fractions.svg'
                : '📐',
            'ProblemsCount': index == 4 ? 9 : 24,
            'IsFree': index < 2,
          },
      ],
    });
    expect(stage.categories, hasLength(5));
    expect(stage.freeCategoryIds, [1, 2]);
    expect(stage.categories.where((category) => category.isFree), hasLength(2));
    expect(stage.categories.last.problemsCount, 9);
    expect(stage.categories.last.icon, endsWith('/fractions.svg'));
    expect(stage.categories.last.canOpen(isPremium: false), false);
    expect(stage.categories.last.canOpen(isPremium: true), true);
  });

  test('accessibility text size prevents multi-column clipping', () {
    expect(StageCategoryGridLayout.columns(1180, textScale: 1.4), 1);
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.4), 206);
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.3), 188);
    expect(StageCategoryGridLayout.cardExtent(2, textScale: 1.3), 242);
    expect(StageCategoryGridLayout.columns(-10), 1);
  });
}
