import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_routes.dart';
import '../core/network/api_envelope.dart';
import '../core/utils/error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/learning_journey_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/premium_analytics_provider.dart';
import '../providers/learning_tracks_provider.dart';
import '../providers/repositories_provider.dart';

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
      if(result['TrackId']!=id||result['StageId']!=widget.stageId)throw StateError('Invalid track selection response');
      if(!mounted||ref.read(authProvider).user?.id!=actor)return;
      ref.invalidate(trackSelectionProvider);
      ref.invalidate(trackProgressProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(learningJourneyProvider);
      ref.invalidate(dailyChallengeProvider);
      ref.invalidate(premiumAnalyticsProvider);
      setState(()=>_changing=false);
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
    if(selection.isLoading&&!selection.hasValue)return const Center(child:CircularProgressIndicator());
    if(selection.hasError)return Center(child:TextButton(onPressed:()=>ref.invalidate(trackSelectionProvider),child:Text(ar?'إعادة المحاولة':'Retry')));
    final current=selection.valueOrNull;
    final id=trackNumber(current?['TrackId']);
    final selected=current?['StageId']==widget.stageId && widget.catalog.items.any((t)=>t['Id']==id);
    if(selected&&!_changing)return _TrackContent(key:ValueKey(id),id:id,onChange:()=>setState(()=>_changing=true));
    return ListView(padding:const EdgeInsets.all(16),children:[
      Text(ar?'اختر الصف أو المساق':'Choose grade or course',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:8),
      Text(ar?'اختيارك لا يحذف تقدمك السابق.':'Your previous progress is preserved.'),
      const SizedBox(height:12),
      for(final track in widget.catalog.items) Card(child:ListTile(
        title:Text(trackText(track,'Name',ar)),
        subtitle:Text('${trackNumber(track['ProblemsCount'])} ${ar?'مسألة':'problems'}'),
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

class _TrackContent extends ConsumerWidget{
  final int id;final VoidCallback onChange;
  const _TrackContent({super.key,required this.id,required this.onChange});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final ar=context.locale.languageCode=='ar';
    final detail=ref.watch(trackDetailsProvider(id));final progress=ref.watch(trackProgressProvider(id));
    void reload(){ref.invalidate(trackDetailsProvider(id));ref.invalidate(trackProgressProvider(id));}
    if(detail.hasError||progress.hasError)return Center(child:TextButton(onPressed:reload,child:Text(ar?'إعادة المحاولة':'Retry')));
    final d=detail.valueOrNull;final p=progress.valueOrNull;
    if(d==null||p==null)return const Center(child:CircularProgressIndicator());
    final track=Map<String,dynamic>.from(d['Track'] as Map);
    final stats={for(final c in trackRows(p['Categories']))trackNumber(c['CategoryId']):c};
    final percent=(p['CompletionPercent'] as num?)?.toDouble()??0;
    return RefreshIndicator(onRefresh:()async{reload();await ref.read(trackProgressProvider(id).future);},child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Text(trackText(track,'Name',ar),style:Theme.of(context).textTheme.headlineSmall)),TextButton(onPressed:onChange,child:Text(ar?'تغيير':'Change'))]),
      Text('${ar?'التقدم':'Progress'}: ${trackNumber(p['Solved'])}/${trackNumber(p['ProblemsCount'])} · ${percent.toStringAsFixed(1)}%'),
      const SizedBox(height:8),
      LinearProgressIndicator(value:(percent/100).clamp(0.0,1.0).toDouble()),
      const SizedBox(height:16),
      for(final c in trackRows(d['Categories'])) Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text(trackText(c,'Name',ar),style:Theme.of(context).textTheme.titleMedium)),Text('${trackNumber(c['ProblemsCount'])} ${ar?'مسألة':'problems'}')]),
        if(trackText(c,'Description',ar).isNotEmpty)Text(trackText(c,'Description',ar)),
        Text('${ar?'محلولة':'Solved'}: ${trackNumber(stats[trackNumber(c['Id'])]?['Solved'])}/${trackNumber(c['ProblemsCount'])}'),
        Wrap(spacing:8,children:[
          TextButton(onPressed:()=>showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:Text(ar?'المهارات':'Skills'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
            for(final skill in trackRows(d['Skills']).where((s)=>s['CategoryId']==c['Id'])) ListTile(title:Text(trackText(skill,'Name',ar)),subtitle:Text(trackText(skill,'Description',ar))),
          ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(ar?'إغلاق':'Close'))])),child:Text(ar?'عرض المهارات':'View skills')),
          if(stats[trackNumber(c['Id'])]?['IsLocked']==false)
            FilledButton(onPressed:()async{await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>_TrackPractice(id:id,categoryId:trackNumber(c['Id']),name:trackText(c,'Name',ar))));if(context.mounted)ref.invalidate(trackProgressProvider(id));},child:Text(ar?'عرض المسائل':'View problems'))
          else TextButton(onPressed:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits),child:Text(ar?'ترقية الحساب':'Upgrade account')),
        ]),
      ]))),
      TextButton(onPressed:()=>Navigator.pushNamed(context,AppRoutes.learningStage),child:Text(ar?'تغيير المرحلة':'Change stage')),
    ]));
  }
}
class _TrackPractice extends ConsumerStatefulWidget{
  final int id,categoryId;final String name;
  const _TrackPractice({required this.id,required this.categoryId,required this.name});
  @override ConsumerState<_TrackPractice> createState()=>_TrackPracticeState();
}
class _TrackPracticeState extends ConsumerState<_TrackPractice>{
  int _page=1;
  @override Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final key=(trackId:widget.id,categoryId:widget.categoryId,page:_page);
    final state=ref.watch(trackPracticeProvider(key));
    final data=state.valueOrNull;
    return Scaffold(appBar:AppBar(title:Text(widget.name)),body:state.hasError?Center(child:TextButton(onPressed:()=>ref.invalidate(trackPracticeProvider(key)),child:Text(ar?'إعادة المحاولة':'Retry'))):data==null?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(12),children:[
      for(final problem in trackRows(data['Items'])) Card(child:ListTile(title:Text(trackText(problem,'Title',ar)),subtitle:Text(problem['IsSolved']==true?(ar?'محلولة':'Solved'):(ar?'غير محلولة':'Unsolved')),onTap:()async{
        await Navigator.pushNamed(context,AppRoutes.problemDetails,arguments:trackNumber(problem['Id']));
        if(mounted){ref.invalidate(trackPracticeProvider(key));ref.invalidate(trackProgressProvider(widget.id));ref.invalidate(dashboardProvider);ref.invalidate(learningJourneyProvider);}
      })),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        TextButton(onPressed:_page<=1?null:()=>setState(()=>_page--),child:Text(ar?'السابق':'Previous')),
        Text('$_page'),
        TextButton(onPressed:_page*trackNumber(data['PageSize'])>=trackNumber(data['Total'])?null:()=>setState(()=>_page++),child:Text(ar?'التالي':'Next')),
      ]),
    ]));
  }
}
