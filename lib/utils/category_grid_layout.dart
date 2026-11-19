/// One consistent responsive layout for all educational-stage category cards.
/// Keeps Arabic titles, Premium status and learner progress readable on phones.
class StageCategoryGridLayout {
  StageCategoryGridLayout._();

  static int columns(double width, {double textScale = 1}) {
    if (!width.isFinite || width <= 0) return 1;
    if (textScale > 1.35) return 1;
    if (width >= 1000) return 4;
    if (width >= 740) return 3;
    if (width >= 310) return 2;
    return 1;
  }

  static double cardExtent(int columns, {double textScale = 1}) {
    // Stage topic cards now stack the icon, topic and count for readable
    // two-column layouts on phones without truncating Arabic labels.
    if (textScale > 1.35) return 206;
    if (textScale > 1.2) return columns == 1 ? 188 : 242;
    return columns == 1 ? 152 : 224;
  }
}
