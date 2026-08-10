import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final Set<int> busyProblemIds;

  const ErrorNotebookState({
    required this.problems,
    this.includeArchived = false,
    this.busyProblemIds = const {},
  });

  const ErrorNotebookState.loading()
      : this(problems: const AsyncValue.loading());

  ErrorNotebookState copyWith({
    AsyncValue<List<ErrorNotebookProblem>>? problems,
    bool? includeArchived,
    Set<int>? busyProblemIds,
  }) {
    return ErrorNotebookState(
      problems: problems ?? this.problems,
      includeArchived: includeArchived ?? this.includeArchived,
      busyProblemIds: busyProblemIds ?? this.busyProblemIds,
    );
  }
}

final errorNotebookProvider = StateNotifierProvider.autoDispose<
    ErrorNotebookNotifier, ErrorNotebookState>((ref) {
  final languageCode = ref.watch(
    settingsProvider.select((settings) => settings.languageCode),
  );

  return ErrorNotebookNotifier(
    repository: ref.watch(problemsRepositoryProvider),
    languageCode: languageCode,
  );
});

/// Coordinates loading, filtering, archiving, and restoring notebook items.
class ErrorNotebookNotifier extends StateNotifier<ErrorNotebookState> {
  final ProblemsRepository _repository;
  final String _languageCode;

  ErrorNotebookNotifier({
    required ProblemsRepository repository,
    required String languageCode,
  })  : _repository = repository,
        _languageCode = languageCode,
        super(const ErrorNotebookState.loading()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(problems: const AsyncValue.loading());

    try {
      final problems = await _repository.getErrorNotebook(
        languageCode: _languageCode,
        includeArchived: state.includeArchived,
      );
      state = state.copyWith(problems: AsyncValue.data(problems));
    } catch (error, stackTrace) {
      state = state.copyWith(
        problems: AsyncValue.error(error, stackTrace),
      );
    }
  }

  Future<void> setIncludeArchived(bool value) async {
    if (state.includeArchived == value) {
      return;
    }

    state = state.copyWith(includeArchived: value);
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
      final serverValue = await _repository.setErrorNotebookArchive(
        problemId: problemId,
        isArchived: isArchived,
      );

      final List<ErrorNotebookProblem> current =
          state.problems.valueOrNull ?? <ErrorNotebookProblem>[];
      final updated = current
          .map(
            (problem) => problem.id == problemId
                ? problem.copyWith(isArchived: serverValue)
                : problem,
          )
          .where(
            (problem) => state.includeArchived || !problem.isArchived,
          )
          .toList();

      state = state.copyWith(problems: AsyncValue.data(updated));
    } finally {
      final nextBusy = {...state.busyProblemIds}..remove(problemId);
      state = state.copyWith(busyProblemIds: nextBusy);
    }
  }
}
