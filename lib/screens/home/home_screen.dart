import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../core/network/api_envelope.dart';
import '../../models/learning_journey.dart';
import '../../models/daily_challenge.dart';
import '../../models/problem_search.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../providers/student_badges_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';
import '../../widgets/student_badges_card.dart';
import '../../widgets/rich_math_text.dart';
import '../../widgets/learning_session_cards.dart';
import '../certificates/certificates_screen.dart';
import '../premium/custom_exams_screen.dart';

import '../../widgets/mobile_section.dart';
import '../../widgets/premium_button.dart';

/// Show navigation immediately; independent failures must not block the home page.
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenStages;
  const HomeScreen({super.key,required this.onOpenStages});
  @override ConsumerState<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _resuming=false;
  @override Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final user=ref.watch(authProvider.select((s)=>(name:s.user?.fullName??'',premium:s.user?.subscriptionType.toLowerCase()=='premium')));
    final journeyState=ref.watch(learningJourneyProvider);
    final j=journeyState.valueOrNull;
    final dashboardState=ref.watch(dashboardProvider);
    final dashboard=dashboardState.valueOrNull;
    final examsEnabled=ref.watch(customExamAvailabilityProvider).valueOrNull==true;
    final primary=Theme.of(context).colorScheme.primary;
    final gold=AppColors.pointsGold(context);
    final stageAccent=j==null?primary:AppColors.stageForIdentity(j.stageId,j.nameAr);
    String tr(String a,String e)=>ar?a:e;
    Future<void> resumeNextProblem() async {
      if(_resuming)return;
      final learner = ref.read(authProvider).user;
      final stageId = learner?.currentStageId;
      // Free students start from their unlocked categories.
      if (learner?.subscriptionType.toLowerCase() != 'premium' ||
          stageId == null || stageId <= 0) {
        widget.onOpenStages();
        return;
      }
      setState(()=>_resuming=true);
      try {
        // Read the selected journey first; an active track never falls back
        // to the whole-stage search if resume is temporarily unavailable.
        final journey = await ref.read(learningJourneyProvider.future);
        if (!context.mounted) return;
        if (journey == null) { widget.onOpenStages(); return; }
        if (journey.trackId != null) {
          final response = await ref.read(apiClientProvider).get('/users/learning-tracks/continue');
          final payload = ApiEnvelope.map(response.data);
          if (!context.mounted) return;
          if (payload['TrackId'] != journey.trackId || payload['Problem'] is! Map) {
            widget.onOpenStages(); return;
          }
          final id = (payload['Problem'] as Map)['Id'];
          if (id is! int || id <= 0) { widget.onOpenStages(); return; }
          final submitted=await Navigator.pushNamed(context, AppRoutes.problemDetails, arguments: id);
          if (context.mounted&&submitted==true) {
            ref.invalidate(dashboardProvider);
            ref.invalidate(learningJourneyProvider);
          }
          return;
        }
        // The server excludes solved work before pagination.
        final result = await ref.read(problemsRepositoryProvider).search(
          ProblemSearchParams(stageId: stageId, hideSolved: true, pageSize: 1),
          context.locale.languageCode,
        );
        if (!context.mounted) return;
        if (result.problems.isEmpty) {
          showMathWorldNotice(context,context.locale.languageCode == 'ar'
                ? 'أنجزت المسائل المتاحة في مرحلتك. يمكنك استكشاف الفئات.'
                : 'You have completed the available questions in this stage.',kind:MathWorldNoticeKind.success);
          widget.onOpenStages();
          return;
        }
        final submitted=await Navigator.pushNamed(
          context, AppRoutes.problemDetails,
          arguments: result.problems.first.id,
        );
        if(context.mounted&&submitted==true){ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);}
      } catch (_) {
        if (!context.mounted) return;
        showMathWorldNotice(context,context.locale.languageCode == 'ar'
              ? 'تعذّر تحديد المسألة التالية. يمكنك المتابعة من الفئات.'
              : 'Could not load the next question. Browse your topics.',kind:MathWorldNoticeKind.error);
        widget.onOpenStages();
      }finally{if(mounted)setState(()=>_resuming=false);}
    }

    final sections=<Widget>[
      Row(children:[
        CircleAvatar(radius:23,backgroundColor:primary.withValues(alpha:.12),foregroundColor:primary,
          child:const Icon(Icons.person_outline_rounded)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(user.name.isEmpty?tr('أهلاً بك','Welcome'):user.name,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800),maxLines:2,overflow:TextOverflow.ellipsis),
          Text([if(j!=null)j.getName(context.locale.languageCode),user.premium?'Premium':'Free'].join(' · '),style:Theme.of(context).textTheme.bodySmall?.copyWith(color:stageAccent,fontWeight:FontWeight.w700)),
        ])),
      ]),
      MobilePanel(gradient:Theme.of(context).brightness==Brightness.dark?AppGradients.darkHero:AppGradients.lightHero,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(tr('تقدمك الدراسي','Your progress'),style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:12),
        if(j!=null||dashboard!=null)...[
          Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Expanded(child:_Metric(label:tr('النقاط','Points'),value:'${j?.displayedPoints??dashboard!.totalPoints}',color:gold,icon:Icons.star_rounded)),
            Expanded(child:_Metric(label:tr('المحلولة','Solved'),value:j==null?'${dashboard!.solvedProblemsCount}':'${j.solvedProblems}/${j.totalProblems}',color:AppColors.success)),
            Expanded(child:_Metric(label:tr('الإنجاز','Progress'),value:j==null?'—':'${j.completionPercent}%',color:stageAccent)),
          ]),
          if(j!=null)...[const SizedBox(height:12),LinearProgressIndicator(value:(j.completionPercent/100).clamp(0.0,1.0).toDouble(),color:AppColors.success,borderRadius:BorderRadius.circular(8))],
        ]else if(journeyState.isLoading||dashboardState.isLoading)
          Row(children:[const AppInlineLoader(size:18),const SizedBox(width:10),Expanded(child:Text(tr('جارٍ تحميل تقدمك…','Loading your progress…'),style:Theme.of(context).textTheme.bodySmall))])
        else
          TextButton.icon(onPressed:(){ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);},icon:const Icon(Icons.refresh),label:Text(tr('تعذّر تحميل التقدم · إعادة المحاولة','Progress unavailable · Retry'))),
        if(j==null&&journeyState.hasError&&dashboard!=null)
          TextButton(onPressed:()=>ref.invalidate(learningJourneyProvider),child:Text(tr('تحديث تقدم الصف','Refresh grade progress'))),
      ])),
      MobilePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(children:[Icon(Icons.auto_stories_outlined,color:stageAccent),const SizedBox(width:8),Expanded(child:Text(tr('تابع التعلم','Continue learning'),style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)))]),
        const SizedBox(height:8),
        Text(j?.recommendedCategory?.getName(context.locale.languageCode)??tr('استكشف الفئات المتاحة لك','Explore your available topics')),
        const SizedBox(height:12),
        PremiumButton(onPressed:resumeNextProblem,isLoading:_resuming,expand:true,label:tr('متابعة التعلم','Continue learning'),trailingIcon:Icons.arrow_forward_rounded),
      ])),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        MobileSectionTitle(title:tr('أدوات التعلم','Learning tools')),
        const SizedBox(height:8),
        MobilePanel(padding:EdgeInsets.zero,child:Column(children:[
          MobileActionRow(icon:Icons.insights_rounded,color:const Color(0xFF0F766E),title:tr('التقارير والإحصائيات','Reports & analytics'),subtitle:tr('تقدمك في الصف الحالي','Your current grade progress'),onTap:()=>Navigator.pushNamed(context,AppRoutes.premiumReport)),
          if(examsEnabled)...[const Divider(height:1,indent:12,endIndent:12),MobileActionRow(icon:Icons.school_outlined,color:primary,title:tr('الامتحانات المخصصة','Custom exams'),subtitle:tr('اختبر نفسك واحصل على شهادة','Test yourself and earn a certificate'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const CustomExamsScreen())))],
          if(j?.learningSessionsEnabled==true)...[const Divider(height:1,indent:12,endIndent:12),MobileActionRow(icon:Icons.calculate_outlined,color:primary,title:tr('التدريب والتحديات','Practice & challenges'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>_TrainingScreen(journey:j!))))],
          if(j!=null&&!j.learningSessionsEnabled&&user.premium)...[const Divider(height:1,indent:12,endIndent:12),MobileActionRow(icon:Icons.emoji_events_outlined,color:gold,title:tr('تحدي اليوم','Daily challenge'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const _DailyChallengeScreen())))],
          const Divider(height:1,indent:12,endIndent:12),
          MobileActionRow(icon:Icons.auto_stories_outlined,color:primary,title:tr('دفتر الأخطاء','Error notebook'),onTap:()=>Navigator.pushNamed(context,AppRoutes.errorNotebook)),
          const Divider(height:1,indent:12,endIndent:12),
          MobileActionRow(icon:Icons.emoji_events_outlined,color:gold,title:tr('المتفوقون','Leaderboard'),onTap:()=>Navigator.pushNamed(context,AppRoutes.leaderboard)),
        ])),
      ]),
      if(!user.premium)MobilePanel(padding:EdgeInsets.zero,child:MobileActionRow(icon:Icons.workspace_premium_rounded,color:gold,title:tr('مميزات Premium','Premium benefits'),subtitle:tr('افتح جميع الفئات والتقارير والحلول','Unlock topics, reports and solutions'),onTap:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits))),
      StudentBadgesCard(loadSummary:j!=null||dashboard!=null),
      if(j?.certificatesEnabled==true||examsEnabled)CertificateHomeSummary(journey:j,examsEnabled:examsEnabled,loadSummary:j!=null||dashboard!=null),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        MobileSectionTitle(title:tr('آخر النشاطات','Recent activity'),actionLabel:tr('عرض الكل','View all'),onAction:()=>Navigator.pushNamed(context,AppRoutes.solved)),
        if(dashboardState.isLoading&&dashboard==null)const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Center(child:AppInlineLoader(size:18)))
        else if(dashboard==null)TextButton(onPressed:()=>ref.invalidate(dashboardProvider),child:Text(tr('إعادة تحميل النشاطات','Reload activity')))
        else if(dashboard.recentActivities.isEmpty)Text('no_activity_yet'.tr())
        else MobilePanel(padding:EdgeInsets.zero,child:Column(children:[
          for(final activity in dashboard.recentActivities.take(3))ListTile(
            leading:const Icon(Icons.check_circle_outline_rounded,color:AppColors.success),
            title:RichMathText(text:activity.title,inline:true,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleSmall),
            subtitle:Text(activity.categoryName,maxLines:1,overflow:TextOverflow.ellipsis),
            trailing:LayoutUtils.forwardIcon(context),
            onTap:()=>Navigator.pushNamed(context,AppRoutes.problemDetails,arguments:activity.problemId),
          ),
        ])),
      ]),
    ];
    return MathBackground(showSymbols:false,child:SafeArea(bottom:false,child:RefreshIndicator(
      onRefresh:()async{
        ref.invalidate(studentBadgesProvider);
        try{await Future.wait([ref.refresh(dashboardProvider.future),ref.refresh(learningJourneyProvider.future)]);}catch(_){}
      },
      child:ListView.separated(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,24),
        itemCount:sections.length,itemBuilder:(_,i)=>sections[i],separatorBuilder:(_,__)=>const SizedBox(height:16)),
    )));
  }
}
class _Metric extends StatelessWidget {
  final String label,value;
  final Color color;
  final IconData? icon;
  const _Metric({required this.label,required this.value,required this.color,this.icon});
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[if(icon!=null)...[Icon(icon,color:color,size:16),const SizedBox(width:4)],Flexible(child:Text(value,style:Theme.of(context).textTheme.titleMedium?.copyWith(color:color,fontWeight:FontWeight.w800),maxLines:1,overflow:TextOverflow.ellipsis))]),
    Text(label,style:Theme.of(context).textTheme.labelSmall,maxLines:2),
  ]);
}
class _TrainingScreen extends StatelessWidget {
  final LearningJourney journey;
  const _TrainingScreen({required this.journey});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(context.locale.languageCode=='ar'?'التدريب والتحديات':'Practice & challenges')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[LearningSessionCards(journey:journey)])));
}
class _DailyChallengeScreen extends ConsumerWidget {
  const _DailyChallengeScreen();
  @override Widget build(BuildContext context,WidgetRef ref){
    final state=ref.watch(dailyChallengeProvider);
    final ar=context.locale.languageCode=='ar';
    return Scaffold(appBar:AppBar(title:Text(ar?'تحدي اليوم':'Daily challenge')),body:SafeArea(child:state.when(
      loading:()=>const AppContentSkeleton(count:3),
      error:(e,_)=>AppErrorView(message:localizedErrorMessage(e),onRetry:()=>ref.invalidate(dailyChallengeProvider)),
      data:(challenge)=>challenge==null?Center(child:Text(ar?'لا يوجد تحدٍ متاح حالياً':'No challenge currently available')):ListView(padding:const EdgeInsets.all(16),children:[
        _DailyPracticeCard(challenge:challenge,onOpen:(id)async{
          var nextId=id;
          for(var step=0;step<5;step++){
            final submitted=await Navigator.pushNamed(context,AppRoutes.problemDetails,arguments:{'problemId':nextId,'dailyChallenge':true});
            if(!context.mounted||submitted!=true)break;
            ref.invalidate(dailyChallengeProvider);ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);ref.invalidate(studentBadgesProvider);
            try{
              final latest=await ref.read(dailyChallengeProvider.future);
              if(!context.mounted||latest==null)break;
              final waiting=latest.problems.where((p)=>!p.isAnswered);
              if(waiting.isEmpty)break;
              nextId=waiting.first.id;
            }catch(_){break;}
          }
        }),
      ]),
    )));
  }
}
class _DailyPracticeCard extends StatelessWidget {
  const _DailyPracticeCard({
    required this.challenge,
    required this.onOpen,
  });

