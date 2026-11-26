import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/student_badges_service.dart';
import 'repositories_provider.dart';
import 'auth_provider.dart';

final studentBadgesServiceProvider = Provider<StudentBadgesService>(
  (ref) => StudentBadgesService(ref.watch(apiClientProvider)),
);

final studentBadgesProvider = FutureProvider.autoDispose<StudentBadges>(
  (ref) {
    ref.watch(authProvider.select((s)=>(id:s.user?.id,stageId:s.user?.currentStageId,premium:s.user?.subscriptionType)));
    return ref.watch(studentBadgesServiceProvider).getBadges();
  },
);
