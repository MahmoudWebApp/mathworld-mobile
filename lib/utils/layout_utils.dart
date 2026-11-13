import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Centralizes direction-aware layout decisions for Arabic and English.
class LayoutUtils {
  const LayoutUtils._();

  static const Set<String> _rtlLanguageCodes = {
    'ar',
    'fa',
    'he',
    'ur',
  };

  /// Returns true when the active locale uses a right-to-left script.
  static bool isRtl(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_rtlLanguageCodes.contains(languageCode)) {
      return true;
    }

    return Directionality.maybeOf(context) == ui.TextDirection.rtl;
  }

  /// Returns the explicit glyph used to navigate deeper into the application.
  ///
  /// The returned [IconData] must be rendered with an LTR icon direction to
  /// avoid Flutter mirroring it a second time in RTL layouts.
  static IconData forwardChevron(BuildContext context) {
    return isRtl(context)
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;
  }

  /// Returns the explicit glyph used to navigate back to the previous screen.
  static IconData backChevron(BuildContext context) {
    return isRtl(context)
        ? Icons.chevron_right_rounded
        : Icons.chevron_left_rounded;
  }

  /// Physical arrows selected by navigation meaning (no double mirroring).
  static IconData forwardArrow(BuildContext context) =>
      isRtl(context) ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;

  static IconData backArrow(BuildContext context) =>
      isRtl(context) ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;

  /// For semantic navigation icons passed into reusable icon buttons.
  /// Non-directional icons (login, checkmark, etc.) stay unchanged.
  static IconData resolveSemanticIcon(BuildContext context, IconData icon) {
    if (icon == Icons.arrow_forward_rounded) return forwardArrow(context);
    if (icon == Icons.arrow_back_rounded) return backArrow(context);
    if (icon == Icons.chevron_right_rounded) return forwardChevron(context);
    if (icon == Icons.chevron_left_rounded) return backChevron(context);
    return icon;
  }

  static IconData nextPage(BuildContext context) => forwardChevron(context);

  static IconData previousPage(BuildContext context) => backChevron(context);

  /// Builds a forward icon without Material's automatic RTL mirroring.
  static Widget forwardIcon(
    BuildContext context, {
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return Icon(
      forwardChevron(context),
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: ui.TextDirection.ltr,
    );
  }

  /// Builds a back icon without Material's automatic RTL mirroring.
  static Widget backIcon(
    BuildContext context, {
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return Icon(
      backChevron(context),
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: ui.TextDirection.ltr,
    );
  }

  /// Builds a next-page icon without automatic mirroring.
  static Widget nextPageIcon(
    BuildContext context, {
    double? size,
    Color? color,
  }) {
    return Icon(
      nextPage(context),
      size: size,
      color: color,
      textDirection: ui.TextDirection.ltr,
    );
  }

  /// Builds a previous-page icon without automatic mirroring.
  static Widget previousPageIcon(
    BuildContext context, {
    double? size,
    Color? color,
  }) {
    return Icon(
      previousPage(context),
      size: size,
      color: color,
      textDirection: ui.TextDirection.ltr,
    );
  }

  static TextAlign textAlignment(BuildContext context) {
    return isRtl(context) ? TextAlign.right : TextAlign.left;
  }

  static CrossAxisAlignment crossAxisAlignment(BuildContext context) {
    return isRtl(context) ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }
}
