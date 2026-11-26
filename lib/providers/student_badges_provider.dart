import 'dart:async';
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
    // A lazy home section can leave the viewport during an in-flight read.
    // Retain the same account-scoped result briefly instead of restarting it.
    final lease=ref.keepAlive();
    final expiry=Timer(const Duration(seconds:60),lease.close);
    ref.onDispose(expiry.cancel);
    return ref.watch(studentBadgesServiceProvider).getBadges();
  },
);
