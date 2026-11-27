import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/network/api_envelope.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/mathworld_pagination.dart';
import '../../widgets/mobile_section.dart';
import '../../widgets/math_background.dart';

final currentGradeReportProvider=FutureProvider.autoDispose<Map<String,dynamic>>((ref) async {
  final actor=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId)));
  if(actor.id==null)throw StateError('No authenticated account');
  final client=ref.watch(apiClientProvider);
  final selected=await ref.watch(trackSelectionProvider.future);
  final id=trackNumber(selected['TrackId']);
  if(id<=0)throw StateError('No active learning track');
  final response=await client.get('/users/current-grade-report');
  final report=ApiEnvelope.map(response.data);
  if(trackNumber(report['TrackId'])!=id||report['MetricsScope']!='CurrentTrack')throw const FormatException('Report scope changed');
  return report;
});

class CurrentGradeReportScreen extends ConsumerWidget {
  const CurrentGradeReportScreen({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){
    final ar=context.locale.languageCode=='ar';
    final entitlement=ref.watch(studentPremiumProvider);
    return Scaffold(appBar:AppBar(title:Text(ar?'تقرير الصف الحالي':'Current grade report')),
      body:MathBackground(child:SafeArea(child:entitlement.when(
        loading:()=>const AppContentSkeleton(),
        error:(e,_)=>AppErrorView(message:localizedErrorMessage(e),onRetry:()=>ref.invalidate(studentPremiumProvider)),
        data:(premium)=>!premium?Center(child:Padding(padding:const EdgeInsets.all(16),child:AppEmptyView(
          icon:Icons.workspace_premium_outlined,title:ar?'التقارير لحساب Premium':'Reports are for Premium accounts',
          action:FilledButton(onPressed:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits),child:Text(ar?'ترقية الحساب':'Upgrade account')),
        ))):ref.watch(currentGradeReportProvider).when(skipLoadingOnRefresh:false,skipLoadingOnReload:false,
          loading:()=>const AppContentSkeleton(),
          error:(e,_){
            final code=e is AppException?e.serverMessage?.trim():null;
            final message=code=='TrackReportIsolationUnavailable'
              ?(ar?'تقرير الصف غير متاح حالياً. تقدمك محفوظ ولم يُحذف.':'The grade report is currently unavailable. Your progress is preserved.')
              :code=='LearningTrackRequired'
                ?(ar?'اختر الصف أو المستوى التعليمي لعرض التقرير.':'Choose a grade or level to view the report.')
                :localizedErrorMessage(e);
            return AppErrorView(message:message,onRetry:(){ref.invalidate(trackSelectionProvider);ref.invalidate(currentGradeReportProvider);});
          },
          data:(p)=>_ReportBody(report:p,ar:ar,onRefresh:() async {try{await ref.refresh(currentGradeReportProvider.future).then((_) {});}catch(_){}}),
        ),
      ))));
  }
}

