import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/problem.dart';
import '../../providers/learning_provider.dart';
import '../../providers/problem_details_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/daily_quota_card.dart';
import '../../widgets/rich_math_text.dart';
import '../../widgets/geometry_diagram.dart';
import '../../widgets/premium_solution_panel.dart';
import '../../services/premium_api_service.dart';
import '../../services/geometry_api_service.dart';
import '../../services/api_service.dart';

/// Displays one problem, its learning summary, and all recorded attempts.
class ProblemDetailsScreen extends ConsumerStatefulWidget {
  const ProblemDetailsScreen({super.key});

  @override
  ConsumerState<ProblemDetailsScreen> createState() =>
      _ProblemDetailsScreenState();
}

class _ProblemDetailsScreenState extends ConsumerState<ProblemDetailsScreen> {
  bool _autoRetryTriggered = false;

  ({int? problemId, bool retry}) _readArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is int) {
      return (problemId: arguments, retry: false);
    }
    if (arguments is Map) {
      final rawId = arguments['problemId'] ?? arguments['id'];
      final id = rawId is int ? rawId : int.tryParse('$rawId');
      return (
        problemId: id,
        retry: arguments['retry'] == true,
      );
    }
    return (problemId: null, retry: false);
  }

  @override
  Widget build(BuildContext context) {
    final routeArguments = _readArguments();
    final problemId = routeArguments.problemId;
    if (problemId == null) {
      return Scaffold(
        body: AppErrorView(
          message: 'invalid_route_arguments'.tr(),
          onRetry: () => Navigator.maybePop(context),
        ),
      );
    }

    final state = ref.watch(problemDetailsProvider(problemId));
    final notifier = ref.read(problemDetailsProvider(problemId).notifier);
    final loadedProblem = state.problem.valueOrNull;
    final historyState = loadedProblem?.hasAttempted == true
        ? ref.watch(problemAttemptHistoryProvider(problemId))
        : null;

    if (routeArguments.retry &&
        !_autoRetryTriggered &&
        loadedProblem?.hasAttempted == true &&
        loadedProblem?.canRetry == true) {
      _autoRetryTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.startRetry();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('problem_details'.tr())),
      body: MathBackground(
        child: state.problem.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: notifier.load,
          ),
          data: (problem) => _ProblemContent(
            problem: problem,
            state: state,
            historyState: historyState,
            onOptionChanged: notifier.selectOption,
            onSubmit: () => _runAction(context, notifier.submitAnswer),
            onStartRetry: notifier.startRetry,
            onCancelRetry: notifier.cancelRetry,
            onToggleFavorite: () =>
                _runAction(context, notifier.toggleFavorite),
          ),
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedErrorMessage(error))),
      );
    }
  }
}

class _ProblemContent extends ConsumerWidget {
  final Problem problem;
  final ProblemDetailsState state;
  final AsyncValue<ProblemAttemptHistory>? historyState;
  final ValueChanged<int?> onOptionChanged;
  final VoidCallback onSubmit;
  final VoidCallback onStartRetry;
  final VoidCallback onCancelRetry;
  final VoidCallback onToggleFavorite;

