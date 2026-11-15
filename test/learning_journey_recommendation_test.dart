import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/learning_journey.dart';

void main() {
  LearningJourneyCategory category(
    int id, {
    bool locked = false,
    int total = 10,
    int solved = 0,
    int attempted = 0,
  }) =>
      LearningJourneyCategory(
        categoryId: id,
        nameAr: 'فئة $id',
        nameEn: 'Category $id',
        totalProblems: total,
        solvedProblems: solved,
        completionPercent: total == 0 ? 0 : 100 * solved ~/ total,
        attemptedProblems: attempted,
        isLocked: locked,
      );

  LearningJourney journey(List<LearningJourneyCategory> categories) =>
      LearningJourney(
        stageId: 1,
        nameAr: 'المرحلة الأولى',
        nameEn: 'Stage one',
        totalProblems: 30,
        attemptedProblems: 5,
        solvedProblems: 2,
        firstTryCorrect: 1,
        masteredProblems: 0,
        totalPoints: 20,
        completionPercent: 7,
        categories: categories,
      );

  test('never recommends a locked Premium category to a Free student', () {
    final result = journey([
      category(9, locked: true),
      category(3, total: 0),
      category(1, solved: 4, attempted: 5),
      category(2, solved: 0),
    ]);
    expect(result.recommendedCategory?.categoryId, 1);
  });

  test('ignores completed categories, then suggests new unlocked inventory', () {
    final result = journey([
      category(1, total: 10, solved: 10, attempted: 10),
      category(2, total: 10, solved: 0),
      category(3, locked: true),
    ]);
    expect(result.recommendedCategory?.categoryId, 2);
  });

  test('returns no recommendation when all available content is locked or done', () {
    expect(journey([category(1, locked: true)]).recommendedCategory, isNull);
    expect(journey([category(1, solved: 10)]).recommendedCategory, isNull);
  });

  test('parses live server IsLocked and attempt counts', () {
    final parsed = LearningJourneyCategory.fromJson({
      'CategoryId': 3,
      'NameAr': 'جبر',
      'NameEn': 'Algebra',
      'TotalProblems': 10,
      'SolvedProblems': 2,
      'AttemptedProblems': 5,
      'FirstTryCorrect': 1,
      'CompletionPercent': 20,
      'IsLocked': true,
    });
    expect(parsed.isLocked, isTrue);
    expect(parsed.attemptedProblems, 5);
    expect(parsed.firstTryCorrect, 1);
  });

  test('missing category lock flag is never treated as unlocked', () {
    final legacy = LearningJourneyCategory.fromJson({
      'CategoryId': 4,
      'NameAr': 'هندسة',
      'NameEn': 'Geometry',
      'TotalProblems': 10,
      'SolvedProblems': 0,
      'CompletionPercent': 0,
      // A deployed older endpoint may omit IsLocked entirely.
    });
    expect(legacy.isLocked, isTrue);
    expect(journey([legacy]).recommendedCategory, isNull);
  });
}
