import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../widgets/brand_logo.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../providers/premium_reports_provider.dart';
import '../../providers/premium_analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/learning_journey_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stages_provider.dart';

final studentOnboardingProvider = FutureProvider.autoDispose<String>((ref) async {
  final account = ref.watch(authProvider.select((s) => (id: s.user?.id, role: s.user?.role.toLowerCase(), stage: s.user?.currentStageId)));
  if (account.id == null || account.role != 'student') return 'SignedOut';
  try {
    final response = await ref.watch(apiClientProvider).get('/users/onboarding');
    final payload = ApiEnvelope.map(response.data);
    final step = payload['NextStep'] ?? payload['nextStep'];
    if (step is String && ['VerifyEmail','SelectStage','SelectTrack','Complete'].contains(step)) return step;
    throw const AppException(type: AppExceptionType.invalidResponse, messageKey: 'invalid_response');
  } on AppException {
    rethrow;
  }
});

class StudentOnboardingGate extends ConsumerWidget {
  const StudentOnboardingGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final status = ref.watch(studentOnboardingProvider);
    return status.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const BrandMark(size: 64),
        const SizedBox(height: 20),
        Text(ar ? 'تعذّر التحقق من جاهزية الحساب' : 'Could not check account setup', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(localizedErrorMessage(error), textAlign: TextAlign.center),
        FilledButton(onPressed: () => ref.invalidate(studentOnboardingProvider), child: Text(ar?'إعادة المحاولة':'Retry')),
        TextButton(onPressed: () async { await ref.read(authProvider.notifier).logout(); if(context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false); }, child: Text(ar?'تسجيل الخروج':'Sign out')),
      ]))))),
      data: (step) => step == 'Complete' ? child : _SetupScreen(key: ValueKey(step), step: step),
    );
  }
}

