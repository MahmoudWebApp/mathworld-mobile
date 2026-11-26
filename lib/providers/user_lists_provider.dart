import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

final favoritesProvider = FutureProvider.autoDispose<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId)));
  final stageId=account.stage;
  if(account.id==null||stageId==null||stageId<=0)return [];
  final all = await ref.watch(problemsRepositoryProvider).getFavorites(languageCode);
  return all.where((problem) => problem.stageId == stageId).toList();
});

final solvedProvider = FutureProvider.autoDispose<List<ProblemPreview>>((ref) async {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId)));
  final stageId=account.stage;
  if(account.id==null||stageId==null||stageId<=0)return [];
  final all = await ref.watch(problemsRepositoryProvider).getSolved(languageCode);
  return all.where((problem) => problem.stageId == stageId).toList();
});
