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
  final response=await ref.watch(apiClientProvider).get('/learning-tracks/$id');
  return ApiEnvelope.map(response.data);
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
  final response=await ref.watch(apiClientProvider).get('/users/learning-tracks/${key.trackId}/categories/${key.categoryId}/problems',queryParameters:{'page':key.page,'hideSolved':key.hideSolved});
  return ApiEnvelope.map(response.data);
});