class _ReportBody extends StatefulWidget {
  const _ReportBody({required this.report,required this.ar,required this.onRefresh});
  final Map<String,dynamic> report;
  final bool ar;
  final Future<void> Function() onRefresh;
  @override State<_ReportBody> createState()=>_ReportBodyState();
}
class _ReportBodyState extends State<_ReportBody>{
  int _categoryPage=1,_attemptPage=1;
  Map<String,dynamic> get report=>widget.report;
  bool get ar=>widget.ar;
  Future<void> Function() get onRefresh=>widget.onRefresh;
  String percent(Object? v)=>v is num?'${v.toStringAsFixed(1)}%':'—';
  @override Widget build(BuildContext context){
    final p=report,theme=Theme.of(context);
    final track=p['Track'] is Map?Map<String,dynamic>.from(p['Track'] as Map):<String,dynamic>{};
    final allCategories=trackRows(p['Categories']),allRecent=trackRows(p['RecentAttempts']);
    final categoryPages=(allCategories.length+4)~/5,attemptPages=(allRecent.length+4)~/5;
    final cp=_categoryPage.clamp(1,categoryPages<1?1:categoryPages).toInt(),ap=_attemptPage.clamp(1,attemptPages<1?1:attemptPages).toInt();
    final categories=allCategories.skip((cp-1)*5).take(5).toList(),recent=allRecent.skip((ap-1)*5).take(5).toList();
    final gold=AppColors.pointsGold(context);
    Widget metric(String label,Object? value,{Color? tint})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(label)),const SizedBox(width:12),Text(value?.toString()??'—',style:TextStyle(fontWeight:FontWeight.bold,color:tint))]));
    Widget section(String title)=>Padding(padding:const EdgeInsets.only(top:24,bottom:12),child:MobileSectionTitle(title:title));
    return RefreshIndicator(onRefresh:onRefresh,child:ListView.builder(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(16),itemCount:categories.length+recent.length+6,itemBuilder:(context,i){
      if(i==0)return MobilePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(trackText(track,'Name',ar),style:theme.textTheme.titleLarge),
        if(p['CompletionPercent'] is num)...[const SizedBox(height:12),LinearProgressIndicator(value:((p['CompletionPercent'] as num)/100).clamp(0.0,1.0).toDouble(),color:AppColors.progressFill((p['CompletionPercent'] as num)/100),backgroundColor:AppColors.progressTrack(context))],
        metric(ar?'نسبة الإنجاز':'Completion',percent(p['CompletionPercent'])),
        metric(ar?'المسائل المحلولة':'Solved','${p['Solved']} / ${p['ProblemsCount']}'),
        metric(ar?'دقة المحاولات المسجلة':'Recorded attempt accuracy',percent(p['AccuracyPercent'])),
        metric(ar?'النقاط المكتسبة':'Earned points',p['Points'],tint:gold),
        metric(ar?'المحاولات المسجلة':'Recorded attempts',p['Attempts']),
        Text(ar?'الإنجاز والإتقان للدورة الحالية؛ الدقة والنقاط وسجل المحاولات للتاريخ المسجل في هذا الصف.':'Completion and mastery reflect the current cycle; accuracy, points and attempts reflect recorded history in this grade.',style:theme.textTheme.bodySmall),
      ]));
      if(i==1)return section(ar?'الأداء حسب الفئة':'Performance by category');
      if(i<categories.length+2){
        final c=categories[i-2],mastery=c['MasteryPercent'];
        final attempts=trackNumber(c['Attempts']);
        final status=attempts==0?(ar?'لم تبدأ بعد':'Not started'):mastery is num&&mastery>=80?(ar?'نقطة قوة':'Strength'):(ar?'واصل التدريب':'Keep practicing');
        return Padding(padding:const EdgeInsets.only(bottom:12),child:MobilePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(trackText(c,'Name',ar),style:theme.textTheme.titleMedium),Text(status,style:theme.textTheme.bodySmall),
          metric(ar?'المسائل المحلولة':'Solved','${c['Solved']} / ${c['ProblemsCount']}'),
          metric(ar?'المحاولات':'Attempts',c['Attempts']),metric(ar?'الإتقان':'Mastery',percent(mastery)),metric(ar?'الدقة':'Accuracy',percent(c['AccuracyPercent'])),
        ])));
      }
      if(i==categories.length+2)return categoryPages>1?MathWorldPagination(page:cp,pageCount:categoryPages,arabic:ar,onChanged:(p)=>setState(()=>_categoryPage=p)):const SizedBox.shrink();
      if(i==categories.length+3)return section(ar?'المحاولات الأخيرة':'Recent attempts');
      final index=i-categories.length-4;
      if(index==recent.length+1)return attemptPages>1?MathWorldPagination(page:ap,pageCount:attemptPages,arabic:ar,onChanged:(p)=>setState(()=>_attemptPage=p)):const SizedBox.shrink();
      if(index==recent.length)return Padding(padding:const EdgeInsets.only(top:12),child:Text(recent.isEmpty?(ar?'لا توجد محاولات مسجلة لهذا الصف.':'No recorded attempts for this grade.'):(ar?'آخر 10 محاولات مسجلة كحد أقصى.':'Up to 10 most recent recorded attempts.')));
      final a=recent[index],correct=a['IsCorrect']==true;
      final date=DateTime.tryParse(a['SubmittedAtUtc']?.toString()??'')?.toLocal();
      return ListTile(leading:Icon(correct?Icons.check_circle_outline:Icons.cancel_outlined,color:correct?AppColors.success:theme.colorScheme.error),title:Text(trackText(a,'Title',ar),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(date==null?'—':DateFormat.yMMMd(context.locale.languageCode).add_jm().format(date)),trailing:Text('+${a['PointsEarned']??0}',style:TextStyle(color:gold,fontWeight:FontWeight.bold)));
    }));
  }
}
