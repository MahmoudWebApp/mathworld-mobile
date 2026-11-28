import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/problem.dart';
import 'package:mathworld_mobile/config/design_tokens.dart';
import 'package:mathworld_mobile/widgets/problem_card.dart';
import 'package:mathworld_mobile/widgets/learning_track_workspace.dart';
import 'package:mathworld_mobile/screens/premium/current_grade_report_screen.dart';
import 'package:mathworld_mobile/widgets/mobile_section.dart';

void main() {
  test('free labels require a free account and live restricted categories', () {
    final categories = <Map<String,dynamic>>[
      {'Id':1,'IsFree':true}, {'Id':2,'IsFree':false},
    ];
    final restricted = <int,Map<String,dynamic>>{
      1:{'IsLocked':false},2:{'IsLocked':true},
    };
    final unlocked = <int,Map<String,dynamic>>{
      1:{'IsLocked':false},2:{'IsLocked':false},
    };
    expect(showTrackFreeLabels('Free',categories,restricted),isTrue);
    expect(showTrackFreeLabels('Premium',categories,restricted),isFalse);
    expect(showTrackFreeLabels('Free',categories,unlocked),isFalse);
    expect(showTrackFreeLabels(null,categories,restricted),isFalse);
    expect(showTrackFreeLabels('Free',categories,{}),isFalse);
  });

  testWidgets('scoped problem card hides stage and category and uses gold new status',(tester) async {
    const problem=ProblemPreview(id:1,title:'Example',stageId:1,stageName:'Elementary',categoryId:1,categoryName:'Numbers',viewsCount:0,points:10,progressKnown:true);
    for(final ar in [false,true]){
      final label=ar?'جديدة':'New';
      await tester.pumpWidget(MaterialApp(
        locale:Locale(ar?'ar':'en'),
        supportedLocales:const [Locale('en'),Locale('ar')],
        localizationsDelegates:GlobalMaterialLocalizations.delegates,
        home:Scaffold(body:ProblemCard(problem:problem,showCategory:false,onTap:(){})),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Numbers'),findsNothing);
      expect(find.text('Elementary'),findsNothing);
      expect(find.text(label),findsOneWidget);
      expect(tester.widget<Text>(find.text(label)).style?.color,AppColors.pointsGold(tester.element(find.text(label))));
      expect(tester.takeException(),isNull);
    }
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:ProblemCard(problem:problem,onTap:(){}))));
    await tester.pumpAndSettle();
    expect(find.text('Numbers'),findsOneWidget);
    expect(find.text('Elementary'),findsOneWidget);
  });

  testWidgets('grade report fits a narrow screen and keeps actual metrics and scope disclosure',(tester) async {
    final report=<String,dynamic>{
      'Track':{'NameAr':'الصف الأول','NameEn':'Grade one','StageId':1},
      'CompletionPercent':50.0,'Solved':5,'ProblemsCount':10,'Points':45,
      'AccuracyPercent':75.0,'Attempts':8,'ProgressScope':'SharedStagePracticeCycle',
      'Categories':<Map<String,dynamic>>[],
      'RecentAttempts':<Map<String,dynamic>>[],
    };
    for(final ar in [false,true]){
      await tester.pumpWidget(MaterialApp(
        locale:Locale(ar?'ar':'en'),
        supportedLocales:const [Locale('en'),Locale('ar')],
        localizationsDelegates:GlobalMaterialLocalizations.delegates,
        home:Scaffold(body:Align(alignment:Alignment.topCenter,child:SizedBox(width:320,child:CurrentGradeReportBody(report:report,ar:ar,onRefresh:()async{})))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('50.0%'),findsOneWidget);
      expect(find.byType(LearningProgressBar),findsOneWidget);
      expect(tester.takeException(),isNull);
      final disclosure=find.text(ar?'كيف تُحسب النتائج؟':'How are results calculated?');
      await tester.scrollUntilVisible(disclosure,120);
      await tester.ensureVisible(disclosure);
      await tester.pumpAndSettle();
      expect(disclosure.hitTestable(),findsOneWidget);
      await tester.tap(disclosure.hitTestable());
      await tester.pumpAndSettle();
      expect(find.textContaining(ar?'لا تُنسب حصراً':'not exclusively grade-attributed'),findsOneWidget);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
