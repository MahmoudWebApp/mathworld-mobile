/// A small, optional UTC-day practice selection supplied by the backend.
/// This is not a timed assessment or a daily Free question quota.
class DailyChallenge {
  final String dateUtc;
  final int stageId;
  final int total;
  final int completed;
  final int correct;
  final List<DailyChallengeProblem> problems;

  const DailyChallenge({
    required this.dateUtc,
    required this.stageId,
    required this.total,
    required this.completed,
    required this.correct,
    required this.problems,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final raw = json['Problems'] ?? json['problems'];
    final problems = raw is List
        ? raw.whereType<Map>().map((row) =>
            DailyChallengeProblem.fromJson(Map<String, dynamic>.from(row))).toList()
        : <DailyChallengeProblem>[];
    return DailyChallenge(
      dateUtc: (json['DateUtc'] ?? json['dateUtc'] ?? '').toString(),
      stageId: _int(json['StageId'] ?? json['stageId']),
      total: problems.length, // The actual server-authorized cards, never a made-up quota.
      completed: problems.where((problem) => problem.isAnswered).length,
      correct: problems.where((problem) => problem.isSolved).length,
      problems: problems,
    );
  }
}

class DailyChallengeProblem {
  final int id;
  final int categoryId;
  final String titleAr;
  final String titleEn;
  final int points;
  final bool isSolved;
  final bool isAnswered;

  const DailyChallengeProblem({
    required this.id,
    required this.categoryId,
    required this.titleAr,
    required this.titleEn,
    required this.points,
    required this.isSolved,
    required this.isAnswered,
  });

  factory DailyChallengeProblem.fromJson(Map<String, dynamic> json) =>
      DailyChallengeProblem(
        id: _int(json['Id'] ?? json['id']),
        categoryId: _int(json['CategoryId'] ?? json['categoryId']),
        titleAr: (json['TitleAr'] ?? json['titleAr'] ?? '').toString(),
        titleEn: (json['TitleEn'] ?? json['titleEn'] ?? '').toString(),
        points: _int(json['Points'] ?? json['points']),
        isSolved: (json['IsSolved'] ?? json['isSolved']) == true,
        isAnswered: (json['IsAnswered'] ?? json['isAnswered']) == true ||
            (json['IsSolved'] ?? json['isSolved']) == true,
      );

  String getName(String language) => language == 'en' ? titleEn : titleAr;
}

int _int(dynamic raw) => raw is num ? raw.toInt() :
    int.tryParse(raw?.toString() ?? '') ?? 0;
