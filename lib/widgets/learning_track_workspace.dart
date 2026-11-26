import 'app_states.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/design_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'math_background.dart';
import 'mathworld_pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_routes.dart';
import '../core/network/api_envelope.dart';
import '../core/utils/error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/learning_journey_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/premium_analytics_provider.dart';
import '../providers/premium_reports_provider.dart';
import '../providers/learning_tracks_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/user_lists_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/problems_provider.dart';
import '../providers/problem_details_provider.dart';
import '../providers/student_badges_provider.dart';
import '../providers/leaderboard_provider.dart';

class LearningTrackWorkspace extends ConsumerStatefulWidget {
  final int stageId;
  final TrackCatalog catalog;
  const LearningTrackWorkspace({super.key,required this.stageId,required this.catalog});
  @override
  ConsumerState<LearningTrackWorkspace> createState()=>_LearningTrackWorkspaceState();
}
class _LearningTrackWorkspaceState extends ConsumerState<LearningTrackWorkspace> {
  bool _busy=false;
  bool _changing=false;
  String? _error;
  Future<void> _choose(int id) async {
    if(_busy)return;
    final actor=ref.read(authProvider).user?.id;
    setState((){_busy=true;_error=null;});
    try{
      final response=await ref.read(apiClientProvider).put('/users/learning-track',data:{'TrackId':id});
      final result=ApiEnvelope.map(response.data);
      if(trackNumber(result['TrackId'])!=id||trackNumber(result['StageId'])!=widget.stageId)throw StateError('Invalid track selection response');
      if(!mounted||ref.read(authProvider).user?.id!=actor)return;
      await ref.read(authProvider.notifier).refreshProfile();
      if(!mounted||ref.read(authProvider).user?.id!=actor)return;
      ref.invalidate(trackSelectionProvider);
      ref.invalidate(trackPracticeProvider);
      ref.invalidate(trackProgressProvider);
      ref.invalidate(solvedProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(errorNotebookProvider);
      ref.invalidate(problemDetailsProvider);
      ref.invalidate(problemsProvider);
      ref.invalidate(leaderboardProvider);
      ref.invalidate(studentBadgesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(learningJourneyProvider);
      ref.invalidate(dailyChallengeProvider);
      ref.invalidate(premiumAnalyticsProvider);
      ref.invalidate(filteredPremiumAnalyticsProvider);
      ref.invalidate(premiumProgressReportProvider);
      Navigator.pushNamedAndRemoveUntil(context,AppRoutes.home,(_)=>false);
    }catch(error){
      if(mounted)setState(()=>_error=localizedErrorMessage(error));
    }finally{
      if(mounted)setState(()=>_busy=false);
    }
  }
  @override
  Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final selection=ref.watch(trackSelectionProvider);
    if(selection.isLoading&&!selection.hasValue)return const AppContentSkeleton(cards:true);
    if(selection.hasError)return AppErrorView(message:localizedErrorMessage(selection.error!),onRetry:()=>ref.invalidate(trackSelectionProvider));
    final current=selection.valueOrNull;
    final id=trackNumber(current?['TrackId']);
    final selected=trackNumber(current?['StageId'])==widget.stageId && widget.catalog.items.any((t)=>trackNumber(t['Id'])==id);
    if(selected&&!_changing)return _TrackContent(key:ValueKey(id),id:id,onChange:()=>setState(()=>_changing=true));
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text(ar?'اختر الصف أو المستوى':'Choose grade or level',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:8),
      const SizedBox(height:4),
      for(final track in widget.catalog.items) Card(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.stageForOrder(widget.stageId).withValues(alpha: .4))), child:ListTile(
        title:Text(trackText(track,'Name',ar)),
        subtitle:Text('${trackNumber(track['ProblemsCount'])} ${ar?'مسألة':'problems'}${track['FreeProblemsCount']!=null&&trackNumber(track['FreeProblemsCount'])==0?'\n${ar?'التدريب لمشتركي Premium':'Premium practice only'}':''}'),
        trailing:track['Id']==id?const Icon(Icons.check_circle_outline):null,
        enabled:!_busy,onTap:()=>_choose(trackNumber(track['Id'])),
      )),
      if(_busy)const LinearProgressIndicator(),
      if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
      if(selected)TextButton(onPressed:_busy?null:()=>setState(()=>_changing=false),child:Text(ar?'إلغاء':'Cancel')),
      TextButton(onPressed:_busy?null:()=>Navigator.pushNamed(context,AppRoutes.learningStage),child:Text(ar?'تغيير المرحلة':'Change stage')),
    ]);
  }
}

