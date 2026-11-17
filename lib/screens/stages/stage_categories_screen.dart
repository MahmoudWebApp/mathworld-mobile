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
        child: accessState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(
              stageCategoryAccessProvider(stage.id),
            ),
          ),
          data: (access) {
            if (premiumState?.isLoading ?? false) {
              return const Center(child: CircularProgressIndicator());
            }
            if (premiumState?.hasError ?? false) {
              return AppErrorView(
                message: localizedErrorMessage(premiumState!.error!),
                onRetry: () => ref.invalidate(studentPremiumProvider),
              );
            }
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

            final available = categories.where((category) =>
                user?.role != 'Student' ||
                isPremium ||
                access.freeCategoryIds.contains(category.id)).toList();
            final unavailable = categories.where((category) =>
                user?.role == 'Student' &&
                !isPremium &&
                !access.freeCategoryIds.contains(category.id)).toList();
            final ready = available.where((c) => (c.problemsCount ?? 0) > 0).toList();
            final unverified = available.where((c) => c.problemsCount == null).toList();
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

                Widget cards(List<Category> items, {required bool locked}) =>
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
                          locked: locked,
                          freeCategory: access.freeCategoryIds.contains(category.id),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      Text(
                        ar ? 'فئات مرحلتك' : 'Your stage topics',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(stage.getName(localeCode),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPremium
                                  ? (ar ? 'كل الفئات متاحة لحسابك' : 'All topics are unlocked')
                                  : (ar ? 'هاي فئاتك المفتوحة' : 'These are your unlocked topics'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              isPremium
                                  ? (ar
                                      ? 'اختَر فئة فيها مسائل وابدأ الحل.'
                                      : 'Choose any topic with questions to start.')
                                  : (ar
                                      ? 'حسابك المجاني بيسمحلك تحل بلا حد داخل الفئتين المفتوحتين في كل مرحلة. ابدأ من الفئات تحت.'
                                      : 'Your Free account includes two unlocked topics per stage, with unlimited practice. Start below.'),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              ar
                                  ? '${available.length} فئة مفتوحة · ${ready.length} فيها مسائل منشورة'
                                  : '${available.length} unlocked · ${ready.length} with published questions',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            if (unverified.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                ar
                                    ? 'عدد المسائل غير متاح لبعض الفئات على هذا الخادم؛ افتح الفئة لتتحقق من محتواها.'
                                    : 'This server has not provided question counts for every topic. Open one to check its content.',
                              ),
                            ],
                            if (ready.isEmpty && unverified.isEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                ar
                                    ? 'ما في مسائل جاهزة للحل بهالمرحلة حاليًا. جرّب التحديث أو غيّر مرحلتك.'
                                    : 'No questions are ready in this stage. Refresh or change your stage.',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.learningStage),
                                icon: const Icon(Icons.school_outlined),
                                label: Text(ar ? 'تغيير المرحلة' : 'Change stage'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (available.isNotEmpty) ...[
                        Text(
                          ar ? '1. ابدأ بفئاتك المفتوحة' : '1. Start with unlocked topics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        cards(available, locked: false),
                      ],
                      if (unavailable.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          ar ? '2. فئات إضافية مقفلة' : '2. Other locked topics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ar
                              ? 'هاي الفئات مو ضمن حسابك المجاني. فيك تشوف مميزات الاشتراك من مكان واحد.'
                              : 'These topics are not included with Free. View membership benefits in one place.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        cards(unavailable, locked: true),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.premiumCheckout),
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: Text(ar ? 'مزايا الاشتراك' : 'Membership benefits'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.learningStage),
                        icon: const Icon(Icons.school_outlined),
                        label: Text(ar ? 'مو مرحلتك؟ غيّر المرحلة' : 'Wrong stage? Change stage'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    return embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: Text(stage.getName(localeCode))),
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
        child: TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.learningStage),
          icon: const Icon(Icons.school_outlined),
          label: Text('choose_learning_stage_title'.tr()),
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
        return AppErrorView(
          onRetry: () => ref.invalidate(stagesProvider),
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
  final bool freeCategory;

  const _CategoryCard({
    required this.category,
    required this.localeCode,
    required this.stageId,
    required this.stageOrder,
    required this.locked,
    required this.freeCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _categoryColor(stageOrder);
    final title = category.getName(localeCode);
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final noPublishedProblems = category.problemsCount == 0;

    return GlassCard(
      // The API now returns a real per-stage count. Never navigate into a
      // category known to have zero questions and then show a dead-end page.
      // Unavailable topics never route to a paywall or empty question list.
      // One single membership page is offered below the topic sections.
      onTap: (noPublishedProblems || locked) ? null : () => Navigator.pushNamed(
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
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
          if (locked || freeCategory) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  locked ? Icons.lock_outline : Icons.lock_open_rounded,
                  size: 15,
                  color: accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  locked
                      ? (localeCode == 'ar' ? 'مقفلة' : 'Locked')
                      : (localeCode == 'ar' ? 'مفتوحة' : 'Unlocked'),
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (noPublishedProblems)
            Text(
              localeCode == 'ar'
                  ? 'لا توجد مسائل منشورة بعد'
                  : 'No published problems yet',
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else if (category.problemsCount != null)
            Text(
              category.solvedCount != null
                  ? 'category_progress'.tr(
                      namedArgs: {
                        'solved': '${category.solvedCount}',
                        'total': '${category.problemsCount}',
                      },
                    )
                  : 'problems_count_value'.tr(
                      namedArgs: {'count': '${category.problemsCount}'},
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'browse_all'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                LayoutUtils.forwardIcon(
                  context,
                  size: 19,
                  color: accent,
                ),
              ],
            ),
          if (category.progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                semanticsLabel: localeCode == 'ar'
                    ? 'تقدم $title'
                    : '$title progress',
                semanticsValue:
                    '${(category.progress! * 100).round()}%',
                value: category.progress,
                minHeight: 6,
                backgroundColor: accent.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ],
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

  Color _categoryColor(int value) {
    const colors = [
      AppColors.stageCyan,
      AppColors.stageOrange,
      AppColors.stageGreen,
      AppColors.stageViolet,
    ];

    final index = (value <= 0 ? 0 : value - 1) % colors.length;
    return colors[index];
  }
}
