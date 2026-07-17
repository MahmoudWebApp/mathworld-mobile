import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central API endpoint and environment configuration.
class ApiConstants {
  const ApiConstants._();

  static String get baseUrl {
    final configured = _readEnvironmentValue('API_BASE_URL')?.trim();

    final value = configured == null || configured.isEmpty
        ? 'https://mathwordbackend.onrender.com/api'
        : configured;

    return value.replaceFirst(RegExp(r'/$'), '');
  }

  /// Selects the backend search engine used by the unified search endpoint.
  ///
  /// PostgreSQL is the safe default.
  /// MeiliSearch is used only when SEARCH_ENGINE is explicitly set
  /// to `meilisearch`.
  static String get searchEngine {
    final configured =
        _readEnvironmentValue('SEARCH_ENGINE')?.trim().toLowerCase();

    return configured == 'meilisearch' ? 'meilisearch' : 'postgresql';
  }

  static const String login = '/auth/login';
  static const String register = '/auth/register';

  static const String stages = '/stages';
  static const String categories = '/categories';

  static const String problemsSearch = '/problems/search';
  static const String problemDetail = '/problems';
  static const String submitAnswer = '/problems/submit';

  static const String userProfile = '/users/profile';
  static const String userDashboard = '/users/dashboard';
  static const String userFavorites = '/users/favorites';
  static const String userSolved = '/users/solved';

  static const String toggleFavorite = '/users/favorite/toggle';
  static const String favoriteCheck = '/users/favorite/check';

  static const String stats = '/stats';

  static String? _readEnvironmentValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }
}

/// Application-wide configuration values.
class AppConstants {
  const AppConstants._();

  static const String appName = 'MathWorld';
  static const String appVersion = '1.1.0';
  static const String defaultLanguage = 'ar';
  static const String tokenKey = 'auth_token';
  static const int pageSize = 10;
  static const Duration contentCacheDuration = Duration(days: 7);
}

/// Hive box names used by the application.
class HiveBoxes {
  const HiveBoxes._();

  static const String authBox = 'auth_box';
  static const String cacheBox = 'cache_box';
  static const String settingsBox = 'settings_box';
}

/// Cache keys used by repositories.
class CacheKeys {
  const CacheKeys._();

  static const String stages = 'stages';
  static const String categories = 'categories';
}