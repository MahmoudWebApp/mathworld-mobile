import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/category_access/stage_category_access.dart';
import 'repositories_provider.dart';

/// Uses the same authenticated ApiService as the rest of the application.
final stageCategoryAccessProvider =
    FutureProvider.family<StageCategoryAccess, int>((ref, stageId) async {
  final response = await ref.watch(apiClientProvider).get(
    '/stages/$stageId/free-categories',
  );
  final raw = response.data;
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('Invalid stage access response');
  }
  final data = raw['Data'] ?? raw['data'] ?? raw;
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Invalid stage access data');
  }
  return StageCategoryAccess.fromJson(data);
});

final studentPremiumProvider = FutureProvider<bool>((ref) async {
  final response = await ref.watch(apiClientProvider).get('/users/subscription');
  final raw = response.data;
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('Invalid subscription response');
  }
  final data = raw['Data'] ?? raw['data'] ?? raw;
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Invalid subscription data');
  }
  return data['IsPremium'] == true || data['isPremium'] == true;
});
