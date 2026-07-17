import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/core/utils/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 7, 16, 12);

  test('uses minutes for values under one hour', () {
    final value = relativeTimeValue(
      now.subtract(const Duration(minutes: 8)),
      now: now,
    );

    expect(value.key, 'minutes_ago');
    expect(value.namedArgs['minutes'], '8');
  });

  test('uses an absolute date after one week', () {
    final value = relativeTimeValue(
      now.subtract(const Duration(days: 8)),
      now: now,
    );

    expect(value.key, 'absolute_date');
  });
}
