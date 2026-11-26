import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
import '../utils/layout_utils.dart';

/// Flat, shared mobile surface. No per-card blur or expensive shadow layers.
class MobilePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  const MobilePanel({super.key,required this.child,this.padding=const EdgeInsets.all(14),this.gradient,this.borderColor});
  @override Widget build(BuildContext context) => DecoratedBox(
    decoration:BoxDecoration(color:gradient==null?Theme.of(context).colorScheme.surface:null,gradient:gradient,
      border:Border.all(color:borderColor??(Theme.of(context).brightness==Brightness.dark?AppColors.darkBorder:AppColors.lightBorder)),
      borderRadius:BorderRadius.circular(16)),
    child:Padding(padding:padding,child:child),
  );
}
class MobileSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const MobileSectionTitle({super.key,required this.title,this.actionLabel,this.onAction});
  @override Widget build(BuildContext context)=>Row(children:[
    Expanded(child:Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800))),
    if(actionLabel!=null&&onAction!=null)TextButton(onPressed:onAction,child:Text(actionLabel!)),
  ]);
}
class MobileActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const MobileActionRow({super.key,required this.icon,required this.color,required this.title,this.subtitle,this.onTap});
  @override Widget build(BuildContext context)=>ListTile(
    contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:2),
    leading:Container(width:42,height:42,decoration:BoxDecoration(
      color:color.withValues(alpha:.10),borderRadius:BorderRadius.circular(12)),
      child:Icon(icon,color:color,size:23)),
    title:Text(title,style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w700)),
    subtitle:subtitle==null?null:Text(subtitle!,style:Theme.of(context).textTheme.bodySmall,maxLines:2,overflow:TextOverflow.ellipsis),
    trailing:onTap==null?null:LayoutUtils.forwardIcon(context),
    onTap:onTap,
  );
}
/// The medal artwork is yellow-gold; only text uses the contrast-aware ink.
class MobileMedal extends StatelessWidget {
  final IconData icon;
  final bool earned;
  final bool locked;
  final double size;
  const MobileMedal({super.key,required this.icon,this.earned=false,this.locked=false,this.size=48});
  @override Widget build(BuildContext context)=>SizedBox.square(dimension:size,child:Stack(
    clipBehavior:Clip.none,children:[
      Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(shape:BoxShape.circle,
        gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:locked?[const Color(0xFFEEE9DC),const Color(0xFFC9BFA7)]:const [Color(0xFFFFF0A3),Color(0xFFF5C518),Color(0xFFD89A08)]),
        border:Border.all(color:locked?const Color(0xFF9E9279):const Color(0xFFD39A13),width:1.5)),
        child:Center(child:Icon(icon,size:size*.52,color:const Color(0xFF795000))))),
      if(earned)PositionedDirectional(end:-2,bottom:-1,child:Icon(Icons.check_circle,color:AppColors.success,size:size*.34)),
      if(locked)PositionedDirectional(end:-2,bottom:-1,child:Icon(Icons.lock_rounded,color:Theme.of(context).colorScheme.onSurfaceVariant,size:size*.32)),
    ],
  ));
}

/// Determinate learning progress: zero has no colored fill.
class LearningProgressBar extends StatelessWidget {
  final double value;
  final double height;
  const LearningProgressBar({super.key,required this.value,this.height=5});
  @override Widget build(BuildContext context){
    final fraction=value.isFinite?value.clamp(0.0,1.0).toDouble():0.0;
    final track=Theme.of(context).brightness==Brightness.dark?AppColors.darkBorder:AppColors.lightBorder;
    return Semantics(value:'${(fraction*100).round()}%',child:ClipRRect(
      borderRadius:BorderRadius.circular(99),child:SizedBox(height:height,child:ColoredBox(color:track,
        child:Align(alignment:AlignmentDirectional.centerStart,child:FractionallySizedBox(widthFactor:fraction,heightFactor:1,
          child:ColoredBox(color:fraction>=1?AppColors.success:AppColors.rewardGold)))))));
  }
}
