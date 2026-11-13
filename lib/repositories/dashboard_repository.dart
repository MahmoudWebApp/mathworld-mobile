import '../config/constants.dart';
import '../core/network/api_envelope.dart';
import '../models/dashboard_stats.dart';
import '../models/learning_journey.dart';
import '../models/stage_daily_quota.dart';
import '../models/leaderboard.dart';
import '../core/network/api_client.dart';

/// Loads user dashboard and public platform statistics.
class DashboardRepository {
  final ApiClient _apiService;

  const DashboardRepository(this._apiService);

  Future<DashboardStats> getDashboard(String languageCode) async {
    final response = await _apiService.get(ApiConstants.userDashboard);
    return DashboardStats.fromJson(
      ApiEnvelope.map(response.data),
      languageCode: languageCode,
    );
  }

  Future<LearningJourney> getJourney(int stageId) async {
    final response = await _apiService.get(
      ApiConstants.userJourney,
      queryParameters: {'stageId': stageId},
    );
    return LearningJourney.fromJson(ApiEnvelope.map(response.data));
  }

  Future<StageDailyQuota> getDailyQuota(int stageId) async {
    final response = await _apiService.get(
      ApiConstants.userDailyQuota,
      queryParameters: {'stageId': stageId},
    );
    return StageDailyQuota.fromJson(ApiEnvelope.map(response.data));
  }

  Future<LeaderboardData> getLeaderboard({
    required int stageId,
    required String period,
    required int page,
  }) async {
    final response = await _apiService.get(
      ApiConstants.userLeaderboard,
      queryParameters: {
        'stageId': stageId,
        'period': period,
        'page': page,
        'pageSize': 20,
      },
    );
    return LeaderboardData.fromJson(ApiEnvelope.map(response.data));
  }

  Future<PlatformStats> getPlatformStats() async {
    final response = await _apiService.get(ApiConstants.stats);
    return PlatformStats.fromJson(ApiEnvelope.map(response.data));
  }
}
