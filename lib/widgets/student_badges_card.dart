import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../providers/student_badges_provider.dart';
import 'glass_card.dart';

class StudentBadgesCard extends ConsumerWidget {
  const StudentBadgesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final badgesState = ref.watch(studentBadgesProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  color: AppColors.primary, size: 27),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ar ? 'شارات إنجازاتي' : 'My achievement badges',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(studentBadgesProvider),
                tooltip: ar ? 'تحديث الشارات' : 'Refresh badges',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          badgesState.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Text(
              ar ? 'تعذّر تحميل الشارات. اضغط تحديث.'
                  : 'Could not load badges. Tap refresh.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            data: (result) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar
                      ? 'حصلت على ${result.earnedCount} من ${result.totalBadges} شارات'
                      : 'Earned ${result.earnedCount} of ${result.totalBadges} badges',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: result.badges.map((badge) {
                    final color = badge.earned
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.outline;
                    return Semantics(
                      label: '${ar ? badge.titleAr : badge.titleEn}: '
                          '${badge.currentProgress}/${badge.requiredSolved}',
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: badge.earned ? 0.10 : 0.04),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              badge.earned
                                  ? Icons.verified_rounded
                                  : Icons.lock_outline_rounded,
                              color: color,
                              size: 26,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ar ? badge.titleAr : badge.titleEn,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              '${badge.currentProgress}/${badge.requiredSolved}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (result.nextMilestone != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ar
                        ? 'الشارة التالية عند حل ${result.nextMilestone} مسألة مختلفة.'
                        : 'Next badge after ${result.nextMilestone} unique solves.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
