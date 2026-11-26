import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/mathworld_feedback.dart';

void main(){
  testWidgets('confirmation cancels without executing and confirms explicitly',(tester)async{
    bool? answer;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Builder(builder:(context)=>TextButton(
      onPressed:()async{answer=await showMathWorldConfirmation(context,title:'Delete',message:'Only the selected item',cancel:'Cancel',confirm:'Confirm',destructive:true);},
      child:const Text('Open'),
    )))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog),findsOneWidget);
    expect(find.byIcon(Icons.delete_outline),findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answer,false);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(answer,true);
  });
  testWidgets('feedback distinguishes success and failure',(tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Builder(builder:(context)=>Column(children:[
      TextButton(onPressed:()=>showMathWorldNotice(context,'Saved',kind:MathWorldNoticeKind.success),child:const Text('Save')),
      TextButton(onPressed:()=>showMathWorldNotice(context,'Failed',kind:MathWorldNoticeKind.error),child:const Text('Error')),
    ])))));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'),findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline),findsOneWidget);
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    expect(find.text('Failed'),findsOneWidget);
    expect(find.byIcon(Icons.error_outline),findsOneWidget);
  });
}
