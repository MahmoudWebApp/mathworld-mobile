import 'package:flutter/material.dart';

/// Central visual tokens used across the MathWorld application.
class AppColors {
  AppColors._();

  // Shared with web: accessible purple actions and pink accents, no cyan UI.
  static const Color brandPurple = Color(0xFF5C24FF);
  static const Color brandViolet = Color(0xFFA21CAF);
  static const Color brandPink = Color(0xFFFF2399);
  static const Color brandLavender = Color(0xFF9B83DF);

  // Stage identities: playful color differentiation alongside the original
  // MathWorld purple brand. Always pair with text/icons, not color alone.
  static const Color stageCyan = Color(0xFF087E99);
  static const Color stageOrange = Color(0xFFC05B18);
  static const Color stageGreen = Color(0xFF21785F);
  static const Color stageViolet = Color(0xFF7937C3);


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

  /// Preserve white glyphs and alpha while tinting the icon shading to its stage.
  static ColorFilter topicArtworkFilter(Color accent) {
    List<double> channel(double value) {
      final base = value * 255 * .32;
      final gain = 1 - base / 255;
      return [.2126 * gain, .7152 * gain, .0722 * gain, 0, base];
    }
    return ColorFilter.matrix([
      ...channel(accent.r), ...channel(accent.g), ...channel(accent.b),
      0, 0, 0, 1, 0,
    ]);
  }

  /// Identical stage accents to the web's StagePremiumCard identity.
  static Color stageForOrder(int order) {
    const colors = [stageCyan, stageOrange, stageGreen, stageViolet];
    return colors[((order <= 0 ? 1 : order) - 1) % colors.length];
  }

  /// Problem previews may contain a stage name but not its editorial order.
  /// Prefer the bilingual stage identity before falling back to the legacy ID.
  static Color stageForIdentity(int stageId, String? stageName) {
    final name = (stageName ?? '').trim().toLowerCase();
    if (name.contains('ابتد') || name.contains('elementary') ||
        name.contains('primary')) return stageCyan;
    if (name.contains('إعداد') || name.contains('اعداد') ||
        name.contains('middle') || name.contains('intermediate')) return stageOrange;
    if (name.contains('ثانو') || name.contains('secondary') ||
        name.contains('high school')) return stageGreen;
    if (name.contains('جامع') || name.contains('univers')) return stageViolet;
    return stageForOrder(stageId);
  }
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
    colors: [AppColors.brandPurple, AppColors.brandPink],
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