import '../config/constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';
import '../models/problem.dart';
import '../models/problem_search.dart';

/// Handles problem search, details, answers, favorites, and user lists.
class ProblemsRepository {
  final ApiClient _apiService;

  const ProblemsRepository(this._apiService);

  /// Searches through the unified backend endpoint.
  ///
  /// The selected engine is read from `SEARCH_ENGINE` and defaults to
  /// MeiliSearch. PostgreSQL remains available through the same endpoint.
  Future<ProblemSearchResult> search(
    ProblemSearchParams params,
    String languageCode,
  ) async {
    final queryParameters = <String, dynamic>{
      'engine': ApiConstants.searchEngine,
      'page': params.page,
      'pageSize': params.pageSize,
    };

    if (params.query?.trim().isNotEmpty == true) {
      queryParameters['q'] = params.query!.trim();
    }
    if (params.categoryId != null) {
      queryParameters['categoryId'] = params.categoryId;
    }
    if (params.stageId != null) {
      queryParameters['stageId'] = params.stageId;
    }

    final response = await _apiService.get(
      ApiConstants.problemsSearch,
      queryParameters: queryParameters,
    );

    final data = ApiEnvelope.map(response.data);
    final rawResults = data['Results'] ?? data['results'] ?? const [];
    final results = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map(
              (item) => ProblemPreview.fromJson(
                Map<String, dynamic>.from(item),
                languageCode: languageCode,
              ),
            )
            .toList()
        : <ProblemPreview>[];

    return ProblemSearchResult(
      problems: results,
      total: _int(data['Total'] ?? data['total']),
      page: _int(data['Page'] ?? data['page'], fallback: params.page),
      totalPages: _int(
        data['TotalPages'] ?? data['totalPages'],
        fallback: 1,
      ),
    );
  }

  /// Loads a single localized problem.
  Future<Problem> getProblem(int problemId, String languageCode) async {
    final response = await _apiService.get(
      '${ApiConstants.problemDetail}/$problemId',
    );

    return Problem.fromJson(
      ApiEnvelope.map(response.data),
      languageCode: languageCode,
    );
  }

  /// Submits one answer and parses the server-validated result.
  Future<AnswerResult> submitAnswer({
    required int problemId,
    required int selectedOptionId,
    required int timeSpentSeconds,
    required String languageCode,
  }) async {
    final response = await _apiService.post(
      ApiConstants.submitAnswer,
      data: {
        'ProblemId': problemId,
        'SelectedOptionId': selectedOptionId,
        'TimeSpentSeconds': timeSpentSeconds.clamp(1, 86400).toInt(),
      },
    );

    final result = AnswerResult.fromJson(
      ApiEnvelope.map(response.data),
      languageCode: languageCode,
    );

    return result.copyWith(
      selectedOptionId: result.selectedOptionId ?? selectedOptionId,
    );
  }

  /// Sets the requested favorite state on the backend.
  Future<bool> setFavorite({
    required int problemId,
    required bool isFavorite,
  }) async {
    final response = await _apiService.post(
      ApiConstants.toggleFavorite,
      data: {
        'ProblemId': problemId,
        'IsFavorite': isFavorite,
      },
    );

    final data = ApiEnvelope.data(response.data);
    if (data is Map) {
      final value = data['IsFavorite'] ?? data['isFavorite'];
      if (value is bool) {
        return value;
      }
    }

    return isFavorite;
  }

  /// Checks whether a problem is currently in the user's favorites.
  Future<bool> checkFavorite(int problemId) async {
    final response = await _apiService.get(
      '${ApiConstants.favoriteCheck}/$problemId',
    );

    final data = ApiEnvelope.data(response.data);
    if (data is Map) {
      final value = data['IsFavorite'] ?? data['isFavorite'];
      if (value is bool) {
        return value;
      }
    }

    return false;
  }

  Future<List<ProblemPreview>> getFavorites(String languageCode) {
    return _getUserList(ApiConstants.userFavorites, languageCode);
  }

  Future<List<ProblemPreview>> getSolved(String languageCode) {
    return _getUserList(ApiConstants.userSolved, languageCode);
  }

  Future<List<ProblemPreview>> _getUserList(
    String endpoint,
    String languageCode,
  ) async {
    final response = await _apiService.get(endpoint);
    final raw = ApiEnvelope.list(response.data);

    return raw
        .whereType<Map>()
        .map(
          (item) => ProblemPreview.fromJson(
            Map<String, dynamic>.from(item),
            languageCode: languageCode,
          ),
        )
        .toList();
  }
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
