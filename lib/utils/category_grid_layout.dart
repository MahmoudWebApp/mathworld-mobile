/// One consistent responsive layout for all educational-stage category cards.
/// Keeps Arabic titles, Premium status and learner progress readable on phones.
class StageCategoryGridLayout {
  StageCategoryGridLayout._();

  static int columns(double width, {double textScale = 1}) {
    if (!width.isFinite || width <= 0) return 1;
    if (textScale > 1.35) return 1;
    if (width >= 740) return 3;
    if (width >= 310) return 2;
    return 1;
  }

  static double cardExtent(int columns, {double textScale = 1}) {
    // Stage topic cards now stack the icon, topic and count for readable
    // two-column layouts on phones without truncating Arabic labels.
    // Questions, restart and public learning-skills actions stay INSIDE each card.
    // Extra height avoids truncating Arabic 3-line titles and solved status.
    if (textScale > 1.35) return 405;
    if (textScale > 1.2) return columns == 1 ? 367 : 415;
    return columns == 1 ? 325 : columns == 2 ? 378 : 355;
  }
}
