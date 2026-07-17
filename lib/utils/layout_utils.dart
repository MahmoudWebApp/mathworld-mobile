import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Centralizes direction-aware layout decisions for Arabic and English.
class LayoutUtils {
  const LayoutUtils._();

  /// Returns true when the current interface direction is right-to-left.
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == ui.TextDirection.rtl;
  }

  /// Returns a chevron for navigating deeper into the application.
  ///
  /// Flutter mirrors the icon automatically in RTL.
  static IconData forwardChevron(BuildContext context) {
    return Icons.chevron_right_rounded;
  }

  /// Returns an arrow for forward actions.
  ///
  /// Flutter mirrors the icon automatically in RTL.
  static IconData forwardArrow(BuildContext context) {
    return Icons.arrow_forward_rounded;
  }

  /// Returns the back navigation icon.
  ///
  /// Flutter mirrors the icon automatically in RTL.
  static IconData backChevron(BuildContext context) {
    return Icons.chevron_left_rounded;
  }

  /// Returns the next-page icon.
  static IconData nextPage(BuildContext context) {
    return Icons.chevron_right_rounded;
  }

  /// Returns the previous-page icon.
  static IconData previousPage(BuildContext context) {
    return Icons.chevron_left_rounded;
  }

  /// Returns text alignment matching the current interface direction.
  static TextAlign textAlignment(BuildContext context) {
    return isRtl(context) ? TextAlign.right : TextAlign.left;
  }
}
