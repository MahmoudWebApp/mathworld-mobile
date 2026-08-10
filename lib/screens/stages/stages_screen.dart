import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/stages_provider.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Displays educational stages with accessible contrast in both themes.
class StagesScreen extends ConsumerWidget {
  final bool embedded;

  const StagesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesState = ref.watch(stagesProvider);
    final localeCode = context.locale.languageCode;

    final content = MathBackground(
      child: SafeArea(
        bottom: false,
        child: stagesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(stagesProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () => ref.refresh(stagesProvider.future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                embedded ? AppSpacing.lg : AppSpacing.sm,
                AppSpacing.lg,
                embedded ? 132 : AppSpacing.xxl,
              ),
              itemCount: items.length + (embedded ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                if (embedded && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'educational_stages'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'stages_description'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                final stage = items[index - (embedded ? 1 : 0)];
                return _StageCard(
                  title: stage.getName(localeCode),
                  order: stage.order,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.stageCategories,
                    arguments: stage,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text('stages'.tr())),
      body: content,
    );
  }
}

class _StageCard extends StatelessWidget {
  final String title;
  final int order;
  final VoidCallback onTap;

  const _StageCard({
    required this.title,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _stageColor(order);
    final titleColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtitleColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return GlassCard(
      onTap: onTap,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      border: BorderSide(
        color: accent.withValues(alpha: isDark ? 0.26 : 0.18),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.34 : 0.22),
              ),
            ),
            child: Icon(Icons.school_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'stage_number'.tr(
                    namedArgs: {'number': '$order'},
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.13 : 0.08),
              shape: BoxShape.circle,
            ),
            child: LayoutUtils.forwardIcon(
              context,
              color: accent,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Color _stageColor(int value) {
    const colors = [
      AppColors.brandCyan,
      AppColors.brandBlue,
      AppColors.brandViolet,
      AppColors.brandPurple,
    ];

    final index = (value <= 0 ? 0 : value - 1) % colors.length;
    return colors[index];
  }
}
