import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/utils/category_grid_layout.dart';

void main() {
  test('category grid stays single-column on narrow phones', () {
    expect(StageCategoryGridLayout.columns(320), 1);
    expect(StageCategoryGridLayout.columns(390), 1);
    expect(StageCategoryGridLayout.columns(430), 1);
    expect(StageCategoryGridLayout.cardExtent(1), 220);
  });

  test('larger layouts increase columns without overcrowding', () {
    expect(StageCategoryGridLayout.columns(440), 2);
    expect(StageCategoryGridLayout.columns(740), 3);
    expect(StageCategoryGridLayout.columns(1000), 4);
    expect(StageCategoryGridLayout.cardExtent(3), 248);
  });

  test('accessibility text size prevents multi-column clipping', () {
    expect(StageCategoryGridLayout.columns(1180, textScale: 1.4), 1);
    expect(StageCategoryGridLayout.cardExtent(1, textScale: 1.4), 288);
    expect(StageCategoryGridLayout.columns(-10), 1);
  });
}
