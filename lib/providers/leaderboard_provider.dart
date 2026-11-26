import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

typedef LeaderboardFilter = ({int stageId, String period, int page});

/// Fetches authenticated stage rankings; nothing is computed on device.
final leaderboardProvider =
    FutureProvider.autoDispose.family<LeaderboardData, LeaderboardFilter>(
  (ref, filter) async {
    final user=ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role,stage:s.user?.currentStageId)));
    if(user.id==null||user.role!='Student'||user.stage==null) {
      throw StateError('Choose a stage as a signed-in student.');
    }
    return ref.watch(dashboardRepositoryProvider).getLeaderboard(
          stageId: filter.stageId,
          period: filter.period,
          page: filter.page,
        );
  },
);
