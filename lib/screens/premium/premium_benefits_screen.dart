import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Central, calm explanation of Free and Premium benefits.
/// This screen does not pretend that payments or future features are active.
class PremiumBenefitsScreen extends ConsumerWidget {
  const PremiumBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(authProvider.select(
      (state) => state.user?.subscriptionType.toLowerCase() == 'premium',
    ));
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final benefits = <({IconData icon, String titleKey, String detailKey, bool upcoming})>[
      (
        icon: Icons.lock_open_rounded,
        titleKey: 'premium_all_categories_title',
        detailKey: 'premium_all_categories_detail',
        upcoming: false,
      ),
      (
        icon: Icons.visibility_outlined,
        titleKey: 'premium_preview_title',
        detailKey: 'premium_preview_detail',
        upcoming: false,
      ),
      (
        icon: Icons.block_rounded,
        titleKey: 'premium_no_ads_title',
        detailKey: 'premium_no_ads_detail',
        upcoming: true,
      ),
      (
        icon: Icons.analytics_outlined,
        titleKey: 'premium_reports_title',
        detailKey: 'premium_reports_detail',
        upcoming: true,
      ),
      (
        icon: Icons.school_outlined,
        titleKey: 'premium_tutors_title',
        detailKey: 'premium_tutors_detail',
        upcoming: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('premium_benefits_title'.tr())),
      body: MathBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 38, color: primary),
                    const SizedBox(height: AppSpacing.md),
                    Text('premium_benefits_title'.tr(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: AppSpacing.sm),
                    Text('premium_benefits_intro'.tr(),
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPremium
                            ? 'premium_account_active'.tr()
                            : 'premium_account_free'.tr(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: primary, fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('premium_benefits_list_title'.tr(),
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              ...benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(benefit.icon, color: primary, size: 28),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        benefit.titleKey.tr(),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      (benefit.upcoming
                                              ? 'premium_coming_soon'
                                              : 'premium_available_now').tr(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: benefit.upcoming
                                            ? theme.colorScheme.onSurfaceVariant
                                            : primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(benefit.detailKey.tr(),
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('premium_free_includes_title'.tr(),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text('premium_free_includes_detail'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('premium_payment_notice'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
