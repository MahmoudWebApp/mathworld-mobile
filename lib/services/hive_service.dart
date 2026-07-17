import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';

/// Provides typed access to local settings, session data, and cached content.
class HiveService {
  const HiveService._();
  static Future<void> init() async {
    try {
      await Hive.openBox<dynamic>(HiveBoxes.authBox);
      await Hive.openBox<dynamic>(HiveBoxes.cacheBox);
      await Hive.openBox<dynamic>(HiveBoxes.settingsBox);
      await _sanitizeLegacyUserCache();
    } catch (error, stackTrace) {
      debugPrint('Hive initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> _sanitizeLegacyUserCache() async {
    final value = _authBox.get('user');
    if (value is! Map) {
      return;
    }
    final sanitized = Map<String, dynamic>.from(value)
      ..remove('Token')
      ..remove('token');
    await _authBox.put('user', sanitized);
  }

  static Box<dynamic> get _authBox => Hive.box<dynamic>(HiveBoxes.authBox);
  static Box<dynamic> get _cacheBox => Hive.box<dynamic>(HiveBoxes.cacheBox);
  static Box<dynamic> get _settingsBox =>
      Hive.box<dynamic>(HiveBoxes.settingsBox);
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _authBox.put('user', userData);
  }

  static Map<String, dynamic>? getUser() {
    final value = _authBox.get('user');
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static Future<void> clearAuth() => _authBox.clear();
  static Future<void> saveCache(String key, dynamic data) async {
    await _cacheBox.put(key, {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
  }

  static dynamic getCache(
    String key, {
    Duration? maxAge,
  }) {
    final value = _cacheBox.get(key);
    if (value is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(value);
    final savedAt = DateTime.tryParse(map['savedAt']?.toString() ?? '');
    if (savedAt == null) {
      return null;
    }
    if (maxAge != null &&
        DateTime.now().toUtc().difference(savedAt.toUtc()) > maxAge) {
      return null;
    }
    return map['data'];
  }

  static Future<void> clearCache() => _cacheBox.clear();
  static Future<void> saveLanguage(String language) async {
    await _settingsBox.put('language', language);
  }

  static String getLanguage() {
    final value = _settingsBox.get(
      'language',
      defaultValue: AppConstants.defaultLanguage,
    );
    return value is String && value.isNotEmpty
        ? value
        : AppConstants.defaultLanguage;
  }

  static Future<void> saveThemeMode(String mode) async {
    await _settingsBox.put('theme_mode', mode);
  }

  static String getThemeMode() {
    final value = _settingsBox.get('theme_mode', defaultValue: 'system');
    return value is String && value.isNotEmpty ? value : 'system';
  }
}
