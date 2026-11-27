import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/problem.dart';
import 'package:mathworld_mobile/providers/problem_prefetch_provider.dart';
import 'package:mathworld_mobile/repositories/problems_repository.dart';

class _Repository implements ProblemsRepository {
  int requests=0;
  Problem? response;
  final Completer<void> gate=Completer<void>();
  @override
  Future<Problem> getProblem(int problemId,String languageCode)async{
    requests++;
    await gate.future;
    return response!;
  }
  @override
  dynamic noSuchMethod(Invocation invocation)=>super.noSuchMethod(invocation);
}
Problem fixture({int scope=4,bool solved=false})=>Problem(
  id:9,practiceScopeId:scope,title:'Title',questionText:'1+1',
  stageId:2,stageName:'Stage',categoryId:5,categoryName:'Numbers',
  points:10,isSolved:solved,hasAttempted:solved,isFavorite:false,viewsCount:0,
  options:const []);
void main(){
  test('a pending successor is fetched once and consumed once',()async{
    final repo=_Repository()..response=fixture();
    final cache=ProblemPrefetch(repo,stageId:2,trackId:4,language:'en',enabled:true);
    addTearDown(cache.clear);
    cache.warm(9,5,4);
    cache.warm(9,5,4);
    final pending=cache.take(9);
    repo.gate.complete();
    expect((await pending)?.id,9);
    expect(repo.requests,1);
    expect(await cache.take(9),isNull);
  });
  test('reject wrong scope, solved content and disabled accounts',()async{
    for(final p in [fixture(scope:7),fixture(solved:true)]){
      final repo=_Repository()..response=p;
      final cache=ProblemPrefetch(repo,stageId:2,trackId:4,language:'ar',enabled:true);
      cache.warm(9,5,7);
      expect(repo.requests,0);
      cache.warm(9,5,4);
      repo.gate.complete();
      expect(await cache.take(9),isNull);
      cache.clear();
    }
    final repo=_Repository();
    final cache=ProblemPrefetch(repo,stageId:2,trackId:4,language:'en',enabled:false);
    cache.warm(9,5,4);
    expect(repo.requests,0);
    expect(await cache.take(9),isNull);
    cache.clear();
  });
}
