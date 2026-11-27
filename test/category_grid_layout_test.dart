import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/utils/category_grid_layout.dart';
import 'package:mathworld_mobile/features/category_access/stage_category_access.dart';
import 'package:mathworld_mobile/models/published_curriculum_skill.dart';

void main() {
  test('category grid shows two compact columns on phones', () {
    expect(StageCategoryGridLayout.columns(320), 2);
    expect(StageCategoryGridLayout.columns(390), 2);
    expect(StageCategoryGridLayout.columns(430), 2);
    expect(StageCategoryGridLayout.cardExtent(2), 378);
    // Footer buttons must stay inside each card even with larger text.
    expect(StageCategoryGridLayout.cardExtent(2, textScale: 1.30),
        greaterThan(StageCategoryGridLayout.cardExtent(2)));
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.40),
        greaterThan(StageCategoryGridLayout.cardExtent(1)));
  });

  test('larger layouts increase columns without overcrowding', () {
    expect(StageCategoryGridLayout.columns(440), 2);
    expect(StageCategoryGridLayout.columns(740), 3);
    expect(StageCategoryGridLayout.columns(1000), 3);
    expect(StageCategoryGridLayout.cardExtent(3), 355);
  });

  test('published curriculum skills parse both API JSON casing styles', () {
    final pascal = PublishedCurriculumSkill.fromJson({
      'StableKey': 'p-fractions-decimals-equivalence',
      'CategoryId': 21,
      'DomainKey': 'numbers-operations',
      'NameAr': 'الكسور المتكافئة',
      'NameEn': 'Equivalent Fractions',
      'DescriptionAr': 'الكسور المتكافئة',
      'DescriptionEn': 'Equivalent Fractions',
    });
    final camel = PublishedCurriculumSkill.fromJson({
      'stableKey': 's-sequences-series-series-convergence',
      'categoryId': 23,
      'domainKey': 'algebra-functions',
      'nameAr': 'تقارب المتسلسلات وتباعدها',
      'nameEn': 'Series Convergence and Divergence',
      'descriptionAr': 'تقارب المتسلسلات وتباعدها',
      'descriptionEn': 'Series Convergence and Divergence',
    });
    expect(pascal.categoryId, 21);
    expect(pascal.localizedName('ar'), 'الكسور المتكافئة');
    expect(pascal.localizedName('en'), 'Equivalent Fractions');
    expect(camel.categoryId, 23);
    expect(camel.localizedName('en'), 'Series Convergence and Divergence');
    expect(camel.stableKey, isNotEmpty);
  });

  test('malformed skills fail validation instead of becoming fake objectives', () {
    expect(() => PublishedCurriculumSkill.fromJson({
      'StableKey': 'bad',
      'CategoryId': 0,
      'NameAr': '',
      'NameEn': '',
    }), throwsFormatException);
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
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.4), 405);
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.3), 367);
    expect(StageCategoryGridLayout.cardExtent(2, textScale: 1.3), 415);
    expect(StageCategoryGridLayout.columns(-10), 1);
  });
}
