import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../models/learning_journey.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../core/network/api_envelope.dart';
import '../../services/learning_session_api.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  final LearningJourney journey;
  const CertificatesScreen({super.key,required this.journey});
  @override ConsumerState<CertificatesScreen> createState()=>_CertificatesScreenState();
}
class _CertificatesScreenState extends ConsumerState<CertificatesScreen>{
  static const _root='/users/certificates';
  Map<String,dynamic>? _list,_eligibility;
  int? _choice;
  bool _busy=true,_checking=false,_error=false;
  String? _notice;
  late final int? _owner;
  bool get _sameOwner=>_owner!=null&&ref.read(authProvider).user?.id==_owner;
  bool get ar=>context.locale.languageCode=='ar';
  String tr(String a,String e)=>ar?a:e;
  @override void initState(){super.initState();_owner=ref.read(authProvider).user?.id;_load();}
  Future<void> _load() async{
    if(!mounted||!_sameOwner)return;
    setState((){_busy=true;_error=false;});
    try{
      final r=await ref.read(apiClientProvider).get(_root);
      if(mounted&&_sameOwner)setState(()=>_list=ApiEnvelope.map(r.data));
    }catch(_){if(mounted&&_sameOwner)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Map<String,dynamic> get _scope=>{
    'StageId':widget.journey.stageId,
    if(widget.journey.trackId!=null)'TrackId':widget.journey.trackId,
    if(_choice!=null&&_choice!=0)'CategoryId':_choice,
  };
  Future<void> _check(int? choice) async{
    if(!_sameOwner||_busy||_checking)return;
    setState((){_choice=choice;_eligibility=null;_notice=null;_error=false;_checking=choice!=null;});
    if(choice==null)return;
    try{
      final r=await ref.read(apiClientProvider).get('$_root/eligibility',queryParameters:{
        'stageId':widget.journey.stageId,if(widget.journey.trackId!=null)'trackId':widget.journey.trackId,
        if(choice!=0)'categoryId':choice});
      if(mounted&&_sameOwner&&_choice==choice)setState(()=>_eligibility=ApiEnvelope.map(r.data));
    }catch(_){if(mounted&&_sameOwner)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_checking=false);}
  }
  Future<void> _issue() async{
    if(!_sameOwner||_busy||_checking||_eligibility?['Eligible']!=true)return;
    setState((){_busy=true;_error=false;_notice=null;});
    try{
      await ref.read(apiClientProvider).post('$_root/issue',data:_scope);
      if(!mounted||!_sameOwner)return;
      setState(()=>_notice=tr('تم إصدار الشهادة وحفظها.','Certificate issued and saved.'));
      await _load();
    }catch(_){if(mounted&&_sameOwner)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _share(Map<String,dynamic> cert,String lang) async{
    if(_busy||!_sameOwner)return;
    final id=sessionText(cert,'Id');
    if(!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id))return;
    setState((){_busy=true;_error=false;});
    try{
      final bytes=await ref.read(apiClientProvider).getBinary('$_root/$id/pdf',queryParameters:{'lang':lang});
      if(bytes.length<5||String.fromCharCodes(bytes.take(5))!='%PDF-')throw const FormatException('Invalid PDF');
      if(!mounted||!_sameOwner)return;
      await SharePlus.instance.share(ShareParams(files:[XFile.fromData(Uint8List.fromList(bytes),mimeType:'application/pdf',name:'mathworld-certificate-$lang.pdf')],fileNameOverrides:['mathworld-certificate-$lang.pdf']));
    }catch(_){if(mounted&&_sameOwner)setState(()=>_error=true);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context){
    final user=ref.watch(authProvider.select((s)=>s.user));
    if(user?.id!=_owner||user?.role!='Student')return Scaffold(appBar:AppBar(),body:Center(child:Text(tr('سجّل الدخول مجدداً','Sign in again'))));
    final premium=ref.watch(studentPremiumProvider).valueOrNull==true;
    final j=widget.journey;
    final categories=j.categories.where((c)=>c.accessVerified&&!c.isLocked&&c.totalProblems>=5).toList();
    final items=sessionRows(_list?['Items']);
    final e=_eligibility;
    return Scaffold(appBar:AppBar(title:Text(tr('شهاداتي التعليمية','My learning certificates'))),body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
      if(_busy||_checking)const LinearProgressIndicator(),
      if(_error)Card(child:ListTile(title:Text(tr('تعذّر إكمال الطلب. أعد المحاولة.','Request failed. Please retry.')),trailing:IconButton(onPressed:_busy||_checking?null:() async{await _load();if(mounted&&_choice!=null)await _check(_choice);},icon:const Icon(Icons.refresh)))),
      if(_notice!=null)Text(_notice!),
      if(_list?['IssuanceEnabled']==true&&premium)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(tr('استحقاق شهادة جديدة','New certificate eligibility'),style:Theme.of(context).textTheme.titleMedium),
        Text(tr('أكمل جميع مسائل النطاق المعتمد وأثبت الحل المستقل في كل مهارة.','Complete every problem in the approved scope and demonstrate independent solving in every skill.')),
        DropdownButton<int>(isExpanded:true,value:_choice,hint:Text(tr('اختر النطاق','Choose scope')),onChanged:_busy||_checking?null:_check,items:[
          if(j.trackId!=null)DropdownMenuItem(value:0,child:Text(tr('الصف أو المساق الكامل','Entire grade or course'))),
          for(final c in categories)DropdownMenuItem(value:c.categoryId,child:Text(c.getName(context.locale.languageCode),overflow:TextOverflow.ellipsis)),
        ]),
        if(e!=null)...[
          Text('${tr('المسائل المكتملة','Completed problems')}: ${sessionInt(e['SolvedProblems'])} / ${sessionInt(e['TotalProblems'])}'),
          Text('${tr('المهارات المستقلة','Independent skills')}: ${sessionInt(e['IndependentSkills'])} / ${sessionInt(e['RequiredSkills'])}'),
          if(e['CatalogReady']!=true)Text(tr('محتوى هذا النطاق لم يستوف شروط إصدار الشهادة.','This scope has not met certificate catalog requirements.')),
          FilledButton(onPressed:_busy||_checking||e['Eligible']!=true?null:_issue,child:Text(tr('إصدار الشهادة','Issue certificate'))),
        ],
      ]))),
      const SizedBox(height:12),Text(tr('الشهادات الصادرة','Issued certificates'),style:Theme.of(context).textTheme.titleMedium),
      if(_list!=null&&items.isEmpty)Padding(padding:const EdgeInsets.all(12),child:Text(tr('لم تصدر لك شهادات بعد.','No certificates issued yet.'))),
      for(final c in items)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.workspace_premium_outlined),title:Text(sessionText(c,ar?'TitleAr':'TitleEn')),subtitle:Text(sessionText(c,'StudentName'))),
        Text(sessionText(c,'IssuedAtUtc').split('T').first),
        Text(tr('رمز التحقق','Verification code')),
        SelectableText(sessionText(c,'VerificationCode')),
        Wrap(spacing:8,children:[
          OutlinedButton.icon(onPressed:_busy?null:()=>_share(c,'ar'),icon:const Icon(Icons.share_outlined),label:const Text('PDF العربية')),
          OutlinedButton.icon(onPressed:_busy?null:()=>_share(c,'en'),icon:const Icon(Icons.share_outlined),label:const Text('PDF English')),
        ]),
      ]))),
    ])));
  }
}
