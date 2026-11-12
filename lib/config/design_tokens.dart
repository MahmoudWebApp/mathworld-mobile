import 'package:flutter/material.dart';

/// Central visual tokens used across the MathWorld application.
class AppColors {
  AppColors._();

  // Shared with web: accessible purple actions and pink accents, no cyan UI.
  static const Color brandPurple = Color(0xFF6D28D9);
  static const Color brandViolet = Color(0xFFA21CAF);
  static const Color brandPink = Color(0xFFEC4899);
  static const Color brandLavender = Color(0xFF9B83DF);

  // Compatibility aliases for existing widgets; both now use the brand palette.
  static const Color brandBlue = brandViolet;
  static const Color brandCyan = brandPink;

  static const Color primary = brandPurple;
  static const Color primaryDark = brandLavender;
  static const Color secondary = brandViolet;
  static const Color cyan = brandPink;
  static const Color success = Color(0xFF27866B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF476F);

  static const Color lightBackground = Color(0xFFFAF8FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF5F1FA);
  static const Color lightText = Color(0xFF21172F);
  static const Color lightMuted = Color(0xFF6D6478);
  static const Color lightBorder = Color(0xFFE8E0EF);

  static const Color darkBackground = Color(0xFF110C1E);
  static const Color darkSurface = Color(0xFF1B1428);
  static const Color darkSurfaceMuted = Color(0xFF231B30);
  static const Color darkText = Color(0xFFFBF8FF);
  static const Color darkMuted = Color(0xFFB9ADBF);
  static const Color darkBorder = Color(0xFF40344D);
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
    colors: [AppColors.brandPurple, AppColors.brandViolet, AppColors.brandPink],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient darkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF27183D), Color(0xFF21142F), Color(0xFF35172E)],
  );

  static const LinearGradient lightHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3EBFF), Color(0xFFFFF1F7)],
  );
}