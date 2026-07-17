import '../config/constants.dart';
import '../core/network/api_envelope.dart';
import '../models/dashboard_stats.dart';
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

  Future<PlatformStats> getPlatformStats() async {
    final response = await _apiService.get(ApiConstants.stats);
    return PlatformStats.fromJson(ApiEnvelope.map(response.data));
  }
}
