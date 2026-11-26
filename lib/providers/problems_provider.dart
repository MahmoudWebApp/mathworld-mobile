import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem_search.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';
import 'auth_provider.dart';

export '../models/problem_search.dart';

/// Searches localized problems with pagination and optional filters.
final problemsProvider =
    FutureProvider.autoDispose.family<ProblemSearchResult, ProblemSearchParams>(
  (ref, params) async {
    ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,plan:s.user?.subscriptionType)));
    final languageCode = ref.watch(
      settingsProvider.select((settings) => settings.languageCode),
    );
    final lease=ref.keepAlive();
    final timer=Timer(const Duration(seconds:30),lease.close);
    ref.onDispose(timer.cancel);
    try { return await ref.watch(problemsRepositoryProvider).search(params, languageCode); }
    catch (_) { lease.close(); rethrow; }
  },
);
