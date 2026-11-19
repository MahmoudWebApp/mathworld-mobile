import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_challenge.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';
import 'stage_category_access_provider.dart';

/// Recreates the daily-practice request after login or stage switching.
/// The server decides which published, currently unlocked problems are safe.
final dailyChallengeProvider = FutureProvider.autoDispose<DailyChallenge?>((ref) async {
  final user = ref.watch(authProvider.select((state) => state.user));
  final stageId = user?.currentStageId;
  if (user?.role != 'Student' || stageId == null || stageId <= 0) {
    return null;
  }
  // The daily challenge is an upgrade benefit. Fail closed while account
  // entitlement is loading or unavailable; Free still has unlimited practice
  // in the two categories selected for their stage.
  final membership = ref.watch(studentPremiumProvider);
  if (membership.valueOrNull != true) return null;
  return ref.watch(dashboardRepositoryProvider).getDailyChallenge(stageId);
});
