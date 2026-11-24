import 'dart:math';
import '../core/network/api_client.dart';
import '../core/network/api_envelope.dart';
import '../core/errors/app_exception.dart';

String sessionRequestId() {
  final random=Random.secure();
  final bytes=List<int>.generate(16,(_)=>random.nextInt(256));
  bytes[6]=(bytes[6]&15)|64; bytes[8]=(bytes[8]&63)|128;
  final hex=bytes.map((x)=>x.toRadixString(16).padLeft(2,'0')).join();
  return '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
}
int sessionInt(dynamic x)=>x is num?x.toInt():0;
List<Map<String,dynamic>> sessionRows(dynamic x)=>x is List?x.whereType<Map>().map((r)=>Map<String,dynamic>.from(r)).toList():[];
Map<String,dynamic>? sessionMap(dynamic x)=>x is Map?Map<String,dynamic>.from(x):null;
String sessionText(Map<String,dynamic> x,String key)=>x[key]?.toString()??'';
class SessionScope {
  final String kind;
  final int stageId;
  final int? trackId,categoryId;
  const SessionScope({required this.kind,required this.stageId,this.trackId,this.categoryId});
  bool matches(Map<String,dynamic> data)=>data['Kind']==kind&&data['StageId']==stageId&&data['TrackId']==trackId&&data['CategoryId']==categoryId;
}
class LearningSessionApi {
  final ApiClient client;
  const LearningSessionApi(this.client);
  static const root='/users/learning-sessions';
  Future<Map<String,dynamic>?> current(SessionScope scope) async {
    try{
      final response=await client.get('$root/current',queryParameters:{'kind':scope.kind,if(scope.categoryId!=null)'categoryId':scope.categoryId});
      return checked(ApiEnvelope.map(response.data),scope);
    } on AppException catch(e){
      if(e.statusCode==404||e.type==AppExceptionType.notFound)return null;
      rethrow;
    }
  }
  Map<String,dynamic> checked(Map<String,dynamic> data,SessionScope scope){
    if(!scope.matches(data)||sessionText(data,'Id').isEmpty||sessionInt(data['Total'])<5||sessionInt(data['Total'])>10||
       sessionInt(data['Completed'])<0||sessionInt(data['Completed'])>sessionInt(data['Total'])){
      throw const AppException(type:AppExceptionType.invalidResponse,messageKey:'invalid_response');
    }
    return data;
  }
  Future<Map<String,dynamic>> start(SessionScope scope,int count,String requestId) async {
    final response=await client.post('$root/start',data:{'RequestId':requestId,'Kind':scope.kind,'Count':count,if(scope.categoryId!=null)'CategoryId':scope.categoryId});
    return checked(ApiEnvelope.map(response.data),scope);
  }
  Future<Map<String,dynamic>> get(String id,SessionScope scope) async {
    final response=await client.get('$root/$id');
    return checked(ApiEnvelope.map(response.data),scope);
  }
  Future<Map<String,dynamic>> answer(String id,Map<String,dynamic> request) async {
    final response=await client.post('$root/$id/answer',data:request);
    final result=ApiEnvelope.map(response.data);
    if(result['SessionId']!=id||result['RequestId']!=request['RequestId']||result['Position']!=request['Position']||
        result['ProblemId']!=request['ProblemId']||result['IsCorrect'] is! bool){
      throw const AppException(type:AppExceptionType.invalidResponse,messageKey:'invalid_response');
    }
    return result;
  }
  Future<Map<String,dynamic>> hint(String id,int position,int problemId,int level) async {
    final response=await client.post('$root/$id/hints',data:{'Position':position,'ProblemId':problemId,'Level':level});
    return ApiEnvelope.map(response.data);
  }
  Future<Map<String,dynamic>> achievements() async=>ApiEnvelope.map((await client.get('$root/achievements')).data);
  Future<Map<String,dynamic>> previewRestart(int? category) async=>ApiEnvelope.map((await client.get('$root/restart-scope',queryParameters:{if(category!=null)'categoryId':category})).data);
  Future<void> restart(Map<String,dynamic> preview) async {await client.post('$root/restart-scope',data:preview);}
}
