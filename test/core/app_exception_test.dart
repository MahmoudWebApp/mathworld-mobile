import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/core/errors/app_exception.dart';

void main() {
  test('network exceptions can use cached content', () {
    const exception = AppException(
      type: AppExceptionType.network,
      messageKey: 'network_error',
    );

    expect(exception.canUseCachedData, isTrue);
    expect(exception.isSessionExpired, isFalse);
  });
}
