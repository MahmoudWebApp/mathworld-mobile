import 'package:flutter/material.dart';

/// Central visual tokens used across the MathWorld application.
class AppColors {
  AppColors._();

  // MathWorld brand palette. Keep branded surfaces and actions inside this
  // purple-to-cyan family so the application matches the logo everywhere.
  static const Color brandPurple = Color(0xFF7B3FF2);
  static const Color brandViolet = Color(0xFF9A5BFF);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandCyan = Color(0xFF25C9E8);

  static const Color primary = brandPurple;
  static const Color primaryDark = brandCyan;
  static const Color secondary = brandViolet;
  static const Color cyan = brandCyan;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF476F);

  static const Color lightBackground = Color(0xFFF6F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF0F2F8);
  static const Color lightText = Color(0xFF17182C);
  static const Color lightMuted = Color(0xFF666B80);
  static const Color lightBorder = Color(0xFFE1E4EE);

  static const Color darkBackground = Color(0xFF0B0C14);
  static const Color darkSurface = Color(0xFF171826);
  static const Color darkSurfaceMuted = Color(0xFF202231);
  static const Color darkText = Color(0xFFF7F8FC);
  static const Color darkMuted = Color(0xFFB2B6C8);
  static const Color darkBorder = Color(0xFF303344);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

class AppGradients {
  AppGradients._();

  /// Primary MathWorld gradient used by the logo mark and main CTAs.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.brandPurple,
      AppColors.brandViolet,
      AppColors.brandBlue,
      AppColors.brandCyan,
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  /// Dark branded panel gradient derived only from the logo palette.
  static const LinearGradient darkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A174D),
      Color(0xFF1A2450),
      Color(0xFF0E3D4B),
    ],
  );

  /// Light branded panel gradient derived only from the logo palette.
  static const LinearGradient lightHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF2EBFF),
      Color(0xFFEDF2FF),
      Color(0xFFEAFBFF),
    ],
  );
}
