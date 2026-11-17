import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_challenge.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

/// Recreates the daily-practice request after login or stage switching.
/// The server decides which published, currently unlocked problems are safe.
final dailyChallengeProvider = FutureProvider.autoDispose<DailyChallenge?>((ref) async {
  final user = ref.watch(authProvider.select((state) => state.user));
  final stageId = user?.currentStageId;
  if (user?.role != 'Student' || stageId == null || stageId <= 0) {
    return null;
  }
  return ref.watch(dashboardRepositoryProvider).getDailyChallenge(stageId);
});
