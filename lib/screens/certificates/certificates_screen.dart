import 'dart:async';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/learning_journey.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stage_category_access_provider.dart';
import '../../core/network/api_envelope.dart';
import '../../services/learning_session_api.dart';
import '../../widgets/math_background.dart';
import '../../config/design_tokens.dart';
import '../../widgets/mobile_section.dart';
import '../../widgets/app_states.dart';
import '../../widgets/mathworld_pagination.dart';
import '../../config/constants.dart';
import '../premium/custom_exams_screen.dart';

final certificateListProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,({int owner,int page})>((ref,key) async{
  final actor=ref.watch(authProvider.select((s)=>s.user?.id));
  if(actor!=key.owner)return {};
  final lease=ref.keepAlive();
  final expiry=Timer(const Duration(seconds:60),lease.close);
  ref.onDispose(expiry.cancel);
  try {
    final response=await ref.watch(apiClientProvider).get('/users/certificates',queryParameters:{'page':key.page,'pageSize':AppConstants.pageSize});
    final data=ApiEnvelope.map(response.data);
    if(data['Total'] is! num||data['PageSize']!=AppConstants.pageSize||sessionRows(data['Items']).length>AppConstants.pageSize)throw const FormatException('Invalid certificate page');
    return data;
  } catch (_) {lease.close();rethrow;}
});

/// Fetch only when the summary scrolls into view. Share the same account-scoped
/// request with the full certificate screen.
class CertificateHomeSummary extends ConsumerWidget {
  final LearningJourney? journey;
  final bool examsEnabled;
  final bool loadSummary;
  const CertificateHomeSummary({super.key,this.journey,this.examsEnabled=false,this.loadSummary=true});
  @override Widget build(BuildContext context,WidgetRef ref){
    final ar=context.locale.languageCode=='ar';
    final owner=ref.watch(authProvider.select((s)=>s.user?.id));
    if(owner==null)return const SizedBox.shrink();
    final learningEnabled=journey?.certificatesEnabled==true;
    final learning=learningEnabled&&loadSummary?ref.watch(certificateListProvider((owner:owner,page:1))):null;
    final exams=examsEnabled&&loadSummary?ref.watch(customExamHistoryProvider((owner:owner,page:1,certificatesOnly:true))):null;
    final learningItems=sessionRows(learning?.valueOrNull?['Items']);
    final examHistory=rows(exams?.valueOrNull?['Items']);
    final total=sessionInt(learning?.valueOrNull?['Total'])+sessionInt(exams?.valueOrNull?['Total']);
    final examItems=examHistory.where((x)=>x['CertificateIssued']==true).toList();
    final items=[for(final x in learningItems)(title:sessionText(x,ar?'TitleAr':'TitleEn'),date:DateTime.tryParse(sessionText(x,'IssuedAtUtc'))),for(final x in examItems)(title:sessionText(x,ar?'TitleAr':'TitleEn'),date:DateTime.tryParse(sessionText(x,'FinishedAtUtc')))];
    items.sort((a,b)=>(b.date??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.date??DateTime.fromMillisecondsSinceEpoch(0)));
    final pending=(learningEnabled&&learning?.valueOrNull==null)||(examsEnabled&&exams?.valueOrNull==null);
    final failed=learning?.hasError==true||exams?.hasError==true;
    final summary=!loadSummary?(ar?'عرض الشهادات':'View certificates'):pending?(failed?(ar?'تعذّر تحميل الملخص':'Summary unavailable'):(ar?'جارٍ تحميل الشهادات…':'Loading certificates…'))
      :items.isEmpty?(ar?'لم تصدر شهادات بعد':'No certificates yet')
      :'$total ${ar?'شهادة':'certificates'} · ${items.first.title}';
    return MobilePanel(padding:EdgeInsets.zero,child:MobileActionRow(
      icon:Icons.workspace_premium_rounded,color:AppColors.pointsGold(context),
      title:ar?'شهاداتي':'My certificates',subtitle:summary,
      onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>learningEnabled?CertificatesScreen(journey:journey!,showExams:examsEnabled):const CustomExamsScreen(certificatesOnly:true))),
    ));
  }
}

