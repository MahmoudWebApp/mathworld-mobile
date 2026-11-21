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
import '../../widgets/stage_math_glyph.dart';
import '../../widgets/curriculum_framework_note.dart';

/// Displays educational stages with accessible contrast in both themes.
class StagesScreen extends ConsumerWidget {
  final bool embedded;

  const StagesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesState = ref.watch(stagesProvider);
    final localeCode = context.locale.languageCode;

    final content = MathBackground(
      showSymbols: true,
      child: SafeArea(
        bottom: false,
        child: stagesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AppErrorView(
            message: localizedErrorMessage(error),
            onRetry: () => ref.invalidate(stagesProvider),
          ),
          data: (items) => items.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => ref.refresh(stagesProvider.future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      AppEmptyView(
                        icon: Icons.school_outlined,
                        title: 'no_results'.tr(),
                        subtitle: localeCode == 'ar'
                            ? 'ما في مراحل تعليمية منشورة حالياً. اسحب للأسفل للتحديث.'
                            : 'No learning stages are published yet. Pull down to refresh.',
                        action: OutlinedButton.icon(
                          onPressed: () => ref.invalidate(stagesProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('retry'.tr()),
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 600 ? 3 : 2;
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final cardHeight = (205.0 + (scale - 1).clamp(0.0, 1.0) * 48).toDouble();
                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(stagesProvider.future),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md, embedded ? AppSpacing.lg : AppSpacing.sm,
                          AppSpacing.md, embedded ? 132 : AppSpacing.xxl,
                        ),
                        children: [
                          if (embedded) ...[
                            Text('educational_stages'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text('stages_description'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          const CurriculumFrameworkNote(),
                          const SizedBox(height: AppSpacing.lg),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisExtent: cardHeight,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final stage = items[index];
                              return _StageCard(
                                title: stage.getName(localeCode),
                                order: stage.order,
                                onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.stageCategories, arguments: stage),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
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
    final accent = AppColors.stageForOrder(order);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      color: dark ? AppColors.darkSurface : AppColors.lightSurface,
      border: BorderSide(color: accent.withValues(alpha: dark ? .32 : .22)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? .18 : .10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: accent.withValues(alpha: .24)),
              ),
              child: StageMathGlyph(stageOrder: order, color: accent, size: 37),
            ),
            const Spacer(),
            LayoutUtils.forwardIcon(context, color: accent, size: 19),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            'stage_number'.tr(namedArgs: {'number': '$order'}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
