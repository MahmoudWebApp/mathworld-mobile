import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

final favoritesProvider = FutureProvider<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  return ref.watch(problemsRepositoryProvider).getFavorites(languageCode);
});

final solvedProvider = FutureProvider<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  return ref.watch(problemsRepositoryProvider).getSolved(languageCode);
});
