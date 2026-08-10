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
  /// PostgreSQL. MeiliSearch can be enabled explicitly through the same endpoint.
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

  /// Loads all recorded attempts for one problem.
  Future<ProblemAttemptHistory> getAttemptHistory(int problemId) async {
    final response = await _apiService.get(
      '${ApiConstants.problemDetail}/$problemId/attempts',
    );

    return ProblemAttemptHistory.fromJson(
      ApiEnvelope.map(response.data),
    );
  }

  /// Loads the user's active or archived error-notebook problems.
  Future<List<ErrorNotebookProblem>> getErrorNotebook({
    required String languageCode,
    bool includeArchived = false,
  }) async {
    final response = await _apiService.get(
      ApiConstants.errorNotebook,
      queryParameters: {
        'includeArchived': includeArchived,
      },
    );

    return ApiEnvelope.list(response.data)
        .whereType<Map>()
        .map(
          (item) => ErrorNotebookProblem.fromJson(
            Map<String, dynamic>.from(item),
            languageCode: languageCode,
          ),
        )
        .toList();
  }

  /// Archives or restores one problem in the error notebook.
  Future<bool> setErrorNotebookArchive({
    required int problemId,
    required bool isArchived,
  }) async {
    final response = await _apiService.put(
      '${ApiConstants.errorNotebook}/$problemId/archive',
      data: {'IsArchived': isArchived},
    );

    final data = ApiEnvelope.map(response.data);
    final value = data['IsArchived'] ?? data['isArchived'];
    return value is bool ? value : isArchived;
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
