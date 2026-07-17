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
}
