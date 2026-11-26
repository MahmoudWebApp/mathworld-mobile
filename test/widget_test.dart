import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/app_states.dart';
import 'package:mathworld_mobile/config/design_tokens.dart';

void main() {
  testWidgets('basic application shell renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('MathWorld')),
      ),
    );

    expect(find.text('MathWorld'), findsOneWidget);
  });
  testWidgets('content loading uses logo-free skeleton and supports reduced motion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppLoadingView())));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(AppContentSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(disableAnimations: true,size: Size(320,480)),
      child: Scaffold(body: AppContentSkeleton(cards:true,count:4)),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(AppContentSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact action loading keeps only an inline spinner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child:AppInlineLoader()))));
    expect(find.byType(CircularProgressIndicator),findsOneWidget);
    expect(find.byType(AppContentSkeleton),findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('points share the same contrast-aware gold', (tester) async {
    for(final dark in [false,true]){
      Color? gold;
      await tester.pumpWidget(MaterialApp(theme:dark?ThemeData.dark():ThemeData.light(),home:Builder(builder:(context){
        gold=AppColors.pointsGold(context);
        return const SizedBox.shrink();
      })));
      expect(gold,dark?const Color(0xFFF7C948):const Color(0xFFA66B00));
    }
  });
}
