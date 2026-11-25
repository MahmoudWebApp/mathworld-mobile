import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_envelope.dart';
import '../providers/repositories_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import 'glass_card.dart';

final leaderboardNamePreferenceProvider=FutureProvider.autoDispose.family<bool,int>((ref,id) async{
  final user=ref.watch(authProvider.select((s)=>s.user));
  if(user?.id!=id || user?.role!='Student')throw StateError('Student session required');
  final result=await ref.watch(apiClientProvider).get('/users/leaderboard-preferences');
  final value=ApiEnvelope.map(result.data)['ShareLeaderboardFullName'];
  if(value is! bool)throw StateError('Invalid preference');
  return value;
});
class LeaderboardNamePreference extends ConsumerStatefulWidget {
  final int userId;
  const LeaderboardNamePreference({super.key,required this.userId});
  @override
  ConsumerState<LeaderboardNamePreference> createState()=>_LeaderboardNamePreferenceState();
}
class _LeaderboardNamePreferenceState extends ConsumerState<LeaderboardNamePreference>{
  bool saving=false;
  bool failed=false;
  @override
  Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final provider=leaderboardNamePreferenceProvider(widget.userId);
    final q=ref.watch(provider);
    return GlassCard(padding:EdgeInsets.zero,child:q.when(
      loading:()=>const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator())),
      error:(_,__)=>ListTile(title:Text(ar?'تعذّر تحميل الخصوصية':'Could not load privacy'),trailing:TextButton(onPressed:()=>ref.invalidate(provider),child:Text(ar?'إعادة المحاولة':'Retry'))),
      data:(value)=>Column(children:[
        SwitchListTile(title:Text(ar?'عرض اسمي الكامل للطلاب في مرحلتي':'Show my full name to students in my stage'),value:value,onChanged:saving?null:(next)async{
          setState((){saving=true;failed=false;});
          try{
            if(ref.read(authProvider).user?.id!=widget.userId)return;
            await ref.read(apiClientProvider).put('/users/leaderboard-preferences',data:{'ShareLeaderboardFullName':next});
            if(!mounted||ref.read(authProvider).user?.id!=widget.userId)return;
            ref.invalidate(leaderboardProvider);
            await ref.refresh(provider.future);
          }catch(_){if(mounted)setState(()=>failed=true);}
          finally{if(mounted)setState(()=>saving=false);}
        }),
        if(failed)Padding(padding:const EdgeInsets.all(12),child:Text(ar?'تعذّر حفظ الاختيار':'Could not save preference')),
      ]),
    ));
  }
}
