import '../errors/app_exception.dart';

/// Extracts payloads from wrapped and unwrapped API responses.
class ApiEnvelope {
  const ApiEnvelope._();

  static dynamic data(dynamic body) {
    if (body is Map) {
      if (body.containsKey('Data')) {
        return body['Data'];
      }
      if (body.containsKey('data')) {
        return body['data'];
      }
    }
    return body;
  }

  static Map<String, dynamic> map(dynamic body) {
    final value = data(body);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const AppException(
      type: AppExceptionType.invalidResponse,
      messageKey: 'invalid_response',
    );
  }

  static List<dynamic> list(dynamic body) {
    final value = data(body);
    if (value is List) {
      return List<dynamic>.from(value);
    }
    throw const AppException(
      type: AppExceptionType.invalidResponse,
      messageKey: 'invalid_response',
    );
  }
}
