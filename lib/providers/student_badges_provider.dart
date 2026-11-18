import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/student_badges_service.dart';
import 'repositories_provider.dart';

final studentBadgesServiceProvider = Provider<StudentBadgesService>(
  (ref) => StudentBadgesService(ref.watch(apiClientProvider)),
);

final studentBadgesProvider = FutureProvider.autoDispose<StudentBadges>(
  (ref) => ref.watch(studentBadgesServiceProvider).getBadges(),
);