  const _ProblemContent({
    required this.problem,
    required this.state,
    required this.historyState,
    required this.onOptionChanged,
    required this.onSubmit,
    required this.onStartRetry,
    required this.onCancelRetry,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.locale.languageCode == 'ar';
    final canSelect = state.answerResult == null &&
        (!problem.hasAttempted || state.isRetryMode);
    final solution = _solutionText(problem, state);
    final videoUrl =
        state.answerResult?.youtubeSolutionUrl ?? problem.youtubeSolutionUrl;
    final history = historyState?.valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        DailyQuotaCard(stageId: problem.stageId, compact: true),
        const SizedBox(height: AppSpacing.md),
        _ProblemHeader(
          problem: problem,
          isArabic: isArabic,
          isFavoriteBusy: state.isFavoriteBusy,
          onToggleFavorite: onToggleFavorite,
        ),
        if (problem.hasAttempted) ...[
          const SizedBox(height: AppSpacing.lg),
          _LearningSummaryCard(problem: problem, history: history),
        ],
        if (state.isRetryMode) ...[
          const SizedBox(height: AppSpacing.lg),
          _RetryModeBanner(onCancel: onCancelRetry),
        ],
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: RichMathText(
            text: problem.questionText,
            isArabic: isArabic,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        _OptionalProblemDiagram(problemId: problem.id, isArabic: isArabic),
        if (!problem.hasAttempted && !state.isRetryMode) ...[
          const SizedBox(height: AppSpacing.md),
          PremiumSolutionPanel(
            problemId: problem.id,
            service: PremiumApiService(ApiService()),
            isArabic: isArabic,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          'choose_answer'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        RadioGroup<int>(
          groupValue: state.selectedOptionId,
          onChanged: canSelect ? onOptionChanged : (_) {},
          child: Column(
            children: [
              for (var index = 0; index < problem.options.length; index++) ...[
                _AnswerOptionCard(
                  option: problem.options[index],
                  isArabic: isArabic,
                  isSelected:
                      state.selectedOptionId == problem.options[index].id,
                  isCorrect: _isCorrectOption(problem.options[index], state),
                  isWrong: _isWrongOption(problem.options[index], state),
                  enabled: canSelect,
                ),
                if (index < problem.options.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        if (canSelect) ...[
          const SizedBox(height: AppSpacing.xl),
          PremiumButton(
            onPressed: state.selectedOptionId == null ||
                    state.isSubmitting
                ? null
                : onSubmit,
            label: state.isRetryMode
                ? 'submit_training_answer'.tr()
                : 'submit_answer'.tr(),
            trailingIcon: Icons.send_rounded,
            isLoading: state.isSubmitting,
            expand: true,
          ),
        ],
        if (state.answerResult != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _AnswerResultCard(result: state.answerResult!),
        ],
        if (problem.hasAttempted &&
            problem.canRetry &&
            !state.isRetryMode &&
            !state.isSubmitting) ...[
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            onPressed: onStartRetry,
            label: 'train_again'.tr(),
            leadingIcon: Icons.model_training_rounded,
            expand: true,
          ),
        ],
        if (solution.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'detailed_solution'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            border: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
            ),
            child: RichMathText(
              text: solution,
              isArabic: isArabic,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
        if (videoUrl?.trim().isNotEmpty == true && !state.isRetryMode) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _openVideo(context, videoUrl!),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text('video_solution'.tr()),
          ),
        ],
        if (historyState != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          _AttemptHistorySection(historyState: historyState!),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextButton.icon(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.list_alt_rounded),
          label: Text('back_to_problems'.tr()),
        ),
      ],
    );
  }

  bool _isCorrectOption(Option option, ProblemDetailsState state) {
    final result = state.answerResult;
    if (result == null) {
      return false;
    }
    if (result.correctOptionId != null) {
      return result.correctOptionId == option.id;
    }

    final correctText = result.correctOptionText;
    if (correctText != null && correctText.trim().isNotEmpty) {
      return _normalizeMathText(correctText) ==
          _normalizeMathText(option.latexCode);
    }

    return result.isCorrect && state.selectedOptionId == option.id;
  }

  String _normalizeMathText(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'^\$+|\$+$'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  bool _isWrongOption(Option option, ProblemDetailsState state) {
    final result = state.answerResult;
    return result != null &&
        !result.isCorrect &&
        state.selectedOptionId == option.id;
  }

  String _solutionText(Problem problem, ProblemDetailsState state) {
    if (state.isRetryMode && state.answerResult == null) {
      return '';
    }
    final resultSolution = state.answerResult?.detailedSolution.trim() ?? '';
    if (resultSolution.isNotEmpty) {
      return resultSolution;
    }
    if (problem.hasAttempted) {
      return problem.detailedSolution?.trim() ?? '';
    }
    return '';
  }

  Future<void> _openVideo(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    final isSupportedScheme =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');

    var opened = false;
    if (isSupportedScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('unable_to_open_link'.tr())),
      );
    }
  }
}

class _LearningSummaryCard extends StatelessWidget {
  final Problem problem;
  final ProblemAttemptHistory? history;

  const _LearningSummaryCard({required this.problem, this.history});

  @override
  Widget build(BuildContext context) {
    final status = history?.masteryStatus ?? problem.masteryStatus;
    final statusColor = _masteryColor(status);
    final totalAttempts = history?.totalAttempts ?? problem.attemptCount;
    final bestTime = history?.bestTimeSeconds ?? problem.bestTimeSeconds;
    final averageTime =
        history?.averageTimeSeconds ?? problem.averageTimeSeconds;
    final nextReview = history?.nextReviewAt ?? problem.nextReviewAt;

    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.brandPurple.withValues(alpha: 0.11),
          AppColors.brandCyan.withValues(alpha: 0.07),
        ],
      ),
      border: BorderSide(
        color: AppColors.brandCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_masteryIcon(status), color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _masteryLabel(status),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                'attempts_value'.tr(
                  namedArgs: {'count': '$totalAttempts'},
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (bestTime != null)
                _LearningPill(
                  icon: Icons.bolt_rounded,
                  label: 'best_time_value'.tr(
                    namedArgs: {'time': _formatDuration(bestTime)},
                  ),
                  color: AppColors.success,
                ),
              if (averageTime != null)
                _LearningPill(
                  icon: Icons.timer_outlined,
                  label: 'average_time_value'.tr(
                    namedArgs: {'time': _formatDuration(averageTime)},
                  ),
                  color: AppColors.brandCyan,
                ),
              if (nextReview != null)
                _LearningPill(
                  icon: Icons.event_repeat_rounded,
                  label: 'next_review_value'.tr(
                    namedArgs: {
                      'date': DateFormat.yMMMd(
                        context.locale.toString(),
                      ).format(nextReview.toLocal()),
                    },
                  ),
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetryModeBanner extends StatelessWidget {
  final VoidCallback onCancel;

  const _RetryModeBanner({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: AppColors.brandPurple.withValues(alpha: 0.08),
      border: BorderSide(
        color: AppColors.brandPurple.withValues(alpha: 0.28),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.model_training_rounded,
            color: AppColors.brandViolet,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'training_mode'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('training_mode_desc'.tr()),
              ],
            ),
          ),
          TextButton(onPressed: onCancel, child: Text('cancel'.tr())),
        ],
      ),
    );
  }
}

class _AttemptHistorySection extends StatelessWidget {
  final AsyncValue<ProblemAttemptHistory> historyState;

  const _AttemptHistorySection({required this.historyState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'attempt_history'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => GlassCard(
            child: Text(localizedErrorMessage(error)),
          ),
          data: (history) {
            if (history.attempts.isEmpty) {
              return GlassCard(child: Text('no_attempts_yet'.tr()));
            }
            return GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0;
                      index < history.attempts.length;
                      index++) ...[
                    _AttemptTile(attempt: history.attempts[index]),
                    if (index < history.attempts.length - 1)
                      const Divider(height: 1, indent: 20, endIndent: 20),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final ProblemAttempt attempt;

  const _AttemptTile({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final color = attempt.isCorrect ? AppColors.success : AppColors.error;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          attempt.isCorrect ? Icons.check_rounded : Icons.close_rounded,
          color: color,
        ),
      ),
      title: Text(
        attempt.isOfficial
            ? 'official_attempt_value'.tr(
                namedArgs: {'number': '${attempt.attemptNumber}'},
              )
            : 'training_attempt_value'.tr(
                namedArgs: {'number': '${attempt.attemptNumber}'},
              ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: RichMathText(
          text: attempt.selectedOptionText,
          inline: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      trailing: Text(
        _formatDuration(attempt.timeSpentSeconds),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LearningPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LearningPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemHeader extends StatelessWidget {
  final Problem problem;
  final bool isArabic;
  final bool isFavoriteBusy;
  final VoidCallback onToggleFavorite;

  const _ProblemHeader({
    required this.problem,
    required this.isArabic,
    required this.isFavoriteBusy,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichMathText(
                text: problem.title,
                isArabic: isArabic,
                inline: true,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              onPressed: isFavoriteBusy ? null : onToggleFavorite,
              tooltip: problem.isFavorite
                  ? 'remove_from_favorites'.tr()
                  : 'add_to_favorites'.tr(),
              icon: isFavoriteBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      problem.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _InfoPill(
              icon: Icons.category_outlined,
              label: problem.categoryName,
            ),
            _InfoPill(
              icon: Icons.star_rounded,
              label: 'points_value'.tr(
                namedArgs: {'count': '${problem.points}'},
              ),
              color: AppColors.warning,
            ),
            _InfoPill(
              icon: Icons.visibility_outlined,
              label: 'views_value'.tr(
                namedArgs: {'count': '${problem.viewsCount}'},
              ),
              color: AppColors.cyan,
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerOptionCard extends StatelessWidget {
  final Option option;
  final bool isArabic;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool enabled;

  const _AnswerOptionCard({
    required this.option,
    required this.isArabic,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stateColor = isCorrect
        ? AppColors.success
        : isWrong
            ? AppColors.error
            : isSelected
                ? scheme.primary
                : scheme.outline;

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: stateColor.withValues(
          alpha: isCorrect || isWrong || isSelected ? 0.09 : 0.0,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: stateColor,
          width: isCorrect || isWrong || isSelected ? 1.7 : 1,
        ),
      ),
      child: RadioListTile<int>(
        value: option.id,
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: isCorrect
            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
            : isWrong
                ? const Icon(Icons.cancel_rounded, color: AppColors.error)
                : null,
        title: Semantics(
          value: isCorrect
              ? (isArabic ? 'إجابة صحيحة' : 'Correct answer')
              : isWrong
                  ? (isArabic ? 'إجابة خاطئة' : 'Incorrect answer')
                  : isSelected
                      ? (isArabic ? 'الإجابة المختارة' : 'Selected answer')
                      : null,
          child: RichMathText(
          text: option.latexCode,
          isArabic: isArabic,
          inline: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: effectiveColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnswerResultCard extends StatelessWidget {
  final AnswerResult result;

  const _AnswerResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final resultColor = result.isCorrect ? AppColors.success : AppColors.error;
    return GlassCard(
      color: resultColor.withValues(alpha: 0.08),
      border: BorderSide(color: resultColor.withValues(alpha: 0.30)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: resultColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isCorrect
                      ? 'correct_answer'.tr()
                      : 'wrong_answer'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: resultColor,
                      ),
                ),
                if (result.attemptNumber > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.isOfficialAttempt
                        ? 'official_attempt_value'.tr(
                            namedArgs: {'number': '${result.attemptNumber}'},
                          )
                        : 'training_attempt_value'.tr(
                            namedArgs: {'number': '${result.attemptNumber}'},
                          ),
                  ),
                ],
                if (result.attemptTimeSeconds > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'attempt_time_value'.tr(
                      namedArgs: {
                        'time': _formatDuration(result.attemptTimeSeconds),
                      },
                    ),
                  ),
                ],
                if (result.pointsEarned > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'points_earned_value'.tr(
                      namedArgs: {'count': '${result.pointsEarned}'},
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _masteryLabel(String status) {
  switch (status.toLowerCase()) {
    case 'needsreview':
      return 'mastery_needs_review'.tr();
    case 'practicing':
      return 'mastery_practicing'.tr();
    case 'mastered':
      return 'mastery_mastered'.tr();
    default:
      return 'mastery_new'.tr();
  }
}

Color _masteryColor(String status) {
  switch (status.toLowerCase()) {
    case 'needsreview':
      return AppColors.error;
    case 'practicing':
      return AppColors.warning;
    case 'mastered':
      return AppColors.success;
    default:
      return AppColors.brandCyan;
  }
}

IconData _masteryIcon(String status) {
  switch (status.toLowerCase()) {
    case 'needsreview':
      return Icons.error_outline_rounded;
    case 'practicing':
      return Icons.model_training_rounded;
    case 'mastered':
      return Icons.workspace_premium_rounded;
    default:
      return Icons.fiber_new_rounded;
  }
}

String _formatDuration(int seconds) {
  if (seconds < 60) {
    return 'seconds_short'.tr(namedArgs: {'count': '$seconds'});
  }
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  if (remaining == 0) {
    return 'minutes_short'.tr(namedArgs: {'count': '$minutes'});
  }
  return 'minutes_seconds_short'.tr(
    namedArgs: {'minutes': '$minutes', 'seconds': '$remaining'},
  );
}


/// Diagram is loaded separately so older problem payloads remain compatible.
class _OptionalProblemDiagram extends StatefulWidget {
  const _OptionalProblemDiagram({required this.problemId, required this.isArabic});
  final int problemId;
  final bool isArabic;

  @override
  State<_OptionalProblemDiagram> createState() => _OptionalProblemDiagramState();
}

class _OptionalProblemDiagramState extends State<_OptionalProblemDiagram> {
  late Future<Map<String, dynamic>?> _diagram;

  @override
  void initState() {
    super.initState();
    _diagram = GeometryApiService(ApiService()).getDiagram(widget.problemId);
  }

  @override
  void didUpdateWidget(covariant _OptionalProblemDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problemId != widget.problemId) {
      _diagram = GeometryApiService(ApiService()).getDiagram(widget.problemId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _diagram,
    builder: (context, snapshot) {
      final scene = snapshot.data;
      if (scene == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GeometryDiagram(scene: scene, isArabic: widget.isArabic),
        ),
      );
    },
  );
}
