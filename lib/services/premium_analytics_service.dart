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
    this.totalProblems,
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
  final int? totalProblems;
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
        totalProblems: _field(json, 'TotalProblems') == null ? null : _nonnegativeInt(json, 'TotalProblems'),
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

typedef AnalyticsFilter = ({int? stageId,int? categoryId,int? trackId,int? days});
const AnalyticsFilter allAnalytics = (stageId:null,categoryId:null,trackId:null,days:null);
Map<String,dynamic> analyticsParams(AnalyticsFilter filter) => {
  if(filter.stageId!=null)'stageId':filter.stageId,
  if(filter.categoryId!=null)'categoryId':filter.categoryId,
  if(filter.trackId!=null)'trackId':filter.trackId,
  if(filter.days!=null)'days':filter.days,
};

class PremiumAnalyticsReport {
  const PremiumAnalyticsReport({
    required this.generatedAtUtc,
    required this.attemptedProblems,
    this.totalProblems,
    required this.solvedProblems,
    required this.attempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.firstTryCorrect,
    required this.awardedPoints,
    required this.timeSpentSeconds,
    required this.categories,
    this.recentAttempts,
    this.scoreBasis='ActiveProgress',
    this.filter=allAnalytics,
  });

  final DateTime generatedAtUtc;
  final int attemptedProblems;
  final int? totalProblems;
  final int solvedProblems;
  final int attempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final int firstTryCorrect;
  final int awardedPoints;
  final int timeSpentSeconds;
  final List<PremiumCategoryStatistics> categories;
  final List<PremiumRecentAttempt>? recentAttempts;
  final String scoreBasis;
  final AnalyticsFilter filter;

  factory PremiumAnalyticsReport.fromJson(Map<String, dynamic> json) =>
      PremiumAnalyticsReport(
        generatedAtUtc: _reportDate(json),
        attemptedProblems: _nonnegativeInt(json, 'AttemptedProblems'),
        totalProblems: _field(json, 'TotalProblems') == null ? null : _nonnegativeInt(json, 'TotalProblems'),
        solvedProblems: _nonnegativeInt(json, 'SolvedProblems'),
        attempts: _nonnegativeInt(json, 'Attempts'),
        correctAttempts: _nonnegativeInt(json, 'CorrectAttempts'),
        incorrectAttempts: _nonnegativeInt(json, 'IncorrectAttempts'),
        firstTryCorrect: _nonnegativeInt(json, 'FirstTryCorrect'),
        awardedPoints: _nonnegativeInt(json, 'AwardedPoints'),
        timeSpentSeconds: _nonnegativeInt(json, 'TimeSpentSeconds'),
        categories: _categories(json),
        recentAttempts: _recentAttempts(json),
        scoreBasis: _field(json,'ScoreBasis')=='PermanentAchievements'?'PermanentAchievements':'ActiveProgress',
        filter:(stageId:_optionalPositive(json,'FilterStageId'),categoryId:_optionalPositive(json,'FilterCategoryId'),trackId:_optionalPositive(json,'FilterTrackId'),days:_optionalPositive(json,'WindowDays')),
      );
}

class PremiumRecentAttempt {
  const PremiumRecentAttempt({required this.problemId, required this.titleAr,
    required this.titleEn, required this.isCorrect, required this.submittedAtUtc});
  final int problemId;
  final String titleAr, titleEn;
  final bool isCorrect;
  final DateTime submittedAtUtc;
}

List<PremiumRecentAttempt>? _recentAttempts(Map<String,dynamic> json) {
  final raw = _field(json, 'RecentAttempts');
  if (raw == null) return null;
  if (raw is! List || raw.length > 10) {
    throw const FormatException('Invalid recent attempts');
  }
  return List<PremiumRecentAttempt>.unmodifiable(raw.map((item) {
    if (item is! Map) throw const FormatException('Invalid recent attempt');
    final row = Map<String,dynamic>.from(item);
    final correct = _field(row, 'IsCorrect');
    final date = DateTime.tryParse(_requiredText(row, 'SubmittedAtUtc'));
    if (correct is! bool || date == null) {
      throw const FormatException('Invalid recent attempt fields');
    }
    return PremiumRecentAttempt(problemId: _nonnegativeInt(row, 'ProblemId'),
      titleAr: _requiredText(row, 'TitleAr'), titleEn: _requiredText(row, 'TitleEn'),
      isCorrect: correct, submittedAtUtc: date.toUtc());
  }));
}

int? _optionalPositive(Map<String,dynamic> json,String name){
  final v=_field(json,name);
  if(v==null)return null;
  final n=_nonnegativeInt(json,name);
  if(n==0)throw FormatException('Invalid report filter: $name');
  return n;
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
  Future<Uint8List> exportXlsx({required String language,AnalyticsFilter filter=allAnalytics}) async {
    if (language != 'ar' && language != 'en') {
      throw ArgumentError.value(language, 'language');
    }
    final bytes = await _api.getBinary(
      '/users/premium-analytics/export.xlsx',
      queryParameters: {'lang': language,...analyticsParams(filter)},
    );
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b ||
        bytes[2] != 0x03 || bytes[3] != 0x04) {
      throw const FormatException('Invalid XLSX workbook bytes');
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> exportPdf({required String language,AnalyticsFilter filter=allAnalytics}) async {
    if(language!='ar'&&language!='en')throw ArgumentError.value(language,'language');
    final bytes=await _api.getBinary('/users/premium-analytics/export.pdf',queryParameters:{'lang':language,...analyticsParams(filter)});
    if(bytes.length<5||String.fromCharCodes(bytes.take(5))!='%PDF-')throw const FormatException('Invalid PDF bytes');
    return Uint8List.fromList(bytes);
  }
  Future<Uint8List> exportCsv({required String language,AnalyticsFilter filter=allAnalytics}) async {
    if(language!='ar'&&language!='en')throw ArgumentError.value(language,'language');
    final bytes=await _api.getBinary('/users/premium-analytics/export.csv',queryParameters:{'lang':language,...analyticsParams(filter)});
    if(bytes.length<3||bytes[0]!=0xef||bytes[1]!=0xbb||bytes[2]!=0xbf)throw const FormatException('Invalid CSV bytes');
    return Uint8List.fromList(bytes);
  }
  Future<PremiumAnalyticsReport> getReport({AnalyticsFilter filter=allAnalytics}) async {
    final response = await _api.get('/users/premium-analytics',queryParameters:analyticsParams(filter));
    final envelope = Map<String, dynamic>.from(response.data as Map);
    final rawData = envelope['Data'] ?? envelope['data'] ?? envelope;
    if (rawData is! Map) {
      throw const FormatException('Invalid Premium report response');
    }
    final report=PremiumAnalyticsReport.fromJson(Map<String,dynamic>.from(rawData));
    // The server resolves an omitted stage/track to the authenticated student's
    // current grade. Explicitly requested filters must still match exactly.
    if ((filter.stageId != null && report.filter.stageId != filter.stageId) ||
        (filter.trackId != null && report.filter.trackId != filter.trackId) ||
        report.filter.categoryId != filter.categoryId ||
        report.filter.days != filter.days) {
      throw const FormatException('Report scope mismatch');
    }
    return report;
  }
}
