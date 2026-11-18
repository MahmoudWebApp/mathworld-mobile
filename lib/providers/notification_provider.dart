import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_api_service.dart';
import 'repositories_provider.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>(
  (ref) => NotificationApiService(ref.watch(apiClientProvider)),
);

final notificationInboxProvider = FutureProvider.autoDispose<NotificationInbox>(
  (ref) => ref.watch(notificationApiServiceProvider).getInbox(),
);

const int notificationPageSize = 30;

/// A page of the same JWT-owned 30-day history used by the compact bell.
/// The bell continues using the first page without changing its provider.
final notificationPageProvider =
    FutureProvider.autoDispose.family<NotificationInbox, int>(
  (ref, page) {
    if (page < 0 || page * notificationPageSize > 10000) {
      throw ArgumentError.value(page, 'page', 'Invalid inbox page');
    }
    return ref.watch(notificationApiServiceProvider).getInbox(
      take: notificationPageSize,
      skip: page * notificationPageSize,
    );
  },
);
