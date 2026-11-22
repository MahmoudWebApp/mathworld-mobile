import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/user.dart';

void main() {
  test('missing user role never defaults to Student', () {
    final unknown = User.fromJson({
      'Id': 2, 'FullName': 'No role', 'Email': 'unknown@example.com',
      'SubscriptionType': 'Free',
    });
    expect(unknown.role, isNot('Student'));
    final profile = UserProfile.fromJson({
      'Id': 3, 'FullName': 'No role', 'Email': 'unknown@example.com',
    });
    expect(profile.role, isNot('Student'));
  });

  test('administrator role survives API parsing for web-only gate', () {
    final admin = AuthResult.fromJson({
      'Id': 4, 'FullName': 'Operator', 'Email': 'operator@example.com',
      'Role': 'Admin', 'SubscriptionType': 'Free', 'Token': 'test-token',
    });
    expect(admin.user.role, 'Admin');
  });

  test('cached user data never contains the authentication token', () {
    final result = AuthResult.fromJson({
      'Id': 1,
      'FullName': 'Student',
      'Email': 'student@example.com',
      'Role': 'Student',
      'SubscriptionType': 'Free',
      'Token': 'secret-token',
    });

    final cached = result.user.toCacheJson();

    expect(result.token, 'secret-token');
    expect(cached.containsKey('Token'), isFalse);
    expect(cached.containsKey('token'), isFalse);
  });
}
