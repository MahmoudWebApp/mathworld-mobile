import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String languageCode;

  const AppSettings({
    required this.themeMode,
    required this.languageCode,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(
          AppSettings(
            themeMode: _themeModeFromStorage(HiveService.getThemeMode()),
            languageCode: _languageFromStorage(HiveService.getLanguage()),
          ),
        );

  static String _languageFromStorage(String value) {
    return value == 'en' ? 'en' : 'ar';
  }

  static ThemeMode _themeModeFromStorage(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await HiveService.saveThemeMode(_themeModeToStorage(mode));
  }

  Future<void> setLanguage(String code) async {
    final normalized = _languageFromStorage(code);
    await HiveService.saveLanguage(normalized);
    state = state.copyWith(languageCode: normalized);
  }
}
