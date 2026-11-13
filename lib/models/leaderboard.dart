/// Server-scored, stage-isolated leaderboard.
class LeaderboardData {
  final int stageId;
  final String nameAr;
  final String nameEn;
  final String period;
  final int page;
  final int pageSize;
  final int totalLearners;
  final int? myRank;
  final List<LeaderboardEntry> entries;

  const LeaderboardData({
    required this.stageId,
    required this.nameAr,
    required this.nameEn,
    required this.period,
    required this.page,
    required this.pageSize,
    required this.totalLearners,
    required this.myRank,
    required this.entries,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['Entries'] ?? json['entries'];
    final rank = json['MyRank'] ?? json['myRank'];
    return LeaderboardData(
      stageId: _toInt(json['StageId'] ?? json['stageId']),
      nameAr: (json['NameAr'] ?? json['nameAr'] ?? '').toString(),
      nameEn: (json['NameEn'] ?? json['nameEn'] ?? '').toString(),
      period: (json['Period'] ?? json['period'] ?? 'all').toString(),
      page: _toInt(json['Page'] ?? json['page']),
      pageSize: _toInt(json['PageSize'] ?? json['pageSize']),
      totalLearners: _toInt(json['TotalLearners'] ?? json['totalLearners']),
      myRank: rank == null ? null : _toInt(rank),
      entries: rawEntries is List
          ? rawEntries.whereType<Map>().map((item) =>
              LeaderboardEntry.fromJson(Map<String, dynamic>.from(item))).toList()
          : <LeaderboardEntry>[],
    );
  }

  String stageName(String language) => language == 'en' ? nameEn : nameAr;
}

class LeaderboardEntry {
  final int rank;
  final String displayName;
  final int solvedProblems;
  final int points;
  final int firstTryCorrect;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.solvedProblems,
    required this.points,
    required this.firstTryCorrect,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _toInt(json['Rank'] ?? json['rank']),
      displayName: (json['DisplayName'] ?? json['displayName'] ?? '').toString(),
      solvedProblems: _toInt(json['SolvedProblems'] ?? json['solvedProblems']),
      points: _toInt(json['Points'] ?? json['points']),
      firstTryCorrect: _toInt(json['FirstTryCorrect'] ?? json['firstTryCorrect']),
      isCurrentUser: json['IsCurrentUser'] == true || json['isCurrentUser'] == true,
    );
  }
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
