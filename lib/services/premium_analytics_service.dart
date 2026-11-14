import '../core/network/api_client.dart';

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class PremiumCategoryStatistics {
  const PremiumCategoryStatistics({
    required this.stageId,
    required this.categoryId,
    required this.stageNameAr,
    required this.stageNameEn,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.errorNotebookProblems,
    required this.attempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.firstTryCorrect,
    required this.awardedPoints,
    required this.timeSpentSeconds,
  });

  final int stageId;
  final int categoryId;
  final String stageNameAr;
  final String stageNameEn;
  final String categoryNameAr;
  final String categoryNameEn;
  final int attemptedProblems;
  final int solvedProblems;
  final int errorNotebookProblems;
  final int attempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final int firstTryCorrect;
  final int awardedPoints;
  final int timeSpentSeconds;

  factory PremiumCategoryStatistics.fromJson(Map<String, dynamic> json) =>
      PremiumCategoryStatistics(
        stageId: _asInt(json['StageId']),
        categoryId: _asInt(json['CategoryId']),
        stageNameAr: json['StageNameAr'] as String? ?? '',
        stageNameEn: json['StageNameEn'] as String? ?? '',
        categoryNameAr: json['CategoryNameAr'] as String? ?? '',
        categoryNameEn: json['CategoryNameEn'] as String? ?? '',
        attemptedProblems: _asInt(json['AttemptedProblems']),
        solvedProblems: _asInt(json['SolvedProblems']),
        errorNotebookProblems: _asInt(json['ErrorNotebookProblems']),
        attempts: _asInt(json['Attempts']),
        correctAttempts: _asInt(json['CorrectAttempts']),
        incorrectAttempts: _asInt(json['IncorrectAttempts']),
        firstTryCorrect: _asInt(json['FirstTryCorrect']),
        awardedPoints: _asInt(json['AwardedPoints']),
        timeSpentSeconds: _asInt(json['TimeSpentSeconds']),
      );
}

class PremiumAnalyticsReport {
  const PremiumAnalyticsReport({
    required this.generatedAtUtc,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.attempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.firstTryCorrect,
    required this.awardedPoints,
    required this.timeSpentSeconds,
    required this.categories,
  });

  final DateTime generatedAtUtc;
  final int attemptedProblems;
  final int solvedProblems;
  final int attempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final int firstTryCorrect;
  final int awardedPoints;
  final int timeSpentSeconds;
  final List<PremiumCategoryStatistics> categories;

  factory PremiumAnalyticsReport.fromJson(Map<String, dynamic> json) =>
      PremiumAnalyticsReport(
        generatedAtUtc: DateTime.tryParse(json['GeneratedAtUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        attemptedProblems: _asInt(json['AttemptedProblems']),
        solvedProblems: _asInt(json['SolvedProblems']),
        attempts: _asInt(json['Attempts']),
        correctAttempts: _asInt(json['CorrectAttempts']),
        incorrectAttempts: _asInt(json['IncorrectAttempts']),
        firstTryCorrect: _asInt(json['FirstTryCorrect']),
        awardedPoints: _asInt(json['AwardedPoints']),
        timeSpentSeconds: _asInt(json['TimeSpentSeconds']),
        categories: (json['Categories'] as List<dynamic>? ?? const [])
            .map((item) => PremiumCategoryStatistics.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(growable: false),
      );
}

/// Backend verifies Premium ownership on every request, independent of UI state.
class PremiumAnalyticsService {
  const PremiumAnalyticsService(this._api);

  final ApiClient _api;

  Future<PremiumAnalyticsReport> getReport() async {
    final response = await _api.get('/users/premium-analytics');
    final envelope = Map<String, dynamic>.from(response.data as Map);
    final data = Map<String, dynamic>.from(
      (envelope['Data'] ?? envelope) as Map,
    );
    return PremiumAnalyticsReport.fromJson(data);
  }
}
