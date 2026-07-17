import 'package:flutter/material.dart';

/// Central visual tokens used across the MathWorld application.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6D5DFB);
  static const Color primaryDark = Color(0xFF67D8FF);
  static const Color secondary = Color(0xFF8A5CF6);
  static const Color cyan = Color(0xFF20C7E8);
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

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary, AppColors.cyan],
  );

  static const LinearGradient darkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF242039), Color(0xFF172035), Color(0xFF102A34)],
  );

  static const LinearGradient lightHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF1EEFF), Color(0xFFECF9FD), Color(0xFFFFFFFF)],
  );
}
