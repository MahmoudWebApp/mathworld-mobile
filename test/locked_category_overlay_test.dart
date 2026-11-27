import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/locked_category_overlay.dart';

void main(){
  for(final ar in [false,true]){
    for(final dark in [false,true]){
      testWidgets('locked topic overlay: arabic=$ar dark=$dark',(tester)async{
        var opened=0,upgraded=0;
        Widget card(bool locked)=>MaterialApp(
          theme:dark?ThemeData.dark():ThemeData.light(),
          home:Scaffold(body:Center(child:SizedBox(width:150,height:236,
            child:LockedCategoryCard(locked:locked,arabic:ar,name:'Numbers',
              onUpgrade:()=>upgraded++,
              child:FilledButton(onPressed:()=>opened++,child:const Text('Open questions')))))));
        await tester.pumpWidget(card(true));
        final upgrade=find.text(ar?'ترقية الحساب':'Upgrade account');
        expect(upgrade,findsOneWidget);
        expect(find.byIcon(Icons.lock_rounded),findsOneWidget);
        await tester.tap(find.text('Open questions'),warnIfMissed:false);
        expect(opened,0);
        await tester.tap(upgrade);
        expect(upgraded,1);
        expect(tester.takeException(),isNull);
        await tester.pumpWidget(card(false));
        expect(upgrade,findsNothing);
        await tester.tap(find.text('Open questions'));
        expect(opened,1);
      });
    }
  }
}
