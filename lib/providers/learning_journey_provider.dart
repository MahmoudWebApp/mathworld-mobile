import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learning_journey.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

/// Reloads when the signed-in user or the selected learning stage changes.
final learningJourneyProvider = FutureProvider<LearningJourney?>((ref) async {
  final user = ref.watch(authProvider.select((state) => state.user));
  final stageId = user?.currentStageId;
  if (user?.role != 'Student' || stageId == null) {
    return null;
  }
  return ref.watch(dashboardRepositoryProvider).getJourney(stageId);
});
