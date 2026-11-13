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
  /// Supported values are `meilisearch` and `postgresql`.
  /// PostgreSQL is the safe default until MeiliSearch is explicitly enabled.
  static String get searchEngine {
    final configured =
        _readEnvironmentValue('SEARCH_ENGINE')?.trim().toLowerCase();
    return configured == 'meilisearch' ? 'meilisearch' : 'postgresql';
  }

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String socialGoogle = '/auth/social/google';
  static const String socialLinkGoogle = '/auth/social/link/google';
  static const String stages = '/stages';
  static const String categories = '/categories';
  static const String problemsSearch = '/problems/search';
  static const String problemDetail = '/problems';
  static const String submitAnswer = '/problems/submit';
  static const String userProfile = '/users/profile';
  static const String userLearningStage = '/users/learning-stage';
  static const String userJourney = '/users/journey';
  static const String userDashboard = '/users/dashboard';
  static const String userFavorites = '/users/favorites';
  static const String userSolved = '/users/solved';
  static const String toggleFavorite = '/users/favorite/toggle';
  static const String favoriteCheck = '/users/favorite/check';
  static const String errorNotebook = '/users/error-notebook';
  static const String stats = '/stats';

  static String? _readEnvironmentValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }
}

/// Build-time feature flags for optional native social sign-in.
/// No provider credentials are baked into the default release APK.
class SocialAuthConfig {
  const SocialAuthConfig._();

  static const bool enabled = bool.fromEnvironment(
    'MATHWORLD_SOCIAL_LOGIN_ENABLED',
    defaultValue: false,
  );

  static const String googleServerClientId = String.fromEnvironment(
    'MATHWORLD_GOOGLE_SERVER_CLIENT_ID',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'MATHWORLD_GOOGLE_IOS_CLIENT_ID',
  );

  static bool get googleAvailable =>
      enabled && googleServerClientId.trim().isNotEmpty;
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
