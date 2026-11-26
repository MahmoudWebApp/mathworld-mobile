import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/premium_analytics_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../services/premium_analytics_service.dart';
import '../../providers/learning_journey_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

class PremiumAnalyticsScreen extends ConsumerStatefulWidget {
  const PremiumAnalyticsScreen({super.key});
  @override ConsumerState<PremiumAnalyticsScreen> createState()=>_PremiumAnalyticsScreenState();
}
class _PremiumAnalyticsScreenState extends ConsumerState<PremiumAnalyticsScreen>{
  String _scope='track';
  int _days=0;
  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final entitlement = ref.watch(studentPremiumProvider);
    final j=entitlement.valueOrNull==true?ref.watch(learningJourneyProvider).valueOrNull:null;
    final enabled=j?.learningSessionsEnabled==true;
    final category=_scope.startsWith('category:')?int.tryParse(_scope.substring(9)):null;
    final validCategory=enabled&&j!.categories.any((c)=>c.categoryId==category)?category:null;
    final scope=validCategory!=null?_scope:'track';
    final AnalyticsFilter filter=enabled?(stageId:j!.stageId,categoryId:validCategory,trackId:j.trackId,days:_days==0?null:_days):allAnalytics;
    final reportProvider=filter==allAnalytics?premiumAnalyticsProvider:filteredPremiumAnalyticsProvider(filter);

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'تقريري الشخصي' : 'My progress report'),
      ),
      body: entitlement.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          message: localizedErrorMessage(error),
          onRetry: () => ref.invalidate(studentPremiumProvider),
        ),
        data: (premium) => premium
            ? Column(children:[
                if(enabled&&j!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),child:Column(children:[
                  DropdownButtonFormField<String>(decoration:InputDecoration(labelText:ar?'النطاق':'Scope',border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),isExpanded:true,initialValue:scope,key:ValueKey(scope),onChanged:(v)=>setState(()=>_scope=v??'track'),items:[
                    DropdownMenuItem(value:'track',child:Text(ar?'الصف أو المساق الحالي':'Current grade or course')),
                    
                    
                    for(final c in j.categories)DropdownMenuItem(value:'category:'+c.categoryId.toString(),child:Text(c.getName(context.locale.languageCode),overflow:TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height:12),
                  DropdownButtonFormField<int>(decoration:InputDecoration(labelText:ar?'الفترة':'Period',border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),isExpanded:true,initialValue:_days,key:ValueKey(_days),onChanged:(v)=>setState(()=>_days=v??0),items:[
                    DropdownMenuItem(value:0,child:Text(ar?'كل الوقت':'All time')),
                    for(final d in [7,30,90,365])DropdownMenuItem(value:d,child:Text(ar?'آخر $d يوم':'Last $d days')),
                  ]),
                ])),
                Expanded(child:ref.watch(reportProvider).when(skipLoadingOnRefresh:false,skipLoadingOnReload:false,
                loading: () => const AppLoadingView(mode:AppLoadingMode.filter),
                error: (error, _) => AppErrorView(
                  message: localizedErrorMessage(error),
                  onRetry: () => ref.invalidate(reportProvider),
                ),
                data: (report) => _ReportBody(key:ValueKey(filter),report: report,onRefresh:()=>ref.refresh(reportProvider.future).then((_){})),
              )),])
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
  const _ReportBody({super.key,required this.report,required this.onRefresh});

  final PremiumAnalyticsReport report;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final color = Theme.of(context).colorScheme.primary;
    final total = report.totalProblems;
    final completion = total != null && total > 0 ? (report.solvedProblems / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final correctness = report.attempts <= 0
        ? 0.0
        : 100 * report.correctAttempts / report.attempts;

    final attemptedCategories=report.categories.where((c)=>c.attempts>0).toList();
    // Use the observed ratio only, and disclose the underlying attempt count.
    attemptedCategories.sort((a,b)=>(b.correctAttempts/b.attempts).compareTo(a.correctAttempts/a.attempts));
    final strongest=attemptedCategories.isNotEmpty?attemptedCategories.first:null;
    final weakest=attemptedCategories.length>1 && attemptedCategories.last.correctAttempts/attemptedCategories.last.attempts < attemptedCategories.first.correctAttempts/attemptedCategories.first.attempts?attemptedCategories.last:null;
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
        onRefresh: onRefresh,
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
                  if(report.scoreBasis=='PermanentAchievements')Text(ar?'النقاط حسب تاريخ اكتسابها، ودفتر الأخطاء يعرض الحالة الحالية. زمن الجلسات الموجهة غير مقاس.':'Points follow original earn dates; review errors show current state. Guided-session time is not measured.'),
                  const SizedBox(height: AppSpacing.md),
                  if (total != null) ...[
                    Text(ar ? 'الإنجاز: ${report.solvedProblems} / $total' : 'Completion: ${report.solvedProblems} / $total'),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(value: completion),
                    Text('${(completion * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: AppSpacing.sm),
                  ],
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Single column on very small phones or with enlarged text:
                // prevent Arabic metric labels from overflowing the card.
                crossAxisCount: MediaQuery.sizeOf(context).width < 390 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.25
                    ? 1
                    : 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: 166,
              ),
              itemBuilder: (context, index) {
                final stat = metrics[index];
                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(stat.$3, color: index == 3 ? AppColors.rewardGold : color, size: 23),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${stat.$2}', style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, color: index == 3 ? (Theme.of(context).brightness == Brightness.dark ? AppColors.rewardGoldBright : AppColors.rewardGoldInk) : null)),
                      Text(
                        stat.$1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
                  if(strongest!=null) ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.trending_up,color:AppColors.success),title:Text(ar?'أعلى دقة مسجلة':'Highest observed accuracy'),subtitle:Text('${ar?strongest.categoryNameAr:strongest.categoryNameEn} · ${(100*strongest.correctAttempts/strongest.attempts).toStringAsFixed(0)}% · ${strongest.attempts} ${ar?'محاولة':'attempts'}')),
                  if(weakest!=null) ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.refresh,color:AppColors.warning),title:Text(ar?'فئة تحتاج مراجعة':'Category to review'),subtitle:Text('${ar?weakest.categoryNameAr:weakest.categoryNameEn} · ${(100*weakest.correctAttempts/weakest.attempts).toStringAsFixed(0)}% · ${weakest.attempts} ${ar?'محاولة':'attempts'}')),
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
                          subtitle: Text(ar
                              ? 'المحاولات: ${category.attempts} · الدقة: ${category.attempts == 0 ? "—" : "${(100 * category.correctAttempts / category.attempts).toStringAsFixed(0)}%"}'
                              : 'Attempts: ${category.attempts} · Accuracy: ${category.attempts == 0 ? "—" : "${(100 * category.correctAttempts / category.attempts).toStringAsFixed(0)}%"}'),
                          trailing: Text(
                            '${category.solvedProblems}/${category.totalProblems ?? category.attemptedProblems}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        if (category.masteredProblems != null) Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Expanded(child: Text(ar ? 'الإتقان الحالي' : 'Current mastery')),
                            Text('${category.masteredProblems} / ${category.totalProblems ?? "—"}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const Divider(height: 1),
                      ],
                    )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (report.recentAttempts != null) ...[
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ar ? 'آخر المحاولات' : 'Recent attempts', style: Theme.of(context).textTheme.titleLarge),
                if (report.recentAttempts!.isEmpty) Text(ar ? 'لا توجد محاولات في هذا النطاق.' : 'No attempts in this scope.'),
                for (final attempt in report.recentAttempts!)
                  ListTile(contentPadding: EdgeInsets.zero,
                    leading: Icon(attempt.isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: attempt.isCorrect ? Colors.green : Theme.of(context).colorScheme.error),
                    title: Text(ar ? attempt.titleAr : attempt.titleEn),
                    subtitle: Text(DateFormat.yMMMd(context.locale.languageCode).add_jm().format(attempt.submittedAtUtc.toLocal())),
                    trailing: Text(attempt.isCorrect ? (ar ? 'صحيحة' : 'Correct') : (ar ? 'خاطئة' : 'Incorrect'))),
              ])),
              const SizedBox(height: AppSpacing.lg),
            ],
            _PdfShareButton(report: report),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final bytes=await ref.read(premiumAnalyticsServiceProvider).exportCsv(language:ar?'ar':'en',filter:report.filter);
                  if(!context.mounted)return;
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
            _XlsxDownloadButton(filter:report.filter),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final bytes=await ref.read(premiumAnalyticsServiceProvider).exportCsv(language:ar?'ar':'en',filter:report.filter);
                  if(!context.mounted)return;
                  await Clipboard.setData(ClipboardData(text:utf8.decode(bytes.sublist(3))));
                }catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ar?'تعذّر تحميل التقرير':'Could not load report')));return;}
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
                    ? 'يمكنك مشاركة PDF وExcel وCSV باللغة الحالية وبنفس فلاتر التقرير من الخادم.'
                    : 'Share PDF, Excel and CSV in the current language using the same server report filters.',
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

