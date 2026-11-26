import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learning_journey.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

/// Reloads when the signed-in user or the selected learning stage changes.
final learningJourneyProvider = FutureProvider<LearningJourney?>((ref) async {
  final account = ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role,stageId:s.user?.currentStageId,premium:s.user?.subscriptionType)));
  final stageId = account.stageId;
  if (account.id==null || account.role != 'Student' || stageId == null) {
    return null;
  }
  return ref.watch(dashboardRepositoryProvider).getJourney(stageId);
});
