/// Stage-scoped progress as reported by MathWorld's backend.
class LearningJourney {
  final int stageId;
  final int? trackId;
  final String nameAr;
  final String nameEn;
  final int totalProblems;
  final int attemptedProblems;
  final int solvedProblems;
  final int firstTryCorrect;
  final int masteredProblems;
  final int totalPoints;
  final bool learningSessionsEnabled;
  final bool certificatesEnabled;
  final bool trackPracticeIsolationEnabled;
  final int? permanentPoints;
  final int? permanentSolvedProblems;
  int get displayedPoints => learningSessionsEnabled ? (permanentPoints ?? totalPoints) : totalPoints;
  final int completionPercent;
  final List<LearningJourneyCategory> categories;

  const LearningJourney({
    required this.stageId,
    this.trackId,
    required this.nameAr,
    required this.nameEn,
    required this.totalProblems,
    required this.attemptedProblems,
    required this.solvedProblems,
    required this.firstTryCorrect,
    required this.masteredProblems,
    required this.totalPoints,
    this.learningSessionsEnabled = false,
    this.certificatesEnabled = false,
    this.trackPracticeIsolationEnabled = false,
    this.permanentPoints,
    this.permanentSolvedProblems,
    required this.completionPercent,
    required this.categories,
  });

  factory LearningJourney.fromJson(Map<String, dynamic> data) {
    final raw = data['Categories'] ?? data['categories'];
    return LearningJourney(
      stageId: _integer(data['StageId'] ?? data['stageId']),
      trackId: _integer(data['TrackId'] ?? data['trackId']) > 0 ? _integer(data['TrackId'] ?? data['trackId']) : null,
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
      learningSessionsEnabled: data['LearningSessionsEnabled']==true,
      certificatesEnabled: data['CertificatesEnabled']==true,
      trackPracticeIsolationEnabled: data['TrackPracticeIsolationEnabled']==true,
      permanentPoints: data['PermanentPoints'] is num ? _integer(data['PermanentPoints']) : null,
      permanentSolvedProblems: data['PermanentSolvedProblems'] is num ? _integer(data['PermanentSolvedProblems']) : null,
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

  /// Recommend only genuinely unlocked inventory: never send a Free learner
  /// into a Premium category. Prefer unfinished started topics, then new ones.
  LearningJourneyCategory? get recommendedCategory {
    final available = categories.where((category) =>
        category.accessVerified &&
        !category.isLocked && category.totalProblems > 0 &&
        category.solvedProblems < category.totalProblems).toList();
    if (available.isEmpty) return null;
    available.sort((a, b) {
      final aStarted = a.attemptedProblems > 0 ? 0 : 1;
      final bStarted = b.attemptedProblems > 0 ? 0 : 1;
      if (aStarted != bStarted) return aStarted.compareTo(bStarted);
      final completion = a.completionPercent.compareTo(b.completionPercent);
      return completion != 0 ? completion : a.categoryId.compareTo(b.categoryId);
    });
    return available.first;
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
  final int attemptedProblems;
  final int firstTryCorrect;
  final bool isLocked;
  /// False on older APIs that omit IsLocked; never call this Premium-locked.
  final bool accessVerified;

  const LearningJourneyCategory({
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.totalProblems,
    required this.solvedProblems,
    required this.completionPercent,
    this.attemptedProblems = 0,
    this.firstTryCorrect = 0,
    this.isLocked = false,
    this.accessVerified = true,
  });

  factory LearningJourneyCategory.fromJson(Map<String, dynamic> data) {
    final accessFlag = data['IsLocked'] ?? data['isLocked'];
    return LearningJourneyCategory(
      categoryId: _integer(data['CategoryId'] ?? data['categoryId']),
      nameAr: _string(data['NameAr'] ?? data['nameAr']),
      nameEn: _string(data['NameEn'] ?? data['nameEn']),
      totalProblems: _integer(data['TotalProblems'] ?? data['totalProblems']),
      solvedProblems: _integer(data['SolvedProblems'] ?? data['solvedProblems']),
      completionPercent: _integer(
        data['CompletionPercent'] ?? data['completionPercent'],
      ),
      attemptedProblems: _integer(
        data['AttemptedProblems'] ?? data['attemptedProblems'],
      ),
      firstTryCorrect: _integer(
        data['FirstTryCorrect'] ?? data['firstTryCorrect'],
      ),
      // Missing metadata on an old backend is unknown, not a subscription
      // decision. Stay fail-closed, but don't mislead the user with Premium.
      isLocked: accessFlag != false,
      accessVerified: accessFlag is bool,
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
