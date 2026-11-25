import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_envelope.dart';
import '../../providers/auth_provider.dart';
import '../../providers/learning_tracks_provider.dart';
import '../../providers/repositories_provider.dart';
import '../../providers/stages_provider.dart';

final studentOnboardingProvider = FutureProvider.autoDispose<String>((ref) async {
  final user = ref.watch(authProvider.select((s) => s.user));
  if (user == null || user.role != 'Student') return 'SignedOut';
  try {
    final response = await ref.watch(apiClientProvider).get('/users/onboarding');
    final step = ApiEnvelope.map(response.data)['NextStep'];
    if (step is String && ['VerifyEmail','SelectStage','SelectTrack','Complete'].contains(step)) return step;
    throw const AppException(type: AppExceptionType.invalidResponse, messageKey: 'invalid_response');
  } on AppException catch (e) {
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
      error: (_, __) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(ar ? 'تعذّر التحقق من جاهزية الحساب' : 'Could not check account setup'),
        FilledButton(onPressed: () => ref.invalidate(studentOnboardingProvider), child: Text(ar?'إعادة المحاولة':'Retry')),
      ]))),
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

  Future<void> perform(Future<void> Function() action, {String? success}) async {
    if (busy) return;
    setState(() { busy = true; notice = ''; });
    try {
      await action();
      if (mounted && success != null) setState(() => notice = success);
    } catch (_) {
      if (mounted) setState(() => notice = context.locale.languageCode == 'ar' ? 'تعذّر إتمام العملية، حاول مجدداً.' : 'Unable to complete the action. Try again.');
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
    final stage = widget.step == 'SelectStage';
    final stages = stage || (!verify && user?.currentStageId == null) ? ref.watch(stagesProvider) : null;
    final stageId = selectedStage ?? user?.currentStageId;
    final tracks = !verify && !stage && stageId != null ? ref.watch(publishedTracksProvider(stageId)) : null;
    return PopScope(canPop: false, child: Scaffold(
      appBar: AppBar(title: Text(ar?'إكمال إعداد الحساب':'Complete account setup'), automaticallyImplyLeading: false),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        if (widget.step == 'SignedOut')
          FilledButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false), child: Text(ar?'تسجيل الدخول':'Sign in'))
        else if (verify) ...[
          const Icon(Icons.mark_email_unread_outlined, size: 56),
          Text(ar?'أكد بريدك الإلكتروني أولاً':'Verify your email first', style: Theme.of(context).textTheme.headlineSmall),
          Text(ar?'افتح رابط التأكيد من بريدك، ثم ارجع واضغط متابعة.':'Open the verification link from your inbox, then return and continue.'),
          FilledButton(onPressed: busy?null:()=>ref.invalidate(studentOnboardingProvider), child: Text(ar?'تحقق من التأكيد وتابع':'Check verification and continue')),
          OutlinedButton(onPressed: busy?null:()=>perform(() async {await client.post('/auth/email-verification/request',data:{'Language':ar?'ar':'en'});},success:ar?'تم طلب الرابط. تحقق من بريدك.':'Link requested. Check your inbox.'), child: Text(ar?'إعادة إرسال رابط التأكيد':'Resend verification link')),
        ] else ...[
          Text(stage?(ar?'اختر مرحلتك التعليمية':'Choose your learning stage'):(ar?'اختر الصف أو السنة أو المساق':'Choose grade, year or course'),style: Theme.of(context).textTheme.headlineSmall),
          if(stages != null) stages.when(
            loading:()=>const Center(child:CircularProgressIndicator()),
            error:(_,__)=>TextButton(onPressed:()=>ref.invalidate(stagesProvider),child:Text(ar?'إعادة المحاولة':'Retry')),
            data:(items)=>Column(children:items.map((item)=>ListTile(
              title:Text(item.getName(ar?'ar':'en')),
              trailing:stageId==item.id?const Icon(Icons.check_circle):null,
              onTap:busy?null:()=>setState((){selectedStage=item.id;selectedTrack=null;}),
            )).toList()),
          ),
          if(stage) FilledButton(onPressed:busy||stageId==null?null:()=>perform(() async{
            await ref.read(authProvider.notifier).chooseLearningStage(stageId);
            ref.invalidate(studentOnboardingProvider);
            if(mounted) Navigator.pushNamedAndRemoveUntil(context,AppRoutes.home,(_)=>false);
          }),child:Text(ar?'حفظ المرحلة والمتابعة':'Save stage and continue')),
          if(!stage && tracks!=null) tracks.when(
            loading:()=>const Center(child:CircularProgressIndicator()),
            error:(_,__)=>TextButton(onPressed:()=>ref.invalidate(publishedTracksProvider(stageId!)),child:Text(ar?'إعادة المحاولة':'Retry')),
            data:(catalog)=>Column(children:[
              if(catalog.items.isEmpty) Text(ar?'لا توجد صفوف أو مساقات منشورة حالياً.':'No published grades or courses yet.'),
              ...catalog.items.map((item)=>ListTile(title:Text(trackText(item,'Name',ar)),subtitle:_gradeAge(item,ar),trailing:selectedTrack==trackNumber(item['Id'])?const Icon(Icons.check_circle):null,onTap:busy?null:()=>setState(()=>selectedTrack=trackNumber(item['Id'])))),
              FilledButton(onPressed:busy||selectedTrack==null||!catalog.items.any((x)=>trackNumber(x['Id'])==selectedTrack)?null:()=>perform(() async{
                await client.put('/users/learning-track',data:{'TrackId':selectedTrack});
                await ref.read(authProvider.notifier).refreshProfile();
                ref.invalidate(trackSelectionProvider);
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
