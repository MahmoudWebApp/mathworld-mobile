/// Stage-scoped progress as reported by MathWorld's backend.
class LearningJourney {
  final int stageId;
  final String nameAr;
  final String nameEn;
  final int totalProblems;
  final int attemptedProblems;
  final int solvedProblems;
  final int firstTryCorrect;
  final int masteredProblems;
  final int totalPoints;
  final int completionPercent;
  final List<LearningJourneyCategory> categories;

  const LearningJourney({
    required this.stageId,
    required this.nameAr,
    required this.nameEn,
    required this.totalProblems,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.firstTryCorrect,
    required this.masteredProblems,
    required this.totalPoints,
    required this.completionPercent,
    required this.categories,
  });

  factory LearningJourney.fromJson(Map<String, dynamic> data) {
    final raw = data['Categories'] ?? data['categories'];
    return LearningJourney(
      stageId: _integer(data['StageId'] ?? data['stageId']),
      nameAr: _string(data['NameAr'] ?? data['nameAr']),
      nameEn: _string(data['NameEn'] ?? data['nameEn']),
      totalProblems: _integer(data['TotalProblems'] ?? data['totalProblems']),
      attemptedProblems: _integer(
        data['AttemptedProblems'] ?? data['attemptedProblems'],
      ),
      solvedProblems: _integer(data['SolvedProblems'] ?? data['solvedProblems']),
      firstTryCorrect: _integer(data['FirstTryCorrect'] ?? data['firstTryCorrect']),
      masteredProblems: _integer(
        data['MasteredProblems'] ?? data['masteredProblems'],
      ),
      totalPoints: _integer(data['TotalPoints'] ?? data['totalPoints']),
      completionPercent: _integer(
        data['CompletionPercent'] ?? data['completionPercent'],
      ),
      categories: raw is List
          ? raw.whereType<Map>().map((category) =>
              LearningJourneyCategory.fromJson(
                Map<String, dynamic>.from(category),
              )).toList()
          : <LearningJourneyCategory>[],
    );
  }

  String getName(String locale) => locale == 'en' ? nameEn : nameAr;
}

class LearningJourneyCategory {
  final int categoryId;
  final String nameAr;
  final String nameEn;
  final int totalProblems;
  final int solvedProblems;
  final int completionPercent;

  const LearningJourneyCategory({
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.totalProblems,
    required this.solvedProblems,
    required this.completionPercent,
  });

  factory LearningJourneyCategory.fromJson(Map<String, dynamic> data) {
    return LearningJourneyCategory(
      categoryId: _integer(data['CategoryId'] ?? data['categoryId']),
      nameAr: _string(data['NameAr'] ?? data['nameAr']),
      nameEn: _string(data['NameEn'] ?? data['nameEn']),
      totalProblems: _integer(data['TotalProblems'] ?? data['totalProblems']),
      solvedProblems: _integer(data['SolvedProblems'] ?? data['solvedProblems']),
      completionPercent: _integer(
        data['CompletionPercent'] ?? data['completionPercent'],
      ),
    );
  }

  String getName(String locale) => locale == 'en' ? nameEn : nameAr;
}

int _integer(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _string(dynamic value) => value?.toString() ?? '';