class CertificatesScreen extends ConsumerStatefulWidget {
  final LearningJourney journey;
  final bool showExams;
  const CertificatesScreen({super.key,required this.journey,this.showExams=false});
  @override ConsumerState<CertificatesScreen> createState()=>_CertificatesScreenState();
}
class _CertificatesScreenState extends ConsumerState<CertificatesScreen>{
  static const _root='/users/certificates';
  Map<String,dynamic>? _list,_eligibility;
  int? _choice;
  int _page=1;
  bool _busy=true,_checking=false,_error=false;
  String? _notice;
  late final int? _owner;
  bool get _sameOwner=>_owner!=null&&ref.read(authProvider).user?.id==_owner;
  bool get ar=>context.locale.languageCode=='ar';
  String tr(String a,String e)=>ar?a:e;
  @override void initState(){super.initState();_owner=ref.read(authProvider).user?.id;_load();}
  Future<void> _load({bool refresh=false,int? page}) async{
    if(!mounted||!_sameOwner)return;
    setState((){_busy=true;_error=false;});
    try{
      final target=page??_page;
      final provider=certificateListProvider((owner:_owner!,page:target));
      if(refresh)ref.invalidate(certificateListProvider);
      final data=await ref.read(provider.future);
      if(mounted&&_sameOwner)setState((){_list=data;_page=target;});
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
      setState((){_choice=null;_eligibility=null;_notice=tr('تم إصدار الشهادة وحفظها.','Certificate issued and saved.');});
      await _load(refresh:true,page:1);
    }catch(_){if(mounted&&_sameOwner)setState((){_error=true;_eligibility=null;});}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _preview(Map<String,dynamic> cert,String lang) async{
    if(_busy||!_sameOwner)return;
    final id=sessionText(cert,'Id');
    if(!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id))return;
    setState((){_busy=true;_error=false;});
    try{
      final bytes=await ref.read(apiClientProvider).getBinary('$_root/$id/pdf',queryParameters:{'lang':lang});
      if(bytes.length<5||String.fromCharCodes(bytes.take(5))!='%PDF-')throw const FormatException('Invalid PDF');
      if(!mounted||!_sameOwner)return;
      final pdf=Uint8List.fromList(bytes);
      await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>Scaffold(
        appBar:AppBar(title:Text(tr('معاينة الشهادة','Certificate preview'))),
        body:PdfPreview(build:(_)=>pdf,pdfFileName:'mathworld-certificate-$lang.pdf',canChangePageFormat:false,canChangeOrientation:false,canDebug:false,allowPrinting:true,allowSharing:true),
      )));
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
    final pages=(sessionInt(_list?['Total'])+AppConstants.pageSize-1)~/AppConstants.pageSize;
    final e=_eligibility;
    return Scaffold(appBar:AppBar(title:Text(tr('شهاداتي التعليمية','My learning certificates'))),body:MathBackground(child:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
      if(_busy||_checking)const LinearProgressIndicator(),
      if(_error)Card(child:ListTile(title:Text(tr('تعذّر إكمال الطلب. أعد المحاولة.','Request failed. Please retry.')),trailing:IconButton(onPressed:_busy||_checking?null:() async{await _load(refresh:true);if(mounted&&_choice!=null)await _check(_choice);},icon:const Icon(Icons.refresh)))),
      if(_notice!=null)Text(_notice!),
      if(widget.showExams)MobilePanel(padding:EdgeInsets.zero,child:MobileActionRow(icon:Icons.school_outlined,color:AppColors.pointsGold(context),title:tr('شهادات الامتحانات','Exam certificates'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const CustomExamsScreen(certificatesOnly:true))))),
      const SizedBox(height:16),
      if(_list?['IssuanceEnabled']==true&&premium)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(tr('استحقاق شهادة جديدة','New certificate eligibility'),style:Theme.of(context).textTheme.titleMedium),
        Text(tr('أكمل جميع مسائل النطاق المعتمد وأثبت الحل المستقل في كل مهارة.','Complete every problem in the approved scope and demonstrate independent solving in every skill.')),
        DropdownButtonFormField<int>(isExpanded:true,initialValue:_choice,decoration:InputDecoration(labelText:tr('اختر النطاق','Choose scope')),onChanged:_busy||_checking?null:_check,items:[
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
      if(_busy&&_list==null)const SizedBox(height:400,child:AppContentSkeleton(count:5)),
      if(_list!=null&&items.isEmpty)Padding(padding:const EdgeInsets.all(12),child:Text(tr('لم تصدر لك شهادات بعد.','No certificates issued yet.'))),
      for(final c in items)Padding(padding:const EdgeInsets.only(top:16),child:MobilePanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.workspace_premium_outlined,color:AppColors.rewardGold),title:Text(sessionText(c,ar?'TitleAr':'TitleEn')),subtitle:Text(sessionText(c,'StudentName'))),
        Text(sessionText(c,'IssuedAtUtc').split('T').first),
        Text(tr('رمز التحقق','Verification code')),
        SelectableText(sessionText(c,'VerificationCode')),
        Wrap(spacing:8,children:[
          OutlinedButton.icon(onPressed:_busy?null:()=>_preview(c,'ar'),icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('PDF العربية')),
          OutlinedButton.icon(onPressed:_busy?null:()=>_preview(c,'en'),icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('PDF English')),
        ]),
      ]))),
      if(pages>1)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:MathWorldPagination(page:_page,pageCount:pages,arabic:ar,onChanged:(p){if(!_busy&&!_checking)_load(page:p);})),
    ]))));
  }
}
