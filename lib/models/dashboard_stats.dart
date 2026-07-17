import 'problem.dart';

/// Represents localized dashboard statistics and recent user activity.
class DashboardStats {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String subscriptionType;
  final int solvedProblemsCount;
  final int favoriteProblemsCount;
  final int totalPoints;
  final int successRate;
  final DateTime? memberSince;
  final List<ProblemPreview> recentSolved;
  final List<ProblemPreview> recentFavorites;
  final List<RecentActivity> recentActivities;
  const DashboardStats({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.subscriptionType,
    required this.solvedProblemsCount,
    required this.favoriteProblemsCount,
    required this.totalPoints,
    required this.successRate,
    required this.memberSince,
    required this.recentSolved,
    required this.recentFavorites,
    required this.recentActivities,
  });
  factory DashboardStats.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    return DashboardStats(
      id: _int(json['Id'] ?? json['id']),
      fullName: _string(json['FullName'] ?? json['fullName']),
      email: _string(json['Email'] ?? json['email']),
      role: _string(json['Role'] ?? json['role']),
      subscriptionType: _string(
        json['SubscriptionType'] ?? json['subscriptionType'],
      ),
      solvedProblemsCount: _int(
        json['SolvedProblemsCount'] ?? json['solvedProblemsCount'],
      ),
      favoriteProblemsCount: _int(
        json['FavoriteProblemsCount'] ?? json['favoriteProblemsCount'],
      ),
      totalPoints: _int(json['TotalPoints'] ?? json['totalPoints']),
      successRate: _int(json['SuccessRate'] ?? json['successRate']),
      memberSince: _date(json['MemberSince'] ?? json['memberSince']),
      recentSolved: _list(json['RecentSolved'] ?? json['recentSolved'])
          .map(
            (item) => ProblemPreview.fromJson(
              _map(item),
              languageCode: languageCode,
            ),
          )
          .toList(),
      recentFavorites: _list(json['RecentFavorites'] ?? json['recentFavorites'])
          .map(
            (item) => ProblemPreview.fromJson(
              _map(item),
              languageCode: languageCode,
            ),
          )
          .toList(),
      recentActivities:
          _list(json['RecentActivities'] ?? json['recentActivities'])
              .map(
                (item) => RecentActivity.fromJson(
                  _map(item),
                  languageCode: languageCode,
                ),
              )
              .toList(),
    );
  }
}

/// Represents a localized recent activity entry.
class RecentActivity {
  final int problemId;
  final String title;
  final String categoryName;
  final DateTime? solvedAt;
  const RecentActivity({
    required this.problemId,
    required this.title,
    required this.categoryName,
    required this.solvedAt,
  });
  factory RecentActivity.fromJson(
    Map<String, dynamic> json, {
    String languageCode = 'ar',
  }) {
    return RecentActivity(
      problemId: _int(json['ProblemId'] ?? json['problemId']),
      title: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'Title',
        arabicKey: 'TitleAr',
        englishKey: 'TitleEn',
      ),
      categoryName: localizedString(
        json,
        languageCode: languageCode,
        localizedKey: 'CategoryName',
        arabicKey: 'CategoryNameAr',
        englishKey: 'CategoryNameEn',
      ),
      solvedAt: _date(json['SolvedAt'] ?? json['solvedAt']),
    );
  }
}

/// Represents public platform-wide statistics.
class PlatformStats {
  final int totalProblems;
  final int totalUsers;
  final int totalSolved;
  final int totalViews;
  const PlatformStats({
    required this.totalProblems,
    required this.totalUsers,
    required this.totalSolved,
    required this.totalViews,
  });
  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalProblems: _int(json['TotalProblems'] ?? json['totalProblems']),
      totalUsers: _int(json['TotalUsers'] ?? json['totalUsers']),
      totalSolved: _int(json['TotalSolved'] ?? json['totalSolved']),
      totalViews: _int(json['TotalViews'] ?? json['totalViews']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : const {};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];
int _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _string(dynamic value) => value?.toString().trim() ?? '';
DateTime? _date(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '');
}
