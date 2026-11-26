import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_routes.dart';
import '../config/design_tokens.dart';
import '../providers/student_badges_provider.dart';
import 'glass_card.dart';
import 'app_states.dart';
import '../services/student_badges_service.dart';

IconData _badgeIcon(String icon) => switch (icon) {
  'graduation' => Icons.school_rounded,
  'trophy' => Icons.emoji_events_rounded,
  'crown' => Icons.workspace_premium_rounded,
  'puzzle' => Icons.extension_rounded,
  'gem' => Icons.diamond_rounded,
  'target' => Icons.gps_fixed_rounded,
  'flame' => Icons.local_fire_department_rounded,
  'bolt' => Icons.bolt_rounded,
  'globe' => Icons.public_rounded,
  _ => Icons.military_tech_rounded,
};

String _badgeUnit(String unit, bool ar) => switch (unit) {
  'days' => ar ? 'أيام متتالية' : 'Consecutive days',
  'categories' => ar ? 'فئات مكتملة' : 'Completed categories',
  'mastered' => ar ? 'مسائل متقنة' : 'Mastered problems',
  'stages' => ar ? 'مراحل' : 'Stages',
  _ => ar ? 'مسائل' : 'Problems',
};

class StudentBadgesCard extends ConsumerWidget {
  const StudentBadgesCard({super.key,this.showAll=false});
  final bool showAll;

  void _showPremiumBadge(BuildContext context, String badgeName, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 32, color: AppColors.brandViolet),
              const SizedBox(height: AppSpacing.md),
              Text(
                ar ? 'شارة Premium مقفولة' : 'Locked Premium badge',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ar
                    ? 'شارة «$badgeName» تظهر لك للتعرّف عليها، ويمكن فتحها عند ترقية حسابك إلى Premium.'
                    : 'The “$badgeName” badge stays visible for you to discover. Upgrade to Premium to unlock it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, AppRoutes.premiumBenefits);
                  },
                  child: Text(ar
                      ? 'عرض المميزات وترقية الحساب'
                      : 'View benefits and upgrade'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  double _progress(MathBadge badge)=>badge.requiredSolved>0?(badge.currentProgress/badge.requiredSolved).clamp(0.0,1.0).toDouble():0;
  List<MathBadge> _featured(List<MathBadge> badges){
    final earned=badges.where((b)=>b.isAvailable&&b.earned).toList()..sort((a,b){
      final x=a.milestoneReachedAtUtc,y=b.milestoneReachedAtUtc;
      if(x!=null&&y!=null)return y.compareTo(x);
      if(x!=null)return -1;
      if(y!=null)return 1;
      return b.requiredSolved.compareTo(a.requiredSolved);
    });
    final pending=badges.where((b)=>b.isAvailable&&!b.earned).toList()..sort((a,b)=>_progress(b).compareTo(_progress(a)));
    return [...earned.take(1),...pending].take(4).toList();
  }
  Widget _tile(BuildContext context,MathBadge badge,bool ar){
    final locked=!badge.isAvailable,earned=badge.isAvailable&&badge.earned;
    final name=ar?badge.titleAr:badge.titleEn,description=ar?badge.descriptionAr:badge.descriptionEn;
    final gold=AppColors.pointsGold(context);
    final progress=_progress(badge);
    return Semantics(label:name,hint:description,button:locked,child:InkWell(
      borderRadius:BorderRadius.circular(14),onTap:locked?()=>_showPremiumBadge(context,name,ar):null,
      child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(
        color:gold.withValues(alpha:.06),borderRadius:BorderRadius.circular(14),border:Border.all(color:gold.withValues(alpha:.32))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(_badgeIcon(badge.icon),color:gold,size:28),const Spacer(),if(earned)const Icon(Icons.check_circle_rounded,color:AppColors.success,size:18) else if(locked)const Icon(Icons.lock_outline,size:18)]),
          const SizedBox(height:8),Text(name,style:Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight:FontWeight.w800),maxLines:2,overflow:TextOverflow.ellipsis),
          if(earned&&badge.milestoneReachedAtUtc!=null)
            Padding(padding:const EdgeInsets.only(top:4),child:Text(
              (ar?'بلوغ الهدف: ':'Milestone reached: ')+DateFormat.yMMMd(context.locale.languageCode).format(badge.milestoneReachedAtUtc!.toLocal()),
              style:Theme.of(context).textTheme.bodySmall,
            )),
          if(showAll&&description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:4),child:Text(description,style:Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height:8),
          if(locked)Text('Premium',style:TextStyle(color:gold,fontWeight:FontWeight.w700))else...[
            Directionality(textDirection:ui.TextDirection.ltr,child:Text('${badge.currentProgress}/${badge.requiredSolved}',style:TextStyle(color:gold,fontWeight:FontWeight.w700))),
            if(showAll)Text(_badgeUnit(badge.unit,ar),style:Theme.of(context).textTheme.labelSmall),
            const SizedBox(height:6),
            LinearProgressIndicator(value:progress,color:earned?AppColors.success:AppColors.rewardGoldBright,backgroundColor:gold.withValues(alpha:.12),borderRadius:BorderRadius.circular(8)),
          ],
        ]),
      ),
    ));
  }
  Widget _grid(BuildContext context,List<MathBadge> badges,bool ar)=>LayoutBuilder(builder:(context,limits){
    final columns=limits.maxWidth>=520?3:2;
    final width=(limits.maxWidth-(columns-1)*8)/columns;
    return Wrap(spacing:8,runSpacing:8,children:[for(final b in badges)SizedBox(width:width,child:_tile(context,b,ar))]);
  });
  @override Widget build(BuildContext context,WidgetRef ref){
    final ar=context.locale.languageCode=='ar';
    final state=ref.watch(studentBadgesProvider);
    return GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(Icons.military_tech_rounded,color:AppColors.pointsGold(context),size:28),const SizedBox(width:8),Expanded(child:Text(ar?'الشارات والإنجازات':'Badges & achievements',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>ref.invalidate(studentBadgesProvider),tooltip:ar?'تحديث':'Refresh',icon:const Icon(Icons.refresh))]),
      state.when(loading:()=>const SizedBox(height:180,child:AppContentSkeleton(cards:true,count:4)),error:(_,__)=>Text(ar?'تعذر تحميل الشارات. اضغط تحديث.':'Could not load badges. Tap refresh.'),data:(result){
        final badges=result.badges;
        final featured=_featured(badges);
        final groups=<String,List<MathBadge>>{
          ar?'مكتسبة':'Earned':badges.where((b)=>b.isAvailable&&b.earned).toList(),
          ar?'قيد الإنجاز':'In progress':badges.where((b)=>b.isAvailable&&!b.earned).toList(),
          ar?'شارات Premium':'Premium badges':badges.where((b)=>!b.isAvailable).toList(),
        };
        return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${result.earnedCount} / ${badges.where((b)=>b.isAvailable).length}',style:TextStyle(color:AppColors.pointsGold(context),fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          if(showAll)...[for(final group in groups.entries)if(group.value.isNotEmpty)...[Text(group.key,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),_grid(context,group.value,ar),const SizedBox(height:16)]]else...[
            if(featured.isEmpty)Text(ar?'ابدأ التدريب لجمع الشارات.':'Start practicing to earn badges.')else _grid(context,featured,ar),
            const SizedBox(height:8),
            TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>Scaffold(appBar:AppBar(title:Text(ar?'جميع الشارات':'All badges')),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:const StudentBadgesCard(showAll:true)))))),child:Text(ar?'عرض جميع الشارات':'View all badges')),
          ],
        ]);
      }),
    ]));
  }
}
