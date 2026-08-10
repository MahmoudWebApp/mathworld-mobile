import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/problem.dart';

void main() {
  test('problem selects requested localized fields without correctness data',
      () {
    final problem = Problem.fromJson(
      {
        'Id': 7,
        'TitleAr': 'عنوان عربي',
        'TitleEn': 'English title',
        'QuestionTextAr': 'سؤال',
        'QuestionTextEn': 'Question',
        'StageNameAr': 'مرحلة',
        'StageNameEn': 'Stage',
        'CategoryNameAr': 'جبر',
        'CategoryNameEn': 'Algebra',
        'Options': [
          {'Id': 1, 'LatexCode': r'$x=2$', 'Order': 1, 'IsCorrect': true},
        ],
      },
      languageCode: 'en',
    );

    expect(problem.title, 'English title');
    expect(problem.questionText, 'Question');
    expect(problem.options.single.latexCode, r'$x=2$');
  });

  test('answer result supports correct option ID metadata', () {
    final result = AnswerResult.fromJson({
      'IsCorrect': false,
      'SelectedOptionId': 2,
      'CorrectOptionId': 3,
      'PointsEarned': 0,
      'DetailedSolution': 'Solution',
    });

    expect(result.isCorrect, isFalse);
    expect(result.selectedOptionId, 2);
    expect(result.correctOptionId, 3);
  });

  test('answer result supports correct option text metadata', () {
    final result = AnswerResult.fromJson({
      'IsCorrect': false,
      'PointsEarned': 0,
      'CorrectOptionText': r'$x=3$',
      'DetailedSolution': 'Solution',
    });

    expect(result.correctOptionId, isNull);
    expect(result.correctOptionText, r'$x=3$');
  });

  test('problem restores the previous answer state from the API', () {
    final problem = Problem.fromJson({
      'Id': 9,
      'Title': 'Problem',
      'QuestionText': 'Question',
      'StageId': 1,
      'StageName': 'Stage',
      'CategoryId': 2,
      'CategoryName': 'Category',
      'HasAttempted': true,
      'WasCorrect': false,
      'SelectedOptionId': 12,
      'CorrectOptionId': 14,
      'Options': [
        {'Id': 12, 'LatexCode': '2', 'Order': 1},
        {'Id': 14, 'LatexCode': '4', 'Order': 2},
      ],
    });

    expect(problem.hasAttempted, isTrue);
    expect(problem.wasCorrect, isFalse);
    expect(problem.selectedOptionId, 12);
    expect(problem.correctOptionId, 14);
  });

  test('problem parses retry, timing, mastery, and error notebook metadata',
      () {
    final problem = Problem.fromJson({
      'Id': 10,
      'Title': 'Problem',
      'QuestionText': 'Question',
      'StageId': 1,
      'StageName': 'Stage',
      'CategoryId': 2,
      'CategoryName': 'Category',
      'HasAttempted': true,
      'AttemptCount': 3,
      'FirstAttemptCorrect': false,
      'CanRetry': true,
      'MasteryStatus': 'Practicing',
      'BestTimeSeconds': 11,
      'AverageTimeSeconds': 19,
      'IsInErrorNotebook': true,
      'NextReviewAt': '2026-07-21T00:00:00Z',
      'Options': const [],
    });

    expect(problem.attemptCount, 3);
    expect(problem.canRetry, isTrue);
    expect(problem.masteryStatus, 'Practicing');
    expect(problem.bestTimeSeconds, 11);
    expect(problem.averageTimeSeconds, 19);
    expect(problem.isInErrorNotebook, isTrue);
    expect(problem.nextReviewAt, isNotNull);
  });

  test('answer result parses complete attempt metadata', () {
    final result = AnswerResult.fromJson({
      'IsCorrect': true,
      'IsSolved': true,
      'SelectedOptionId': 2,
      'PointsEarned': 10,
      'DetailedSolution': 'Solution',
      'AttemptId': 99,
      'AttemptNumber': 3,
      'IsOfficialAttempt': false,
      'FirstAttemptCorrect': false,
      'AttemptTimeSeconds': 15,
      'BestTimeSeconds': 11,
      'TotalAttempts': 3,
      'CanRetry': true,
      'MasteryStatus': 'Practicing',
      'IsInErrorNotebook': true,
      'NextReviewAt': '2026-07-21T00:00:00Z',
    });

    expect(result.attemptId, 99);
    expect(result.attemptNumber, 3);
    expect(result.isOfficialAttempt, isFalse);
    expect(result.attemptTimeSeconds, 15);
    expect(result.totalAttempts, 3);
    expect(result.canRetry, isTrue);
  });
}
