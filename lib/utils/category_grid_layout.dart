/// One consistent responsive layout for all educational-stage category cards.
/// Keeps Arabic titles, Premium status and learner progress readable on phones.
class StageCategoryGridLayout {
  StageCategoryGridLayout._();

  static int columns(double width, {double textScale = 1}) {
    if (!width.isFinite || width <= 0) return 1;
    if (textScale > 1.2) return 1;
    if (width >= 1000) return 4;
    if (width >= 740) return 3;
    if (width >= 440) return 2;
    return 1;
  }

  static double cardExtent(int columns, {double textScale = 1}) {
    // The category card uses an icon + details row. Avoid the old tall
    // 220-248dp cards with large unused space on ordinary phones.
    if (textScale > 1.35) return 206;
    if (textScale > 1.2) return 188;
    return columns == 1 ? 152 : 166;
  }
}
