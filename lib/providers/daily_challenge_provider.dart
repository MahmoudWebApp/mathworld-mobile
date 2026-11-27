import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_challenge.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';
import 'stage_category_access_provider.dart';
import 'learning_journey_provider.dart';

/// Recreates the daily-practice request after login or stage switching.
/// The server decides which published, currently unlocked problems are safe.
final dailyChallengeProvider = FutureProvider.autoDispose<DailyChallenge?>((ref) async {
  final account = ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role,stageId:s.user?.currentStageId)));
  final stageId = account.stageId;
  if (account.id==null || account.role != 'Student' || stageId == null || stageId <= 0) {
    return null;
  }
  // The daily challenge is an upgrade benefit. Fail closed while account
  // entitlement is loading or unavailable; Free still has unlimited practice
  // in the two categories selected for their stage.
  final membership = await ref.watch(studentPremiumProvider.future);
  if (membership != true) return null;
  final journey=await ref.watch(learningJourneyProvider.future);
  if(journey?.learningSessionsEnabled==true)return null;
  return ref.watch(dashboardRepositoryProvider).getDailyChallenge(stageId);
});
