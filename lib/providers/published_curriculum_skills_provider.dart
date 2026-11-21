import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/published_curriculum_skill.dart';
import 'repositories_provider.dart';

/// Public, published-only curriculum metadata is independent of learner
/// entitlement. Free/Premium gates remain enforced for actual questions.
final publishedCurriculumSkillsProvider =
    FutureProvider.autoDispose.family<List<PublishedCurriculumSkill>, int>(
        (ref, stageId) async {
  if (stageId <= 0) throw ArgumentError.value(stageId, 'stageId');
  final response = await ref.watch(apiClientProvider).get(
    '/curriculum/stages/$stageId/skills',
  );
  final raw = response.data;
  if (raw is! List) {
    throw const FormatException('Invalid published curriculum skills payload');
  }
  return raw.map((item) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Malformed curriculum skill item');
    }
    return PublishedCurriculumSkill.fromJson(item);
  }).toList(growable: false);
});
