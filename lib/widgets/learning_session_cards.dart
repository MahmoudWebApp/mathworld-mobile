import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_journey.dart';
import '../providers/auth_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/stage_category_access_provider.dart';
import '../providers/learning_journey_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../screens/home/learning_session_screen.dart';
import '../services/learning_session_api.dart';

typedef SessionCardKey=({int userId,int stageId,int? trackId});
final _dailySessionProvider=FutureProvider.autoDispose.family<Map<String,dynamic>?,SessionCardKey>((ref,key){
  return LearningSessionApi(ref.watch(apiClientProvider)).current(SessionScope(kind:'daily',stageId:key.stageId,trackId:key.trackId));
});
final _sessionAchievementsProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,int>((ref,id){
  return LearningSessionApi(ref.watch(apiClientProvider)).achievements();
});
class LearningSessionCards extends ConsumerWidget{
  final LearningJourney journey;
  const LearningSessionCards({super.key,required this.journey});
  @override Widget build(BuildContext context,WidgetRef ref){
    final user=ref.watch(authProvider.select((s)=>s.user));
    if(!journey.learningSessionsEnabled||user?.role!='Student'||user?.currentStageId!=journey.stageId||user==null)return const SizedBox.shrink();
    final ar=context.locale.languageCode=='ar';
    final premium=ref.watch(studentPremiumProvider).valueOrNull==true;
    final key=(userId:user.id,stageId:journey.stageId,trackId:journey.trackId);
    final daily=premium?ref.watch(_dailySessionProvider(key)):null;
    final achievements=ref.watch(_sessionAchievementsProvider(user.id));
    Future<void> open(String kind) async {
      await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>LearningSessionScreen(scope:SessionScope(kind:kind,stageId:journey.stageId,trackId:journey.trackId))));
      if(!context.mounted)return;
      ref.invalidate(_dailySessionProvider(key));ref.invalidate(_sessionAchievementsProvider(user.id));
      ref.invalidate(learningJourneyProvider);ref.invalidate(dashboardProvider);ref.invalidate(leaderboardProvider);
    }
    final complete=daily?.valueOrNull?['IsComplete']==true;
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Card(child:ListTile(leading:const Icon(Icons.school_outlined),title:Text(ar?'جلسة تدريب':'Practice session'),subtitle:Text(ar?'من 5 إلى 10 مسائل':'5 to 10 questions'),onTap:()=>open('practice'),trailing:const Icon(Icons.chevron_right))),
      if(premium&&!complete)Card(child:ListTile(leading:const Icon(Icons.emoji_events_outlined),title:Text(ar?'تحدي اليوم':'Daily challenge'),subtitle:Text(daily?.isLoading==true?(ar?'جارٍ التحقق…':'Checking…'):daily?.hasError==true?(ar?'تعذّر تحميل التحدي':'Challenge unavailable'):daily?.valueOrNull!=null?'${daily!.valueOrNull!['Completed']} / 5':ar?'5 مسائل':'5 questions'),onTap:()=>open('daily'),trailing:const Icon(Icons.chevron_right))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(ar?'إنجازات التدريب والتحديات':'Practice and challenge achievements',style:Theme.of(context).textTheme.titleMedium),
        achievements.when(loading:()=>const LinearProgressIndicator(),error:(_,__)=>TextButton(onPressed:()=>ref.invalidate(_sessionAchievementsProvider(user.id)),child:Text(ar?'إعادة المحاولة':'Retry')),data:(data)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${ar?'جلسات مكتملة':'Completed sessions'}: ${sessionInt(data['CompletedPracticeSessions'])} · ${ar?'تحديات':'Challenges'}: ${sessionInt(data['CompletedDailyChallenges'])}'),
          Wrap(spacing:8,runSpacing:8,children:[for(final badge in sessionRows(data['Badges']))Chip(avatar:const Icon(Icons.military_tech),label:Text(sessionText(badge,ar?'TitleAr':'TitleEn')))]),
        ])),
      ]))),
      const SizedBox(height:16),
    ]);
  }
}
