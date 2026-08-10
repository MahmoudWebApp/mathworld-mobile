import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import '../repositories/problems_repository.dart';
import 'dashboard_provider.dart';
import 'learning_provider.dart';
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
  final bool isRetryMode;

  const ProblemDetailsState({
    required this.problem,
    this.selectedOptionId,
    this.answerResult,
    this.isSubmitting = false,
    this.isFavoriteBusy = false,
    this.isRetryMode = false,
  });

  const ProblemDetailsState.loading()
      : this(problem: const AsyncValue.loading());

  ProblemDetailsState copyWith({
    AsyncValue<Problem>? problem,
    int? selectedOptionId,
    bool clearSelectedOption = false,
    AnswerResult? answerResult,
    bool clearAnswerResult = false,
    bool? isSubmitting,
    bool? isFavoriteBusy,
    bool? isRetryMode,
  }) {
    return ProblemDetailsState(
      problem: problem ?? this.problem,
      selectedOptionId: clearSelectedOption
          ? null
          : (selectedOptionId ?? this.selectedOptionId),
      answerResult:
          clearAnswerResult ? null : (answerResult ?? this.answerResult),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFavoriteBusy: isFavoriteBusy ?? this.isFavoriteBusy,
      isRetryMode: isRetryMode ?? this.isRetryMode,
    );
  }
}

