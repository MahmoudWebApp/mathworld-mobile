import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/stage_daily_quota.dart';

void main() {
  test('Free quota is stage-specific and exhausted at 10', () {
    final data = StageDailyQuota.fromJson({
      'StageId': 2,
      'NameAr': 'المرحلة الإعدادية',
      'NameEn': 'Middle School',
      'Limit': 10,
      'Used': 10,
      'Remaining': 0,
      'Unlimited': false,
      'SubscriptionType': 'Free',
      'DayUtc': '2026-11-13T00:00:00Z',
      'ResetsAtUtc': '2026-11-14T00:00:00Z',
    });
    expect(data.stageId, 2);
    expect(data.stageName('ar'), 'المرحلة الإعدادية');
    expect(data.stageName('en'), 'Middle School');
    expect(data.exhausted, isTrue);
    expect(data.remaining, 0);
    expect(data.resetsAtUtc!.isUtc, isTrue);
  });

  test('Premium may omit null Remaining when backend suppresses null JSON', () {
    final premium = StageDailyQuota.fromJson({
      'stageId': 1,
      'limit': 10,
      'used': 15,
      'unlimited': true,
      'subscriptionType': 'Premium',
    });
    expect(premium.unlimited, isTrue);
    expect(premium.remaining, isNull);
    expect(premium.exhausted, isFalse);
  });

  test('Free quota keeps remaining slots independent of stage ID', () {
    final stageOne = StageDailyQuota.fromJson({
      'StageId': 1, 'Used': 9, 'Limit': 10,
      'Remaining': 1, 'Unlimited': false,
    });
    final stageTwo = StageDailyQuota.fromJson({
      'StageId': 2, 'Used': 0, 'Limit': 10,
      'Remaining': 10, 'Unlimited': false,
    });
    expect(stageOne.exhausted, isFalse);
    expect(stageOne.remaining, 1);
    expect(stageTwo.remaining, 10);
  });
}
