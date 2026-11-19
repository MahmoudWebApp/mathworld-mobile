import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/design_tokens.dart';
import '../providers/student_badges_provider.dart';
import '../config/app_routes.dart';
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
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.primary, size: 27),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShaderMask(
                  shaderCallback: AppGradients.primary.createShader,
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    ar ? 'شارات إنجازاتي' : 'My achievement badges',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(ar ? 'الشارات المكتسبة' : 'Earned badges',
                      style: Theme.of(context).textTheme.bodyMedium),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text('${result.earnedCount} / ${result.badges.where((badge) => badge.isAvailable).length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (result.badges.any((badge) => !badge.isAvailable)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ar ? 'في شارات إضافية بتفتح لما ترقّي حسابك. تقدّمك محفوظ.'
                        : 'More badges unlock when you upgrade your account. Your progress is saved.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.premiumBenefits),
                      child: Text(ar ? 'ترقية الحساب' : 'Upgrade account'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: result.badges.where((badge) => badge.isAvailable).map((badge) {
                    final color = badge.earned
                        ? AppColors.brandViolet
                        : Theme.of(context).colorScheme.outline;
                    return Semantics(
                      label: '${ar ? badge.titleAr : badge.titleEn}: '
                          '${badge.currentProgress}/${badge.requiredSolved}. ',
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
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                '${badge.currentProgress}/${badge.requiredSolved}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 5,
                                child: LayoutBuilder(
                                  builder: (context, limits) => Stack(
                                    children: [
                                      Container(color: color.withValues(alpha: 0.10)),
                                      Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Container(
                                          width: limits.maxWidth *
                                              (badge.currentProgress / badge.requiredSolved)
                                                  .clamp(0.0, 1.0),
                                          decoration: const BoxDecoration(
                                            gradient: AppGradients.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
