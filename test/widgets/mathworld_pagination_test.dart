import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/mathworld_pagination.dart';

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
      await tester.tap(find.text('8'));
      expect(next,8);
      await tester.tap(find.byTooltip(ar?'السابق':'Previous'));
      expect(next,2);
      await tester.tap(find.byTooltip(ar?'التالي':'Next'));
      expect(next,4);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('single page and loading cannot trigger a request',(tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:MathWorldPagination(
      page:1,pageCount:1,arabic:false,disabled:true,onChanged:(_)=>fail('Disabled pagination'),
    ))));
    for(final b in tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)))expect(b.onPressed,isNull);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,isNull);
  });
}
