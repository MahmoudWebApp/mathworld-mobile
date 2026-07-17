/// Defines the high-level error categories used throughout the application.
enum AppExceptionType {
  validation,
  unauthorized,
  forbidden,
  notFound,
  network,
  timeout,
  certificate,
  cancelled,
  server,
  invalidResponse,
  unknown,
}

/// Represents a typed application error that can be localized in the UI.
class AppException implements Exception {
  final AppExceptionType type;
  final String messageKey;
  final int? statusCode;
  final String? serverMessage;
  final Object? cause;

  const AppException({
    required this.type,
    required this.messageKey,
    this.statusCode,
    this.serverMessage,
    this.cause,
  });

  bool get isSessionExpired =>
      type == AppExceptionType.unauthorized && messageKey == 'session_expired';

  bool get canUseCachedData {
    return type == AppExceptionType.network ||
        type == AppExceptionType.timeout ||
        type == AppExceptionType.server;
  }

  @override
  String toString() => serverMessage?.trim().isNotEmpty == true
      ? serverMessage!.trim()
      : messageKey;
}
