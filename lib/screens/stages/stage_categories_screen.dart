import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/category.dart';
import '../../models/stage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stages_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../utils/category_grid_layout.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/stage_math_glyph.dart';

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
    final user = ref.watch(authProvider.select((state) => state.user));
    final premiumState = user?.role == 'Student'
        ? ref.watch(studentPremiumProvider)
        : null;
    final localeCode = context.locale.languageCode;

    final content = MathBackground(
      showSymbols: true,
      child: SafeArea(
        top: embedded,
        bottom: false,
        child: accessState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
              icon: item.icon,
              stageId: stage.id,
              order: item.order,
              problemsCount: item.problemsCount,
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

            // Guests have the same Free access as students. Only a verified
            // Admin or Premium account can see every category as unlocked.
            final isAdmin = user?.role == 'Admin';
            final hasFullAccess = isAdmin || isPremium || user == null;
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

    return ref.watch(stagesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
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

  const _CategoryCard({
    required this.category,
    required this.localeCode,
    required this.stageId,
    required this.stageOrder,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.stageForOrder(stageOrder);
    final title = category.getName(localeCode);
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final noPublishedProblems = category.problemsCount == 0;

    final lockTooltipKey = GlobalKey<TooltipState>();
    return Tooltip(
      key: lockTooltipKey,
      message: localeCode == 'ar'
          ? 'هذه الفئة متاحة لحساب Premium'
          : 'Available with Premium',
      triggerMode: TooltipTriggerMode.manual,
      child: GlassCard(
      // The API now returns a real per-stage count. Never navigate into a
      // category known to have zero questions and then show a dead-end page.
      // Unavailable topics never route to a paywall or empty question list.
      // One single membership page is offered below the topic sections.
      onTap: noPublishedProblems
          ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localeCode == 'ar'
                  ? 'هذه الفئة لا تحتوي على مسائل منشورة بعد.'
                  : 'This category has no published problems yet.'),
            ))
          : locked
              ? () => lockTooltipKey.currentState?.ensureTooltipVisible()
              : () => Navigator.pushNamed(
                    context,
                    AppRoutes.problems,
                    arguments: {
                      'categoryId': category.id,
                      'stageId': stageId,
                      'title': title,
                    },
                  ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: BorderSide(
        color: accent.withValues(alpha: isDark ? 0.27 : 0.18),
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
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                  backgroundColor: mutedColor.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _categoryIcon(Color accent) {
    final value = category.icon?.trim() ?? '';
    if (value.startsWith('https://')) {
      return Image.network(
        value,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.calculate_outlined, color: accent, size: 26),
      );
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
