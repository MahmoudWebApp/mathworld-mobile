import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/problem.dart';
import '../../providers/problem_details_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/rich_math_text.dart';

/// Displays one problem and delegates all interactions to its notifier.
class ProblemDetailsScreen extends ConsumerWidget {
  const ProblemDetailsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! int) {
      return Scaffold(
        body: AppErrorView(
          message: 'invalid_route_arguments'.tr(),
          onRetry: () => Navigator.maybePop(context),
        ),
      );
    }
    final state = ref.watch(problemDetailsProvider(arguments));
    final notifier = ref.read(problemDetailsProvider(arguments).notifier);
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
            onOptionChanged: notifier.selectOption,
            onSubmit: () => _runAction(
              context,
              notifier.submitAnswer,
            ),
            onToggleFavorite: () => _runAction(
              context,
              notifier.toggleFavorite,
            ),
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

class _ProblemContent extends StatelessWidget {
  final Problem problem;
  final ProblemDetailsState state;
  final ValueChanged<int?> onOptionChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleFavorite;
  const _ProblemContent({
    required this.problem,
    required this.state,
    required this.onOptionChanged,
    required this.onSubmit,
    required this.onToggleFavorite,
  });
  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final canSelect = state.answerResult == null && !problem.hasAttempted;
    final solution = _solutionText(problem, state.answerResult);
    final videoUrl =
        state.answerResult?.youtubeSolutionUrl ?? problem.youtubeSolutionUrl;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _ProblemHeader(
          problem: problem,
          isArabic: isArabic,
          isFavoriteBusy: state.isFavoriteBusy,
          onToggleFavorite: onToggleFavorite,
        ),
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
                  isCorrect: _isCorrectOption(
                    problem.options[index],
                    state,
                  ),
                  isWrong: _isWrongOption(problem.options[index], state),
                  enabled: canSelect,
                ),
                if (index < problem.options.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        if (state.answerResult == null && !problem.hasAttempted) ...[
          const SizedBox(height: AppSpacing.xl),
          PremiumButton(
            onPressed: state.selectedOptionId == null || state.isSubmitting
                ? null
                : onSubmit,
            label: 'submit_answer'.tr(),
            icon: Icons.send_rounded,
            isLoading: state.isSubmitting,
            expand: true,
          ),
        ],
        if (state.answerResult != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _AnswerResultCard(result: state.answerResult!),
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
        if (videoUrl?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _openVideo(context, videoUrl!),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: Text('video_solution'.tr()),
          ),
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

  String _solutionText(Problem problem, AnswerResult? result) {
    final resultSolution = result?.detailedSolution.trim() ?? '';
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
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
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
      duration: const Duration(milliseconds: 180),
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
        title: RichMathText(
          text: option.latexCode,
          isArabic: isArabic,
          inline: true,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
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
  const _InfoPill({
    required this.icon,
    required this.label,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.18),
        ),
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
