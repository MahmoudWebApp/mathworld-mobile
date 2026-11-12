import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Builds consistent Arabic and English themes for the whole application.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme(String languageCode) {
    return _buildTheme(Brightness.light, languageCode);
  }

  static ThemeData darkTheme(String languageCode) {
    return _buildTheme(Brightness.dark, languageCode);
  }

  static ThemeData _buildTheme(Brightness brightness, String languageCode) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final mutedSurface =
        isDark ? AppColors.darkSurfaceMuted : AppColors.lightSurfaceMuted;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final baseTextTheme = languageCode == 'ar'
        ? GoogleFonts.alexandriaTextTheme()
        : GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: isDark ? AppColors.darkBackground : Colors.white,
        secondary: AppColors.brandPink,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        surfaceContainerHighest: mutedSurface,
        outline: border,
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: text,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: text,
          fontWeight: FontWeight.w900,
          height: 1.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: text, height: 1.7),
        bodyMedium:
            baseTextTheme.bodyMedium?.copyWith(color: muted, height: 1.6),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: muted, height: 1.5),
        labelLarge:
            baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, width: 1.7),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.7),
        hintStyle: TextStyle(color: muted),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(mutedSurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: border),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(TextStyle(color: muted)),
        textStyle: WidgetStatePropertyAll(TextStyle(color: text)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return baseTextTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? primary : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
            size: states.contains(WidgetState.selected) ? 25 : 22,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: mutedSurface,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
        labelStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSurfaceMuted : AppColors.lightText,
        contentTextStyle:
            TextStyle(color: isDark ? AppColors.darkText : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}