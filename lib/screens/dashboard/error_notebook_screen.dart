import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/problem.dart';
import '../../providers/learning_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/rich_math_text.dart';

/// Displays active and archived problems from the student's error notebook.
class ErrorNotebookScreen extends ConsumerWidget {
  const ErrorNotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(errorNotebookProvider);
    final notifier = ref.read(errorNotebookProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('error_notebook'.tr())),
      body: MathBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.includeArchived,
                    onChanged: notifier.setIncludeArchived,
                    secondary: const Icon(Icons.inventory_2_outlined),
                    title: Text('show_archived_problems'.tr()),
                    subtitle: Text('show_archived_problems_desc'.tr()),
                  ),
                ),
              ),
              Expanded(
                child: state.problems.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => AppErrorView(
                    message: localizedErrorMessage(error),
                    onRetry: notifier.load,
                  ),
                  data: (problems) {
                    if (problems.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppEmptyView(
                          icon: Icons.auto_stories_outlined,
                          title: 'error_notebook_empty'.tr(),
                          subtitle: 'error_notebook_empty_desc'.tr(),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: notifier.load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxxl,
                        ),
                        itemCount: problems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final problem = problems[index];
                          return _ErrorNotebookCard(
                            problem: problem,
                            isBusy: state.busyProblemIds.contains(problem.id),
                            onOpen: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.problemDetails,
                                arguments: {
                                  'problemId': problem.id,
                                  'retry': true,
                                },
                              ).then((_) => notifier.load());
                            },
                            onArchiveChanged: () async {
                              try {
                                await notifier.setArchived(
                                  problemId: problem.id,
                                  isArchived: !problem.isArchived,
                                );
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizedErrorMessage(error),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorNotebookCard extends StatelessWidget {
  final ErrorNotebookProblem problem;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onArchiveChanged;

  const _ErrorNotebookCard({
    required this.problem,
    required this.isBusy,
    required this.onOpen,
    required this.onArchiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final masteryColor = _masteryColor(problem.masteryStatus);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: masteryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  problem.isArchived
                      ? Icons.inventory_2_outlined
                      : Icons.menu_book_outlined,
                  color: masteryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: RichMathText(
                  text: problem.title,
                  isArabic: context.locale.languageCode == 'ar',
                  inline: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height:
                            context.locale.languageCode == 'ar' ? 1.65 : 1.4,
                      ),
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onArchiveChanged,
                tooltip: problem.isArchived
                    ? 'restore_problem'.tr()
                    : 'archive_problem'.tr(),
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        problem.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _NotebookPill(
                icon: Icons.school_outlined,
                label: problem.stageName,
                color: AppColors.primary,
              ),
              _NotebookPill(
                icon: Icons.category_outlined,
                label: problem.categoryName,
                color: AppColors.cyan,
              ),
              _NotebookPill(
                icon: Icons.replay_rounded,
                label: 'attempts_value'.tr(
                  namedArgs: {'count': '${problem.attemptCount}'},
                ),
                color: AppColors.warning,
              ),
              _NotebookPill(
                icon: _masteryIcon(problem.masteryStatus),
                label: _masteryLabel(problem.masteryStatus),
                color: masteryColor,
              ),
            ],
          ),
          if (problem.nextReviewAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.event_repeat_rounded,
                  size: 19,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'next_review_value'.tr(
                      namedArgs: {
                        'date': DateFormat.yMMMd(
                          context.locale.toString(),
                        ).format(problem.nextReviewAt!),
                      },
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.model_training_rounded),
              label: Text('train_again'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NotebookPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
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
      return AppColors.cyan;
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
