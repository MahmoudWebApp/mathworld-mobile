import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/premium_analytics_service.dart';
import 'repositories_provider.dart';

final premiumAnalyticsServiceProvider = Provider<PremiumAnalyticsService>(
  (ref) => PremiumAnalyticsService(ref.watch(apiClientProvider)),
);

final premiumAnalyticsProvider = FutureProvider.autoDispose<PremiumAnalyticsReport>(
  (ref) => ref.watch(premiumAnalyticsServiceProvider).getReport(),
);
