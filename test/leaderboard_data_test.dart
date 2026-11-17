import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/leaderboard.dart';

void main() {
  test('a single ranked student is a real leaderboard result', () {
    final report = LeaderboardData.fromJson({
      'StageId': 1,
      'NameAr': 'المرحلة الأولى',
      'NameEn': 'Stage One',
      'Period': 'all',
      'Page': 1,
      'PageSize': 20,
      'TotalLearners': 1,
      'MyRank': 1,
      'Entries': [
        {
          'Rank': 1,
          'DisplayName': 'You',
          'SolvedProblems': 1,
          'Points': 10,
          'FirstTryCorrect': 1,
          'IsCurrentUser': true,
        },
      ],
    });

    expect(report.stageId, 1);
    expect(report.totalLearners, 1);
    expect(report.myRank, 1);
    expect(report.entries, hasLength(1));
    expect(report.entries.single.rank, 1);
    expect(report.entries.single.isCurrentUser, isTrue);
    expect(report.entries.single.solvedProblems, 1);
    expect(report.entries.single.points, 10);
    expect(report.entries.single.firstTryCorrect, 1);
  });

  test('no solved attempts means no invented personal rank', () {
    final report = LeaderboardData.fromJson({
      'stageId': 2,
      'nameAr': 'المرحلة الثانية',
      'nameEn': 'Stage Two',
      'period': 'weekly',
      'page': 1,
      'pageSize': 20,
      'totalLearners': 0,
      'entries': <Map<String, Object>>[],
    });

    expect(report.stageId, 2);
    expect(report.period, 'weekly');
    expect(report.myRank, isNull);
    expect(report.totalLearners, 0);
    expect(report.entries, isEmpty);
  });
}
