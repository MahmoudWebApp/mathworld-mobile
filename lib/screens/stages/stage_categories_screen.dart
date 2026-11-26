import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/category.dart';
import '../../models/stage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stages_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../providers/problems_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/user_lists_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../providers/student_badges_provider.dart';
import '../../providers/premium_analytics_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../utils/category_grid_layout.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/stage_math_glyph.dart';
import '../../widgets/curriculum_framework_note.dart';
import '../../widgets/published_stage_skills_panel.dart';
import '../../widgets/category_skills_dialog.dart';
import '../../widgets/learning_track_workspace.dart';
import '../../providers/learning_tracks_provider.dart';

/// Displays localized categories for the selected educational stage.
class StageCategoriesScreen extends ConsumerWidget {
  final Stage? stage;
  final bool embedded;

  const StageCategoriesScreen({super.key, this.stage, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments = this.stage ?? ModalRoute.of(context)?.settings.arguments;
    if (arguments is! Stage) {
      return Scaffold(
        body: AppErrorView(onRetry: () => Navigator.maybePop(context)),
      );
    }

    final stage = arguments;
    final accessState = ref.watch(stageCategoryAccessProvider(stage.id));
    // Actual journey data, never a guessed learning result.
    final journey = ref.watch(learningJourneyProvider).valueOrNull;
    final solvedCounts = <int, int>{};
    final attemptedCounts = <int, int>{};
    if (journey?.stageId == stage.id) {
      for (final result in journey!.categories) {
        solvedCounts[result.categoryId] = result.solvedProblems;
        attemptedCounts[result.categoryId] = result.attemptedProblems;
      }
    }
    final user = ref.watch(authProvider.select((state) => state.user));
    final premiumState = user?.role == 'Student'
        ? ref.watch(studentPremiumProvider)
        : null;
    Future<void> restartPractice({int? categoryId, required String name}) async {
      if (user?.role != 'Student') return;
      final ar = context.locale.languageCode == 'ar';
      final accepted=await showMathWorldConfirmation(context,
        title:ar?'تأكيد إعادة التدريب':'Confirm practice restart',
        message:(categoryId==null?(ar?'إعادة تدريب المرحلة كاملة: ':'Restart the entire stage: '):(ar?'إعادة تدريب الفئة: ':'Restart category: '))+name+'\n\n'+
          (ar?'ستعود المسائل ضمن هذا النطاق جديدة وغير محلولة. يتصفّر تقدم التدريب ودفتر الأخطاء فقط؛ لا تتأثر النطاقات الأخرى، والمفضلة محفوظة. لا يمكن التراجع عن التصفير.':'Questions in this scope become new and unsolved. Only practice progress and error-notebook entries reset; other scopes and favorites remain. This reset cannot be undone.'),
        cancel:ar?'إلغاء':'Cancel',confirm:ar?'تأكيد':'Confirm');
      if (accepted != true || !context.mounted) return;
      try {
        await ref.read(problemsRepositoryProvider).resetPractice(
          stageId: stage.id, categoryId: categoryId);
        ref.invalidate(learningJourneyProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(solvedProvider);
        ref.invalidate(errorNotebookProvider);
        ref.invalidate(favoritesProvider);
        ref.invalidate(problemsProvider);
        ref.invalidate(dailyChallengeProvider);
        ref.invalidate(studentBadgesProvider);
        ref.invalidate(premiumAnalyticsProvider);
        ref.invalidate(filteredPremiumAnalyticsProvider);
        ref.invalidate(leaderboardProvider);
        ref.invalidate(stageCategoryAccessProvider(stage.id));
        if (context.mounted) {
          showMathWorldNotice(context,ar ? 'تم بدء دورة تدريب جديدة في $name.' :
              'A new practice cycle started in $name.',kind:MathWorldNoticeKind.success);
        }
      } catch (error) {
        if (context.mounted) {
          showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
        }
      }
    }

    final localeCode = context.locale.languageCode;

    final content = MathBackground(
      showSymbols: true,
      child: SafeArea(
        top: embedded,
        bottom: false,
        child: accessState.when(
          loading: () => AppContentSkeleton(cards:true,count:4,title:stage.getName(localeCode)),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(
              stageCategoryAccessProvider(stage.id),
            ),
          ),
          data: (access) {
            // One verified stage response drives titles, entitlements and
            // published counts. Avoid a second, potentially stale /categories
            // response making the entire stage appear empty or unavailable.
            final categories = access.categories.map((item) => Category(
              id: item.id,
              nameAr: item.nameAr,
              nameEn: item.nameEn,
              descriptionAr: item.descriptionAr,
              descriptionEn: item.descriptionEn,
              icon: item.icon,
              stageId: stage.id,
              order: item.order,
              problemsCount: item.problemsCount,
              solvedCount: solvedCounts[item.id],
            )).toList()..sort((a, b) {
              final order = a.order.compareTo(b.order);
              return order != 0 ? order : a.id.compareTo(b.id);
            });
            final isPremium = premiumState?.valueOrNull ?? false;
            if (categories.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => ref.refresh(stageCategoryAccessProvider(stage.id).future).then((_) {}),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppEmptyView(
                      icon: Icons.category_outlined,
                      title: 'no_categories'.tr(),
                      subtitle: 'no_categories_desc'.tr(),
                      action: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.invalidate(stageCategoryAccessProvider(stage.id));
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text('retry'.tr()),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.learningStage),
                            icon: const Icon(Icons.school_outlined),
                            label: Text(localeCode == 'ar'
                                ? 'اختيار مرحلة ثانية'
                                : 'Choose another stage'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Guests can browse stage metadata, but they have only Free
            // category access. Do not display Premium-only topics as unlocked.
            final isAdmin = user?.role == 'Admin';
            final hasFullAccess = isAdmin || isPremium;
            final ordered = [
              ...categories.where((category) => hasFullAccess ||
                  access.freeCategoryIds.contains(category.id)),
              ...categories.where((category) => !hasFullAccess &&
                  !access.freeCategoryIds.contains(category.id)),
            ];
            final ar = localeCode == 'ar';

            return LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final columns = StageCategoryGridLayout.columns(
                  constraints.maxWidth,
                  textScale: textScale,
                );
                final extent = StageCategoryGridLayout.cardExtent(
                  columns,
                  textScale: textScale,
                );

                Widget cards(List<Category> items) =>
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisExtent: extent,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final category = items[index];
                        return _CategoryCard(
                          category: category,
                          localeCode: localeCode,
                          stageId: stage.id,
                          stageOrder: stage.order,
                          onShowSkills: () => showCategorySkillsDialog(context,
                            category: category, stageId: stage.id, stageOrder: stage.order),
                          onRestart: (user?.role == 'Student' &&
                              (hasFullAccess || access.freeCategoryIds.contains(category.id)) &&
                              (attemptedCounts[category.id] ?? 0) > 0)
                            ? () => restartPractice(categoryId: category.id,
                                name: category.getName(localeCode))
                            : null,
                          locked: !hasFullAccess &&
                            !access.freeCategoryIds.contains(category.id),
                        );
                      },
                    );

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      ref.refresh(stageCategoryAccessProvider(stage.id).future),
                      if (user?.role == 'Student')
                        ref.refresh(studentPremiumProvider.future),
                    ]);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      embedded ? 144 : AppSpacing.xxl,
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48, height: 48, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.stageForOrder(stage.order).withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: StageMathGlyph(
                              stageOrder: stage.order,
                              color: AppColors.stageForOrder(stage.order),
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (ar ? 'استكشف الفئات' : 'Explore topics'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  stage.getName(localeCode),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.stageForOrder(stage.order),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (user?.role == 'Student' &&
                          journey?.stageId == stage.id &&
                          (journey?.attemptedProblems ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton.icon(
                              onPressed: () => restartPractice(
                                name: stage.getName(localeCode)),
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: Text(ar ? 'إعادة تدريب المرحلة' : 'Restart stage'),
                            ),
                          ),
                        ),
                      const CurriculumFrameworkNote(),
                      PublishedStageSkillsPanel(stageId: stage.id, categories: categories),
                      const SizedBox(height: AppSpacing.lg),
                      if (user?.role == 'Student' &&
                          (premiumState?.hasError ?? false)) ...[
                        TextButton.icon(
                          onPressed: () => ref.invalidate(studentPremiumProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(ar ? 'إعادة تحميل الصلاحيات' : 'Retry access'),
                        ),
                      ],
                      cards(ordered),
                      if (user?.role == 'Student') ...[
                        const SizedBox(height: AppSpacing.lg),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.learningStage),
                          icon: const Icon(Icons.school_outlined),
                          label: Text(ar ? 'تغيير المرحلة' : 'Change stage'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      );
    return embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: Text(
        stage.getName(localeCode),
        style: TextStyle(
          color: AppColors.stageForOrder(stage.order),
          fontWeight: FontWeight.w900,
        ),
      )),
            body: content,
          );
  }
}

/// Shows only categories in the active learning stage. Unlike the original
/// Stage list this follows the user's saved stage preference.
class CurrentStageCategoriesScreen extends ConsumerWidget {
  const CurrentStageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final stageId = user?.currentStageId;
    if (stageId == null || user?.role != 'Student') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyView(
            icon: Icons.school_outlined,
            title: 'choose_learning_stage_title'.tr(),
            subtitle: 'choose_learning_stage_desc'.tr(),
            action: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.learningStage,
              ),
              icon: Icon(LayoutUtils.forwardArrow(context), textDirection: ui.TextDirection.ltr),
              label: Text('learning_stage'.tr()),
            ),
          ),
        ),
      );
    }

    final trackCatalog = ref.watch(publishedTracksProvider(stageId));
    // An explicit disabled/legacy API response preserves existing stage UI.
    // A temporary failure must not silently switch a selected track to a stage.
    if (trackCatalog.isLoading && !trackCatalog.hasValue) {
      return AppContentSkeleton(cards:true,title:context.locale.languageCode=='ar'?'الفئات التعليمية':'Learning topics');
    }
    if (trackCatalog.hasError) {
      return AppErrorView(onRetry: () => ref.invalidate(publishedTracksProvider(stageId)));
    }
    final catalog = trackCatalog.valueOrNull;
    if (catalog != null && catalog.enabled && catalog.items.isNotEmpty) {
      return LearningTrackWorkspace(key: ValueKey('tracks-${user!.id}-$stageId'), stageId: stageId, catalog: catalog);
    }

    return ref.watch(stagesProvider).when(
      loading: () => AppContentSkeleton(cards:true,count:4,title:context.locale.languageCode=='ar'?'الفئات التعليمية':'Learning topics'),
      error: (error, _) => AppErrorView(
        message: localizedErrorMessage(error),
        onRetry: () => ref.invalidate(stagesProvider),
      ),
      data: (stages) {
        for (final stage in stages) {
          if (stage.id == stageId) {
            return StageCategoriesScreen(
              key: ValueKey(stage.id),
              stage: stage,
              embedded: true,
            );
          }
        }
        // A deleted/renamed stage is not a network error. Give learners
        // a direct route to choose a valid stage instead of retrying forever.
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppEmptyView(
              icon: Icons.school_outlined,
              title: 'choose_learning_stage_title'.tr(),
              subtitle: 'choose_learning_stage_desc'.tr(),
              action: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.learningStage,
                ),
                icon: const Icon(Icons.school_outlined),
                label: Text('learning_stage'.tr()),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final String localeCode;
  final int stageId;
  final int stageOrder;
  final bool locked;
  final VoidCallback? onRestart;
  final VoidCallback onShowSkills;

  const _CategoryCard({
    required this.category,
    required this.localeCode,
    required this.stageId,
    required this.stageOrder,
    required this.locked,
    this.onRestart,
    required this.onShowSkills,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.stageForOrder(stageOrder);
    final title = category.getName(localeCode);
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final noPublishedProblems = category.problemsCount == 0;
    void openQuestions() {
      if (noPublishedProblems) return;
      Navigator.pushNamed(context, AppRoutes.problems, arguments: {
        'categoryId': category.id,
        'stageId': stageId,
        'title': title,
      });
    }

    return GlassCard(
      // The API now returns a real per-stage count. Never navigate into a
      // category known to have zero questions and then show a dead-end page.
      // Unavailable topics never route to a paywall or empty question list.
      // One single membership page is offered below the topic sections.
      // Unlocked topics have two buttons at the bottom of this same card.
      // Locked topics retain their existing Premium explanation.
      onTap: noPublishedProblems
          ? () => showMathWorldNotice(context,localeCode == 'ar'
                  ? 'هذه الفئة لا تحتوي على مسائل منشورة بعد.'
                  : 'This category has no published problems yet.',kind:MathWorldNoticeKind.info)
          : locked
              ? () => _showPremiumLockedSheet(context, title)
              : null,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: BorderSide(
        color: accent.withValues(alpha: isDark ? 0.55 : 0.36),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.17 : 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.34 : 0.23),
                  ),
                ),
                child: _categoryIcon(accent),
              ),
              const Spacer(),
              if (locked)
                Icon(Icons.lock_outline_rounded, color: mutedColor, size: 19),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            noPublishedProblems
                ? (localeCode == 'ar' ? 'لا توجد مسائل' : 'No problems')
                : category.problemsCount != null
                    ? 'problems_count_value'.tr(namedArgs: {
                        'count': '${category.problemsCount}',
                      })
                    : 'browse_all'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: noPublishedProblems ? mutedColor : accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (category.solvedCount != null && category.solvedCount! > 0) ...[
             const SizedBox(height: AppSpacing.xs),
             Text(
               localeCode == 'ar'
                 ? 'تم حل ${category.solvedCount} من ${category.problemsCount ?? 0}'
                 : 'Solved ${category.solvedCount} of ${category.problemsCount ?? 0}',
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
               style: Theme.of(context).textTheme.labelSmall?.copyWith(color: mutedColor),
             ),
           ],
           if (category.progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: localeCode == 'ar' ? 'تقدم $title' : '$title progress',
              value: '${(category.progress! * 100).round()}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: category.progress!.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: AppColors.progressTrack(context),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.progressFill(category.progress!)),
                ),
              ),
            ),
          ],
          // Category objectives are public even when solving is Premium-only.
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShowSkills,
              icon: const Icon(Icons.fact_check_outlined, size: 15),
              label: Text(localeCode == 'ar' ? 'عرض المهارات' : 'View skills',
                maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 35),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: .55)),
                backgroundColor: accent.withValues(alpha: .07),
              ),
            ),
          ),
          if (!locked) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: mutedColor.withValues(alpha: 0.25)),
            const SizedBox(height: AppSpacing.sm),
            // Two explicit actions inside the connected topic card.
            // They are stacked to preserve the two-column phone layout.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: noPublishedProblems ? null : openQuestions,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Text(localeCode == 'ar' ? 'عرض المسائل' : 'View questions',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRestart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: .55)),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Text(localeCode == 'ar' ? 'إعادة التدريب' : 'Restart practice',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPremiumLockedSheet(BuildContext context, String title) async {
    final ar = localeCode == 'ar';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_rounded, size: 40,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(ar ? 'هذه الفئة متاحة مع Premium' : 'This topic requires Premium',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(ar
                ? 'افتح كل فئات مرحلتك وشاهد الحل قبل الإجابة واحصل على إحصائيات وتقارير شخصية.'
                : 'Unlock all topics in your stage, preview solutions, and access personal reports.',
                textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, AppRoutes.premiumBenefits);
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(ar ? 'المميزات وترقية الحساب' : 'Benefits & upgrade'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(Color accent) {
    final value = category.icon?.trim() ?? '';
    if (value.startsWith('https://') && value.toLowerCase().split('?').first.endsWith('.svg')) {
      return ColorFiltered(colorFilter: AppColors.topicArtworkFilter(accent), child: SvgPicture.network(value, width: 34, height: 34,
        placeholderBuilder: (_) => SizedBox.square(
          dimension: 24,
          child: AppInlineLoader(size:20),
        ),
        errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.calculate_outlined, color: accent, size: 26),
      ));
    }
    if (value.startsWith('https://')) {
      return ColorFiltered(colorFilter: AppColors.topicArtworkFilter(accent), child: Image.network(
        value,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.calculate_outlined, color: accent, size: 26),
      ));
    }
    // The API may return an asset path or URL instead of a glyph.
    // Never display a long raw URL or path over the category card.
    if (value.isNotEmpty &&
        value.runes.length <= 4 &&
        !value.contains('/') &&
        !value.contains('\\')) {
      return Text(value, style: const TextStyle(fontSize: 25));
    }
    return StageMathGlyph(stageOrder: stageOrder, color: accent, size: 32);
  }

}
