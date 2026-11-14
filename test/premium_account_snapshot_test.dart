import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/user.dart';

void main() {
  test('verified Premium gift updates only local subscription snapshot', () {
    const user = User(
      id: 42,
      fullName: 'Test Student',
      email: 'student@example.invalid',
      role: 'Student',
      subscriptionType: 'Free',
      currentStageId: 3,
    );
    final updated = user.copyWith(subscriptionType: 'Premium');
    expect(updated.id, user.id);
    expect(updated.role, 'Student');
    expect(updated.subscriptionType, 'Premium');
    expect(updated.currentStageId, 3);
    expect(user.subscriptionType, 'Free');
    expect(updated.toCacheJson()['SubscriptionType'], 'Premium');
  });

  test('stage switching does not reset current Premium entitlement', () {
    const user = User(
      id: 42,
      fullName: 'Test Student',
      email: 'student@example.invalid',
      role: 'Student',
      subscriptionType: 'Premium',
      currentStageId: 1,
    );
    final updated = user.copyWith(currentStageId: 2);
    expect(updated.subscriptionType, 'Premium');
    expect(updated.currentStageId, 2);
  });
}
