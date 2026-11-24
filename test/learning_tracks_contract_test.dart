import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/providers/learning_tracks_provider.dart';
void main(){
  test('disabled or empty tracks preserve legacy catalog',(){
    expect(TrackCatalog.fromJson({'Enabled':false,'Items':[]}).enabled,isFalse);
    final catalog=TrackCatalog.fromJson({'Enabled':true,'Items':[{'Id':1,'ProblemsCount':0},{'Id':2,'ProblemsCount':3}]});
    expect(catalog.items.single['Id'],2);
    expect(trackText({'NameAr':'الصف الأول','NameEn':'Grade 1'},'Name',true),'الصف الأول');
  });
}
