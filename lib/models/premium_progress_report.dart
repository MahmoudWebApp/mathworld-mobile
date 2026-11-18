class PremiumCategoryProgress {
  final int categoryId;
  final String name;
  final int totalProblems;
  final int attemptedProblems;
  final int solvedProblems;
  final int firstTryCorrect;
  final int masteredProblems;
  final int officialPoints;
  final int completionPercent;

  const PremiumCategoryProgress({
    required this.categoryId,
    required this.name,
    required this.totalProblems,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.firstTryCorrect,
    required this.masteredProblems,
    required this.officialPoints,
    required this.completionPercent,
  });

  factory PremiumCategoryProgress.fromJson(Map<String, dynamic> json) =>
      PremiumCategoryProgress(
        categoryId: (json['CategoryId'] as num).toInt(),
        name: (json['Name'] ?? '').toString(),
        totalProblems: (json['TotalProblems'] as num?)?.toInt() ?? 0,
        attemptedProblems: (json['AttemptedProblems'] as num?)?.toInt() ?? 0,
        solvedProblems: (json['SolvedProblems'] as num?)?.toInt() ?? 0,
        firstTryCorrect: (json['FirstTryCorrect'] as num?)?.toInt() ?? 0,
        masteredProblems: (json['MasteredProblems'] as num?)?.toInt() ?? 0,
        officialPoints: (json['OfficialPoints'] as num?)?.toInt() ?? 0,
        completionPercent: (json['CompletionPercent'] as num?)?.toInt() ?? 0,
      );
}

class PremiumProgressReport {
  final int stageId;
  final String stageName;
  final int totalProblems;
  final int attemptedProblems;
  final int solvedProblems;
  final int firstTryCorrect;
  final int masteredProblems;
  final int officialPoints;
  final int completionPercent;
  final List<PremiumCategoryProgress> categories;

  const PremiumProgressReport({
    required this.stageId,
    required this.stageName,
    required this.totalProblems,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.firstTryCorrect,
    required this.masteredProblems,
    required this.officialPoints,
    required this.completionPercent,
    required this.categories,
  });

  factory PremiumProgressReport.fromJson(Map<String, dynamic> json) {
    final raw = json['Categories'] as List<dynamic>? ?? const [];
    return PremiumProgressReport(
      stageId: (json['StageId'] as num).toInt(),
      stageName: (json['StageName'] ?? '').toString(),
      totalProblems: (json['TotalProblems'] as num?)?.toInt() ?? 0,
      attemptedProblems: (json['AttemptedProblems'] as num?)?.toInt() ?? 0,
      solvedProblems: (json['SolvedProblems'] as num?)?.toInt() ?? 0,
      firstTryCorrect: (json['FirstTryCorrect'] as num?)?.toInt() ?? 0,
      masteredProblems: (json['MasteredProblems'] as num?)?.toInt() ?? 0,
      officialPoints: (json['OfficialPoints'] as num?)?.toInt() ?? 0,
      completionPercent: (json['CompletionPercent'] as num?)?.toInt() ?? 0,
      categories: raw.whereType<Map>().map((item) =>
        PremiumCategoryProgress.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}
