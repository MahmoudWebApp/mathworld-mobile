import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/config/constants.dart';

void main() {
  test('recovery always opens the official HTTPS website', () {
    for (final language in ['ar', 'en', 'https://evil.example', '../']) {
      final uri = AppConstants.passwordRecoveryUrl(language);
      expect(uri.scheme, 'https');
      expect(uri.host, 'math-world-frontend.vercel.app');
      expect(uri.path, '/${language == 'en' ? 'en' : 'ar'}/forgot-password');
      expect(uri.hasQuery, isFalse);
      expect(uri.hasFragment, isFalse);
    }
  });
}
