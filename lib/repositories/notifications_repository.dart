import '../config/constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';
import '../models/student_notification.dart';

/// Private student notifications; recipient is always resolved on the server.
class NotificationsRepository {
  final ApiClient _api;
  const NotificationsRepository(this._api);

  Future<StudentNotificationPage> list({int page = 1}) async {
    final result = await _api.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'pageSize': 20},
    );
    return StudentNotificationPage.fromJson(ApiEnvelope.map(result.data));
  }

  Future<int> unreadCount() async {
    final result = await _api.get('${ApiConstants.notifications}/unread-count');
    final data = ApiEnvelope.map(result.data);
    return (data['UnreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) async {
    await _api.put('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.put('${ApiConstants.notifications}/read-all');
  }
}
