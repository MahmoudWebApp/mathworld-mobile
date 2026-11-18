import 'dart:typed_data';

import '../core/network/api_client.dart';

/// Never silently render a broken or partial Premium response as zero
/// activity. The API may use ASP.NET's PascalCase or JSON camelCase.
dynamic _field(Map<String, dynamic> json, String name) =>
    json.containsKey(name)
        ? json[name]
        : json['${name[0].toLowerCase()}${name.substring(1)}'];

int _nonnegativeInt(Map<String, dynamic> json, String name) {
  final value = _field(json, name);
  if (value is int && value >= 0) return value;
  if (value is num && value >= 0 && value.isFinite &&
      value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Invalid Premium report field: $name');
}

String _requiredText(Map<String, dynamic> json, String name) {
  final value = _field(json, name);
  if (value is String) return value;
  throw FormatException('Invalid Premium report field: $name');
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
        stageId: _nonnegativeInt(json, 'StageId'),
        categoryId: _nonnegativeInt(json, 'CategoryId'),
        stageNameAr: _requiredText(json, 'StageNameAr'),
        stageNameEn: _requiredText(json, 'StageNameEn'),
        categoryNameAr: _requiredText(json, 'CategoryNameAr'),
        categoryNameEn: _requiredText(json, 'CategoryNameEn'),
        attemptedProblems: _nonnegativeInt(json, 'AttemptedProblems'),
        solvedProblems: _nonnegativeInt(json, 'SolvedProblems'),
        errorNotebookProblems: _nonnegativeInt(json, 'ErrorNotebookProblems'),
        attempts: _nonnegativeInt(json, 'Attempts'),
        correctAttempts: _nonnegativeInt(json, 'CorrectAttempts'),
        incorrectAttempts: _nonnegativeInt(json, 'IncorrectAttempts'),
        firstTryCorrect: _nonnegativeInt(json, 'FirstTryCorrect'),
        awardedPoints: _nonnegativeInt(json, 'AwardedPoints'),
        timeSpentSeconds: _nonnegativeInt(json, 'TimeSpentSeconds'),
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
        generatedAtUtc: _reportDate(json),
        attemptedProblems: _nonnegativeInt(json, 'AttemptedProblems'),
        solvedProblems: _nonnegativeInt(json, 'SolvedProblems'),
        attempts: _nonnegativeInt(json, 'Attempts'),
        correctAttempts: _nonnegativeInt(json, 'CorrectAttempts'),
        incorrectAttempts: _nonnegativeInt(json, 'IncorrectAttempts'),
        firstTryCorrect: _nonnegativeInt(json, 'FirstTryCorrect'),
        awardedPoints: _nonnegativeInt(json, 'AwardedPoints'),
        timeSpentSeconds: _nonnegativeInt(json, 'TimeSpentSeconds'),
        categories: _categories(json),
      );
}

DateTime _reportDate(Map<String, dynamic> json) {
  final raw = _requiredText(json, 'GeneratedAtUtc');
  final value = DateTime.tryParse(raw);
  if (value == null) throw const FormatException('Invalid Premium report timestamp');
  return value.toUtc();
}

List<PremiumCategoryStatistics> _categories(Map<String, dynamic> json) {
  final raw = _field(json, 'Categories');
  if (raw is! List) {
    throw const FormatException('Missing Premium report categories');
  }
  if (raw.length > 2000) {
    throw const FormatException('Excessive Premium report category count');
  }
  return List<PremiumCategoryStatistics>.unmodifiable(raw.map((item) {
    if (item is! Map) {
      throw const FormatException('Invalid Premium report category');
    }
    return PremiumCategoryStatistics.fromJson(Map<String, dynamic>.from(item));
  }));
}

/// Backend verifies Premium ownership on every request, independent of UI state.
class PremiumAnalyticsService {
  const PremiumAnalyticsService(this._api);

  final ApiClient _api;

  /// Retrieves the actual OOXML workbook generated by the authorized API.
  /// A successful JSON response or HTML error is never treated as an Excel file.
  Future<Uint8List> exportXlsx({required String language}) async {
    if (language != 'ar' && language != 'en') {
      throw ArgumentError.value(language, 'language');
    }
    final bytes = await _api.getBinary(
      '/users/premium-analytics/export.xlsx',
      queryParameters: {'lang': language},
    );
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b ||
        bytes[2] != 0x03 || bytes[3] != 0x04) {
      throw const FormatException('Invalid XLSX workbook bytes');
    }
    return Uint8List.fromList(bytes);
  }

  Future<PremiumAnalyticsReport> getReport() async {
    final response = await _api.get('/users/premium-analytics');
    final envelope = Map<String, dynamic>.from(response.data as Map);
    final rawData = envelope['Data'] ?? envelope['data'] ?? envelope;
    if (rawData is! Map) {
      throw const FormatException('Invalid Premium report response');
    }
    return PremiumAnalyticsReport.fromJson(Map<String, dynamic>.from(rawData));
  }
}
