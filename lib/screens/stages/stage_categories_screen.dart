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
    final localeCode = context.locale.languageCode;
    final currentUser = ref.watch(
      authProvider.select((state) => state.user),
    );
    final isPremium = currentUser?.role == 'Admin' ||
        currentUser?.subscriptionType.toLowerCase() == 'premium';

    final content = MathBackground(
        child: categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () {
              ref.invalidate(categoriesProvider);
              ref.invalidate(stageCategoriesProvider(stage.id));
            },
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return AppEmptyView(
                icon: Icons.category_outlined,
                title: 'no_categories'.tr(),
                subtitle: 'no_categories_desc'.tr(),
                action: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(categoriesProvider);
                    ref.invalidate(stageCategoriesProvider(stage.id));
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('retry'.tr()),
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPremium ? Icons.verified_outlined : Icons.info_outline_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isPremium
                              ? 'category_all_open'.tr()
                              : 'category_free_access_explanation'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                // On narrow phones, a single readable card is preferable
                // to two cramped cards with truncated Arabic titles.
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 620
                        ? 3
                        : constraints.maxWidth >= 420
                            ? 2
                            : 1;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(categoriesProvider);
                    await ref.refresh(stageCategoriesProvider(stage.id).future)
                        .then((_) {});
                  },
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                    mainAxisExtent: 215,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    // The API and server order categories by Order then Id.
                    // Only the first two in each stage are free.
                    return _CategoryCard(
                      category: category,
                      localeCode: localeCode,
                      stageId: stage.id,
                      locked: !isPremium && index >= 2,
                    );
                  },
                  ),
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
              icon: const Icon(Icons.arrow_forward_rounded),
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

  const _CategoryCard({
    required this.category,
    required this.localeCode,
    required this.stageId,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _categoryColor(category.order);
    final title = category.getName(localeCode);
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final empty = category.problemsCount == 0;
    return GlassCard(
      onTap: locked
          ? () => _explainLockedCategory(context)
          : empty
              ? null
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
          if (!locked && !empty)
            Row(
              children: [
                Icon(Icons.lock_open_rounded, size: 16, color: accent),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'category_open'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          if (locked || empty)
            Row(
              children: [
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: mutedColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    locked ? 'category_locked'.tr() : 'category_no_problems'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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

  /// Give a tapped locked card a useful explanation instead of ignoring it.
  /// Keep the upgrade details in one central page, not on every card.
  void _explainLockedCategory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Theme.of(sheetContext).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'category_locked_explanation_title'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'category_locked_explanation_body'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, AppRoutes.premiumBenefits);
                },
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text('premium_benefits_title'.tr()),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text('category_locked_continue_free'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryIcon(Color accent) {
    final icon = category.icon?.trim() ?? '';
    final uri = Uri.tryParse(icon);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(
          icon,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.calculate_outlined, color: accent, size: 26),
        ),
      );
    }
    if (icon.isNotEmpty && !icon.contains('/')) {
      // A literal emoji is valid; a relative path is not displayable text.
      return Text(icon, style: const TextStyle(fontSize: 25));
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
