import 'package:flutter/material.dart';
import '../utils/layout_utils.dart';

/// One-based numbered pagination. Keep bounds and server limits at the caller.
class MathWorldPagination extends StatelessWidget {
  final int page, pageCount;
  final ValueChanged<int> onChanged;
  final bool disabled;
  final bool arabic;
  const MathWorldPagination({super.key,required this.page,required this.pageCount,
    required this.onChanged,required this.arabic,this.disabled=false});
  @override
  Widget build(BuildContext context){
    final last=pageCount<1?1:pageCount;
    final active=page.clamp(1,last).toInt();
    final pages=<int>{1,last,for(final n in [active-1,active,active+1]) if(n>1&&n<last)n}.toList()..sort();
    return Semantics(label:arabic?'الصفحة $active من $last':'Page $active of $last',
      child:Wrap(alignment:WrapAlignment.center,crossAxisAlignment:WrapCrossAlignment.center,spacing:4,runSpacing:4,children:[
        OutlinedButton(onPressed:disabled||active==1?null:()=>onChanged(active-1),
          child:Tooltip(message:arabic?'السابق':'Previous',child:LayoutUtils.previousPageIcon(context,size:18))),
        for(var i=0;i<pages.length;i++)...[
          if(i>0&&pages[i]-pages[i-1]>1)const Text('…'),
          Semantics(selected:pages[i]==active,button:true,label:arabic?'صفحة ${pages[i]}':'Page ${pages[i]}',
            child:pages[i]==active?FilledButton(onPressed:disabled?null:()=>{},style:FilledButton.styleFrom(minimumSize:const Size(44,44),padding:const EdgeInsets.symmetric(horizontal:10)),child:Text('${pages[i]}')):
              OutlinedButton(onPressed:disabled?null:()=>onChanged(pages[i]),style:OutlinedButton.styleFrom(minimumSize:const Size(44,44),padding:const EdgeInsets.symmetric(horizontal:10)),child:Text('${pages[i]}'))),
        ],
        OutlinedButton(onPressed:disabled||active>=last?null:()=>onChanged(active+1),
          child:Tooltip(message:arabic?'التالي':'Next',child:LayoutUtils.nextPageIcon(context,size:18))),
      ]));
  }
}
