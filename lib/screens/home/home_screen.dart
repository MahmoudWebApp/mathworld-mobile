import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../core/utils/relative_time.dart';
import '../../models/dashboard_stats.dart';
import '../../models/learning_journey.dart';
import '../../models/daily_challenge.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/student_badges_card.dart';
import '../../widgets/rich_math_text.dart';
import '../../widgets/stage_math_glyph.dart';

/// Displays the user dashboard, progress summary, and learning shortcuts.
class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenStages;

  const HomeScreen({super.key, required this.onOpenStages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final learningJourney = ref.watch(learningJourneyProvider);
    final dailyPractice = ref.watch(dailyChallengeProvider);

    return MathBackground(
      showSymbols: true,
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
              // Refresh both datasets together: points and the recommended
              // next topic must reflect the same latest saved practice.
              await Future.wait([
                ref.refresh(dashboardProvider.future),
                ref.refresh(learningJourneyProvider.future),
                ref.refresh(dailyChallengeProvider.future),
              ]);
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
                            child: _LearningJourneyCard(journey: journey, onOpenStages: onOpenStages),
                          ),
                        ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _JourneyStatusCard(
                      isLoading: false,
                      message: localizedErrorMessage(error),
                      onRetry: () => ref.invalidate(learningJourneyProvider),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _JourneyStatusCard(isLoading: true),
                  ),
                ),
                dailyPractice.when(
                  data: (challenge) => challenge == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: AnimatedEntry(
                            child: _DailyPracticeCard(
                              challenge: challenge,
                              onOpen: (problemId) async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.problemDetails,
                                  arguments: problemId,
                                );
                                if (!context.mounted) return;
                                ref.invalidate(dailyChallengeProvider);
                                ref.invalidate(dashboardProvider);
                                ref.invalidate(learningJourneyProvider);
                              },
                            ),
                          ),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: GlassCard(
                      child: Row(children: [
                        SizedBox.square(dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: Text('Loading daily practice…')),
                      ]),
                    ),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: GlassCard(child: Row(children: [
                      const Icon(Icons.refresh_outlined,
                        color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(context.locale.languageCode == 'ar'
                        ? 'تعذّر تحميل تمارين اليوم.'
                        : 'Daily practice is unavailable.')),
                      IconButton(
                        tooltip: context.locale.languageCode == 'ar'
                          ? 'إعادة المحاولة' : 'Retry',
                        onPressed: () => ref.invalidate(dailyChallengeProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ])),
                  ),
                ),
                if (learningJourney.valueOrNull != null) ...[
                  AnimatedEntry(
                    index: 1,
                    child: _StatsGrid(journey: learningJourney.valueOrNull!),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const StudentBadgesCard(),
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

class _DailyPracticeCard extends StatelessWidget {
  const _DailyPracticeCard({
    required this.challenge,
    required this.onOpen,
  });

  final DailyChallenge challenge;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final color = Theme.of(context).colorScheme.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.today_outlined, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(
              ar ? 'تحدّي اليوم الاختياري' : 'Optional daily practice',
              style: Theme.of(context).textTheme.titleLarge,
            )),
            Text('${challenge.completed}/${challenge.total}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text(ar
            ? 'حتى خمس مسائل من فئاتك المفتوحة؛ هذا مو حد يومي للحل.'
            : 'Up to five questions from unlocked topics, not a daily solving limit.',
            style: Theme.of(context).textTheme.bodySmall),
          if (challenge.dateUtc.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${challenge.dateUtc} UTC',
              style: Theme.of(context).textTheme.labelSmall),
          ],
          const SizedBox(height: AppSpacing.md),
          if (challenge.problems.isEmpty)
            Text(ar
              ? 'ما في مسائل منشورة ضمن فئاتك المفتوحة حالياً.'
              : 'No published questions in your unlocked categories yet.')
          else
            ...challenge.problems.map((problem) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                title: RichMathText(
                  text: problem.getName(context.locale.languageCode),
                  isArabic: ar,
                  inline: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(problem.isSolved
                  ? (ar ? 'تم حلّها' : 'Solved')
                  : (ar ? 'اضغط للتدرّب' : 'Tap to practice')),
                trailing: problem.isSolved
                  ? const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success)
                  : LayoutUtils.forwardIcon(context, color: color),
                onTap: () => onOpen(problem.id),
              ),
            )),
        ],
      ),
    );
  }
}

