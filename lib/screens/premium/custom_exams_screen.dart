import 'dart:math';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/network/api_envelope.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/rich_math_text.dart';

final customExamAvailabilityProvider=FutureProvider.autoDispose<bool>((ref) async{
  final uid=ref.watch(authProvider.select((s)=>s.user?.id));
  if(uid==null)return false;
  final r=await ref.watch(apiClientProvider).get('/users/custom-exams/availability',handleUnauthorized:false);
  return ApiEnvelope.map(r.data)['Enabled']==true;
});
List<Map<String,dynamic>> rows(Object? raw)=>raw is List?raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():[];
Map<String,dynamic>? asMap(Object? raw)=>raw is Map?Map<String,dynamic>.from(raw):null;
String requestId(){
  final random=Random.secure(),b=List<int>.generate(16,(_)=>random.nextInt(256));
  b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;
  final s=b.map((n)=>n.toRadixString(16).padLeft(2,'0')).join();
  return '${s.substring(0,8)}-${s.substring(8,12)}-${s.substring(12,16)}-${s.substring(16,20)}-${s.substring(20)}';
}
class CustomExamsScreen extends ConsumerWidget{
  const CustomExamsScreen({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){
    final uid=ref.watch(authProvider.select((s)=>s.user?.id));
    return uid==null?const Scaffold():_ExamWorkspace(key:ValueKey(uid),owner:uid);
  }
}
class _ExamWorkspace extends ConsumerStatefulWidget{
  const _ExamWorkspace({super.key,required this.owner});
  final int owner;
  @override ConsumerState<_ExamWorkspace> createState()=>_ExamWorkspaceState();
}
class _ExamWorkspaceState extends ConsumerState<_ExamWorkspace>{
  static const root='/users/custom-exams';
  Map<String,dynamic>? setup,exam;
  List<Map<String,dynamic>> history=[];
  bool busy=false,loaded=false;
  String? error,request;
  int category=0,count=10,difficulty=0;
  int? chosen;
  bool get active=>mounted&&ref.read(authProvider).user?.id==widget.owner;
  bool get ar=>context.locale.languageCode=='ar';
  String tr(String a,String e)=>ar?a:e;
  String name(Map<String,dynamic> row,String key)=>(row[key+(ar?'Ar':'En')]??'').toString();
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_){if(active)load();});}
  Future<void> run(Future<void> Function() task)async{
    if(!active||busy)return;
    setState((){busy=true;error=null;});
    try{await task();}catch(_){if(active)setState(()=>error=tr('تعذّر إكمال الطلب. حاول مجدداً.','Request failed. Please retry.'));}
    finally{if(active)setState(()=>busy=false);}
  }
  Future<Map<String,dynamic>> get(String path)async=>ApiEnvelope.map((await ref.read(apiClientProvider).get(path)).data);
  Future<Map<String,dynamic>> post(String path,[Map<String,dynamic>? data])async=>ApiEnvelope.map((await ref.read(apiClientProvider).post(path,data:data)).data);
  Future<void> reload()async{final h=await get(root);if(active)setState(()=>history=rows(h['Items']));}
  Future<void> load()=>run(()async{
    final premium=await ref.read(studentPremiumProvider.future);
    if(!active)return;
    await reload();if(!active)return;
    final s=premium?await get('$root/setup'):null;
    if(active)setState((){setup=s;loaded=true;});
  });
  void show(Map<String,dynamic> value){if(active)setState((){exam=value;chosen=null;});}
  Future<void> start()=>run(()async{
    request??=requestId();
    show(await post('$root/start',{'RequestId':request,'CategoryId':category==0?null:category,'Count':count,'DifficultyLevel':difficulty==0?null:difficulty}));
    if(active){request=null;await reload();}
  });
  Future<void> open(String id)=>run(()async{show(await get('$root/$id'));});
  Future<void> answer()=>run(()async{
    final e=exam,o=chosen;if(e==null||o==null)return;
    show(await post('$root/${e['Id']}/answer',{'Position':e['Answered'],'OptionId':o}));
  });
  Future<void> finish()=>run(()async{final id=exam?['Id'];if(id==null)return;show(await post('$root/$id/finish'));if(active)await reload();});
  Future<void> abandon(String id)async{
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(tr('إلغاء الامتحان','Abandon exam')),content:Text(tr('لن تستطيع استئناف هذا الامتحان.','This exam cannot be resumed.')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(tr('تراجع','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(tr('إلغاء','Abandon')))]));
    if(yes!=true||!active)return;
    await run(()async{await post('$root/$id/abandon');if(active){setState((){exam=null;chosen=null;request=null;});await reload();}});
  }
  Future<void> certificate(String id)=>run(()async{
    final lang=ar?'ar':'en';
    final bytes=await ref.read(apiClientProvider).getBinary('$root/$id/certificate',queryParameters:{'lang':lang});
    if(bytes.length<5||String.fromCharCodes(bytes.take(5))!='%PDF-')throw const FormatException('Invalid PDF');
    if(!active)return;
    await SharePlus.instance.share(ShareParams(files:[XFile.fromData(Uint8List.fromList(bytes),mimeType:'application/pdf',name:'mathworld-exam-$lang.pdf')],fileNameOverrides:['mathworld-exam-$lang.pdf']));
  });
  @override Widget build(BuildContext context){
    final premium=ref.watch(studentPremiumProvider).valueOrNull==true;
    final e=exam,s=setup,q=asMap(e?['CurrentQuestion']);
    final cats=rows(s?['Categories']);
    final scoped=cats.where((c)=>category==0||c['Id']==category).toList();
    int available(int level)=>scoped.fold<int>(0,(n,c)=>n+(level==0?((c['Count'] as num?)?.toInt()??0):rows(c['DifficultyCounts']).where((d)=>d['Level']==level).fold<int>(0,(sum,d)=>sum+((d['Count'] as num?)?.toInt()??0))));
    final max=available(difficulty);
    final unfinished=history.any((h)=>h['FinishedAtUtc']==null&&h['AbandonedAtUtc']==null);
    return Scaffold(appBar:AppBar(title:Text(tr('الامتحانات المخصصة','Custom exams')),actions:[IconButton(onPressed:busy?null:load,icon:const Icon(Icons.refresh))]),
      body:SafeArea(child:!loaded&&busy?const AppContentSkeleton():ListView(padding:const EdgeInsets.all(16),children:[
        if(error!=null)Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
        if(busy)const Center(child:Padding(padding:EdgeInsets.all(8),child:AppInlineLoader())),
        if(!premium)Card(child:ListTile(leading:const Icon(Icons.workspace_premium_outlined),title:Text(tr('الامتحانات الجديدة لحساب Premium','New exams require Premium')),onTap:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits))),
        if(e!=null&&e['AbandonedAtUtc']==null)...[
          Text(name(e,'Title'),style:Theme.of(context).textTheme.titleLarge),
          if(e['FinishedAtUtc']!=null)...[
            Text("${e['Score']}/${e['Total']} — "+(e['Passed']==true?tr('ناجح','Passed'):tr('لم تجتز','Not passed')),style:Theme.of(context).textTheme.headlineSmall),
            if(e['CertificateIssued']==true)FilledButton.icon(onPressed:busy?null:()=>certificate(e['Id'].toString()),icon:const Icon(Icons.download),label:Text(tr('تحميل الشهادة PDF','Download certificate PDF'))),
            Text(tr('مراجعة الإجابات','Review answers')),
            for(final r in rows(e['Review']))Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
              RichMathText(text:name(asMap(r['Question'])??{},'QuestionText')),
              for(final o in rows(asMap(r['Question'])?['Options']))ListTile(title:RichMathText(text:o['LatexCode'].toString(),assumeMath:true),
                leading:Icon(o['Id']==r['CorrectOptionId']?Icons.check_circle:o['Id']==r['SelectedOptionId']?Icons.cancel:Icons.circle_outlined,color:o['Id']==r['CorrectOptionId']?AppColors.success:o['Id']==r['SelectedOptionId']?Theme.of(context).colorScheme.error:null),
                trailing:o['Id']==r['SelectedOptionId']?Text(tr('إجابتك','Your answer')):null),
            ]))),
            TextButton(onPressed:()=>setState(()=>exam=null),child:Text(tr('العودة','Back'))),
          ]else...[
            Text("${e['Answered']}/${e['Total']}"),
            LinearProgressIndicator(value:((e['Answered'] as num)/(e['Total'] as num)).clamp(0.0,1.0).toDouble()),
            if(q!=null)...[
              RichMathText(text:name(q,'QuestionText')),
              for(final o in rows(q['Options']))Card(child:ListTile(selected:chosen==o['Id'],leading:Icon(chosen==o['Id']?Icons.radio_button_checked:Icons.radio_button_unchecked),title:RichMathText(text:o['LatexCode'].toString(),assumeMath:true),onTap:busy?null:()=>setState(()=>chosen=(o['Id'] as num).toInt()))),
              FilledButton(onPressed:busy||chosen==null||!premium?null:answer,child:Text(tr('إرسال الإجابة','Submit answer'))),
            ],
            if(e['Answered']==e['Total'])FilledButton(onPressed:busy||!premium?null:finish,child:Text(tr('إنهاء وتصحيح الامتحان','Finish and grade exam'))),
            TextButton(onPressed:busy?null:()=>abandon(e['Id'].toString()),child:Text(tr('إلغاء الامتحان','Abandon exam'))),
          ],
        ]else if(premium&&s!=null)...[
          Text(name(asMap(s['Track'])??{},'Name'),style:Theme.of(context).textTheme.titleLarge),
          DropdownButtonFormField<int>(initialValue:category,isExpanded:true,decoration:InputDecoration(labelText:tr('نطاق الامتحان','Exam scope')),items:[
            DropdownMenuItem(value:0,child:Text(tr('الصف الكامل','Entire grade'))),
            for(final c in cats)DropdownMenuItem(value:(c['Id'] as num).toInt(),child:Text(name(c,'Name'),overflow:TextOverflow.ellipsis)),
          ],onChanged:busy?null:(v)=>setState((){category=v??0;request=null;})),
          const SizedBox(height:12),
          DropdownButtonFormField<int>(initialValue:difficulty,decoration:InputDecoration(labelText:tr('مستوى الصعوبة (اختياري)','Difficulty (optional)')),items:[
            DropdownMenuItem(value:0,child:Text(tr('جميع المستويات','All levels'))),
            for(final level in [1,2,3,4,5])DropdownMenuItem(value:level,enabled:available(level)>0,child:Text(tr('المستوى','Level')+' $level')),
          ],onChanged:busy?null:(v)=>setState((){difficulty=v??0;request=null;})),
          Text(tr('التصفية تعتمد مستويات الصعوبة المراجعة فقط.','Difficulty filters use reviewed levels only.'),style:Theme.of(context).textTheme.bodySmall),
          const SizedBox(height:12),
          DropdownButtonFormField<int>(initialValue:count,decoration:InputDecoration(labelText:tr('عدد الأسئلة','Questions')),items:[for(final n in [5,10,15,20])DropdownMenuItem(value:n,enabled:n<=max,child:Text('$n'))],onChanged:busy?null:(v)=>setState((){count=v??10;request=null;})),
          Text(tr('حد النجاح','Pass threshold')+": ${s['PassPercent']}%"),
          FilledButton(onPressed:busy||unfinished||count>max?null:start,child:Text(tr('ابدأ الامتحان','Start exam'))),
        ],
        const SizedBox(height:20),Text(tr('امتحاناتي وشهاداتي','My exams and certificates'),style:Theme.of(context).textTheme.titleMedium),
        for(final h in history)Card(child:Column(children:[
          ListTile(title:Text(name(h,'Title')),subtitle:Text(h['FinishedAtUtc']!=null?"${h['Score']}/${h['Total']}":h['AbandonedAtUtc']!=null?tr('ملغى','Abandoned'):tr('قيد التنفيذ','In progress'))),
          Wrap(children:[
            if(h['AbandonedAtUtc']==null&&(premium||h['FinishedAtUtc']!=null))TextButton(onPressed:busy?null:()=>open(h['Id'].toString()),child:Text(h['FinishedAtUtc']!=null?tr('النتيجة','Result'):tr('استئناف','Resume'))),
            if(h['FinishedAtUtc']==null&&h['AbandonedAtUtc']==null)TextButton(onPressed:busy?null:()=>abandon(h['Id'].toString()),child:Text(tr('إلغاء','Abandon'))),
            if(h['CertificateIssued']==true)TextButton(onPressed:busy?null:()=>certificate(h['Id'].toString()),child:Text(tr('الشهادة','Certificate'))),
          ]),
        ])),
        if(loaded&&history.isEmpty)Text(tr('لا توجد امتحانات سابقة','No previous exams')),
      ])),
    );
  }
}
