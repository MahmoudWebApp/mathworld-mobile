import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../providers/stage_category_access_provider.dart';
import 'glass_card.dart';

/// Compatibility widget kept for existing imports.
/// Free learners have unlimited attempts within two stage categories.
/// Never fetch or enforce the legacy 10-questions-per-day counter.
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
    if (stageId <= 0) return const SizedBox.shrink();
    final isArabic = context.locale.languageCode == 'ar';
    final premium = ref.watch(studentPremiumProvider);
    final isPremium = premium.valueOrNull == true;

    return GlassCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.all_inclusive,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تدرّب بلا حدود' : 'Unlimited practice',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  premium.isLoading
                      ? (isArabic ? 'جارٍ التحقق من الاشتراك…' : 'Checking membership…')
                      : premium.hasError
                          ? (isArabic
                              ? 'حل بلا حدود ضمن الفئات المفتوحة بحسابك.'
                              : 'Unlimited practice in your unlocked categories.')
                          : isPremium
                          ? (isArabic
                              ? 'Premium: كل الفئات مفتوحة، والمسائل غير محدودة.'
                              : 'Premium: all categories unlocked, unlimited questions.')
                          : (isArabic
                              ? 'Free: حل بلا حدود ضمن الفئتين المفتوحتين من كل مرحلة.'
                              : 'Free: unlimited questions in two unlocked categories per stage.'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
