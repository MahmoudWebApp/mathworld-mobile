import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_notification.dart';
import '../repositories/notifications_repository.dart';
import 'repositories_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsUnreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final notificationsPageProvider =
    FutureProvider.family<StudentNotificationPage, int>((ref, page) {
  return ref.watch(notificationsRepositoryProvider).list(page: page);
});
