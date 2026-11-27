import 'package:flutter/material.dart';
import '../config/app_routes.dart';
import '../services/premium_api_service.dart';
import 'rich_math_text.dart';

/// The server controls both entitlement and progression. No solution preview.
class PremiumHintPanel extends StatefulWidget {
  final int problemId;
  final int? practiceScopeId;
  final PremiumApiService service;
  final bool isArabic;
  const PremiumHintPanel({super.key,required this.problemId,this.practiceScopeId,required this.service,required this.isArabic});
  @override State<PremiumHintPanel> createState()=>_PremiumHintPanelState();
}
class _PremiumHintPanelState extends State<PremiumHintPanel>{
  StudentEntitlement? _entitlement;
  ProblemHints? _hints;
  bool _loading=true;
  bool _error=false;
  int _generation=0;
  @override void initState(){super.initState();_load();}
  @override void didUpdateWidget(covariant PremiumHintPanel oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.problemId!=widget.problemId||oldWidget.isArabic!=widget.isArabic||oldWidget.practiceScopeId!=widget.practiceScopeId){_load();}
  }
  Future<void> _load({int? level}) async{
    if(level!=null&&_loading)return;
    final generation=++_generation;
    setState((){_loading=true;_error=false;if(level==null){_entitlement=null;_hints=null;}});
    try{
      // The reveal endpoint validates entitlement itself. Avoid an extra GET
      // for each hint, but revalidate entitlement on initial load/recovery.
      final entitlement=level!=null&&_entitlement!=null
          ?_entitlement!:await widget.service.getEntitlement();
      if(!mounted||generation!=_generation)return;
      final hints=entitlement.isPremium?await widget.service.getHints(widget.problemId,level:level,practiceScopeId:widget.practiceScopeId):null;
      if(!mounted||generation!=_generation)return;
      setState((){_entitlement=entitlement;_hints=hints?.problemId==widget.problemId?hints:null;});
    }catch(_){if(mounted&&generation==_generation)setState(()=>_error=true);}
    finally{if(mounted&&generation==_generation)setState(()=>_loading=false);}
  }
  @override Widget build(BuildContext context){
    final ar=widget.isArabic;final hints=_hints;
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(ar?'تلميحات تساعدك على الحل':'Hints to help you solve',style:Theme.of(context).textTheme.titleMedium),
      if(_loading)const LinearProgressIndicator(),
      if(_error)TextButton(onPressed:_loading?null:()=>_load(),child:Text(ar?'تعذّر تحميل التلميحات. إعادة المحاولة':'Could not load hints. Retry')),
      if(_entitlement?.isPremium==false)OutlinedButton.icon(onPressed:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits),icon:const Icon(Icons.lock_outline),label:Text(ar?'تلميحات Premium':'Premium hints')),
      if(hints!=null)...[
        if(!hints.available)Text(ar?'لا توجد تلميحات لهذه المسألة بعد.':'Hints are not yet available for this problem.'),
        for(var i=0;i<hints.hints.length;i++)...[
          const SizedBox(height:8),Text('${ar?'التلميح':'Hint'} ${i+1}',style:Theme.of(context).textTheme.titleSmall),
          RichMathText(text:hints.hints[i],isArabic:ar),
        ],
        if(hints.available&&hints.revealedCount<hints.hintCount)OutlinedButton(onPressed:_loading||_error?null:()=>_load(level:hints.revealedCount+1),child:Text('${ar?'عرض التلميح':'Reveal hint'} ${hints.revealedCount+1}')),
      ],
      const SizedBox(height:8),
      Text(ar?'الإجابة وطريقة الحل تظهران بعد الحل الصحيح لجميع الطلاب.':'The answer and solution appear after a correct solve for all learners.',style:Theme.of(context).textTheme.bodySmall),
    ])));
  }
}
