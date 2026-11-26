import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import 'glass_card.dart';
import 'mobile_section.dart';

/// Standard error state used across the application.
class AppErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const AppErrorView({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    size: 36, color: AppColors.error),
              ),
              const SizedBox(height: 18),
              Text(
                message ?? 'error_loading'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard empty state used across the application.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 34, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// First content load uses placeholders; small sections, filters and searches
/// use a compact unbranded loader. The caller owns completion/error state.
enum AppLoadingMode { data, search, filter, section }
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key,this.mode=AppLoadingMode.data});
  final AppLoadingMode mode;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context, constraints) {
    if(mode!=AppLoadingMode.data) {
      final height=constraints.hasBoundedHeight
          ? constraints.maxHeight.clamp(0.0,48.0).toDouble():48.0;
      return SizedBox(height:height,child:const Center(child:AppInlineLoader(size:20)));
    }
    return SizedBox(
      height:constraints.hasBoundedHeight?constraints.maxHeight:320,
      child:const AppContentSkeleton(),
    );
  });
}

/// Compact indeterminate action loader, with no logo or icon.
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key,this.size=20});
  final double size;
  @override Widget build(BuildContext context)=>Semantics(
    label:Localizations.localeOf(context).languageCode=='ar'?'جارٍ التحميل':'Loading',
    child:SizedBox.square(
      dimension:size,
      child:CircularProgressIndicator(strokeWidth:2.5,
        color:Theme.of(context).colorScheme.primary,
        value:MediaQuery.disableAnimationsOf(context)?0.7:null),
    ),
  );
}

/// Bounded, non-interactive placeholder list/grid. Animate one opacity layer,
/// not every bar/card, and stop animation when its route/tab is inactive.
class AppContentSkeleton extends StatefulWidget {
  const AppContentSkeleton({super.key,this.cards=false,this.count=4,this.title,this.sectionTitle,this.cardExtent});
  final bool cards;
  final int count;
  final String? title,sectionTitle;
  final double? cardExtent;
  @override
  State<AppContentSkeleton> createState()=>_AppContentSkeletonState();
}
class _AppContentSkeletonState extends State<AppContentSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse=AnimationController(vsync:this,duration:const Duration(milliseconds:900));
  late final Animation<double> _opacity=Tween<double>(begin:.55,end:1).animate(_pulse);
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    final animate=TickerMode.of(context)&&!MediaQuery.disableAnimationsOf(context);
    if(!animate){_pulse.stop();_pulse.value=1;}
    else if(!_pulse.isAnimating){_pulse.repeat(reverse:true);}
  }
  @override
  void dispose(){_pulse.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final base=Theme.of(context).colorScheme.onSurface.withValues(alpha:.11);
    Widget bar(double width,double height)=>Container(width:width,height:height,decoration:BoxDecoration(
      color:base,borderRadius:BorderRadius.circular(7),
    ));
    Widget item()=>MobilePanel(
      padding:const EdgeInsets.all(12),
      child:widget.cards
        ? Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[bar(44,44),const Spacer(),bar(32,12)]),
            const SizedBox(height:12),bar(double.infinity,14),const SizedBox(height:7),bar(85,12),
            const Spacer(),Align(alignment:AlignmentDirectional.centerEnd,child:bar(42,12)),
            const SizedBox(height:6),bar(double.infinity,5),
            const SizedBox(height:12),bar(double.infinity,24),
          ])
        : Row(children:[bar(36,36),const SizedBox(width:12),Expanded(child:Column(
            mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,
            children:[bar(double.infinity,15),const SizedBox(height:8),bar(120,15),const SizedBox(height:8),bar(75,12)],
          )),const SizedBox(width:8),bar(34,16)]),
    );
    final ar=Localizations.localeOf(context).languageCode=='ar';
    return LayoutBuilder(builder:(context,constraints){
      final count=widget.count.clamp(1,8).toInt();
      final height=constraints.hasBoundedHeight?constraints.maxHeight:320.0;
      final scale=(MediaQuery.textScalerOf(context).scale(14)/14).clamp(1.0,1.8).toDouble();
      final columns=constraints.maxWidth<332||scale>1.35?1:constraints.maxWidth>=732?3:2;
      final child=widget.cards
        ? GridView.builder(physics:const NeverScrollableScrollPhysics(),padding:const EdgeInsets.all(12),
            gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,mainAxisExtent:(widget.cardExtent??236)*scale,crossAxisSpacing:12,mainAxisSpacing:12),
            itemCount:count,itemBuilder:(_,__)=>item())
        : ListView.separated(physics:const NeverScrollableScrollPhysics(),padding:const EdgeInsets.all(16),itemCount:count,itemBuilder:(_,__)=>item(),separatorBuilder:(_,__)=>const SizedBox(height:12));
      return SizedBox(height:height,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(widget.title!=null)Padding(padding:const EdgeInsets.fromLTRB(16,12,16,4),child:Text(widget.title!,style:Theme.of(context).textTheme.headlineSmall)),
        if(widget.sectionTitle!=null)Padding(padding:const EdgeInsets.fromLTRB(16,8,16,4),child:MobileSectionTitle(title:widget.sectionTitle!)),
        Expanded(child:Semantics(label:ar?'جارٍ تحميل المحتوى':'Loading content',child:ExcludeSemantics(
          child:IgnorePointer(child:FadeTransition(opacity:_opacity,child:RepaintBoundary(child:child))),
        ))),
      ]));
    });
  }
}
