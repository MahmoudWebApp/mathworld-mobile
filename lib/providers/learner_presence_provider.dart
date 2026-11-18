import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/learner_presence_service.dart';
import 'repositories_provider.dart';

final learnerPresenceServiceProvider = Provider<LearnerPresenceService>(
  (ref) => LearnerPresenceService(ref.watch(apiClientProvider)),
);
