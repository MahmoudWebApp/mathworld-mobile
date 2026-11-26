import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/mobile_section.dart';

void main(){
  testWidgets('gold medal uses yellow artwork and green earned indicator',(tester)async{
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:MobileMedal(icon:Icons.emoji_events_rounded,earned:true))));
    expect(find.byIcon(Icons.check_circle),findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded),findsOneWidget);
    final boxes=tester.widgetList<DecoratedBox>(find.descendant(of:find.byType(MobileMedal),matching:find.byType(DecoratedBox)));
    expect(boxes.any((b)=>b.decoration is BoxDecoration&&(b.decoration as BoxDecoration).gradient is LinearGradient),isTrue);
    expect(tester.takeException(),isNull);
  });
  testWidgets('flat action row fits a narrow screen with large text',(tester)async{
    await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(size:Size(320,640),textScaler:TextScaler.linear(1.4)),child:Scaffold(body:Align(alignment:Alignment.topCenter,child:SizedBox(width:288,child:MobilePanel(padding:EdgeInsets.zero,child:MobileActionRow(icon:Icons.school,color:Colors.purple,title:'Current grade reports',subtitle:'Your progress in this grade',onTap:(){}))))))));
    expect(find.text('Current grade reports'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
