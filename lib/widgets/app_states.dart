import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import 'glass_card.dart';

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

/// Shared content loading state: animated placeholders, never a branded spinner.
enum AppLoadingMode { data, search, filter, section }
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key,this.mode=AppLoadingMode.data});
  final AppLoadingMode mode;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context, constraints) {
    return SizedBox(
      height:constraints.hasBoundedHeight?constraints.maxHeight:320,
      child:AppContentSkeleton(count:mode==AppLoadingMode.section?3:5),
    );
  });
}

/// Compact indeterminate action loader, with no logo or icon.
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key,this.size=20});
  final double size;
  @override Widget build(BuildContext context)=>SizedBox.square(
    dimension:size,
    child:CircularProgressIndicator(strokeWidth:2.5,
      color:Theme.of(context).colorScheme.primary,
      value:MediaQuery.disableAnimationsOf(context)?0.7:null),
  );
}

/// Loading placeholders follow the eventual content layout; no fake counts.
class AppContentSkeleton extends StatefulWidget {
  const AppContentSkeleton({super.key,this.cards=false,this.count=5});
  final bool cards;
  final int count;
  @override
  State<AppContentSkeleton> createState()=>_AppContentSkeletonState();
}
class _AppContentSkeletonState extends State<AppContentSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse=AnimationController(vsync:this,duration:const Duration(milliseconds:1100));
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(MediaQuery.disableAnimationsOf(context)){_pulse.stop();_pulse.value=1;}
    else if(!_pulse.isAnimating){_pulse.repeat();}
  }
  @override
  void dispose(){_pulse.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final colors=Theme.of(context).colorScheme;
    final reduceMotion=MediaQuery.disableAnimationsOf(context);
    final base=colors.onSurface.withValues(alpha:.075);
    final highlight=colors.onSurface.withValues(alpha:.15);
    Widget bar(double width,double height)=>AnimatedBuilder(animation:_pulse,builder:(_,__) {
      final offset=-2.0+3.0*_pulse.value;
      return RepaintBoundary(child:Container(width:width,height:height,decoration:BoxDecoration(
        color:reduceMotion?base:null,
        gradient:reduceMotion?null:LinearGradient(begin:Alignment(offset,0),end:Alignment(offset+1,0),colors:[base,highlight,base]),
        borderRadius:BorderRadius.circular(7),
      )));
    });
    Widget item()=>Card(elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[bar(42,42),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[bar(140,14),const SizedBox(height:12),bar(double.infinity,10),const SizedBox(height:8),bar(90,10)]))])));
    final ar=Localizations.localeOf(context).languageCode=='ar';
    return Semantics(label:ar?'جارٍ تحميل المحتوى':'Loading content',liveRegion:true,child:ExcludeSemantics(child:widget.cards?GridView.builder(padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent:320,mainAxisExtent:120),itemCount:widget.count,itemBuilder:(_,__)=>item()):ListView.builder(padding:const EdgeInsets.all(12),itemCount:widget.count,itemBuilder:(_,__)=>item()),
    ));
  }
}
