import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/problem.dart';
import '../core/errors/app_exception.dart';
import 'learning_tracks_provider.dart';
import 'problem_prefetch_provider.dart';
import 'auth_provider.dart';
import '../models/solution_preview.dart';
import '../repositories/problems_repository.dart';
import 'dashboard_provider.dart';
import 'daily_challenge_provider.dart';
import 'leaderboard_provider.dart';
import 'learning_journey_provider.dart';
import 'premium_analytics_provider.dart';
import 'student_badges_provider.dart';
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
  final SolutionPreview? solutionPreview;
  final bool isPreviewLoading;
  final bool isSubmitting;
  final bool isFavoriteBusy;
  final bool isRetryMode;

  const ProblemDetailsState({
    required this.problem,
    this.selectedOptionId,
    this.answerResult,
    this.solutionPreview,
    this.isPreviewLoading = false,
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
    SolutionPreview? solutionPreview,
    bool clearSolutionPreview = false,
    bool? isPreviewLoading,
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
      solutionPreview: clearSolutionPreview
          ? null
          : (solutionPreview ?? this.solutionPreview),
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
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

    // The first selection response is hydration, not a track switch.
    // The detail request already checks the current track on the server.
    // Recreate interaction state only after an actual selection change or
    // loss of a previously known selection; account changes still rebuild it.
    ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,role:s.user?.role,tier:s.user?.subscriptionType,status:s.status)));
    var lastSelection = ref.read(trackSelectionProvider).valueOrNull;
    ref.listen(trackSelectionProvider, (_, next) {
      if (next.isLoading) return;
      final current = next.hasError ? null : next.valueOrNull;
      final previous = lastSelection;
      lastSelection = current;
      if (previous != null &&
          (current == null || trackNumber(previous['TrackId']) != trackNumber(current['TrackId']))) {
        ref.invalidateSelf();
      }
    });
    return ProblemDetailsNotifier(
      // Consume a warm entry once; don't rebuild when the prefetch cache
      // itself is recreated during selection hydration.
      initialProblem:()=>ref.read(problemPrefetchProvider).take(problemId),
      repository: ref.watch(problemsRepositoryProvider),
      problemId: problemId,
      languageCode: languageCode,
      onAttemptCompleted: () {
        // Update stage progress and category completion immediately after
        // a successful submission, without a manual app restart.
        ref.invalidate(solvedProvider);
        ref.invalidate(dashboardProvider);
        // A successful API submission changes the stage rankings, journey,
        // achievements and today's solved state. Refresh these even when the
        // learner keeps the app open and never revisits the home tab.
        ref.invalidate(leaderboardProvider);
        ref.invalidate(learningJourneyProvider);
        ref.invalidate(dailyChallengeProvider);
        ref.invalidate(studentBadgesProvider);
        ref.invalidate(premiumAnalyticsProvider);
        ref.invalidate(problemsProvider);
        ref.invalidate(errorNotebookProvider);
        ref.invalidate(trackProgressProvider);
        ref.invalidate(trackPracticeProvider);
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
    Future<Problem?> Function()? initialProblem,
  })  : _repository = repository,
        _problemId = problemId,
        _languageCode = languageCode,
        _onAttemptCompleted = onAttemptCompleted,
        _onFavoriteChanged = onFavoriteChanged,
        super(const ProblemDetailsState.loading()) {
    load(initialProblem:initialProblem);
  }

  Future<void> load({Future<Problem?> Function()? initialProblem}) async {
    state = state.copyWith(
      problem: const AsyncValue.loading(),
      clearSolutionPreview: true,
      isPreviewLoading: false,
    );
    try {
      final warm = initialProblem==null?null:await initialProblem();
      if (!mounted) return;
      final problem = warm ?? await _repository.getProblem(_problemId, _languageCode);
      if (!mounted) return;
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
              solutionStructure:problem.solutionStructure,
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
      if (!mounted) return;
      state = state.copyWith(
        problem: AsyncValue.error(error, stackTrace),
      );
    }
  }

  /// Fetches an optional solution preview without submitting an answer.
  Future<void> previewSolution() async {
    if (state.isPreviewLoading || state.solutionPreview != null ||
        state.problem.valueOrNull == null) {
      return;
    }
    state = state.copyWith(isPreviewLoading: true);
    try {
      final preview = await _repository.previewSolution(_problemId);
      if (!mounted) return;
      state = state.copyWith(
        solutionPreview: preview,
        isPreviewLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isPreviewLoading: false);
      rethrow;
    }
  }

  /// Starts a new training attempt without changing the official first result.
  void startRetry() {
    final problem = state.problem.valueOrNull;
    if (problem == null || !problem.hasAttempted || !problem.canRetry || state.isSubmitting) {
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
    if (problem == null || !problem.hasAttempted || state.isSubmitting) {
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
              solutionStructure:problem.solutionStructure,
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
    state = state.copyWith(selectedOptionId: optionId, clearSelectedOption: optionId == null);
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
        practiceScopeId:problem.practiceScopeId,
        selectedOptionId: selectedOptionId,
        timeSpentSeconds: DateTime.now()
            .difference(startedAt)
            .inSeconds
            .clamp(1, 86400)
            .toInt(),
        languageCode: _languageCode,
      );

      if (!mounted) return;
      final updatedProblem = (state.problem.valueOrNull ?? problem).copyWith(
        isSolved: result.isSolved,
        hasAttempted: true,
        wasCorrect: result.isCorrect,
        selectedOptionId: result.selectedOptionId ?? selectedOptionId,
        solutionStructure:result.solutionStructure,
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
    } on AppException catch (error) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
      if (error.statusCode == 409) {
        // A different device may have switched the learner's practice scope.
        // Reload server-authoritative progress, never silently replay the answer.
        state = state.copyWith(clearSelectedOption: true, clearAnswerResult: true, isRetryMode: false);
        await load();
      }
      rethrow;
    } catch (_) {
      if (!mounted) return;
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

      if (!mounted) return;
      final updated = (state.problem.valueOrNull ?? problem).copyWith(isFavorite: serverValue);
      state = state.copyWith(
        problem: AsyncValue.data(updated),
        isFavoriteBusy: false,
      );
      _onFavoriteChanged();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isFavoriteBusy: false);
      rethrow;
    }
  }
}
