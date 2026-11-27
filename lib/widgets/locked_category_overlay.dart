import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// Visual gate only: callers must use the server's actual access decision.
class LockedCategoryCard extends StatelessWidget {
  final Widget child;
  final bool locked;
  final bool arabic;
  final String name;
  final VoidCallback onUpgrade;
  const LockedCategoryCard({super.key,required this.child,required this.locked,
    required this.arabic,required this.name,required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    if(!locked)return child;
    final theme=Theme.of(context);
    return ClipRRect(
      borderRadius:BorderRadius.circular(AppRadius.md),
      child:Stack(fit:StackFit.passthrough,children:[
        ExcludeFocus(child:IgnorePointer(child:ExcludeSemantics(child:child))),
        Positioned.fill(child:Material(
          color:theme.colorScheme.surface.withValues(alpha:theme.brightness == Brightness.dark ? 0.72 : 0.68),
          child:Center(child:Padding(
            padding:const EdgeInsets.all(8),
            child:Column(mainAxisSize:MainAxisSize.min,children:[
              Container(width:40,height:40,decoration:BoxDecoration(
                color:theme.colorScheme.surface,shape:BoxShape.circle,
                border:Border.all(color:theme.colorScheme.outlineVariant)),
                child:Icon(Icons.lock_rounded,color:theme.colorScheme.primary,size:22)),
              const SizedBox(height:6),
              Text(arabic?'فئة مقفلة':'Locked topic',textAlign:TextAlign.center,
                style:theme.textTheme.labelMedium?.copyWith(fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Tooltip(message:arabic?'ترقية الحساب لفتح $name':'Upgrade account to unlock $name',
                child:FilledButton(
                  style:FilledButton.styleFrom(minimumSize:const Size(44,44),
                    padding:const EdgeInsets.symmetric(horizontal:8,vertical:8)),
                  onPressed:onUpgrade,
                  child:Text(arabic?'ترقية الحساب':'Upgrade account',textAlign:TextAlign.center,
                    style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
                )),
            ]),
          )),
        )),
      ]),
    );
  }
}
