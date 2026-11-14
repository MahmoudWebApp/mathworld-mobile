import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../providers/stage_daily_quota_provider.dart';
import 'glass_card.dart';

/// Compatibility card: the Free 10-question daily cap was removed.
/// Unlimited solving is available within the student's unlocked categories.
class DailyQuotaCard extends ConsumerWidget {
  final int stageId;
  final bool compact;

  const DailyQuotaCard({
    super.key,
    required this.stageId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = context.locale.languageCode == 'ar';
    final entitlement = ref.watch(stageDailyQuotaProvider(stageId));

    return GlassCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: entitlement.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => Text(
          isArabic
              ? 'تعذّر تحميل حالة الممارسة، اسحب للتحديث.'
              : 'Could not load practice access. Pull to refresh.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        data: (access) {
          final isPremium = access.subscriptionType == 'Premium';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.all_inclusive,
                size: 26,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الممارسة بلا حد يومي' : 'Practice without daily limits',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(access.stageName(isArabic ? 'ar' : 'en')),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isPremium
                          ? (isArabic
                              ? 'Premium: كل الفئات مفتوحة، والمسائل غير محدودة.'
                              : 'Premium: all categories unlocked and unlimited questions.')
                          : (isArabic
                              ? 'مجاني: حل بلا حدود ضمن الفئتين المجانيتين بهذه المرحلة.'
                              : 'Free: unlimited practice in two unlocked stage categories.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