class _XlsxDownloadButton extends ConsumerStatefulWidget {
  const _XlsxDownloadButton({required this.filter});
  final AnalyticsFilter filter;

  @override
  ConsumerState<_XlsxDownloadButton> createState() =>
      _XlsxDownloadButtonState();
}

class _XlsxDownloadButtonState extends ConsumerState<_XlsxDownloadButton> {
  bool _sharing = false;

  Future<void> _shareExcel() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final ar = context.locale.languageCode == 'ar';
    try {
      final bytes = await ref.read(premiumAnalyticsServiceProvider)
          .exportXlsx(language: ar ? 'ar' : 'en',filter:widget.filter);
      if (!mounted) return;
      final origin = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: 'mathworld-premium-analytics.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: const ['mathworld-premium-analytics.xlsx'],
        subject: ar ? 'تقرير MathWorld بصيغة Excel' : 'MathWorld Excel report',
        sharePositionOrigin: origin == null
            ? null
            : origin.localToGlobal(Offset.zero) & origin.size,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar
            ? 'تعذّر تجهيز ملف Excel. تأكد من اشتراك Premium والاتصال.'
            : 'Could not export Excel. Check Premium access and your connection.'),
      ));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    return OutlinedButton.icon(
      onPressed: _sharing ? null : _shareExcel,
      icon: _sharing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.table_chart_outlined),
      label: Text(_sharing
          ? (ar ? 'جارٍ تجهيز Excel…' : 'Preparing Excel…')
          : (ar ? 'مشاركة تقرير Excel (XLSX)' : 'Share native Excel workbook (XLSX)')),
    );
  }
}


