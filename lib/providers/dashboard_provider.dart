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
  return ref.watch(dashboardRepositoryProvider).getDashboard(languageCode);
});
