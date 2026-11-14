import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/relative_time.dart';
import '../../models/dashboard_stats.dart';
import '../../models/learning_journey.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/rich_math_text.dart';

/// Displays the user dashboard, progress summary, and learning shortcuts.
class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenStages;

  const HomeScreen({super.key, required this.onOpenStages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final learningJourney = ref.watch(learningJourneyProvider);

    return MathBackground(
      child: SafeArea(
        bottom: false,
        child: dashboardState.when(
          loading: () => const _HomeSkeleton(),
          error: (error, _) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(learningJourneyProvider);
              await ref.refresh(dashboardProvider.future).then((_) {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                32,
              ),
              children: [
                AnimatedEntry(child: _HeroCard(
                  dashboard: dashboard,
                  journey: learningJourney.valueOrNull,
                )),
                const SizedBox(height: AppSpacing.xl),
                learningJourney.when(
                  data: (journey) => journey == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: AnimatedEntry(
                            child: _LearningJourneyCard(journey: journey),
                          ),
                        ),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                ),
                if (learningJourney.valueOrNull != null) ...[
                  AnimatedEntry(
                    index: 1,
                    child: _StatsGrid(journey: learningJourney.valueOrNull!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AnimatedEntry(
                  index: 2,
                  child: _ContinueLearningCard(onTap: onOpenStages),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AnimatedEntry(
                  index: 3,
                  child: _SectionHeader(title: 'recent_activity'.tr()),
                ),
                const SizedBox(height: AppSpacing.md),
                if (dashboard.recentActivities.isEmpty)
                  AppEmptyView(
                    icon: Icons.timeline_rounded,
                    title: 'no_activity_yet'.tr(),
                  )
                else
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: dashboard.recentActivities
                          .take(4)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final activity = entry.value;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                              title: RichMathText(
                                text: activity.title,
                                inline: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity.categoryName),
                                    if (activity.solvedAt != null)
                                      Text(
                                        formatLocalizedDateTime(
                                          context,
                                          activity.solvedAt,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              trailing: LayoutUtils.forwardIcon(context),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.problemDetails,
                                arguments: activity.problemId,
                              ),
                            ),
                            if (entry.key <
                                dashboard.recentActivities.take(4).length - 1)
                              const Divider(
                                height: 1,
                                indent: 72,
                                endIndent: 16,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final DashboardStats dashboard;
  final LearningJourney? journey;

  const _HeroCard({required this.dashboard, required this.journey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = dashboard.fullName.trim().isEmpty
        ? 'M'
        : dashboard.fullName.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.darkHero : AppGradients.lightHero,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hello_user_name'.tr(
                        namedArgs: {'name': dashboard.fullName},
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'home_progress_message'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (dashboard.memberSince != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'member_since_value'.tr(
                          namedArgs: {
                            'date': formatLocalizedDateTime(
                              context,
                              dashboard.memberSince,
                            ),
                          },
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (journey != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${'learning_stage'.tr()}: ${journey!.getName(context.locale.languageCode)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final LearningJourney journey;

  const _StatsGrid({required this.journey});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(
        Icons.check_circle_outline_rounded,
        '${journey.solvedProblems}',
        'stage_solved'.tr(),
        AppColors.success,
      ),
      _StatData(
        Icons.auto_awesome_rounded,
        '${journey.totalPoints}',
        'stage_points'.tr(),
        AppColors.warning,
      ),
      _StatData(
        Icons.trending_up_rounded,
        '${journey.completionPercent}%',
        'stage_completion'.tr(),
        AppColors.cyan,
      ),
      _StatData(
        Icons.favorite_border_rounded,
        '${journey.attemptedProblems}',
        'stage_attempted'.tr(),
        AppColors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ContinueLearningCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      gradient: isDark ? AppGradients.darkHero : AppGradients.lightHero,
      border: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.functions_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'continue_learning'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'continue_learning_desc'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            onPressed: onTap,
            label: 'explore'.tr(),
            trailingIcon: LayoutUtils.forwardChevron(context),
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _LearningJourneyCard extends StatelessWidget {
  final LearningJourney journey;

  const _LearningJourneyCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;
    final color = Theme.of(context).colorScheme.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('learning_journey'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(journey.getName(language),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('stage_completion'.tr()),
              Text('${journey.completionPercent}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: journey.completionPercent.clamp(0, 100) / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _StageStat(
                title: 'stage_solved'.tr(),
                value: '${journey.solvedProblems}/${journey.totalProblems}',
              ),
              _StageStat(
                title: 'stage_attempted'.tr(),
                value: '${journey.attemptedProblems}',
              ),
              _StageStat(
                title: 'stage_points'.tr(),
                value: '${journey.totalPoints}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('stage_topics'.tr(),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (const bool.fromEnvironment(
            'MATHWORLD_LEADERBOARD_ENABLED',
            defaultValue: false,
          ))
            OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text('leaderboard_title'.tr()),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...journey.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.getName(language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${category.solvedProblems}/${category.totalProblems}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageStat extends StatelessWidget {
  final String title;
  final String value;

  const _StageStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatData(this.icon, this.value, this.label, this.color);
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        132,
      ),
      children: List.generate(
        5,
        (index) => Container(
          height: index == 0 ? 180 : 125,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}
