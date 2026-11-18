import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/daily_challenge.dart';

void main() {
  test('parses bilingual, server-selected optional daily practice', () {
    final result = DailyChallenge.fromJson({
      'DateUtc': '2026-11-17',
      'StageId': 2,
      'Total': 5,
      'Completed': 1,
      'Problems': [
        {
          'Id': 21, 'CategoryId': 4,
          'TitleAr': 'أوجد س',
          'TitleEn': 'Find x',
          'Points': 10, 'IsSolved': true,
        },
        {
          'Id': 22, 'CategoryId': 4,
          'TitleAr': 'حل المعادلة',
          'TitleEn': 'Solve equation',
          'Points': 10, 'IsSolved': false,
        },
      ],
    });
    expect(result.stageId, 2);
    expect(result.dateUtc, '2026-11-17');
    expect(result.total, 2);
    expect(result.completed, 1);
    expect(result.problems.first.getName('ar'), 'أوجد س');
    expect(result.problems.first.getName('en'), 'Find x');
  });

  test('empty inventory never invents challenge questions or quota', () {
    final result = DailyChallenge.fromJson({
      'StageId': 4, 'DateUtc': '2026-11-17',
      'Total': 5, 'Completed': 5, 'Problems': [],
    });
    expect(result.problems, isEmpty);
    expect(result.total, 0);
    expect(result.completed, 0);
  });

  test('missing solved flag is not interpreted as solved', () {
    final result = DailyChallenge.fromJson({
      'StageId': 1,
      'Problems': [
        {'Id': 7, 'TitleAr': 'اختبار', 'TitleEn': 'Example'},
      ],
    });
    expect(result.problems.single.isSolved, false);
    expect(result.completed, 0);
  });
}
