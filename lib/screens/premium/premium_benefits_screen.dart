import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// The single membership entry point for Free and Premium learners.
/// Payment is deliberately not offered until a verified payment flow exists.
class PremiumBenefitsScreen extends ConsumerStatefulWidget {
  const PremiumBenefitsScreen({super.key});

  @override
  ConsumerState<PremiumBenefitsScreen> createState() =>
      _PremiumBenefitsScreenState();
}

class _PremiumBenefitsScreenState
    extends ConsumerState<PremiumBenefitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(authProvider.notifier).refreshProfile());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final premium = ref.watch(authProvider.select(
      (state) => state.user?.subscriptionType.toLowerCase() == 'premium',
    ));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(
        premium
            ? (ar ? 'مميزات حسابي' : 'My account benefits')
            : (ar ? 'ترقية الحساب' : 'Upgrade account'),
      )),
      body: MathBackground(
        showSymbols: false,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                ar ? 'مقارنة Free وPremium' : 'Free vs Premium',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ar
                    ? 'قارن الحسابين ومميزاتهما بدون أسعار حالياً. المسائل غير محدودة ضمن الفئات المتاحة لحسابك.'
                    : 'Compare the two plans without prices for now. Practice is unlimited in your accessible topics.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _planCard(
                context,
                title: 'Free',
                selected: !premium,
                icon: Icons.school_outlined,
                features: [
                  ar ? 'أول فئتين من كل مرحلة' : 'First two categories in every stage',
                  ar ? 'حل عدد غير محدود من المسائل' : 'Unlimited practice in open categories',
                  ar ? 'تقدمك محفوظ عند تغيير المرحلة' : 'Progress is kept when you change stages',
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _planCard(
                context,
                title: 'Premium',
                selected: premium,
                icon: Icons.workspace_premium_rounded,
                features: [
                  ar ? 'كل فئات المرحلة التعليمية المختارة' : 'Every topic in your selected stage',
                  ar ? 'حل عدد غير محدود من المسائل' : 'Unlimited problem solving',
                  ar ? 'تلميحان متدرجان قبل الحل' : 'Two progressive hints before solving',
                  ar ? 'تقارير تقدم تفصيلية وإحصائيات خاصة' : 'Detailed private progress analytics',
                  ar ? 'تصدير نتائجك PDF أو CSV المتوافق مع Excel'
                     : 'Export results to PDF or Excel-compatible CSV',
                  ar ? 'بدون إعلانات داخل MathWorld' : 'No ads inside MathWorld',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!premium) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.premiumGiftRedeem,
                  ),
                  icon: const Icon(Icons.redeem_rounded),
                  label: Text(ar
                      ? 'إدخال كود خصم 100% لتفعيل Premium'
                      : 'Redeem a 100% Premium access code'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ar
                      ? 'رمز خصم 100% من إدارة MathWorld يفعّل Premium مجاناً دون دفع. يُستخدم مرة واحدة.'
                      : 'A 100% access code from MathWorld activates Premium free of charge. Each code is single-use.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.premiumReport,
                  ),
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(ar ? 'افتح تقريري' : 'Open my report'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ar ? 'خطة Premium مفعّلة على حسابك.' : 'Premium is active on your account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard(
    BuildContext context, {
    required String title,
    required bool selected,
    required IconData icon,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final ar = context.locale.languageCode == 'ar';
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      border: BorderSide(
        color: selected ? accent : theme.colorScheme.outline,
        width: selected ? 2 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                )),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(ar ? 'خطتك الحالية' : 'Current plan',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: accent, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(feature,
                  style: theme.textTheme.bodyMedium)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
