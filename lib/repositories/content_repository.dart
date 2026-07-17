import '../config/constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_envelope.dart';
import '../models/category.dart';
import '../models/stage.dart';
import '../core/network/api_client.dart';
import '../services/hive_service.dart';

/// Loads educational stages and categories with offline cache fallback.
class ContentRepository {
  final ApiClient _apiService;
  const ContentRepository(this._apiService);
  Future<List<Stage>> getStages(String languageCode) async {
    final cacheKey = '${CacheKeys.stages}_$languageCode';
    try {
      final response = await _apiService.get(ApiConstants.stages);
      final raw = ApiEnvelope.list(response.data);
      await HiveService.saveCache(cacheKey, raw);
      return _parseStages(raw, languageCode);
    } on AppException catch (error) {
      if (!error.canUseCachedData) {
        rethrow;
      }
      final cached = HiveService.getCache(
        cacheKey,
        maxAge: AppConstants.contentCacheDuration,
      );
      if (cached is List) {
        return _parseStages(cached, languageCode);
      }
      rethrow;
    }
  }

  Future<List<Category>> getCategories(String languageCode) async {
    final cacheKey = '${CacheKeys.categories}_$languageCode';
    try {
      final response = await _apiService.get(ApiConstants.categories);
      final raw = ApiEnvelope.list(response.data);
      await HiveService.saveCache(cacheKey, raw);
      return _parseCategories(raw, languageCode);
    } on AppException catch (error) {
      if (!error.canUseCachedData) {
        rethrow;
      }
      final cached = HiveService.getCache(
        cacheKey,
        maxAge: AppConstants.contentCacheDuration,
      );
      if (cached is List) {
        return _parseCategories(cached, languageCode);
      }
      rethrow;
    }
  }

  List<Stage> _parseStages(List<dynamic> raw, String languageCode) {
    return raw
        .whereType<Map>()
        .map(
          (item) => Stage.fromJson(
            Map<String, dynamic>.from(item),
            languageCode: languageCode,
          ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Category> _parseCategories(List<dynamic> raw, String languageCode) {
    return raw
        .whereType<Map>()
        .map(
          (item) => Category.fromJson(
            Map<String, dynamic>.from(item),
            languageCode: languageCode,
          ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
