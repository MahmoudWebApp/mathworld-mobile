import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Centralizes direction-aware layout decisions.
class LayoutUtils {
  const LayoutUtils._();

  /// Returns true when the current interface direction is right-to-left.
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == ui.TextDirection.rtl;
  }

  /// Returns the icon used to navigate deeper into the application.
  ///
  /// Flutter automatically mirrors this directional icon in RTL.
  static IconData forwardChevron(BuildContext context) {
    return Icons.chevron_right_rounded;
  }

  /// Returns the icon used to navigate back to the previous screen.
  ///
  /// Flutter automatically mirrors this directional icon in RTL.
  static IconData backChevron(BuildContext context) {
    return Icons.chevron_left_rounded;
  }

  /// Returns the icon used for the next page action.
  static IconData nextPage(BuildContext context) {
    return Icons.chevron_right_rounded;
  }

  /// Returns the icon used for the previous page action.
  static IconData previousPage(BuildContext context) {
    return Icons.chevron_left_rounded;
  }

  /// Returns a text alignment that matches the current interface direction.
  static TextAlign textAlignment(BuildContext context) {
    return isRtl(context) ? TextAlign.right : TextAlign.left;
  }
}