import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

final favoritesProvider = FutureProvider<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  final stageId = ref.watch(authProvider.select((state) => state.user?.currentStageId));
  if (stageId == null || stageId <= 0) return [];
  final all = await ref.watch(problemsRepositoryProvider).getFavorites(languageCode);
  return all.where((problem) => problem.stageId == stageId).toList();
});

final solvedProvider = FutureProvider<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  final stageId = ref.watch(authProvider.select((state) => state.user?.currentStageId));
  if (stageId == null || stageId <= 0) return [];
  final all = await ref.watch(problemsRepositoryProvider).getSolved(languageCode);
  return all.where((problem) => problem.stageId == stageId).toList();
});
