import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';
import '../models/premium_progress_report.dart';

/// The backend checks the authenticated user's Premium entitlement.
class PremiumReportsRepository {
  final ApiClient _api;
  const PremiumReportsRepository(this._api);

  Future<PremiumProgressReport> getReport({int? stageId}) async {
    final response = await _api.get(
      '/users/premium-report',
      queryParameters: stageId == null ? null : {'stageId': stageId},
    );
    return PremiumProgressReport.fromJson(ApiEnvelope.map(response.data));
  }
}
