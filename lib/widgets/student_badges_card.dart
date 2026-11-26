import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_routes.dart';
import '../config/design_tokens.dart';
import '../providers/student_badges_provider.dart';
import 'glass_card.dart';

IconData _badgeIcon(String icon) => switch (icon) {
  'graduation' => Icons.school_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'crown' => Icons.workspace_premium_rounded,
  'puzzle' => Icons.extension_rounded,
  'gem' => Icons.diamond_rounded,
  'target' => Icons.gps_fixed_rounded,
  'flame' => Icons.local_fire_department_rounded,
  'bolt' => Icons.bolt_rounded,
  'globe' => Icons.public_rounded,
  _ => Icons.military_tech_rounded,
};

String _badgeUnit(String unit, bool ar) => switch (unit) {
  'days' => ar ? 'أيام متتالية' : 'Consecutive days',
  'categories' => ar ? 'فئات مكتملة' : 'Completed categories',
  'mastered' => ar ? 'مسائل متقنة' : 'Mastered problems',
  'stages' => ar ? 'مراحل' : 'Stages',
  _ => ar ? 'مسائل' : 'Problems',
};

class StudentBadgesCard extends ConsumerWidget {
  const StudentBadgesCard({super.key});

  void _showPremiumBadge(BuildContext context, String badgeName, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 32, color: AppColors.brandViolet),
              const SizedBox(height: AppSpacing.md),
              Text(
                ar ? 'شارة Premium مقفولة' : 'Locked Premium badge',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ar
                    ? 'شارة «$badgeName» تظهر لك للتعرّف عليها، ويمكن فتحها عند ترقية حسابك إلى Premium.'
                    : 'The “$badgeName” badge stays visible for you to discover. Upgrade to Premium to unlock it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, AppRoutes.premiumBenefits);
                  },
                  child: Text(ar
                      ? 'عرض المميزات وترقية الحساب'
                      : 'View benefits and upgrade'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

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
                  color: AppColors.rewardGold, size: 27),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShaderMask(
                  shaderCallback: AppGradients.primary.createShader,
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    ar ? 'الشارات والإنجازات' : 'Badges & achievements',
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
                    Text(ar ? 'الشارات المكتسبة من المتاحة' : 'Earned from available badges',
                      style: Theme.of(context).textTheme.bodyMedium),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        '${result.earnedCount} / ${result.badges.where((badge) => badge.isAvailable).length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.rewardGoldBright : AppColors.rewardGoldInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Keep Premium badges visible to Free learners. An unavailable
                // badge is locked, not an earned or progress-bearing badge.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: result.badges.map((badge) {
                    final locked = !badge.isAvailable;
                    final name = ar ? badge.titleAr : badge.titleEn;
                    final earned = !locked && badge.earned;
                    final description = ar ? badge.descriptionAr : badge.descriptionEn;
                    final color = AppColors.rewardGold;
                    final progress = badge.requiredSolved > 0
                        ? (badge.currentProgress / badge.requiredSolved)
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return Semantics(
                      button: locked,
                      hint: description.isEmpty ? null : description,
                      label: locked
                          ? '$name: ${ar ? "شارة Premium مقفولة" : "Locked Premium badge"}'
                          : '$name: ${badge.currentProgress}/${badge.requiredSolved}',
                      child: InkWell(
                        onTap: locked
                            ? () => _showPremiumBadge(context, name, ar)
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          width: 136,
                          constraints: const BoxConstraints(minHeight: 138),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: earned ? 0.10 : 0.04),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: earned ? .24 : .10),
                                  border: Border.all(color: color.withValues(alpha: .45)),
                                  borderRadius: BorderRadius.circular(16)),
                                child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                                  Icon(_badgeIcon(badge.icon), color: color, size: 32),
                                  if (locked || earned) PositionedDirectional(end: -4, bottom: -4,
                                    child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                                      child: Icon(locked ? Icons.lock_rounded : Icons.check_circle_rounded,
                                        size: 18, color: locked ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.success))),
                                ]),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                              ],
                              if (locked) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ar ? 'Premium · مقفولة' : 'Premium · Locked',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandViolet,
                                  ),
                                ),
                              ] else ...[
                                Directionality(
                                  textDirection: ui.TextDirection.ltr,
                                  child: Text(
                                    '${badge.currentProgress}/${badge.requiredSolved}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                Text(_badgeUnit(badge.unit, ar), textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
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
                                              width: limits.maxWidth * progress,
                                              decoration: BoxDecoration(
                                                color: progress >= 1.0 ? AppColors.success : AppColors.rewardGold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
