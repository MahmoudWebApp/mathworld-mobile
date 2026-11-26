import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

enum MathWorldNoticeKind { success,error,info }

/// Use the platform's accessible floating Snackbar, with the same semantic
/// status treatment as the web toast. Do not dismiss important form errors.
void showMathWorldNotice(BuildContext context,String message,{MathWorldNoticeKind kind=MathWorldNoticeKind.info}){
  final scheme=Theme.of(context).colorScheme;
  final dark=Theme.of(context).brightness==Brightness.dark;
  final foreground=kind==MathWorldNoticeKind.error?scheme.error:
    kind==MathWorldNoticeKind.success?(dark?const Color(0xFF6EE7B7):const Color(0xFF166534)):scheme.primary;
  final icon=kind==MathWorldNoticeKind.error?Icons.error_outline:
    kind==MathWorldNoticeKind.success?Icons.check_circle_outline:Icons.info_outline;
  final messenger=ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration:Duration(seconds:kind==MathWorldNoticeKind.error?7:4),
    backgroundColor:scheme.surface,behavior:SnackBarBehavior.floating,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(AppRadius.md),side:BorderSide(color:foreground.withValues(alpha:.4))),
    content:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:foreground),const SizedBox(width:12),
      Expanded(child:Text(message,style:TextStyle(color:scheme.onSurface))),
    ]),
  ));
}

/// Keeps a scrollable message and fixed Cancel/Confirm controls.
Future<bool?> showMathWorldConfirmation(BuildContext context,{required String title,required String message,required String cancel,required String confirm,bool destructive=false}){
  final scheme=Theme.of(context).colorScheme;
  return showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
    scrollable:true,
    icon:Icon(destructive?Icons.delete_outline:Icons.warning_amber_rounded,color:destructive?scheme.error:AppColors.warning),
    title:Text(title),
    content:Text(message),
    actions:[
      OutlinedButton(onPressed:()=>Navigator.pop(dialog,false),child:Text(cancel)),
      FilledButton(style:FilledButton.styleFrom(minimumSize:const Size(90,44),backgroundColor:destructive?scheme.error:null,foregroundColor:destructive?scheme.onError:null),
        onPressed:()=>Navigator.pop(dialog,true),child:Text(confirm)),
    ],
  ));
}
