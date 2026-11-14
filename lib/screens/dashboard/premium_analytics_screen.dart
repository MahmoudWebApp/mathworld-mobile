import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/premium_analytics_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../services/premium_analytics_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

class PremiumAnalyticsScreen extends ConsumerWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final entitlement = ref.watch(studentPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'تقريري الشخصي' : 'My progress report'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث التقرير' : 'Refresh report',
            onPressed: () {
              ref.invalidate(studentPremiumProvider);
              ref.invalidate(premiumAnalyticsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: entitlement.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: localizedErrorMessage(error),
          onRetry: () => ref.invalidate(studentPremiumProvider),
        ),
        data: (premium) => premium
            ? ref.watch(premiumAnalyticsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorView(
                  message: localizedErrorMessage(error),
                  onRetry: () => ref.invalidate(premiumAnalyticsProvider),
                ),
                data: (report) => _ReportBody(report: report),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary, size: 42),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          ar ? 'التقرير المتقدم من مزايا Premium'
                              : 'Advanced reports are a Premium feature',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          ar
                              ? 'تقدر تحل عدد غير محدود من المسائل ضمن الفئتين المجانيتين بكل مرحلة.'
                              : 'You can still solve unlimited questions in two free categories per stage.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          ar ? 'يمكن للأدمن تفعيل Premium حالياً.'
                              : 'An administrator can grant Premium for now.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final PremiumAnalyticsReport report;

  static String _csvCell(Object? value) {
    var text = (value ?? '').toString();
    if (RegExp(r'^\s*[=+\-@]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""').replaceAll(RegExp(r'[\r\n]'), ' ')}"';
  }

  String _csv() {
    final rows = <List<Object?>>[
      [
        'StageId', 'CategoryId', 'StageAr', 'StageEn', 'CategoryAr',
        'CategoryEn', 'Attempted', 'Solved', 'Errors', 'Attempts',
        'Correct', 'Incorrect', 'FirstTryCorrect', 'Points', 'Seconds',
      ],
      for (final c in report.categories)
        [
          c.stageId, c.categoryId, c.stageNameAr, c.stageNameEn,
          c.categoryNameAr, c.categoryNameEn, c.attemptedProblems,
          c.solvedProblems, c.errorNotebookProblems, c.attempts,
          c.correctAttempts, c.incorrectAttempts, c.firstTryCorrect,
          c.awardedPoints, c.timeSpentSeconds,
        ],
    ];
    final total = <Object?>[
      'TOTAL', '', '', '', '', '',
      report.attemptedProblems, report.solvedProblems,
      report.categories.fold<int>(0, (sum, c) => sum + c.errorNotebookProblems),
      report.attempts, report.correctAttempts, report.incorrectAttempts,
      report.firstTryCorrect, report.awardedPoints, report.timeSpentSeconds,
    ];
    rows.add(total);
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n') + '\r\n';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final color = Theme.of(context).colorScheme.primary;
    final correctness = report.attempts <= 0
        ? 0.0
        : 100 * report.correctAttempts / report.attempts;

    final metrics = <(String, int, IconData)>[
      (
        ar ? 'مسائل محلولة' : 'Unique solved',
        report.solvedProblems,
        Icons.verified_outlined,
      ),
      (
        ar ? 'المحاولات' : 'Attempts',
        report.attempts,
        Icons.fact_check_outlined,
      ),
      (
        ar ? 'إجابات صحيحة' : 'Correct answers',
        report.correctAttempts,
        Icons.check_circle_outline_rounded,
      ),
      (
        ar ? 'النقاط' : 'Points',
        report.awardedPoints,
        Icons.stars_rounded,
      ),
    ];

    return MathBackground(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(premiumAnalyticsProvider.future).then((_) {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights_rounded, color: color, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(
                        ar ? 'إحصائياتي المتقدمة' : 'My advanced analytics',
                        style: Theme.of(context).textTheme.titleLarge,
                      )),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(ar ? 'البيانات من محاولاتك المحفوظة، وليست أرقاماً تقديرية.'
                      : 'Stats are calculated from saved attempts, not estimates.'),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    ar ? 'دقة المحاولات: ${correctness.toStringAsFixed(1)}%'
                        : 'Attempt accuracy: ${correctness.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color, fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final stat = metrics[index];
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(stat.$3, color: color, size: 23),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${stat.$2}', style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(stat.$1, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ar ? 'تقدم الفئات' : 'Category progress',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  if (report.categories.isEmpty)
                    Text(ar ? 'ما عندك محاولات بعد. ابدأ بحل المسائل.'
                        : 'No attempts yet. Start practising.')
                  else
                    ...report.categories.map((category) => Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(ar ? category.categoryNameAr
                              : category.categoryNameEn,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(ar ? category.stageNameAr
                              : category.stageNameEn),
                          trailing: Text(
                            '${category.solvedProblems}/${category.attemptedProblems}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                final bytes = Uint8List.fromList([
                  0xEF, 0xBB, 0xBF, ...utf8.encode(_csv()),
                ]);
                try {
                  final origin = context.findRenderObject() as RenderBox?;
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile.fromData(bytes, mimeType: 'text/csv'),
                      ],
                      fileNameOverrides: const ['mathworld-premium-report.csv'],
                      subject: ar ? 'تقرير MathWorld' : 'MathWorld report',
                      sharePositionOrigin: origin == null
                          ? null
                          : origin.localToGlobal(Offset.zero) & origin.size,
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ar
                        ? 'تعذّر مشاركة الملف. يمكنك نسخ البيانات بدلاً منها.'
                        : 'Unable to share the CSV file. Try copying the table.')),
                  );
                }
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(ar ? 'مشاركة ملف CSV / Excel' : 'Share Excel-ready CSV file'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _csv()));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ar
                      ? 'تم نسخ جدول CSV؛ يمكنك لصقه في برنامج جداول.'
                      : 'CSV copied; paste it into your spreadsheet app.')),
                );
              },
              icon: const Icon(Icons.content_copy_rounded),
              label: Text(ar ? 'نسخ جدول CSV' : 'Copy CSV table'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                ar
                    ? 'يمكنك الآن مشاركة ملف CSV من الجوال وفتحه في Excel؛ إصدار PDF يبقى متاحاً من المتصفح عبر الطباعة.'
                    : 'You can now share a CSV file from the app and open it in Excel. Save-as-PDF is available from the Web print view.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
