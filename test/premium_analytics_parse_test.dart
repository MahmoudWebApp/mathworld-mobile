import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/services/premium_analytics_service.dart';

void main() {
  Map<String, dynamic> category({bool camel = false}) {
    final values = <String, dynamic>{
      'StageId': 1,
      'CategoryId': 4,
      'StageNameAr': 'المرحلة الأولى',
      'StageNameEn': 'Stage one',
      'CategoryNameAr': 'الجبر',
      'CategoryNameEn': 'Algebra',
      'AttemptedProblems': 8,
      'SolvedProblems': 5,
      'ErrorNotebookProblems': 1,
      'Attempts': 11,
      'CorrectAttempts': 6,
      'IncorrectAttempts': 5,
      'FirstTryCorrect': 3,
      'AwardedPoints': 55,
      'TimeSpentSeconds': 400,
    };
    return camel
        ? values.map((key, value) => MapEntry(
            '${key[0].toLowerCase()}${key.substring(1)}', value))
        : values;
  }

  Map<String, dynamic> report({bool camel = false}) {
    final values = <String, dynamic>{
      'GeneratedAtUtc': '2026-11-15T10:00:00Z',
      'AttemptedProblems': 8,
      'SolvedProblems': 5,
      'Attempts': 11,
      'CorrectAttempts': 6,
      'IncorrectAttempts': 5,
      'FirstTryCorrect': 3,
      'AwardedPoints': 55,
      'TimeSpentSeconds': 400,
      'Categories': [category(camel: camel)],
    };
    return camel
        ? values.map((key, value) => MapEntry(
            '${key[0].toLowerCase()}${key.substring(1)}', value))
        : values;
  }

  test('parses verified report totals and bilingual category names', () {
    final parsed = PremiumAnalyticsReport.fromJson(report());
    expect(parsed.generatedAtUtc.isUtc, isTrue);
    expect(parsed.solvedProblems, 5);
    expect(parsed.attempts, 11);
    expect(parsed.categories.single.categoryNameAr, 'الجبر');
    expect(parsed.categories.single.timeSpentSeconds, 400);
  });

  test('accepts standard camelCase JSON from ASP.NET serializers', () {
    final parsed = PremiumAnalyticsReport.fromJson(report(camel: true));
    expect(parsed.categories.single.stageNameEn, 'Stage one');
    expect(parsed.categories.single.firstTryCorrect, 3);
  });

  test('valid zero-activity Premium report remains possible', () {
    final empty = report();
    for (final name in [
      'AttemptedProblems', 'SolvedProblems', 'Attempts',
      'CorrectAttempts', 'IncorrectAttempts', 'FirstTryCorrect',
      'AwardedPoints', 'TimeSpentSeconds',
    ]) {
      empty[name] = 0;
    }
    empty['Categories'] = [];
    final parsed = PremiumAnalyticsReport.fromJson(empty);
    expect(parsed.categories, isEmpty);
    expect(parsed.solvedProblems, 0);
  });

  test('missing data is not silently replaced with fake zero totals', () {
    final partial = report()..remove('SolvedProblems');
    expect(() => PremiumAnalyticsReport.fromJson(partial),
        throwsA(isA<FormatException>()));
    final withoutCategories = report()..remove('Categories');
    expect(() => PremiumAnalyticsReport.fromJson(withoutCategories),
        throwsA(isA<FormatException>()));
  });

  test('rejects malformed timestamps and negative or fractional totals', () {
    final missingDate = report()..['GeneratedAtUtc'] = '';
    expect(() => PremiumAnalyticsReport.fromJson(missingDate),
        throwsA(isA<FormatException>()));
    final negative = report()..['Attempts'] = -5;
    expect(() => PremiumAnalyticsReport.fromJson(negative),
        throwsA(isA<FormatException>()));
    final fractional = report()..['TimeSpentSeconds'] = 2.5;
    expect(() => PremiumAnalyticsReport.fromJson(fractional),
        throwsA(isA<FormatException>()));
  });

  test('rejects corrupt category records', () {
    final broken = report()..['Categories'] = [3];
    expect(() => PremiumAnalyticsReport.fromJson(broken),
        throwsA(isA<FormatException>()));
    final invalidName = report()..['Categories'] = [
      category()..remove('CategoryNameAr'),
    ];
    expect(() => PremiumAnalyticsReport.fromJson(invalidName),
        throwsA(isA<FormatException>()));
  });
}