/// Kept separate from the report view so export progress does not rebuild
/// the entire analytics page. The source report is already Premium-gated.
class _PdfShareButton extends ConsumerStatefulWidget {
  const _PdfShareButton({required this.report});
  final PremiumAnalyticsReport report;

  @override
  ConsumerState<_PdfShareButton> createState() => _PdfShareButtonState();
}

class _PdfShareButtonState extends ConsumerState<_PdfShareButton> {
  bool _sharing = false;

  Future<void> _sharePdf() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final ar = context.locale.languageCode == 'ar';
    try {
      final bytes = await ref.read(premiumAnalyticsServiceProvider).exportPdf(language:ar?'ar':'en',filter:widget.report.filter);
      if (!mounted) return;
      final origin = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: 'mathworld-premium-analytics.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        fileNameOverrides: const ['mathworld-premium-analytics.pdf'],
        subject: ar ? 'تقرير MathWorld PDF' : 'MathWorld PDF report',
        sharePositionOrigin: origin == null
            ? null : origin.localToGlobal(Offset.zero) & origin.size,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ar
            ? 'تعذّر إنشاء PDF. تأكد من الاتصال بالإنترنت، ثم أعد المحاولة.'
            : 'Could not create the PDF. Check your connection and retry.'),
      ));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    return OutlinedButton.icon(
      onPressed: _sharing ? null : _sharePdf,
      icon: _sharing
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(_sharing
          ? (ar ? 'جارٍ تجهيز PDF…' : 'Preparing PDF…')
          : (ar ? 'مشاركة تقرير PDF' : 'Share PDF report')),
    );
  }
}