class _TrackContent extends ConsumerStatefulWidget{
  final int id;final VoidCallback onChange;
  const _TrackContent({super.key,required this.id,required this.onChange});
  @override
  ConsumerState<_TrackContent> createState()=>_TrackContentState();
}
class _TrackContentState extends ConsumerState<_TrackContent>{
  int get id=>widget.id;
  bool _resetting=false;
  Future<void> _reset(int stageId,String name,{int? categoryId}) async{
    if(_resetting)return;
    final actor=ref.read(authProvider).user?.id;
    if(actor==null)return;
    final ar=context.locale.languageCode=='ar';
    setState(()=>_resetting=true);
    try{
      final accepted=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
        title:Text(ar?'تأكيد إعادة التدريب':'Confirm practice restart'),
        content:Text('$name\n\n'+(ar?'يعود تقدم التدريب ودفتر الأخطاء في هذا النطاق فقط إلى البداية. النقاط الدائمة والمفضلة والشهادات وتقدم الصفوف الأخرى محفوظة.':'Only practice progress and review errors in this scope reset. Lifetime points, favorites, certificates and other tracks remain.')),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:Text(ar?'إلغاء':'Cancel')),FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:Text(ar?'تأكيد':'Confirm'))]));
      if(accepted!=true||!mounted||ref.read(authProvider).user?.id!=actor)return;
      final selection=ref.read(trackSelectionProvider).valueOrNull;
      if(selection?['StageId']!=stageId||selection?['TrackId']!=id)throw StateError('Practice scope changed');
      await ref.read(apiClientProvider).post('/users/practice/reset',data:{'StageId':stageId,'TrackId':id,if(categoryId!=null)'CategoryId':categoryId});
      if(!mounted||ref.read(authProvider).user?.id!=actor)return;
      ref.invalidate(trackProgressProvider(id));ref.invalidate(trackPracticeProvider);
      ref.invalidate(learningJourneyProvider);ref.invalidate(dashboardProvider);
      ref.invalidate(solvedProvider);ref.invalidate(errorNotebookProvider);ref.invalidate(favoritesProvider);
      ref.invalidate(problemsProvider);ref.invalidate(dailyChallengeProvider);ref.invalidate(studentBadgesProvider);
      ref.invalidate(premiumAnalyticsProvider);ref.invalidate(filteredPremiumAnalyticsProvider);ref.invalidate(leaderboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ar?'بدأ تدريب جديد ضمن النطاق المحدد.':'A new practice cycle has started in the selected scope.')));
    }catch(error){
      if(mounted&&ref.read(authProvider).user?.id==actor)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(localizedErrorMessage(error))));
    }finally{if(mounted)setState(()=>_resetting=false);}
  }
  @override
  Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final detail=ref.watch(trackDetailsProvider(id));final progress=ref.watch(trackProgressProvider(id));
    void reload(){ref.invalidate(trackDetailsProvider(id));ref.invalidate(trackProgressProvider(id));}
    if(detail.hasError||progress.hasError)return AppErrorView(message:localizedErrorMessage(detail.error??progress.error!),onRetry:reload);
    final d=detail.valueOrNull;final p=progress.valueOrNull;
    if(d==null||p==null)return const AppContentSkeleton(cards:true);
    final rawTrack=d['Track'];
    if(rawTrack is! Map)return AppErrorView(onRetry:reload,message:ar?'تعذّر قراءة بيانات الصف أو المساق':'Could not read grade or course data');
    final track=Map<String,dynamic>.from(rawTrack);
    final stats={for(final c in trackRows(p['Categories']))trackNumber(c['CategoryId']):c};
    final percent=double.tryParse(p['CompletionPercent']?.toString()??'')??0;
    final accent=AppColors.stageForOrder(trackNumber(track['StageId']));
    return RefreshIndicator(onRefresh:()async{reload();await ref.read(trackProgressProvider(id).future);},child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Text(trackText(track,'Name',ar),style:Theme.of(context).textTheme.headlineSmall?.copyWith(color:accent,fontWeight:FontWeight.w800))),TextButton(onPressed:_resetting?null:widget.onChange,child:Text(ar?'تغيير':'Change'))]),
      Row(children:[Expanded(child:Text(ar?'التقدم':'Progress')),Text('${trackNumber(p['Solved'])}/${trackNumber(p['ProblemsCount'])} · ${percent.toStringAsFixed(1)}%',style:TextStyle(color:accent,fontWeight:FontWeight.w700))]),
      const SizedBox(height:8),
      LinearProgressIndicator(value:(percent/100).clamp(0.0,1.0).toDouble(),color:accent,borderRadius:BorderRadius.circular(8)),
      if(p['TrackPracticeIsolationEnabled']==true&&stats.values.any((c)=>trackNumber(c['Attempted'])>0))
        OutlinedButton.icon(onPressed:_resetting?null:()=>_reset(trackNumber(p['StageId']),trackText(track,'Name',ar)),icon:const Icon(Icons.restart_alt),label:Text(ar?'إعادة تدريب الصف أو المساق':'Restart grade or course')),
      const SizedBox(height:16),
      for(final c in trackRows(d['Categories'])) Card(color:Theme.of(context).brightness==Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:accent.withValues(alpha:.45))),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[_TrackTopicIcon(value:c['Icon']?.toString()??'',accent:accent),const SizedBox(width:10),Expanded(child:Text(trackText(c,'Name',ar),style:Theme.of(context).textTheme.titleMedium?.copyWith(color:accent,fontWeight:FontWeight.w800))),const SizedBox(width:8),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),decoration:BoxDecoration(color:accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(8)),child:Text('${trackNumber(c['ProblemsCount'])} ${ar?'مسألة':'problems'}',style:TextStyle(color:accent,fontSize:12,fontWeight:FontWeight.w700)))]),
        const SizedBox(height:8),
        if(trackText(c,'Description',ar).isNotEmpty)Text(trackText(c,'Description',ar)),
        const SizedBox(height:8),
        Text('${ar?'محلولة':'Solved'}: ${trackNumber(stats[trackNumber(c['Id'])]?['Solved'])}/${trackNumber(c['ProblemsCount'])}',style:Theme.of(context).textTheme.bodySmall),
        const SizedBox(height:6),
        LinearProgressIndicator(value:trackNumber(c['ProblemsCount'])>0?(trackNumber(stats[trackNumber(c['Id'])]?['Solved'])/trackNumber(c['ProblemsCount'])).clamp(0.0,1.0).toDouble():0,color:accent,borderRadius:BorderRadius.circular(8)),
        const SizedBox(height:6),
        Wrap(spacing:8,children:[
          TextButton(style:TextButton.styleFrom(foregroundColor:accent),onPressed:()=>showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:Text(ar?'المهارات':'Skills'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
            for(final skill in trackRows(d['Skills']).where((s)=>s['CategoryId']==c['Id'])) ListTile(title:Text(trackText(skill,'Name',ar)),subtitle:Text(trackText(skill,'Description',ar))),
          ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(ar?'إغلاق':'Close'))])),child:Text(ar?'عرض المهارات':'View skills')),
          if(stats[trackNumber(c['Id'])]?['IsLocked']==false)
            FilledButton(style:FilledButton.styleFrom(backgroundColor:accent,foregroundColor:Colors.white),onPressed:()async{await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>_TrackPractice(id:id,categoryId:trackNumber(c['Id']),name:trackText(c,'Name',ar))));if(context.mounted)ref.invalidate(trackProgressProvider(id));},child:Text(ar?'عرض المسائل':'View problems'))
          else TextButton(style:TextButton.styleFrom(foregroundColor:accent),onPressed:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits),child:Text(ar?'ترقية الحساب':'Upgrade account')),
          if(p['TrackPracticeIsolationEnabled']==true&&stats[trackNumber(c['Id'])]?['IsLocked']==false&&trackNumber(stats[trackNumber(c['Id'])]?['Attempted'])>0)
            OutlinedButton(style:OutlinedButton.styleFrom(foregroundColor:accent,side:BorderSide(color:accent.withValues(alpha:.55))),onPressed:_resetting?null:()=>_reset(trackNumber(p['StageId']),trackText(c,'Name',ar),categoryId:trackNumber(c['Id'])),child:Text(ar?'إعادة تدريب الفئة':'Restart topic')),
        ]),
      ]))),
      TextButton(onPressed:()=>Navigator.pushNamed(context,AppRoutes.learningStage),child:Text(ar?'تغيير المرحلة':'Change stage')),
      if(trackRows(d['Categories']).isEmpty) AppEmptyView(icon:Icons.category_outlined,title:ar?'لا توجد فئات منشورة':'No published categories',action:TextButton(onPressed:reload,child:Text(ar?'تحديث':'Refresh'))),
    ]));
  }
}
class _TrackTopicIcon extends StatelessWidget {
  const _TrackTopicIcon({required this.value,required this.accent});
  final String value;
  final Color accent;
  @override
  Widget build(BuildContext context){
    final url=value.startsWith('/category-icons/')?'https://math-world-frontend.vercel.app$value':value;
    final uri=Uri.tryParse(url);
    final fallback=Icon(Icons.calculate_outlined,color:accent,size:27);
    Widget icon=fallback;
    if(uri!=null&&uri.scheme=='https'&&uri.host.isNotEmpty){
      icon=uri.path.toLowerCase().endsWith('.svg')
        ?SvgPicture.network(url,width:36,height:36,placeholderBuilder:(_)=>fallback,errorBuilder:(_,__,___)=>fallback)
        :Image.network(url,width:36,height:36,fit:BoxFit.contain,errorBuilder:(_,__,___)=>fallback);
    }
    return Container(width:44,height:44,decoration:BoxDecoration(color:accent.withValues(alpha:.1),borderRadius:BorderRadius.circular(12)),alignment:Alignment.center,child:ColorFiltered(colorFilter:AppColors.topicArtworkFilter(accent),child:icon));
  }
}
class _TrackPractice extends ConsumerStatefulWidget{
  final int id,categoryId;final String name;
  const _TrackPractice({required this.id,required this.categoryId,required this.name});
  @override ConsumerState<_TrackPractice> createState()=>_TrackPracticeState();
}
class _TrackPracticeState extends ConsumerState<_TrackPractice>{
  int _page=1;
  bool _hideSolved=false;
  @override Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final key=(trackId:widget.id,categoryId:widget.categoryId,page:_page,hideSolved:_hideSolved);
    final state=ref.watch(trackPracticeProvider(key));
    final data=state.valueOrNull;
    final rows=trackRows(data?['Items']);
    final visible=rows;
    return Scaffold(appBar:AppBar(title:Text(widget.name)),body:MathBackground(child:state.hasError?AppErrorView(message:localizedErrorMessage(state.error!),onRetry:()=>ref.invalidate(trackPracticeProvider(key))):data==null?const AppContentSkeleton():RefreshIndicator(onRefresh:()async{ref.invalidate(trackPracticeProvider(key));await ref.read(trackPracticeProvider(key).future);},child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(12),children:[
      FilterChip(label:Text(ar?'إخفاء المحلولة':'Hide solved'),selected:_hideSolved,onSelected:(value)=>setState((){_hideSolved=value;_page=1;})),
      if(visible.isEmpty) AppEmptyView(icon:Icons.calculate_outlined,title:ar?'لا توجد مسائل مطابقة':'No matching problems'),
      for(final problem in visible) Card(child:ListTile(title:Text(trackText(problem,'Title',ar)),subtitle:Text(problem['IsSolved']==true?(ar?'محلولة':'Solved'):(ar?'غير محلولة':'Unsolved')),onTap:()async{
        await Navigator.pushNamed(context,AppRoutes.problemDetails,arguments:trackNumber(problem['Id']));
        if(mounted){ref.invalidate(trackPracticeProvider(key));ref.invalidate(trackProgressProvider(widget.id));ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);}
      })),
      MathWorldPagination(page:_page,pageCount:trackNumber(data['PageSize'])<=0?1:(trackNumber(data['Total'])+trackNumber(data['PageSize'])-1)~/trackNumber(data['PageSize']),arabic:ar,onChanged:(p)=>setState(()=>_page=p)),
    ]))));
  }
}
