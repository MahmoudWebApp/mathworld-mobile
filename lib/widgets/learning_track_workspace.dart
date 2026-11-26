import 'app_states.dart';
import 'mobile_section.dart';
import 'rich_math_text.dart';
import '../utils/layout_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/design_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'mathworld_feedback.dart';
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
      final accepted=await showMathWorldConfirmation(context,
        title:ar?'تأكيد إعادة التدريب':'Confirm practice restart',
        message:'$name\n\n'+(ar?'يعود تقدم التدريب ودفتر الأخطاء في هذا النطاق فقط إلى البداية. النقاط الدائمة والمفضلة والشهادات وتقدم الصفوف الأخرى محفوظة.':'Only practice progress and review errors in this scope reset. Lifetime points, favorites, certificates and other tracks remain.'),
        cancel:ar?'إلغاء':'Cancel',confirm:ar?'تأكيد':'Confirm');
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
      showMathWorldNotice(context,ar?'بدأ تدريب جديد ضمن النطاق المحدد.':'A new practice cycle has started in the selected scope.',kind:MathWorldNoticeKind.success);
    }catch(error){
      if(mounted&&ref.read(authProvider).user?.id==actor)showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
    }finally{if(mounted)setState(()=>_resetting=false);}
  }
  @override
  Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final detail=ref.watch(trackDetailsProvider(id));final progress=ref.watch(trackProgressProvider(id));
    void reload(){ref.invalidate(trackDetailsProvider(id));ref.invalidate(trackProgressProvider(id));}
    if(detail.hasError&&!detail.hasValue)return AppErrorView(message:localizedErrorMessage(detail.error!),onRetry:reload);
    final d=detail.valueOrNull;
    if(d==null)return const AppContentSkeleton(cards:true);
    final p=progress.valueOrNull;
    final rawTrack=d['Track'];
    if(rawTrack is! Map)return AppErrorView(onRetry:reload,message:ar?'تعذّر قراءة بيانات الصف أو المستوى':'Could not read grade or level data');
    final track=Map<String,dynamic>.from(rawTrack);
    final stats={for(final c in trackRows(p?['Categories']))trackNumber(c['CategoryId']):c};
    final percent=double.tryParse(p?['CompletionPercent']?.toString()??'')??0;
    final accent=AppColors.stageForOrder(trackNumber(track['StageId']));
    final categories=trackRows(d['Categories']);
    final ordered=[...categories.where((c)=>c['IsFree']==true),...categories.where((c)=>c['IsFree']!=true)];
    void skills(Map<String,dynamic> c){
      final rows=trackRows(d['Skills']).where((s)=>s['CategoryId']==c['Id']).toList();
      showModalBottomSheet<void>(context:context,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:FractionallySizedBox(heightFactor:.62,child:Column(children:[
        Padding(padding:const EdgeInsets.all(16),child:Text(trackText(c,'Name',ar),style:Theme.of(ctx).textTheme.titleLarge)),
        Expanded(child:rows.isEmpty?Center(child:Text(ar?'لا توجد مهارات منشورة':'No published skills')):ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i)=>ListTile(title:Text(trackText(rows[i],'Name',ar)),subtitle:Text(trackText(rows[i],'Description',ar))))),
      ]))));
    }
    Future<void> open(Map<String,dynamic> c)async{
      final locked=stats[trackNumber(c['Id'])]?['IsLocked'];
      if(locked==true){Navigator.pushNamed(context,AppRoutes.premiumBenefits);return;}
      if(locked!=false){if(!progress.isLoading)ref.invalidate(trackProgressProvider(id));return;}
      await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>_TrackPractice(id:id,categoryId:trackNumber(c['Id']),name:trackText(c,'Name',ar))));
      // The practice screen invalidates progress only after a submitted answer.
    }
    return RefreshIndicator(onRefresh:()async{reload();try{await Future.wait([ref.read(trackDetailsProvider(id).future),ref.read(trackProgressProvider(id).future)]);}catch(_){}},child:CustomScrollView(
      physics:const AlwaysScrollableScrollPhysics(),slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,16,16,20),sliver:SliverToBoxAdapter(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Row(children:[Expanded(child:Text(trackText(track,'Name',ar),style:Theme.of(context).textTheme.headlineSmall?.copyWith(color:accent,fontWeight:FontWeight.w800))),TextButton(onPressed:_resetting?null:widget.onChange,child:Text(ar?'تغيير':'Change'))]),
          const SizedBox(height:8),
          if(p==null)
            if(progress.hasError)TextButton.icon(onPressed:()=>ref.invalidate(trackProgressProvider(id)),icon:const Icon(Icons.refresh),label:Text(ar?'تعذّر تحميل التقدم والصلاحيات':'Progress and access unavailable'))
            else const AppLoadingView(mode:AppLoadingMode.section)
          else MobilePanel(child:Column(children:[
            Row(children:[Expanded(child:Text(ar?'التقدم':'Progress')),Text('${trackNumber(p['Solved'])}/${trackNumber(p['ProblemsCount'])} · ${percent.toStringAsFixed(1)}%',style:TextStyle(color:accent,fontWeight:FontWeight.w700))]),
            const SizedBox(height:8),LinearProgressIndicator(value:(percent/100).clamp(0.0,1.0).toDouble(),color:accent,borderRadius:BorderRadius.circular(8)),
          ])),
          if(p?['TrackPracticeIsolationEnabled']==true&&stats.values.any((c)=>trackNumber(c['Attempted'])>0))
            Align(alignment:AlignmentDirectional.centerEnd,child:TextButton.icon(onPressed:_resetting?null:()=>_reset(trackNumber(p?['StageId']),trackText(track,'Name',ar)),icon:const Icon(Icons.restart_alt),label:Text(ar?'إعادة تدريب الصف':'Restart grade practice'))),
          const SizedBox(height:16),MobileSectionTitle(title:ar?'الفئات التعليمية':'Learning topics'),
        ]))),
        if(ordered.isEmpty)SliverToBoxAdapter(child:AppEmptyView(icon:Icons.category_outlined,title:ar?'لا توجد فئات منشورة':'No published categories',action:TextButton(onPressed:reload,child:Text(ar?'تحديث':'Refresh'))))
        else SliverPadding(padding:const EdgeInsets.symmetric(horizontal:16),sliver:SliverLayoutBuilder(builder:(context,constraints){
          final scale=MediaQuery.textScalerOf(context).scale(14)/14;
          final columns=constraints.crossAxisExtent<300||scale>1.35?1:constraints.crossAxisExtent>=700?3:2;
          return SliverGrid(delegate:SliverChildBuilderDelegate((context,i){
            final c=ordered[i],s=stats[trackNumber(ordered[i]['Id'])];
            final locked=s?['IsLocked'];final count=trackNumber(c['ProblemsCount']);final solved=trackNumber(s?['Solved']);
            return MobilePanel(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[_TrackTopicIcon(value:c['Icon']?.toString()??'',accent:accent),const Spacer(),
                if(locked==true)Icon(Icons.lock_outline,color:AppColors.pointsGold(context),size:18)
                else if(c['IsFree']==true)Text(ar?'مجاني':'Free',style:const TextStyle(color:AppColors.success,fontSize:11,fontWeight:FontWeight.w700)),
              ]),
              const SizedBox(height:8),
              Text(trackText(c,'Name',ar),maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleSmall?.copyWith(color:accent,fontWeight:FontWeight.w800)),
              const SizedBox(height:5),
              Text('${count} ${ar?'مسألة':'problems'}',style:Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              if(s!=null)...[
                Text('$solved/$count',style:Theme.of(context).textTheme.labelSmall),
                const SizedBox(height:4),LinearProgressIndicator(value:count>0?(solved/count).clamp(0.0,1.0).toDouble():0,color:AppColors.success,borderRadius:BorderRadius.circular(8)),
              ]else const SizedBox(height:18),
              const SizedBox(height:6),
              Row(children:[
                Expanded(child:TextButton(style:TextButton.styleFrom(foregroundColor:accent,padding:EdgeInsets.zero),onPressed:locked==null?null:()=>open(c),child:Text(locked==true?(ar?'ترقية':'Upgrade'):(ar?'المسائل':'Problems'),maxLines:1,overflow:TextOverflow.ellipsis))),
                IconButton(visualDensity:VisualDensity.compact,tooltip:ar?'عرض المهارات':'View skills',onPressed:()=>skills(c),icon:Icon(Icons.list_alt_outlined,color:accent,size:20)),
                if(p?['TrackPracticeIsolationEnabled']==true&&locked==false&&trackNumber(s?['Attempted'])>0)
                  IconButton(visualDensity:VisualDensity.compact,tooltip:ar?'إعادة تدريب الفئة':'Restart topic',onPressed:_resetting?null:()=>_reset(trackNumber(p?['StageId']),trackText(c,'Name',ar),categoryId:trackNumber(c['Id'])),icon:Icon(Icons.restart_alt,color:accent,size:20)),
              ]),
            ]));
          },childCount:ordered.length),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,crossAxisSpacing:12,mainAxisSpacing:12,mainAxisExtent:236*scale.clamp(1.0,1.8).toDouble()));
        })),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(16),child:TextButton(onPressed:()=>Navigator.pushNamed(context,AppRoutes.learningStage),child:Text(ar?'تغيير المرحلة':'Change stage')))),
      ],
    ));
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
    return Scaffold(appBar:AppBar(title:Text(widget.name)),body:MathBackground(showSymbols:false,child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,8),child:Align(alignment:AlignmentDirectional.centerStart,child:FilterChip(label:Text(ar?'إخفاء المحلولة':'Hide solved'),selected:_hideSolved,onSelected:(value)=>setState((){_hideSolved=value;_page=1;})))),
      Expanded(child:state.hasError&&!state.hasValue?AppErrorView(message:localizedErrorMessage(state.error!),onRetry:()=>ref.invalidate(trackPracticeProvider(key))):data==null?const Center(child:AppInlineLoader(size:28)):RefreshIndicator(onRefresh:()async{ref.invalidate(trackPracticeProvider(key));try{await ref.read(trackPracticeProvider(key).future);}catch(_){}},child:ListView.separated(
        physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,0,16,20),
        itemCount:visible.isEmpty?1:visible.length+1,separatorBuilder:(_,__)=>const SizedBox(height:12),
        itemBuilder:(context,i){
          if(visible.isEmpty)return AppEmptyView(icon:Icons.calculate_outlined,title:ar?'لا توجد مسائل مطابقة':'No matching problems');
          if(i==visible.length)return MathWorldPagination(page:_page,pageCount:trackNumber(data['PageSize'])<=0?1:(trackNumber(data['Total'])+trackNumber(data['PageSize'])-1)~/trackNumber(data['PageSize']),arabic:ar,onChanged:(p)=>setState(()=>_page=p));
          final problem=visible[i];
          return MobilePanel(padding:EdgeInsets.zero,child:ListTile(
            leading:Icon(problem['IsSolved']==true?Icons.check_circle_outline:Icons.calculate_outlined,color:problem['IsSolved']==true?AppColors.success:Theme.of(context).colorScheme.primary),
            title:RichMathText(text:trackText(problem,'Title',ar),inline:true,maxLines:2,overflow:TextOverflow.ellipsis),
            subtitle:Text(problem['IsSolved']==true?(ar?'محلولة':'Solved'):(ar?'غير محلولة':'Unsolved')),
            trailing:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.star_rounded,size:16,color:AppColors.pointsGold(context)),const SizedBox(width:3),Text('${trackNumber(problem['Points'])}',style:TextStyle(color:AppColors.pointsGold(context),fontWeight:FontWeight.w700)),LayoutUtils.forwardIcon(context,size:18)]),
            onTap:()async{
              final submitted=await Navigator.pushNamed(context,AppRoutes.problemDetails,arguments:trackNumber(problem['Id']));
              if(mounted&&submitted==true){ref.invalidate(trackPracticeProvider(key));ref.invalidate(trackProgressProvider(widget.id));ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);}
            },
          ));
        },
      ))),
    ])));
  }
}
