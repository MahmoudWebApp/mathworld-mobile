import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/mathworld_pagination.dart';
import 'package:mathworld_mobile/utils/layout_utils.dart';
import 'package:mathworld_mobile/widgets/premium_button.dart';

void main(){
  for(final ar in [false,true]){
    testWidgets('numbered pagination responds in ${ar?'RTL':'LTR'}',(tester) async {
      int? next;
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:Directionality(
        textDirection:ar?TextDirection.rtl:TextDirection.ltr,
        child:MathWorldPagination(page:3,pageCount:8,onChanged:(p)=>next=p,arabic:ar),
      ))));
      expect(find.text('3'),findsOneWidget);
      expect(find.text('8'),findsOneWidget);
      final previous=find.byTooltip(ar?'السابق':'Previous');
      final following=find.byTooltip(ar?'التالي':'Next');
      final previousIcon=tester.widget<Icon>(find.descendant(of:previous,matching:find.byType(Icon)));
      final nextIcon=tester.widget<Icon>(find.descendant(of:following,matching:find.byType(Icon)));
      expect(previousIcon.icon,ar?Icons.chevron_right_rounded:Icons.chevron_left_rounded);
      expect(nextIcon.icon,ar?Icons.chevron_left_rounded:Icons.chevron_right_rounded);
      expect(previousIcon.textDirection,TextDirection.ltr);
      expect(nextIcon.textDirection,TextDirection.ltr);
      final previousX=tester.getCenter(previous).dx;
      final nextX=tester.getCenter(following).dx;
      expect(ar?previousX>nextX:previousX<nextX,isTrue);
      await tester.tap(find.text('8'));
      expect(next,8);
      await tester.tap(find.byTooltip(ar?'السابق':'Previous'));
      expect(next,2);
      await tester.tap(find.byTooltip(ar?'التالي':'Next'));
      expect(next,4);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('shared navigation respects explicit RTL and LTR layouts',(tester)async{
    for(final direction in [TextDirection.rtl,TextDirection.ltr]){
      final rtl=direction==TextDirection.rtl;
      await tester.pumpWidget(MaterialApp(home:Scaffold(body:Directionality(
        textDirection:direction,
        child:Builder(builder:(context)=>Column(children:[
          LayoutUtils.forwardIcon(context),
          LayoutUtils.backIcon(context),
          PremiumButton(label:'Continue',onPressed:(){},trailingIcon:Icons.arrow_forward_rounded),
        ])),
      ))));
      final icons=tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].icon,rtl?Icons.chevron_left_rounded:Icons.chevron_right_rounded);
      expect(icons[1].icon,rtl?Icons.chevron_right_rounded:Icons.chevron_left_rounded);
      expect(icons[2].icon,rtl?Icons.arrow_back_rounded:Icons.arrow_forward_rounded);
      for(final icon in icons)expect(icon.textDirection,TextDirection.ltr);
      expect(tester.takeException(),isNull);
    }
  });
  testWidgets('single page and loading cannot trigger a request',(tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:MathWorldPagination(
      page:1,pageCount:1,arabic:false,disabled:true,onChanged:(_)=>fail('Disabled pagination'),
    ))));
    for(final b in tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)))expect(b.onPressed,isNull);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,isNull);
  });
}
