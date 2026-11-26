import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'mathworld_pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_routes.dart';
import '../config/design_tokens.dart';
import '../providers/student_badges_provider.dart';
import 'mobile_section.dart';
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

class StudentBadgesCard extends ConsumerStatefulWidget {
  const StudentBadgesCard({super.key,this.showAll=false,this.loadSummary=true});
  final bool showAll;
  final bool loadSummary;

  @override ConsumerState<StudentBadgesCard> createState()=>_StudentBadgesCardState();
}
class _StudentBadgesCardState extends ConsumerState<StudentBadgesCard>{
  int _page=1;
  bool get showAll=>widget.showAll;
  bool get loadSummary=>widget.loadSummary;
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
    final medal=MobileMedal(icon:_badgeIcon(badge.icon),earned:earned,locked:locked,size:showAll?54:44);
    final details=Column(crossAxisAlignment:showAll?CrossAxisAlignment.start:CrossAxisAlignment.center,mainAxisSize:MainAxisSize.min,children:[
      Text(name,style:Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight:FontWeight.w700),textAlign:showAll?TextAlign.start:TextAlign.center,maxLines:showAll?3:2,overflow:TextOverflow.ellipsis),
      if(showAll&&earned&&badge.milestoneReachedAtUtc!=null)
        Text((ar?'بلوغ الهدف: ':'Milestone reached: ')+DateFormat.yMMMd(context.locale.languageCode).format(badge.milestoneReachedAtUtc!.toLocal()),style:Theme.of(context).textTheme.bodySmall),
      if(showAll&&description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:4),child:Text(description,style:Theme.of(context).textTheme.bodySmall)),
      const SizedBox(height:4),
      if(locked)Text('Premium',style:TextStyle(color:gold,fontSize:11,fontWeight:FontWeight.w700))
      else ...[
        Directionality(textDirection:ui.TextDirection.ltr,child:Text('${badge.currentProgress}/${badge.requiredSolved}',style:TextStyle(color:gold,fontSize:12,fontWeight:FontWeight.w700))),
        if(showAll)Text(_badgeUnit(badge.unit,ar),style:Theme.of(context).textTheme.labelSmall),
        const SizedBox(height:5),
        LinearProgressIndicator(value:progress,minHeight:4,color:earned?AppColors.success:AppColors.rewardGoldBright,backgroundColor:AppColors.progressTrack(context),borderRadius:BorderRadius.circular(8)),
      ],
    ]);
    return Semantics(label:name,hint:description,button:locked,child:InkWell(
      borderRadius:BorderRadius.circular(12),onTap:locked?()=>_showPremiumBadge(context,name,ar):null,
      child:Padding(padding:const EdgeInsets.all(4),child:showAll?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[medal,const SizedBox(width:14),Expanded(child:details)]):Column(mainAxisSize:MainAxisSize.min,children:[medal,const SizedBox(height:8),details])),
    ));
  }
  Widget _grid(BuildContext context,List<MathBadge> badges,bool ar)=>LayoutBuilder(builder:(context,limits){
    final columns=showAll?1:(limits.maxWidth>=280&&MediaQuery.textScalerOf(context).scale(14)<=19?4:2);
    final width=(limits.maxWidth-(columns-1)*12)/columns;
    return Wrap(spacing:12,runSpacing:16,children:[for(final b in badges)SizedBox(width:width,child:_tile(context,b,ar))]);
  });
  Widget _placeholder(BuildContext context)=>LayoutBuilder(builder:(context,limits){
    final columns=limits.maxWidth>=280?4:2;
    return Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
      for(var i=0;i<columns;i++)Column(children:[
        CircleAvatar(radius:20,backgroundColor:Theme.of(context).colorScheme.surfaceContainerHighest),
        const SizedBox(height:8),Container(width:42,height:7,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(4))),
      ]),
    ]);
  });
  @override Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final state=loadSummary||showAll?ref.watch(studentBadgesProvider):null;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      MobileSectionTitle(title:ar?'الشارات والإنجازات':'Badges & achievements',actionLabel:showAll?(ar?'تحديث':'Refresh'):(ar?'عرض الكل':'View all'),onAction:showAll?()=>ref.invalidate(studentBadgesProvider):()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>Scaffold(appBar:AppBar(title:Text(ar?'جميع الشارات':'All badges')),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(16),child:const StudentBadgesCard(showAll:true))))))),
      const SizedBox(height:8),
      if(state==null)Text(ar?'عرض الشارات والإنجازات':'View badges and achievements',style:Theme.of(context).textTheme.bodySmall)
      else state.when(loading:()=>_placeholder(context),error:(_,__)=>TextButton.icon(onPressed:()=>ref.invalidate(studentBadgesProvider),icon:const Icon(Icons.refresh),label:Text(ar?'تعذّر تحميل الشارات':'Could not load badges')),data:(result){
        final badges=result.badges;
        final featured=_featured(badges);
        final groups=<String,List<MathBadge>>{
          ar?'مكتسبة':'Earned':badges.where((b)=>b.isAvailable&&b.earned).toList(),
          ar?'قيد الإنجاز':'In progress':badges.where((b)=>b.isAvailable&&!b.earned).toList(),
          ar?'شارات Premium':'Premium badges':badges.where((b)=>!b.isAvailable).toList(),
        };
        final ordered=[for(final group in groups.values)...group];
        final pages=(ordered.length+4)~/5;
        final page=_page.clamp(1,pages<1?1:pages).toInt();
        final visible=ordered.skip((page-1)*5).take(5).map((b)=>b.key).toSet();
        return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${result.earnedCount} / ${badges.where((b)=>b.isAvailable).length}',style:TextStyle(color:AppColors.pointsGold(context),fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          if(showAll)...[for(final group in groups.entries)if(group.value.any((b)=>visible.contains(b.key)))...[Text(group.key,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),_grid(context,group.value.where((b)=>visible.contains(b.key)).toList(),ar),const SizedBox(height:16)],if(pages>1)MathWorldPagination(page:page,pageCount:pages,arabic:ar,onChanged:(p)=>setState(()=>_page=p))]else...[
            if(featured.isEmpty)Text(ar?'ابدأ التدريب لجمع الشارات.':'Start practicing to earn badges.')else _grid(context,featured,ar),
          ],
        ]);
      }),
    ]);
  }
}
