import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/config/constants.dart';

void main() {
  test('Google server OAuth IDs reject placeholders and malformed strings', () {
    expect(SocialAuthConfig.isValidGoogleClientId(
      '123456789012-exampleclientid.apps.googleusercontent.com'), isTrue);
    expect(SocialAuthConfig.isValidGoogleClientId(
      '123456789012-exampleclientid.apps.googleusercontent.com '), isTrue);
    expect(SocialAuthConfig.isValidGoogleClientId(
      'your-google-client-id.apps.googleusercontent.com'), isFalse);
    expect(SocialAuthConfig.isValidGoogleClientId(''), isFalse);
    expect(SocialAuthConfig.isValidGoogleClientId('not-a-client-id'), isFalse);
    expect(SocialAuthConfig.isValidGoogleClientId(
      '1234567-other.example.com'), isFalse);
  });

  test('Google sign-in is disabled in the default mobile QA build', () {
    // User opt-in and actual OAuth client configuration must be explicit.
    expect(SocialAuthConfig.enabled, isFalse);
    expect(SocialAuthConfig.googleAvailable, isFalse);
  });
}