final problemDetailsProvider = StateNotifierProvider.autoDispose
    .family<ProblemDetailsNotifier, ProblemDetailsState, int>(
  (ref, problemId) {
    final languageCode = ref.watch(
      settingsProvider.select((settings) => settings.languageCode),
    );

    return ProblemDetailsNotifier(
      repository: ref.watch(problemsRepositoryProvider),
      problemId: problemId,
      languageCode: languageCode,
      onAttemptCompleted: () {
        ref.invalidate(solvedProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(problemsProvider);
        ref.invalidate(problemAttemptHistoryProvider(problemId));
        ref.invalidate(errorNotebookProvider);
      },
      onFavoriteChanged: () {
        ref.invalidate(favoritesProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(problemsProvider);
      },
    );
  },
);

/// Coordinates loading, training retries, answer submission, and favorites.
class ProblemDetailsNotifier extends StateNotifier<ProblemDetailsState> {
  final ProblemsRepository _repository;
  final int _problemId;
  final String _languageCode;
  final void Function() _onAttemptCompleted;
  final void Function() _onFavoriteChanged;
  DateTime? _attemptStartedAt;

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
        super(const ProblemDetailsState.loading()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(problem: const AsyncValue.loading());
    try {
      final problem = await _repository.getProblem(_problemId, _languageCode);
      final restoredResult = problem.hasAttempted
          ? AnswerResult(
              isCorrect: problem.wasCorrect ??
                  problem.firstAttemptCorrect ??
                  problem.isSolved,
              isSolved: problem.isSolved,
              pointsEarned: 0,
              selectedOptionId: problem.selectedOptionId,
              correctOptionId: problem.correctOptionId,
              detailedSolution: problem.detailedSolution ?? '',
              youtubeSolutionUrl: problem.youtubeSolutionUrl,
              attemptNumber: 1,
              isOfficialAttempt: true,
              firstAttemptCorrect: problem.firstAttemptCorrect,
              bestTimeSeconds: problem.bestTimeSeconds,
              totalAttempts: problem.attemptCount,
              canRetry: problem.canRetry,
              masteryStatus: problem.masteryStatus,
              isInErrorNotebook: problem.isInErrorNotebook,
              nextReviewAt: problem.nextReviewAt,
            )
          : null;

      _attemptStartedAt = problem.hasAttempted ? null : DateTime.now();
      state = state.copyWith(
        problem: AsyncValue.data(problem),
        selectedOptionId: problem.selectedOptionId,
        clearSelectedOption: problem.selectedOptionId == null,
        answerResult: restoredResult,
        clearAnswerResult: restoredResult == null,
        isRetryMode: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        problem: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Starts a new training attempt without changing the official first result.
  void startRetry() {
    final problem = state.problem.valueOrNull;
    if (problem == null || !problem.hasAttempted || !problem.canRetry) {
      return;
    }

    _attemptStartedAt = DateTime.now();
    state = state.copyWith(
      clearSelectedOption: true,
      clearAnswerResult: true,
      isRetryMode: true,
    );
  }

  /// Cancels training mode and restores the official answer state.
  void cancelRetry() {
    final problem = state.problem.valueOrNull;
    if (problem == null || !problem.hasAttempted) {
      return;
    }

    _attemptStartedAt = null;
    state = state.copyWith(
      selectedOptionId: problem.selectedOptionId,
      answerResult: AnswerResult(
        isCorrect: problem.wasCorrect ??
            problem.firstAttemptCorrect ??
            problem.isSolved,
        isSolved: problem.isSolved,
        pointsEarned: 0,
        selectedOptionId: problem.selectedOptionId,
        correctOptionId: problem.correctOptionId,
        detailedSolution: problem.detailedSolution ?? '',
        youtubeSolutionUrl: problem.youtubeSolutionUrl,
        attemptNumber: 1,
        isOfficialAttempt: true,
        firstAttemptCorrect: problem.firstAttemptCorrect,
        bestTimeSeconds: problem.bestTimeSeconds,
        totalAttempts: problem.attemptCount,
        canRetry: problem.canRetry,
        masteryStatus: problem.masteryStatus,
        isInErrorNotebook: problem.isInErrorNotebook,
        nextReviewAt: problem.nextReviewAt,
      ),
      isRetryMode: false,
    );
  }

  void selectOption(int? optionId) {
    final problem = state.problem.valueOrNull;
    final canAnswer = problem != null &&
        (!problem.hasAttempted || state.isRetryMode) &&
        state.answerResult == null;
    if (!canAnswer || state.isSubmitting) {
      return;
    }
    state = state.copyWith(selectedOptionId: optionId);
  }

  Future<void> submitAnswer() async {
    final problem = state.problem.valueOrNull;
    final selectedOptionId = state.selectedOptionId;
    final canAnswer = problem != null &&
        (!problem.hasAttempted || state.isRetryMode) &&
        state.answerResult == null;
    if (!canAnswer || selectedOptionId == null || state.isSubmitting) {
      return;
    }

    final startedAt = _attemptStartedAt ?? DateTime.now();
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await _repository.submitAnswer(
        problemId: problem.id,
        selectedOptionId: selectedOptionId,
        timeSpentSeconds: DateTime.now()
            .difference(startedAt)
            .inSeconds
            .clamp(1, 86400)
            .toInt(),
        languageCode: _languageCode,
      );

      final updatedProblem = problem.copyWith(
        isSolved: result.isSolved,
        hasAttempted: true,
        wasCorrect: result.firstAttemptCorrect ?? problem.wasCorrect,
        selectedOptionId: result.isOfficialAttempt
            ? (result.selectedOptionId ?? selectedOptionId)
            : problem.selectedOptionId,
        correctOptionId: result.correctOptionId ?? problem.correctOptionId,
        attemptCount: result.totalAttempts,
        firstAttemptCorrect:
            result.firstAttemptCorrect ?? problem.firstAttemptCorrect,
        canRetry: result.canRetry,
        masteryStatus: result.masteryStatus,
        bestTimeSeconds: result.bestTimeSeconds,
        isInErrorNotebook: result.isInErrorNotebook,
        nextReviewAt: result.nextReviewAt,
        clearNextReviewAt: result.nextReviewAt == null,
        detailedSolution: result.detailedSolution.isNotEmpty
            ? result.detailedSolution
            : problem.detailedSolution,
        youtubeSolutionUrl:
            result.youtubeSolutionUrl ?? problem.youtubeSolutionUrl,
      );

      _attemptStartedAt = null;
      state = state.copyWith(
        problem: AsyncValue.data(updatedProblem),
        answerResult: result,
        isSubmitting: false,
        isRetryMode: false,
      );
      _onAttemptCompleted();
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<void> toggleFavorite() async {
    final problem = state.problem.valueOrNull;
    if (problem == null || state.isFavoriteBusy) {
      return;
    }

    final requestedValue = !problem.isFavorite;
    state = state.copyWith(isFavoriteBusy: true);

    try {
      final serverValue = await _repository.setFavorite(
        problemId: problem.id,
        isFavorite: requestedValue,
      );

      final updated = problem.copyWith(isFavorite: serverValue);
      state = state.copyWith(
        problem: AsyncValue.data(updated),
        isFavoriteBusy: false,
      );
      _onFavoriteChanged();
    } catch (_) {
      state = state.copyWith(isFavoriteBusy: false);
      rethrow;
    }
  }
}
