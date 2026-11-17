import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../providers/stage_daily_quota_provider.dart';
import 'glass_card.dart';

/// Displays unrestricted practice for both Free and Premium learners.
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
    final status = ref.watch(stageDailyQuotaProvider(stageId));
    return GlassCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: status.when(
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (_, __) => Text(
          isArabic
              ? 'التدرب غير محدود. تعذر تحديث الإحصائيات حالياً.'
              : 'Practice is unlimited. Could not refresh stats.',
        ),
        data: (data) => Row(
          children: [
            Icon(Icons.all_inclusive_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'حل مسائل بلا حدود' : 'Unlimited practice',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    data.stageName(isArabic ? 'ar' : 'en'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    isArabic
                        ? 'حل أي عدد من المسائل في الفئات المتاحة لحسابك.'
                        : 'Solve any number of problems in your available categories.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
