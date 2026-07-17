import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/core/errors/app_exception.dart';
import 'package:mathworld_mobile/core/network/api_envelope.dart';

void main() {
  test('unwraps PascalCase and camelCase response envelopes', () {
    expect(ApiEnvelope.data({'Data': 4}), 4);
    expect(ApiEnvelope.data({'data': 5}), 5);
  });

  test('throws a typed error for an invalid map payload', () {
    expect(
      () => ApiEnvelope.map(const ['invalid']),
      throwsA(isA<AppException>()),
    );
  });
}
