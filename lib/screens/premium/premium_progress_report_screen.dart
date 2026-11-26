import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../models/premium_progress_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/premium_reports_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/mathworld_pagination.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

class PremiumProgressReportScreen extends ConsumerStatefulWidget {
  const PremiumProgressReportScreen({super.key});

  @override
  ConsumerState<PremiumProgressReportScreen> createState() =>
      _PremiumProgressReportScreenState();
}

class _PremiumProgressReportScreenState
    extends ConsumerState<PremiumProgressReportScreen> {
  int _categoryPage=1;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((auth) => auth.user));
    final isPremium = user?.subscriptionType.toLowerCase() == 'premium';
    final stageId = user?.currentStageId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('premium_report_title'.tr())),
      body: MathBackground(
        child: SafeArea(
          child: !isPremium
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppEmptyView(
                      icon: Icons.workspace_premium_outlined,
                      title: 'premium_reports_locked'.tr(),
                      subtitle: 'premium_free_includes_detail'.tr(),
                    ),
                  ),
                )
              : stageId == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: AppEmptyView(
                          icon: Icons.school_outlined,
                          title: 'registration_stage_required'.tr(),
                        ),
                      ),
                    )
                  : ref.watch(premiumProgressReportProvider(stageId)).when(skipLoadingOnRefresh:false,skipLoadingOnReload:false,
                      loading: () => const AppLoadingView(mode:AppLoadingMode.section),
                      error: (error, _) => AppErrorView(
                        message: localizedErrorMessage(error),
                        onRetry: () => ref.invalidate(
                          premiumProgressReportProvider(stageId),
                        ),
                      ),
                      data: (report) {
                        final pages=(report.categories.length+4)~/5;
                        final page=_categoryPage.clamp(1,pages<1?1:pages).toInt();
                        return RefreshIndicator(
                        onRefresh: () async {
                          await ref.refresh(
                            premiumProgressReportProvider(stageId).future,
                          ).then((_) {});
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Text(context.locale.languageCode == 'ar' ? 'الصف أو المساق الحالي' : 'Current grade or course')),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.stageName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  LinearProgressIndicator(
                                    value: (report.completionPercent / 100)
                                        .clamp(0.0, 1.0),
                                    color:AppColors.progressFill(report.completionPercent/100),
                                    backgroundColor:AppColors.progressTrack(context),
                                    minHeight: 9,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    '${report.completionPercent}% '
                                    '${'premium_report_completion'.tr()}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _Metric(
                                  label: 'premium_report_solved'.tr(),
                                  value: '${report.solvedProblems}/${report.totalProblems}',
                                ),
                                _Metric(
                                  label: 'premium_report_first_try'.tr(),
                                  value: '${report.firstTryCorrect}',
                                ),
                                _Metric(
                                  label: 'premium_report_mastered'.tr(),
                                  value: '${report.masteredProblems}',
                                ),
                                _Metric(
                                  label: 'premium_report_points'.tr(),
                                  value: '${report.officialPoints}',
                                  gold: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'premium_report_categories'.tr(),
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...report.categories.skip((page-1)*5).take(5).map((category) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _CategoryReport(category: category),
                                )),
                            if(pages>1)MathWorldPagination(page:page,pageCount:pages,arabic:context.locale.languageCode=='ar',onChanged:(p)=>setState(()=>_categoryPage=p)),
                            if (report.categories.isEmpty)
                              AppEmptyView(
                                icon: Icons.category_outlined,
                                title: 'no_categories'.tr(),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'premium_report_export_notice'.tr(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      );
                      },
                    ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;
  const _Metric({required this.label, required this.value, this.gold = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 145,
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: gold ? (Theme.of(context).brightness == Brightness.dark ? AppColors.rewardGoldBright : AppColors.rewardGoldInk) : null,
                      )),
            ],
          ),
        ),
      );
}

class _CategoryReport extends StatelessWidget {
  final PremiumCategoryProgress category;
  const _CategoryReport({required this.category});

  @override
  Widget build(BuildContext context) => GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: (category.completionPercent / 100).clamp(0.0, 1.0),
              color:AppColors.progressFill(category.completionPercent/100),
              backgroundColor:AppColors.progressTrack(context),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${category.solvedProblems}/${category.totalProblems} '
              '· ${category.completionPercent}%',
            ),
            Text.rich(TextSpan(style: Theme.of(context).textTheme.bodySmall,children:[
              TextSpan(text: '${'premium_report_mastered'.tr()}: ${category.masteredProblems} · '),
              TextSpan(text: '${'premium_report_points'.tr()}: ${category.officialPoints}',style:TextStyle(fontWeight:FontWeight.w700,color:Theme.of(context).brightness == Brightness.dark ? AppColors.rewardGoldBright : AppColors.rewardGoldInk)),
            ])),
          ],
        ),
      );
}
