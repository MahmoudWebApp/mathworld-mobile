import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import '../repositories/problems_repository.dart';
import 'dashboard_provider.dart';
import 'problems_provider.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';
import 'user_lists_provider.dart';

/// Stores the complete interaction state for a single problem.
class ProblemDetailsState {
  final AsyncValue<Problem> problem;
  final int? selectedOptionId;
  final AnswerResult? answerResult;
  final bool isSubmitting;
  final bool isFavoriteBusy;

  const ProblemDetailsState({
    required this.problem,
    this.selectedOptionId,
    this.answerResult,
    this.isSubmitting = false,
    this.isFavoriteBusy = false,
  });

  const ProblemDetailsState.loading()
      : this(
          problem: const AsyncValue.loading(),
        );

  ProblemDetailsState copyWith({
    AsyncValue<Problem>? problem,
    int? selectedOptionId,
    bool clearSelectedOption = false,
    AnswerResult? answerResult,
    bool clearAnswerResult = false,
    bool? isSubmitting,
    bool? isFavoriteBusy,
  }) {
    return ProblemDetailsState(
      problem: problem ?? this.problem,
      selectedOptionId: clearSelectedOption
          ? null
          : selectedOptionId ?? this.selectedOptionId,
      answerResult:
          clearAnswerResult ? null : answerResult ?? this.answerResult,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFavoriteBusy: isFavoriteBusy ?? this.isFavoriteBusy,
    );
  }
}

final problemDetailsProvider = StateNotifierProvider.autoDispose
    .family<ProblemDetailsNotifier, ProblemDetailsState, int>(
  (ref, problemId) {
    final languageCode = ref.watch(
      settingsProvider.select(
        (settings) => settings.languageCode,
      ),
    );

    return ProblemDetailsNotifier(
      repository: ref.watch(
        problemsRepositoryProvider,
      ),
      problemId: problemId,
      languageCode: languageCode,
      onAttemptCompleted: () {
        ref.invalidate(solvedProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(problemsProvider);
      },
      onFavoriteChanged: () {
        ref.invalidate(favoritesProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(problemsProvider);
      },
    );
  },
);

/// Coordinates loading, selection, answer submission, and favorites.
class ProblemDetailsNotifier extends StateNotifier<ProblemDetailsState> {
  final ProblemsRepository _repository;
  final int _problemId;
  final String _languageCode;
  final void Function() _onAttemptCompleted;
  final void Function() _onFavoriteChanged;

  final DateTime _openedAt = DateTime.now();

  ProblemDetailsNotifier({
    required ProblemsRepository repository,
    required int problemId,
    required String languageCode,
    required void Function() onAttemptCompleted,
    required void Function() onFavoriteChanged,
  })  : _repository = repository,
        _problemId = problemId,
        _languageCode = languageCode,
        _onAttemptCompleted = onAttemptCompleted,
        _onFavoriteChanged = onFavoriteChanged,
        super(
          const ProblemDetailsState.loading(),
        ) {
    load();
  }

  /// Loads the problem and restores a previously submitted answer.
  Future<void> load() async {
    state = state.copyWith(
      problem: const AsyncValue.loading(),
    );

    try {
      final problem = await _repository.getProblem(
        _problemId,
        _languageCode,
      );

      state = ProblemDetailsState(
        problem: AsyncValue.data(problem),
        selectedOptionId: problem.selectedOptionId,
        answerResult: _restoreAnswerResult(problem),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        problem: AsyncValue.error(
          error,
          stackTrace,
        ),
      );
    }
  }

  /// Reconstructs the answer result when a previously attempted
  /// problem is opened again.
  AnswerResult? _restoreAnswerResult(
    Problem problem,
  ) {
    if (!problem.hasAttempted) {
      return null;
    }

    final wasCorrect = problem.wasCorrect ?? problem.isSolved;

    return AnswerResult(
      isCorrect: wasCorrect,
      isSolved: problem.isSolved,
      pointsEarned: wasCorrect ? problem.points : 0,
      selectedOptionId: problem.selectedOptionId,
      correctOptionId: problem.correctOptionId,
      detailedSolution: problem.detailedSolution ?? '',
      youtubeSolutionUrl: problem.youtubeSolutionUrl,
    );
  }

  /// Selects an option when the student has not submitted an answer yet.
  void selectOption(int? optionId) {
    final problem = state.problem.valueOrNull;

    if (problem == null ||
        problem.hasAttempted ||
        state.answerResult != null ||
        state.isSubmitting) {
      return;
    }

    state = state.copyWith(
      selectedOptionId: optionId,
    );
  }

  /// Submits the selected answer to the backend.
  Future<void> submitAnswer() async {
    final problem = state.problem.valueOrNull;

    final selectedOptionId = state.selectedOptionId;

    if (problem == null ||
        selectedOptionId == null ||
        state.isSubmitting ||
        problem.hasAttempted ||
        state.answerResult != null) {
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
    );

    try {
      final result = await _repository.submitAnswer(
        problemId: problem.id,
        selectedOptionId: selectedOptionId,
        timeSpentSeconds: DateTime.now()
            .difference(_openedAt)
            .inSeconds
            .clamp(1, 86400)
            .toInt(),
        languageCode: _languageCode,
      );

      final updatedProblem = problem.copyWith(
        isSolved: result.isSolved,
        hasAttempted: true,
        selectedOptionId: result.selectedOptionId ?? selectedOptionId,
        correctOptionId: result.correctOptionId,
        wasCorrect: result.isCorrect,
        detailedSolution: result.detailedSolution.isNotEmpty
            ? result.detailedSolution
            : problem.detailedSolution,
        youtubeSolutionUrl:
            result.youtubeSolutionUrl ?? problem.youtubeSolutionUrl,
      );

      state = state.copyWith(
        problem: AsyncValue.data(
          updatedProblem,
        ),
        selectedOptionId: result.selectedOptionId ?? selectedOptionId,
        answerResult: result,
        isSubmitting: false,
      );

      _onAttemptCompleted();
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
      );

      rethrow;
    }
  }

  /// Adds or removes the problem from the user's favorites.
  Future<void> toggleFavorite() async {
    final problem = state.problem.valueOrNull;

    if (problem == null || state.isFavoriteBusy) {
      return;
    }

    final requestedValue = !problem.isFavorite;

    state = state.copyWith(
      isFavoriteBusy: true,
    );

    try {
      final serverValue = await _repository.setFavorite(
        problemId: problem.id,
        isFavorite: requestedValue,
      );

      final updated = problem.copyWith(
        isFavorite: serverValue,
      );

      state = state.copyWith(
        problem: AsyncValue.data(updated),
        isFavoriteBusy: false,
      );

      _onFavoriteChanged();
    } catch (_) {
      state = state.copyWith(
        isFavoriteBusy: false,
      );

      rethrow;
    }
  }
}
