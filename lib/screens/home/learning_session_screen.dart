import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../services/learning_session_api.dart';
import '../../widgets/rich_math_text.dart';

class LearningSessionScreen extends ConsumerStatefulWidget {
  final SessionScope scope;
  const LearningSessionScreen({super.key,required this.scope});
  @override ConsumerState<LearningSessionScreen> createState()=>_LearningSessionScreenState();
}
class _LearningSessionScreenState extends ConsumerState<LearningSessionScreen>{
  Map<String,dynamic>? _session,_result,_hints,_pending;
  String? _startId;
  int _count=5;
  int? _selected;
  bool _busy=true,_loadFailed=false,_error=false;
  String? _notice;
  late final int? _userId;
  LearningSessionApi get _api=>LearningSessionApi(ref.read(apiClientProvider));
  bool get ar=>context.locale.languageCode=='ar';
  String tr(String a,String e)=>ar?a:e;
  bool get _sameUser=>ref.read(authProvider).user?.id==_userId;
  @override void initState(){super.initState();_userId=ref.read(authProvider).user?.id;_load();}
  void _clear(){_result=null;_hints=null;_pending=null;_selected=null;_error=false;}
  Future<void> _load() async{
    if(!mounted)return;
    setState((){_busy=true;_error=false;});
    try{
      final current=_session;
      Map<String,dynamic>? value;
      try {
        value=current==null?await _api.current(widget.scope):await _api.get(sessionText(current,'Id'),widget.scope);
      } on AppException catch(e) {
        if(current==null||!(e.statusCode==404||e.statusCode==409||e.type==AppExceptionType.notFound))rethrow;
        value=await _api.current(widget.scope);
      }
      if(!mounted||!_sameUser)return;
      setState((){_session=value;_startId=null;_loadFailed=false;_clear();});
    }catch(_){if(mounted&&_sameUser)setState((){_error=true;_loadFailed=_session==null;});}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _begin() async{
    if(_busy)return;
    setState((){_busy=true;_error=false;});_startId??=sessionRequestId();
    try{final value=await _api.start(widget.scope,_count,_startId!);if(!mounted||!_sameUser)return;
      setState((){_session=value;_startId=null;_clear();});}
    on AppException catch(e){if(mounted&&_sameUser)setState((){_error=true;if([400,403,409].contains(e.statusCode))_startId=null;});}
    catch(_){if(mounted&&_sameUser)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _submit() async{
    final s=_session,q=sessionMap(_session?['CurrentQuestion']);
    if(_busy||s==null||q==null||_selected==null)return;
    setState((){_busy=true;_error=false;});
    _pending??={'RequestId':sessionRequestId(),'Position':s['Completed'],'ProblemId':q['Id'],'SelectedOptionId':_selected};
    try{final value=await _api.answer(sessionText(s,'Id'),_pending!);
      if(!mounted||!_sameUser)return;setState((){_result=value;_pending=null;});}
    on AppException catch(e){if(mounted&&_sameUser)setState((){_error=true;if([400,403,409].contains(e.statusCode))_pending=null;});}
    catch(_){if(mounted&&_sameUser)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _hint(int level) async{
    final s=_session,q=sessionMap(_session?['CurrentQuestion']);
    if(_busy||s==null||q==null||_pending!=null)return;
    setState((){_busy=true;_error=false;});
    try{final value=await _api.hint(sessionText(s,'Id'),sessionInt(s['Completed']),sessionInt(q['Id']),level);
      if(mounted&&_sameUser)setState(()=>_hints=value);}
    catch(_){if(mounted&&_sameUser)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _restartScope() async {
    if(_busy||_pending!=null||_startId!=null)return;
    setState((){_busy=true;_error=false;_notice=null;});
    try{
      final preview=await _api.previewRestart(widget.scope.categoryId);
      if(!mounted||!_sameUser)return;
      if(preview['StageId']!=widget.scope.stageId||preview['TrackId']!=widget.scope.trackId||preview['CategoryId']!=widget.scope.categoryId||
          preview['SessionIds'] is! List)throw const AppException(type:AppExceptionType.invalidResponse,messageKey:'invalid_response');
      final count=(preview['SessionIds'] as List).length;
      if(count==0){setState(()=>_notice=tr('لا توجد جلسات مفتوحة ضمن هذا النطاق.','No open sessions in this scope.'));return;}
      final accepted=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
        title:Text(tr('إعادة بدء الجلسات المفتوحة','Restart open sessions')),
        content:Text(tr('سيتم إنهاء $count جلسة مفتوحة في النطاق المحدد فقط. نقاطك وإنجازاتك ومحاولاتك محفوظة.','End $count open sessions in this scope only. Points, achievements and previous attempts remain.')),
        actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:Text(tr('إلغاء','Cancel'))),
          FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:Text(tr('تأكيد','Confirm')))]));
      if(accepted!=true||!mounted||!_sameUser)return;
      await _api.restart(preview);
      if(mounted&&_sameUser)setState((){_session=null;_loadFailed=false;_clear();_notice=tr('تم إنهاء الجلسات المفتوحة. إنجازاتك محفوظة.','Open sessions ended. Achievements preserved.');});
    }catch(_){if(mounted&&_sameUser)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context){
    final user=ref.watch(authProvider.select((s)=>s.user));
    if(user?.id!=_userId||user?.role!='Student')return Scaffold(appBar:AppBar(),body:Center(child:Text(tr('سجّل الدخول مجدداً','Sign in again'))));
    final s=_session,q=sessionMap(s?['CurrentQuestion']),r=_result;
    final completed=sessionInt(r?['Completed']??s?['Completed']),total=sessionInt(s?['Total']);
    final revealed=sessionInt(_hints?['RevealedCount']??s?['HintsRevealed']);
    final practice=widget.scope.kind=='practice';
    return Scaffold(appBar:AppBar(title:Text(practice?tr('جلسة تدريب','Practice session'):tr('تحدي اليوم','Daily challenge'))),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        if(_busy)const LinearProgressIndicator(),
        if(practice)OutlinedButton.icon(onPressed:_busy||_pending!=null||_startId!=null?null:_restartScope,icon:const Icon(Icons.restart_alt),label:Text(tr('إعادة بدء الجلسات المفتوحة','Restart open sessions'))),
        if(_notice!=null)Text(_notice!),
        if(_error)Card(child:ListTile(title:Text(tr('تعذّر إكمال الطلب. أعد المحاولة أو حدّث الجلسة.','Could not complete the request. Retry or reload the session.')),
          trailing:IconButton(onPressed:_busy?null:_load,icon:const Icon(Icons.refresh)))),
        if(s==null&&!_loadFailed&&!_busy)...[
          Text(tr('أجب بشكل صحيح للانتقال إلى المسألة التالية. يمكنك المتابعة من جهاز آخر.','Answer correctly to advance. Resume from another device.')),
          if(practice)DropdownButton<int>(value:_count,onChanged:_startId!=null?null:(n){if(n!=null)setState(()=>_count=n);},
            items:List.generate(6,(i)=>DropdownMenuItem(value:i+5,child:Text('${i+5}')))),
          FilledButton(onPressed:_begin,child:Text(tr('ابدأ','Start'))),
        ],
        if(s!=null)...[
          Text('${tr('التقدم','Progress')}: $completed / $total',style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),LinearProgressIndicator(value:total>0?(completed/total).clamp(0.0,1.0).toDouble():0),
          const SizedBox(height:16),
          if(s['IsComplete']==true&&r==null)...[
            Icon(Icons.emoji_events,size:52,color:Theme.of(context).colorScheme.primary),
            Text(tr('أحسنت! اكتملت الجلسة','Well done! Session complete'),textAlign:TextAlign.center),
            if(practice)FilledButton(onPressed:_busy?null:_begin,child:Text(tr('جلسة جديدة','New session'))),
            OutlinedButton(onPressed:()=>Navigator.pop(context),child:Text(tr('العودة للرئيسية','Back to dashboard'))),
          ]else if(q!=null)...[
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              RichMathText(text:sessionText(q,ar?'QuestionTextAr':'QuestionTextEn'),isArabic:ar),
              const SizedBox(height:16),
              for(final option in sessionRows(q['Options']))
                Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(onPressed:_busy||r!=null||_pending!=null?null:()=>setState(()=>_selected=sessionInt(option['Id'])),
                  style:OutlinedButton.styleFrom(backgroundColor:_selected==option['Id']?Theme.of(context).colorScheme.primaryContainer:null),
                  child:Padding(padding:const EdgeInsets.all(12),child:RichMathText(text:sessionText(option,'LatexCode'),isArabic:ar,assumeMath:true)))),
              if(r==null)...[
                FilledButton(onPressed:_busy||_selected==null?null:_submit,child:Text(tr('تحقق من الإجابة','Check answer'))),
                if(s['CanUseHints']==true)...[
                  for(final hint in sessionRows(_hints?['Hints']))
                    Padding(padding:const EdgeInsets.all(8),child:RichMathText(text:sessionText(hint,'Text'),isArabic:ar)),
                  if(_hints?['Available']==false)Text(tr('لا تتوفر تلميحات مراجعة لهذه المسألة.','Reviewed hints are unavailable.'))
                  else ...[
                    if(_hints==null&&revealed>0)OutlinedButton(onPressed:_busy||_pending!=null?null:()=>_hint(0),child:Text(tr('استعادة التلميحات','Restore hints'))),
                    if(revealed<2)OutlinedButton(onPressed:_busy||_pending!=null?null:()=>_hint(revealed+1),child:Text('${tr('عرض التلميح','Reveal hint')} ${revealed+1}')),
                  ],
                ],
              ],
              if(r!=null&&r['IsCorrect']==false)...[
                Text(tr('حاول مرة أخرى','Try again')),
                FilledButton(onPressed:()=>setState((){_result=null;_selected=null;}),child:Text(tr('إعادة المحاولة','Retry'))),
              ],
              if(r!=null&&r['IsCorrect']==true)...[
                Text('${tr('إجابة صحيحة','Correct answer')} · +${sessionInt(r['PointsEarned'])}',style:const TextStyle(color:Colors.green,fontWeight:FontWeight.bold)),
                _Solution(result:r,ar:ar),
                FilledButton(onPressed:_busy?null:_load,child:Text(r['IsComplete']==true?tr('عرض النتيجة','View result'):tr('المسألة التالية','Next question'))),
              ],
            ]))),
          ],
        ],
      ])));
  }
}
class _Solution extends StatelessWidget{
  final Map<String,dynamic> result;final bool ar;
  const _Solution({required this.result,required this.ar});
  @override Widget build(BuildContext context){
    final s=sessionMap(result['SolutionStructure']);
    if(s==null)return RichMathText(text:sessionText(result,ar?'DetailedSolutionAr':'DetailedSolutionEn'),isArabic:ar);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      RichMathText(text:sessionText(s,'Idea'),isArabic:ar),
      RichMathText(text:sessionText(s,'FormulaLatex'),isArabic:ar,assumeMath:true),
      for(final step in (s['Steps'] is List?s['Steps'] as List:const []))RichMathText(text:step.toString(),isArabic:ar),
      for(final key in ['Substitution','Result','Unit','Verification','CommonError'])RichMathText(text:sessionText(s,key),isArabic:ar),
    ]);
  }
}
