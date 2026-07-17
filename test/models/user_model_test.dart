import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/user.dart';

void main() {
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