  final DailyChallenge challenge;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final color = Theme.of(context).colorScheme.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.today_outlined, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(
              ar ? 'تحدي اليوم' : 'Daily challenge',
              style: Theme.of(context).textTheme.titleLarge,
            )),
            Text('${challenge.completed}/${challenge.total}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text(ar
            ? 'خمس مسائل متنوعة من فئات مرحلتك تتجدد كل يوم بتوقيت UTC. التدريب العادي غير محدود.'
            : 'Five questions across your stage, refreshed daily at UTC midnight. Regular practice remains unlimited.',
            style: Theme.of(context).textTheme.bodySmall),
          if (challenge.dateUtc.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateTime.tryParse(challenge.dateUtc) == null
                  ? challenge.dateUtc
                  : MaterialLocalizations.of(context).formatMediumDate(
                      DateTime.parse(challenge.dateUtc)),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (challenge.problems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            // Five stable progress indicators: correct, wrong, current or
            // upcoming. These are statuses, not links to skip questions.
            Row(children: [
              for (var index = 0; index < challenge.problems.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    label: ar
                        ? 'المسألة ${index + 1}: ${challenge.problems[index].isAnswered ? (challenge.problems[index].isSolved ? 'صحيحة' : 'تحتاج مراجعة') : (index == challenge.completed ? 'الحالية' : 'قادمة')}'
                        : 'Question ${index + 1}: ${challenge.problems[index].isAnswered ? (challenge.problems[index].isSolved ? 'Correct' : 'Needs review') : (index == challenge.completed ? 'Current' : 'Upcoming')}',
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: challenge.problems[index].isAnswered
                            ? (challenge.problems[index].isSolved
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12))
                            : index == challenge.completed
                                ? color.withValues(alpha: 0.13)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: challenge.problems[index].isAnswered
                              ? (challenge.problems[index].isSolved
                                  ? AppColors.success : AppColors.warning)
                              : index == challenge.completed
                                  ? color
                                  : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${index + 1}',
                            style: Theme.of(context).textTheme.labelSmall),
                          if (challenge.problems[index].isAnswered)
                            Icon(
                              challenge.problems[index].isSolved
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.error_outline_rounded,
                              size: 16,
                              color: challenge.problems[index].isSolved
                                  ? AppColors.success : AppColors.warning,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ],
          const SizedBox(height: AppSpacing.md),
          if (challenge.problems.isEmpty)
            Text(ar ? 'لا توجد مسائل جديدة لتحدي اليوم.' :
              'No new challenge questions are available today.')
          else if (challenge.problems.every((problem) => problem.isAnswered))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events_outlined,
                  size: 34, color: AppColors.rewardGold),
                const SizedBox(height: AppSpacing.sm),
                Text(ar ? 'أكملت تحدي اليوم!' : 'Daily challenge complete!',
                  style: Theme.of(context).textTheme.titleMedium),
                Text(ar
                  ? '${challenge.correct} صحيحة · ${challenge.completed - challenge.correct} تحتاج مراجعة'
                  : '${challenge.correct} correct · ${challenge.completed - challenge.correct} to review'),
              ],
            )
          else
            Builder(builder: (context) {
              final waiting = challenge.problems.where((p) => !p.isAnswered).first;
              final index = challenge.problems.indexWhere((p) => p.id == waiting.id);
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                title: RichMathText(
                  text: waiting.getName(context.locale.languageCode),
                  isArabic: ar, inline: true, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(ar
                  ? 'المسألة ${index + 1} من ${challenge.total} · ابدأ التحدي'
                  : 'Problem ${index + 1} of ${challenge.total} · Start challenge'),
                trailing: LayoutUtils.forwardIcon(context, color: color),
                onTap: () => onOpen(waiting.id),
              );
            }),
        ],
      ),
    );
  }
}

