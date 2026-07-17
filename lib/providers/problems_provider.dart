import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem_search.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

export '../models/problem_search.dart';

/// Searches localized problems with pagination and optional filters.
final problemsProvider =
    FutureProvider.family<ProblemSearchResult, ProblemSearchParams>(
  (ref, params) async {
    final languageCode = ref.watch(
      settingsProvider.select((settings) => settings.languageCode),
    );
    return ref.watch(problemsRepositoryProvider).search(params, languageCode);
  },
);
