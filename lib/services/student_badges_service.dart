import '../core/network/api_client.dart';

class MathBadge {
  const MathBadge({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.requiredSolved,
    required this.earned,
    required this.currentProgress,
  });
  final String key;
  final String titleAr;
  final String titleEn;
  final int requiredSolved;
  final bool earned;
  final int currentProgress;

  factory MathBadge.fromJson(Map<String, dynamic> json) => MathBadge(
        key: json['Key'] as String? ?? '',
        titleAr: json['TitleAr'] as String? ?? '',
        titleEn: json['TitleEn'] as String? ?? '',
        requiredSolved: (json['RequiredSolved'] as num).toInt(),
        earned: json['Earned'] == true,
        currentProgress: (json['CurrentProgress'] as num).toInt(),
      );
}

class StudentBadges {
  const StudentBadges({
    required this.uniqueSolved,
    required this.earnedCount,
    required this.totalBadges,
    required this.nextMilestone,
    required this.badges,
  });

  final int uniqueSolved;
  final int earnedCount;
  final int totalBadges;
  final int? nextMilestone;
  final List<MathBadge> badges;

  factory StudentBadges.fromJson(Map<String, dynamic> json) => StudentBadges(
        uniqueSolved: (json['UniqueSolved'] as num).toInt(),
        earnedCount: (json['EarnedCount'] as num).toInt(),
        totalBadges: (json['TotalBadges'] as num).toInt(),
        nextMilestone: (json['NextMilestone'] as num?)?.toInt(),
        badges: (json['Badges'] as List<dynamic>? ?? const [])
            .map((item) => MathBadge.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(growable: false),
      );
}

class StudentBadgesService {
  const StudentBadgesService(this._api);

  final ApiClient _api;

  Future<StudentBadges> getBadges() async {
    final response = await _api.get('/users/achievements');
    final payload = Map<String, dynamic>.from(response.data as Map);
    final data = Map<String, dynamic>.from(
      (payload['Data'] ?? payload) as Map,
    );
    return StudentBadges.fromJson(data);
  }
}
