import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/problem.dart';
import '../repositories/problems_repository.dart';
import 'auth_provider.dart';
import 'learning_tracks_provider.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

/// At most one authorized, unanswered successor, held in memory for 20 seconds.
/// Never retain solved content, credentials or a revealed solution. A cache miss
/// or scope mismatch falls through to the normal authorized detail request.
class ProblemPrefetch {
  final ProblemsRepository repository;
  final int? stageId;
  final int trackId;
  final String language;
  final bool enabled;
  ProblemPrefetch(this.repository,{required this.stageId,required this.trackId,
    required this.language,required this.enabled});
  int? _id;
  int? _categoryId;
  Future<Problem?>? _pending;
  Timer? _expiry;
  DateTime? _started;

  void clear(){
    _expiry?.cancel();_expiry=null;_pending=null;_id=null;_categoryId=null;_started=null;
  }

  void warm(int id,int categoryId,int requestedTrackId){
    if(!enabled||trackId<=0||requestedTrackId!=trackId||id<=0||categoryId<=0)return;
    if(_id==id&&_categoryId==categoryId&&_pending!=null)return;
    clear();
    _id=id;_categoryId=categoryId;_started=DateTime.now();
    _pending=_fetch(id,categoryId);
    _expiry=Timer(const Duration(seconds:20),clear);
  }

  Future<Problem?> _fetch(int id,int categoryId) async {
    try{
      final p=await repository.getProblem(id,language);
      if(p.id!=id||p.categoryId!=categoryId||p.stageId!=stageId||
          p.practiceScopeId!=trackId||p.isSolved||p.hasAttempted||
          p.correctOptionId!=null||p.detailedSolution?.isNotEmpty==true||
          p.solutionStructure!=null)return null;
      return p;
    }catch(_){return null;}
  }

  Future<Problem?> take(int id) async {
    if(!enabled||_id!=id||_started==null||DateTime.now().difference(_started!)>=const Duration(seconds:20))return null;
    final pending=_pending;
    final started=_started!;
    clear();
    final p=await pending;
    return DateTime.now().difference(started)<const Duration(seconds:20)?p:null;
  }
}

final problemPrefetchProvider=Provider.autoDispose<ProblemPrefetch>((ref){
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,
    role:s.user?.role,tier:s.user?.subscriptionType,status:s.status)));
  final track=ref.watch(trackSelectionProvider.select((s)=>trackNumber(s.valueOrNull?['TrackId'])));
  final language=ref.watch(settingsProvider.select((s)=>s.languageCode));
  final cache=ProblemPrefetch(ref.watch(problemsRepositoryProvider),stageId:account.stage,
    trackId:track,language:language,enabled:account.id!=null&&account.role=='Student');
  final lease=ref.keepAlive();
  Timer? idle;
  ref.onCancel(()=>idle=Timer(const Duration(seconds:20),lease.close));
  ref.onResume(()=>idle?.cancel());
  ref.onDispose((){idle?.cancel();cache.clear();});
  return cache;
});
