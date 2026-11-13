import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../models/stage_daily_quota.dart';
import '../providers/stage_daily_quota_provider.dart';
import 'glass_card.dart';

/// Same backend quota shown on Web and mobile; no client-side calculations.
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
    final quota = ref.watch(stageDailyQuotaProvider(stageId));
    return GlassCard(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: quota.when(
        loading: () => Row(
          children: [
            const SizedBox.square(
              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(child: Text(isArabic
              ? 'جاري تحميل حصة المسائل اليومية...'
              : 'Loading daily question allowance...')),
          ],
        ),
        error: (_, __) => Text(
          isArabic ? 'تعذر تحميل الحصة اليومية. اسحب للتحديث.'
            : 'Daily allowance unavailable. Pull to refresh.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        data: (data) => _Content(data: data, isArabic: isArabic),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final StageDailyQuota data;
  final bool isArabic;
  const _Content({required this.data, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? 'المسائل الجديدة اليوم' : 'New questions today';
    final color = Theme.of(context).colorScheme.primary;
    final ratio = data.limit <= 0
        ? 0.0 : (data.used / data.limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              data.unlimited ? Icons.workspace_premium_rounded
                  : Icons.fact_check_outlined,
              color: color, size: 22,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
                Text(data.stageName(isArabic ? 'ar' : 'en'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
            Text(
              data.unlimited
                ? (isArabic ? 'بلا حدود' : 'Unlimited')
                : '${data.used}/${data.limit}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: color,
              ),
            ),
          ],
        ),
        if (!data.unlimited) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(data.exhausted
              ? isArabic
                  ? 'خلصت حصة هذا المستوى اليوم. فيك تعيد حل المسائل السابقة.'
                  : 'Today’s allowance is used. You can still retry old problems.'
              : isArabic
                  ? 'متبقي ${data.remaining ?? 0} مسائل جديدة بهذا المستوى.'
                  : '${data.remaining ?? 0} new problems remaining in this stage.'),
          const SizedBox(height: 4),
          Text(isArabic
            ? 'تتجدد كل يوم عند منتصف الليل UTC'
            : 'Resets daily at midnight UTC',
            style: Theme.of(context).textTheme.bodySmall),
          if (data.exhausted) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(isArabic
                ? 'مميزات Premium قريبًا — يمكن للأدمن تفعيله تجريبيًا.'
                : 'Premium coming soon — admin can enable it for testing.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color)),
          ],
        ] else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(isArabic
              ? 'حساب Premium: عدد غير محدود من المسائل الجديدة.'
              : 'Premium: unlimited new problems every day.'),
          ),
      ],
    );
  }
}
