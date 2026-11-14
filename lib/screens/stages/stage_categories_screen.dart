import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/category.dart';
import '../../models/stage.dart';
import '../../providers/categories_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stages_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../utils/category_grid_layout.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

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
    final categoriesState = ref.watch(stageCategoriesProvider(stage.id));
    final accessState = ref.watch(stageCategoryAccessProvider(stage.id));
    final user = ref.watch(authProvider.select((state) => state.user));
    final premiumState = user?.role == 'Student'
        ? ref.watch(studentPremiumProvider)
        : null;
    final localeCode = context.locale.languageCode;

    final content = MathBackground(
        child: categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(
              stageCategoriesProvider(stage.id),
            ),
          ),
          data: (categories) {
            if (accessState.isLoading || (premiumState?.isLoading ?? false)) {
              return const Center(child: CircularProgressIndicator());
            }
            if (accessState.hasError || (premiumState?.hasError ?? false)) {
              return AppErrorView(
                onRetry: () {
                  ref.invalidate(stageCategoryAccessProvider(stage.id));
                  ref.invalidate(studentPremiumProvider);
                },
              );
            }
            final access = accessState.valueOrNull;
            if (access == null) {
              return AppErrorView(
                onRetry: () => ref.invalidate(stageCategoryAccessProvider(stage.id)),
              );
            }
            final isPremium = premiumState?.valueOrNull ?? false;
            if (categories.isEmpty) {
              return AppEmptyView(
                icon: Icons.category_outlined,
                title: 'no_categories'.tr(),
                subtitle: 'no_categories_desc'.tr(),
              );
            }

            return Column(
              children: [
                if (embedded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'active_stage_categories'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            stage.getName(localeCode),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
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

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisExtent: extent,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(
                      category: category,
                      localeCode: localeCode,
                      stageId: stage.id,
                      locked: user?.role == 'Student' && !isPremium && !access.freeCategoryIds.contains(category.id),
                      freeCategory: access.freeCategoryIds.contains(category.id),
                    );
                  },
                );
                    },
                  ),
                ),
              ],
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
  final bool locked;
  final bool freeCategory;

  const _CategoryCard({
    required this.category,
    required this.localeCode,
    required this.stageId,
    required this.locked,
    required this.freeCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _categoryColor(category.order);
    final title = category.getName(localeCode);
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return GlassCard(
      onTap: locked ? () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(localeCode == 'ar' ? 'فئة Premium' : 'Premium category'),
          content: Text(localeCode == 'ar'
              ? 'الحساب المجاني بيحل مسائل بلا حد ضمن الفئتين المفتوحتين من كل مرحلة. هاي الفئة بحاجة Premium؛ الدفع الإلكتروني غير مفعّل حالياً، وفيك تستخدم كود هدية.'
              : 'Free learners can solve unlimited questions in the two unlocked categories of each stage. This category needs Premium. Checkout is not live; you can redeem a gift code.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(localeCode == 'ar' ? 'رجوع' : 'Back'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, AppRoutes.premiumGiftRedeem);
              },
              icon: const Icon(Icons.card_giftcard_rounded),
              label: Text(localeCode == 'ar' ? 'تفعيل كود هدية' : 'Redeem a gift'),
            ),
          ],
        ),
      ) : () => Navigator.pushNamed(
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
                  locked ? 'Premium' : (localeCode == 'ar' ? 'مجاني' : 'Free'),
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
          if (category.problemsCount != null)
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
    return Icon(Icons.calculate_outlined, color: accent, size: 26);
  }

  Color _categoryColor(int value) {
    const colors = [
      AppColors.brandPurple,
      AppColors.brandCyan,
      AppColors.brandBlue,
      AppColors.brandViolet,
      Color(0xFF6D5DFB),
      Color(0xFF32B8D8),
    ];

    final index = (value <= 0 ? 0 : value - 1) % colors.length;
    return colors[index];
  }
}
