import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_envelope.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

int trackNumber(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
List<Map<String,dynamic>> trackRows(dynamic value) => value is List
    ? value.whereType<Map>().map((row)=>Map<String,dynamic>.from(row)).toList()
    : [];
String trackText(Map<String,dynamic> row, String key, bool ar) =>
    (row['$key${ar?'Ar':'En'}'] ?? '').toString();

class TrackCatalog {
  final bool enabled;
  final List<Map<String,dynamic>> items;
  const TrackCatalog(this.enabled,this.items);
  factory TrackCatalog.fromJson(Map<String,dynamic> json) => TrackCatalog(
    json['Enabled']==true, trackRows(json['Items']).where((x)=>trackNumber(x['Id'])>0&&trackNumber(x['ProblemsCount'])>0).toList(),
  );
}

final publishedTracksProvider=FutureProvider.autoDispose.family<TrackCatalog,int>((ref,stageId) async {
  final client=ref.watch(apiClientProvider);
  // Public catalog only; never retain private progress or entitlement data.
  final lease=ref.keepAlive();
  final timer=Timer(const Duration(minutes:2),lease.close);
  ref.onDispose(timer.cancel);
  try {
    final response=await client.get('/stages/$stageId/tracks',handleUnauthorized:false);
    return TrackCatalog.fromJson(ApiEnvelope.map(response.data));
  } on AppException catch(error) {
    if(error.statusCode==404 || error.type==AppExceptionType.notFound) {
      return const TrackCatalog(false,[]);
    }
    lease.close();
    rethrow;
  }
});

final trackSelectionProvider=FutureProvider.autoDispose<Map<String,dynamic>>((ref) async {
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role.toLowerCase(),stage:s.user?.currentStageId)));
  if(account.id==null||account.role!='student') return {};
  final response=await ref.watch(apiClientProvider).get('/users/learning-track');
  return ApiEnvelope.map(response.data);
});
final trackDetailsProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,int>((ref,id) async {
  final client=ref.watch(apiClientProvider);
  // Keep only successful anonymous catalog details for a short revisit window.
  final lease=ref.keepAlive();
  final timer=Timer(const Duration(minutes:2),lease.close);
  ref.onDispose(timer.cancel);
  try{
    final response=await client.get('/learning-tracks/$id',handleUnauthorized:false);
    return ApiEnvelope.map(response.data);
  }catch(_){
    lease.close();
    rethrow;
  }
});
final trackProgressProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,int>((ref,id) async {
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role.toLowerCase(),stage:s.user?.currentStageId)));
  if(account.id==null||account.role!='student')return {};
  final response=await ref.watch(apiClientProvider).get('/users/learning-tracks/$id/progress');
  return ApiEnvelope.map(response.data);
});
typedef TrackPracticeKey=({int trackId,int categoryId,int page,bool hideSolved});
final trackPracticeProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,TrackPracticeKey>((ref,key) async {
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,role:s.user?.role.toLowerCase(),stage:s.user?.currentStageId)));
  if(account.id==null||account.role!='student')return {};
  final client=ref.watch(apiClientProvider);
  const size=5;
  final path='/users/learning-tracks/${key.trackId}/categories/${key.categoryId}/problems';
  Future<Map<String,dynamic>> fetch(int page) async => ApiEnvelope.map((await client.get(path,queryParameters:{'page':page,'pageSize':size,'hideSolved':key.hideSolved})).data);
  var data=await fetch(key.page);
  final serverSize=trackNumber(data['PageSize']);
  if(serverSize==size||serverSize<=0)return data;
  // Compatibility with old deployments that return 50 rows per page.
  final offset=(key.page-1)*size;
  final serverPage=offset~/serverSize+1;
  if(serverPage!=key.page)data=await fetch(serverPage);
  final start=offset%serverSize;
  final visible=trackRows(data['Items']).skip(start).take(size).toList();
  if(visible.length<size&&offset+visible.length<trackNumber(data['Total'])){
    final next=await fetch(serverPage+1);
    visible.addAll(trackRows(next['Items']).take(size-visible.length));
  }
  return {...data,'Page':key.page,'PageSize':size,'Items':visible};
});
