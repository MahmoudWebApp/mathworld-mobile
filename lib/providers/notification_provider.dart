import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_api_service.dart';
import 'repositories_provider.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>(
  (ref) => NotificationApiService(ref.watch(apiClientProvider)),
);

final notificationInboxProvider = FutureProvider.autoDispose<NotificationInbox>(
  (ref) => ref.watch(notificationApiServiceProvider).getInbox(),
);