class _SetupScreen extends ConsumerStatefulWidget {
  const _SetupScreen({super.key, required this.step});
  final String step;
  @override
  ConsumerState<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<_SetupScreen> {
  int? selectedStage;
  int? selectedTrack;
  bool busy = false;
  String notice = '';
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get verificationCode => _codeController.text.trim();

  Future<void> perform(Future<void> Function() action, {String? success}) async {
    if (busy) return;
    setState(() { busy = true; notice = ''; });
    try {
      await action();
      if (mounted && success != null) setState(() => notice = success);
    } catch (error) {
      if (mounted) setState(() => notice = localizedErrorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final user = ref.watch(authProvider).user;
    final client = ref.watch(apiClientProvider);
    final verify = widget.step == 'VerifyEmail';
    final stage = widget.step == 'SelectStage' || (widget.step == 'SelectTrack' && user?.currentStageId == null);
    final stages = stage ? ref.watch(stagesProvider) : null;
    final stageId = selectedStage ?? user?.currentStageId;
    final tracks = !verify && !stage && stageId != null ? ref.watch(publishedTracksProvider(stageId)) : null;
    return PopScope(canPop: false, child: Scaffold(
      appBar: AppBar(title: Text(ar?'إكمال إعداد الحساب':'Complete account setup'), automaticallyImplyLeading: false),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        const Center(child: BrandMark(size: 64)),
        const SizedBox(height: 16),
        if (widget.step != 'SignedOut') ...[
          Text(ar?'إعداد حسابك':'Set up your account', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: verify ? 1/3 : stage ? 2/3 : 1, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 24),
        ],
        if (widget.step == 'SignedOut')
          FilledButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false), child: Text(ar?'تسجيل الدخول':'Sign in'))
        else if (verify) ...[
          const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.brandPurple),
          const SizedBox(height: 12),
          Text(ar?'أكد بريدك الإلكتروني':'Verify your email', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(ar?'أدخل رمز التحقق المكوّن من 6 أرقام الذي وصلك على بريدك الإلكتروني.':'Enter the six-digit verification code sent to your email.', textAlign: TextAlign.center),
          if(user!=null) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(user.email,textAlign:TextAlign.center,textDirection:ui.TextDirection.ltr,style:Theme.of(context).textTheme.titleSmall)),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            enabled: !busy,
            keyboardType: TextInputType.number,
            textDirection: ui.TextDirection.ltr,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontSize:26, letterSpacing:8, fontWeight:FontWeight.bold),
            decoration: InputDecoration(labelText:ar?'رمز التحقق':'Verification code',hintText:'000000',counterText:''),
            onChanged: (_) => setState(() => notice=''),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: busy||verificationCode.length!=6?null:()=>perform(() async {
            await client.post('/auth/email-verification/confirm-code',data:{'Code':verificationCode});
            if(mounted) ref.invalidate(studentOnboardingProvider);
          }), child: Text(busy?(ar?'جارٍ التحقق…':'Verifying…'):(ar?'تفعيل الحساب والمتابعة':'Verify and continue'))),
          OutlinedButton(onPressed: busy?null:()=>perform(() async {
            await client.post('/auth/email-verification/request',data:{'Language':ar?'ar':'en'});
            if(mounted) _codeController.clear();
          },success:ar?'تم طلب رمز جديد. تحقق من بريدك.':'New code requested. Check your email.'), child: Text(ar?'إعادة إرسال الرمز':'Resend code')),
          TextButton(onPressed:busy?null:()=>ref.invalidate(studentOnboardingProvider), child:Text(ar?'فعّلت البريد من الموقع؟ متابعة':'Verified on the website? Continue')),
        ] else ...[
          Text(stage?(ar?'اختر مرحلتك التعليمية':'Choose your learning stage'):(ar?'اختر الصف أو المستوى':'Choose grade or level'),style: Theme.of(context).textTheme.headlineSmall),
          if(stages != null) stages.when(
            loading:()=>const Center(child:CircularProgressIndicator()),
            error:(_,__)=>TextButton(onPressed:()=>ref.invalidate(stagesProvider),child:Text(ar?'إعادة المحاولة':'Retry')),
            data:(items)=>Column(children:[
              if(items.isEmpty) Text(ar?'لا توجد مراحل متاحة':'No available stages'),
              ...items.map((item)=>_ChoiceCard(title:item.getName(ar?'ar':'en'),subtitle:item.getDescription(ar?'ar':'en').trim().isEmpty?null:Text(item.getDescription(ar?'ar':'en'),maxLines:2,overflow:TextOverflow.ellipsis),accent:AppColors.stageForOrder(item.order),selected:stageId==item.id,icon:Icons.school_outlined,onTap:busy?null:()=>setState((){selectedStage=item.id;selectedTrack=null;}))),
            ]),
          ),
          if(stage) FilledButton(onPressed:busy||stageId==null||!(stages?.asData?.value.any((x)=>x.id==stageId)??false)?null:()=>perform(() async{
            await ref.read(authProvider.notifier).chooseLearningStage(stageId);
            ref.invalidate(studentOnboardingProvider);
            if(mounted) Navigator.pushNamedAndRemoveUntil(context,AppRoutes.home,(_)=>false);
          }),child:Text(ar?'حفظ المرحلة والمتابعة':'Save stage and continue')),
          if(!stage && tracks!=null) tracks.when(
            loading:()=>const Center(child:CircularProgressIndicator()),
            error:(_,__)=>TextButton(onPressed:()=>ref.invalidate(publishedTracksProvider(stageId!)),child:Text(ar?'إعادة المحاولة':'Retry')),
            data:(catalog)=>Column(children:[
              if(catalog.items.isEmpty) Text(ar?'لا توجد صفوف أو مستويات منشورة حالياً.':'No published grades or levels yet.'),
              ...catalog.items.map((item)=>_ChoiceCard(title:trackText(item,'Name',ar),subtitle:_gradeAge(item,ar),accent:AppColors.stageForIdentity(stageId!,null),selected:selectedTrack==trackNumber(item['Id']),icon:Icons.auto_stories_outlined,onTap:busy?null:()=>setState(()=>selectedTrack=trackNumber(item['Id'])))),
              FilledButton(onPressed:busy||selectedTrack==null||!catalog.items.any((x)=>trackNumber(x['Id'])==selectedTrack)?null:()=>perform(() async{
                await client.put('/users/learning-track',data:{'TrackId':selectedTrack});
                await ref.read(authProvider.notifier).refreshProfile();
                ref.invalidate(trackSelectionProvider);
                ref.invalidate(trackProgressProvider);
                ref.invalidate(trackPracticeProvider);
                ref.invalidate(dashboardProvider);
                ref.invalidate(learningJourneyProvider);
                ref.invalidate(premiumProgressReportProvider);
                ref.invalidate(premiumAnalyticsProvider);
                ref.invalidate(filteredPremiumAnalyticsProvider);
                ref.invalidate(studentOnboardingProvider);
                if(mounted) Navigator.pushNamedAndRemoveUntil(context,AppRoutes.home,(_)=>false);
              }),child:Text(ar?'حفظ والانتقال للرئيسية':'Save and go to home')),
            ]),
          ),
        ],
        if(notice.isNotEmpty) Text(notice),
        if(user!=null) TextButton(onPressed:busy?null:()=>perform(() async{
          await ref.read(authProvider.notifier).logout();
          if(mounted) Navigator.pushNamedAndRemoveUntil(context,AppRoutes.login,(_)=>false);
        }),child:Text(ar?'تسجيل الخروج':'Sign out')),
      ])),
    ));
  }
}

Widget? _gradeAge(Map<String,dynamic> item,bool ar){
  final m=RegExp(r'^grade-(\d+)$').firstMatch(item['Code']?.toString()??'');
  final n=int.tryParse(m?.group(1)??'');
  if(n==null||n<1||n>12)return null;
  return Text(ar?'العمر التقريبي: ${n+5}–${n+6} سنة':'Typical age: ${n+5}–${n+6} years');
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.title,required this.selected,required this.accent,required this.icon,this.subtitle,this.onTap});
  final String title;
  final bool selected;
  final Color accent;
  final IconData icon;
  final Widget? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),side: BorderSide(color:selected?accent:Theme.of(context).colorScheme.outlineVariant,width:selected?2:1)),
      child: ListTile(
        selected:selected,
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
        leading:Icon(icon,color:accent),
        title:Text(title,style:TextStyle(fontWeight:FontWeight.w700,color:accent)),
        subtitle:subtitle,
        trailing:Icon(selected?Icons.check_circle:Icons.radio_button_unchecked,color:selected?accent:Theme.of(context).colorScheme.onSurfaceVariant),
        onTap:onTap,
      ),
    );
  }
}
