import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stage_daily_quota.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

/// Backend is the single source of truth across Flutter and Next.js.
final stageDailyQuotaProvider =
    FutureProvider.autoDispose.family<StageDailyQuota, int>(
  (ref, stageId) async {
    final user = ref.watch(authProvider.select((value) => value.user));
    if (user == null || user.role != 'Student' || stageId <= 0) {
      throw StateError('Sign in as a student and choose a stage.');
    }
    return ref.watch(dashboardRepositoryProvider).getDailyQuota(stageId);
  },
);
