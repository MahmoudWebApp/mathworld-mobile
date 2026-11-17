import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_notification.dart';
import '../repositories/notifications_repository.dart';
import 'repositories_provider.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

// Keep the visible bell reasonably fresh without requiring FCM or SignalR.
final notificationsUnreadCountProvider = FutureProvider<int>((ref) async {
  final timer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final notificationsPageProvider =
    FutureProvider.family<StudentNotificationPage, int>((ref, page) {
  return ref.watch(notificationsRepositoryProvider).list(page: page);
});
