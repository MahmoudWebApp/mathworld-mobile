import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/problem_search.dart';
import 'auth_provider.dart';
import 'repositories_provider.dart';
import 'settings_provider.dart';

final favoritesProvider=FutureProvider.autoDispose.family<ProblemSearchResult,int>((ref,page) async {
  final languageCode=ref.watch(settingsProvider.select((s)=>s.languageCode));
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,plan:s.user?.subscriptionType)));
  if(account.id==null||account.stage==null||account.stage!<=0) {
    return ProblemSearchResult(problems:const [],total:0,page:page,totalPages:0);
  }
  final repo=ref.watch(problemsRepositoryProvider);
  final lease=ref.keepAlive();
  final timer=Timer(const Duration(seconds:30),lease.close);
  ref.onDispose(timer.cancel);
  try{return await repo.getUserProblemPage(favorites:true,languageCode:languageCode,page:page);}
  catch(_){lease.close();rethrow;}
});

final solvedProvider=FutureProvider.autoDispose.family<ProblemSearchResult,int>((ref,page) async {
  final languageCode=ref.watch(settingsProvider.select((s)=>s.languageCode));
  final account=ref.watch(authProvider.select((s)=>(id:s.user?.id,stage:s.user?.currentStageId,plan:s.user?.subscriptionType)));
  if(account.id==null||account.stage==null||account.stage!<=0) {
    return ProblemSearchResult(problems:const [],total:0,page:page,totalPages:0);
  }
  final repo=ref.watch(problemsRepositoryProvider);
  final lease=ref.keepAlive();
  final timer=Timer(const Duration(seconds:30),lease.close);
  ref.onDispose(timer.cancel);
  try{return await repo.getUserProblemPage(favorites:false,languageCode:languageCode,page:page);}
  catch(_){lease.close();rethrow;}
});
