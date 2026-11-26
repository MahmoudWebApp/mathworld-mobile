import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import 'auth_provider.dart';

import '../models/problem.dart';
import '../repositories/problems_repository.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

/// Loads the complete attempt history for a single problem.
final problemAttemptHistoryProvider = FutureProvider.autoDispose
    .family<ProblemAttemptHistory, int>((ref, problemId) async {
  return ref.watch(problemsRepositoryProvider).getAttemptHistory(problemId);
});

/// Stores error notebook data, archived visibility, and pending actions.
class ErrorNotebookState {
  final AsyncValue<List<ErrorNotebookProblem>> problems;
  final bool includeArchived;
  final bool dueOnly;
  final int page, total, dueCount;
  int get totalPages => (total+AppConstants.pageSize-1)~/AppConstants.pageSize;
  final Set<int> busyProblemIds;

  const ErrorNotebookState({
    required this.problems,
    this.includeArchived = false,
    this.dueOnly=false,this.page=1,this.total=0,this.dueCount=0,
    this.busyProblemIds = const {},
  });

  const ErrorNotebookState.loading()
      : this(problems: const AsyncValue.loading());

  ErrorNotebookState copyWith({
    AsyncValue<List<ErrorNotebookProblem>>? problems,
    bool? includeArchived,
    bool? dueOnly,int? page,int? total,int? dueCount,
    Set<int>? busyProblemIds,
  }) {
    return ErrorNotebookState(
      problems: problems ?? this.problems,
      includeArchived: includeArchived ?? this.includeArchived,
      dueOnly:dueOnly??this.dueOnly,page:page??this.page,total:total??this.total,dueCount:dueCount??this.dueCount,
      busyProblemIds: busyProblemIds ?? this.busyProblemIds,
    );
  }
}

final errorNotebookProvider = StateNotifierProvider.autoDispose<
    ErrorNotebookNotifier, ErrorNotebookState>((ref) {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );

  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,plan:s.user?.subscriptionType)));
  return ErrorNotebookNotifier(
    stageId:account.id==null?null:account.stage,
    repository: ref.watch(problemsRepositoryProvider),
    languageCode: languageCode,
  );
});

/// Coordinates loading, filtering, archiving, and restoring notebook items.
class ErrorNotebookNotifier extends StateNotifier<ErrorNotebookState> {
  final ProblemsRepository _repository;
  final String _languageCode;
  final int? stageId;
  int _loadRevision = 0;

  ErrorNotebookNotifier({
    required ProblemsRepository repository,
    required String languageCode,
    this.stageId,
  })  : _repository = repository,
        _languageCode = languageCode,
        super(const ErrorNotebookState.loading()) {
    load();
  }

  Future<void> load() async {
    final revision = ++_loadRevision;
    state = state.copyWith(problems: const AsyncValue.loading());

    try {
      if(stageId==null||stageId!<=0){
        if(mounted&&revision==_loadRevision)state=state.copyWith(problems:const AsyncValue.data([]),total:0,dueCount:0);
        return;
      }
      final result=await _repository.getErrorNotebookPage(
        languageCode:_languageCode,includeArchived:state.includeArchived,
        stageId:stageId!,dueOnly:state.dueOnly,page:state.page,
      );
      if(!mounted||revision!=_loadRevision)return;
      final last=((result.total+AppConstants.pageSize-1)~/AppConstants.pageSize).clamp(1,10000).toInt();
      if(state.page>last){state=state.copyWith(page:last);await load();return;}
      state=state.copyWith(problems:AsyncValue.data(result.items),total:result.total,dueCount:result.dueCount);
    } catch (error, stackTrace) {
      if (!mounted || revision != _loadRevision) return;
      state = state.copyWith(
        problems: AsyncValue.error(error, stackTrace),
      );
    }
  }

  Future<void> setIncludeArchived(bool value) async {
    if (state.includeArchived == value) {
      return;
    }

    state = state.copyWith(includeArchived: value,dueOnly:false,page:1);
    await load();
  }

  Future<void> setDueOnly(bool value) async {
    if(state.dueOnly==value)return;
    state=state.copyWith(dueOnly:value,page:1);
    await load();
  }
  Future<void> setPage(int page) async {
    if(page==state.page||page<1||page>state.totalPages)return;
    state=state.copyWith(page:page);
    await load();
  }

  Future<void> setArchived({
    required int problemId,
    required bool isArchived,
  }) async {
    if (state.busyProblemIds.contains(problemId)) {
      return;
    }

    state = state.copyWith(
      busyProblemIds: {...state.busyProblemIds, problemId},
    );

    try {
      await _repository.setErrorNotebookArchive(
        problemId: problemId,
        isArchived: isArchived,
      );

      if (!mounted) return;
      await load();
    } finally {
      if (mounted) {
        final nextBusy = {...state.busyProblemIds}..remove(problemId);
        state = state.copyWith(busyProblemIds: nextBusy);
      }
    }
  }
}
