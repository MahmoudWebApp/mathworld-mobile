import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_envelope.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';

int trackNumber(dynamic value) => value is num ? value.toInt() : 0;
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
  try {
    final response=await client.get('/stages/$stageId/tracks',handleUnauthorized:false);
    return TrackCatalog.fromJson(ApiEnvelope.map(response.data));
  } on AppException catch(error) {
    if(error.statusCode==404 || error.type==AppExceptionType.notFound) {
      return const TrackCatalog(false,[]);
    }
    rethrow;
  }
});

final trackSelectionProvider=FutureProvider.autoDispose<Map<String,dynamic>>((ref) async {
  final user=ref.watch(authProvider.select((s)=>s.user));
  if(user?.role!='Student') return {};
  final response=await ref.watch(apiClientProvider).get('/users/learning-track');
  return ApiEnvelope.map(response.data);
});
final trackDetailsProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,int>((ref,id) async {
  final response=await ref.watch(apiClientProvider).get('/learning-tracks/$id');
  return ApiEnvelope.map(response.data);
});
final trackProgressProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,int>((ref,id) async {
  final user=ref.watch(authProvider.select((s)=>s.user));
  if(user?.role!='Student')return {};
  final response=await ref.watch(apiClientProvider).get('/users/learning-tracks/$id/progress');
  return ApiEnvelope.map(response.data);
});
typedef TrackPracticeKey=({int trackId,int categoryId,int page});
final trackPracticeProvider=FutureProvider.autoDispose.family<Map<String,dynamic>,TrackPracticeKey>((ref,key) async {
  final user=ref.watch(authProvider.select((s)=>s.user));
  if(user?.role!='Student')return {};
  final response=await ref.watch(apiClientProvider).get('/users/learning-tracks/${key.trackId}/categories/${key.categoryId}/problems',queryParameters:{'page':key.page});
  return ApiEnvelope.map(response.data);
});