/// Keep journey errors visible without replacing the rest of the dashboard.
/// The learner can still practice while the optional journey API is down.
class _JourneyStatusCard extends StatelessWidget {
  const _JourneyStatusCard({
    required this.isLoading,
    this.message,
    this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 36,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              const StageMathGlyph(
                stageOrder: 2, color: AppColors.stageOrange, size: 36,
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading
                        ? (ar ? 'جارٍ تحميل رحلتك التعليمية…'
                            : 'Loading your learning journey…')
                        : (ar ? 'تعذّر تحميل تقدّم المرحلة'
                            : 'Stage progress is unavailable'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (!isLoading) ...[
                    const SizedBox(height: 4),
                    Text(
                      message ??
                          (ar ? 'باقي ميزات المنصة متاحة.'
                              : 'You can still use the rest of the platform.'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (!isLoading && onRetry != null)
              IconButton(
                onPressed: onRetry,
                tooltip: ar ? 'إعادة تحميل التقدّم' : 'Retry stage progress',
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
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
        // Small phones and large accessibility text need room for Arabic labels.
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth < 350
                ? 1
                : 2;
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
  final VoidCallback onOpenStages;

  const _LearningJourneyCard({
    required this.journey,
    required this.onOpenStages,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;
    final color = Theme.of(context).colorScheme.primary;
    final reviewCount = journey.categories.where((category) =>
        !category.isLocked &&
        category.attemptedProblems > category.solvedProblems).length;
    // Keep Free-unlocked topics above Premium-locked ones in the compact
    // dashboard preview while retaining the API's order within each group.
    final visibleCategories = [
      ...journey.categories.where((category) => !category.isLocked),
      ...journey.categories.where((category) => category.isLocked),
    ];

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
            children: [
              Expanded(
                child: Text(
                  'stage_completion'.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${journey.completionPercent}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            semanticsLabel: 'stage_completion'.tr(),
            semanticsValue: '${journey.completionPercent}%',
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
          if (journey.recommendedCategory case final suggested?) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(language == 'ar' ? 'الخطوة المقترحة لك' : 'Suggested next step',
                    style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(suggested.getName(language),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(suggested.attemptedProblems > 0
                      ? (language == 'ar'
                          ? 'كمّل فئتك الحالية حتى تحسّن تقدّمك.'
                          : 'Continue this unfinished topic to improve your progress.')
                      : (language == 'ar'
                          ? 'بلّش بفئة جديدة ومفتوحة لحسابك.'
                          : 'Explore a new topic already unlocked for you.')),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.problems,
                      arguments: <String, dynamic>{
                        'categoryId': suggested.categoryId,
                        'stageId': journey.stageId,
                        'title': suggested.getName(language),
                      },
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(language == 'ar' ? 'تابع حل المسائل' : 'Practice this category'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (reviewCount > 0) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context, AppRoutes.errorNotebook,
              ),
              icon: const Icon(Icons.auto_stories_outlined),
              label: Text(language == 'ar'
                  ? 'راجع أخطاءك في دفتر المراجعة'
                  : 'Review your attempts in the error notebook'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('stage_topics'.tr(),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (const bool.fromEnvironment(
            'MATHWORLD_LEADERBOARD_ENABLED',
            defaultValue: true,
          ))
            OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text('leaderboard_title'.tr()),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (journey.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(language == 'ar'
                  ? 'لا توجد فئات منشورة لهذه المرحلة بعد.'
                  : 'No topics have been published for this stage yet.'),
            ),
          ...visibleCategories.take(6).map((category) {
            final canPractice = !category.isLocked && category.totalProblems > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(category.getName(language),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(category.isLocked
                    ? (language == 'ar' ? 'تحتاج اشتراك Premium' : 'Premium access required')
                    : category.totalProblems == 0
                        ? (language == 'ar' ? 'قريباً' : 'Coming soon')
                        : '${category.solvedProblems} / ${category.totalProblems}'),
                trailing: canPractice
                    ? LayoutUtils.forwardIcon(context, color: color)
                    : Icon(
                        category.isLocked
                            ? Icons.lock_outline_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 20,
                      ),
                onTap: canPractice
                    ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.problems,
                          arguments: <String, dynamic>{
                            'categoryId': category.categoryId,
                            'stageId': journey.stageId,
                            'title': category.getName(language),
                          },
                        )
                    : null,
              ),
            );
          }),
          if (journey.categories.length > 6) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onOpenStages,
              icon: LayoutUtils.forwardIcon(context),
              label: Text(language == 'ar'
                  ? 'عرض جميع فئات مرحلتي'
                  : 'Browse all stage topics'),
            ),
          ],
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
