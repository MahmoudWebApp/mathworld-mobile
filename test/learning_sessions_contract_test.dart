import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/learning_journey.dart';
import 'package:mathworld_mobile/services/learning_session_api.dart';
void main(){
  test('capability is opt-in and permanent points remain separate',(){
    final old=LearningJourney.fromJson({'StageId':1,'TotalPoints':12});
    expect(old.learningSessionsEnabled,isFalse);expect(old.displayedPoints,12);
    final next=LearningJourney.fromJson({'StageId':1,'TotalPoints':0,'PermanentPoints':12,'LearningSessionsEnabled':true});
    expect(next.learningSessionsEnabled,isTrue);expect(next.displayedPoints,12);
  });
  test('session scope rejects mismatched stage, track and category',(){
    const scope=SessionScope(kind:'practice',stageId:1,trackId:2,categoryId:3);
    expect(scope.matches({'Kind':'practice','StageId':1,'TrackId':2,'CategoryId':3}),isTrue);
    expect(scope.matches({'Kind':'practice','StageId':1,'TrackId':4,'CategoryId':3}),isFalse);
    expect(scope.matches({'Kind':'daily','StageId':1,'TrackId':2,'CategoryId':3}),isFalse);
  });
  test('request IDs are version 4 UUIDs and distinct',(){
    final values=List.generate(100,(_)=>sessionRequestId());
    expect(values.toSet().length,100);
    for(final id in values){expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(id),isTrue);}
  });
}
