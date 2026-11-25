import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import 'glass_card.dart';
import 'brand_logo.dart';

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

/// Same branded loading state for data, search, filters and section changes.
enum AppLoadingMode { data, search, filter, section }
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key,this.mode=AppLoadingMode.data});
  final AppLoadingMode mode;
  @override
  Widget build(BuildContext context){
    final ar=context.locale.languageCode=='ar';
    final label=switch(mode){
      AppLoadingMode.data=>ar?'جارٍ تحميل البيانات…':'Loading data…',
      AppLoadingMode.search=>ar?'جارٍ البحث…':'Searching…',
      AppLoadingMode.filter=>ar?'جارٍ تصفية النتائج…':'Filtering results…',
      AppLoadingMode.section=>ar?'جارٍ تحميل القسم…':'Loading section…',
    };
    return Semantics(label:label,liveRegion:true,child:ExcludeSemantics(child:Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[
      SizedBox(width:72,height:72,child:Stack(alignment:Alignment.center,children:[
        SizedBox(width:70,height:70,child:CircularProgressIndicator(value:MediaQuery.disableAnimationsOf(context)?0.7:null,strokeWidth:2.5,color:AppColors.brandPurple,backgroundColor:AppColors.brandPink.withValues(alpha:0.14))),
        const BrandMark(size:48),
      ])),const SizedBox(height:12),const Text.rich(TextSpan(children:[TextSpan(text:'Math',style:TextStyle(color:AppColors.brandPurple)),TextSpan(text:'World',style:TextStyle(color:AppColors.brandPink))]),textDirection:TextDirection.ltr,style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(label,textAlign:TextAlign.center),
    ])))));
  }
}
