import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';
import 'auth_provider.dart';

/// Loads the localized user dashboard.
final dashboardProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,plan:s.user?.subscriptionType)));
  if(account.id==null)throw StateError('No authenticated account');
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  final repository = ref.watch(dashboardRepositoryProvider);
  // Reuse the same account-scoped response during short tab switches.
  // Auth/stage/plan/locale changes and explicit mutation invalidations still
  // dispose the provider. Failed requests are never retained.
  final lease = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 20), lease.close);
  ref.onDispose(timer.cancel);
  try {
    return await repository.getDashboard(languageCode);
  } catch (_) {
    lease.close();
    rethrow;
  }
});
