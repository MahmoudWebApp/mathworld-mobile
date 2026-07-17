import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

/// Loads the localized user dashboard.
final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  return ref.watch(dashboardRepositoryProvider).getDashboard(languageCode);
});
