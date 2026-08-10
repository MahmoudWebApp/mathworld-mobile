import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import 'hive_service.dart';

/// Provides centralized HTTP access and session-expiration events.
class ApiService implements ApiClient {
  static final ApiService _instance = ApiService._internal();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  late final Dio _dio;
  bool _isNotifyingSessionExpiration = false;

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await readToken();
          final languageCode = HiveService.getLanguage();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Requests created after logout must never reuse an old header.
            options.headers.remove('Authorization');
          }

          options.headers['Accept-Language'] = languageCode;
          options.headers['X-Language'] = languageCode;
          handler.next(options);
        },
      ),
    );

    final enableLogs =
        _readEnvironmentValue('ENABLE_HTTP_LOGS')?.toLowerCase() == 'true';
    if (kDebugMode && enableLogs) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('HTTP ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              'HTTP ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              'HTTP ERROR ${error.response?.statusCode} '
              '${error.requestOptions.uri}: ${error.type}',
            );
            handler.next(error);
          },
        ),
      );
    }
  }

  @override
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  @override
  Future<void> saveToken(String token) {
    return _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  @override
  Future<String?> readToken() {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  @override
  Future<void> deleteToken() {
    return _secureStorage.delete(key: AppConstants.tokenKey);
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  }) {
    return _execute(
      () => _dio.get(path, queryParameters: queryParameters),
      handleUnauthorized: handleUnauthorized,
    );
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  }) {
    return _execute(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      handleUnauthorized: handleUnauthorized,
    );
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool handleUnauthorized = true,
  }) {
    return _execute(
      () => _dio.put(path, data: data),
      handleUnauthorized: handleUnauthorized,
    );
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    bool handleUnauthorized = true,
  }) {
    return _execute(
      () => _dio.delete(path),
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<Response<dynamic>> _execute(
    Future<Response<dynamic>> Function() request, {
    required bool handleUnauthorized,
  }) async {
    try {
      return await request();
    } on DioException catch (error) {
      final exception = _mapError(
        error,
        handleUnauthorized: handleUnauthorized,
      );

      if (exception.isSessionExpired && handleUnauthorized) {
        await _notifySessionExpired();
      }

      throw exception;
    }
  }

  AppException _mapError(
    DioException error, {
    required bool handleUnauthorized,
  }) {
    final statusCode = error.response?.statusCode;
    final responseMessage = _extractResponseMessage(error.response?.data);

    switch (statusCode) {
      case 400:
      case 409:
      case 422:
        return AppException(
          type: AppExceptionType.validation,
          messageKey: 'invalid_request',
          statusCode: statusCode,
          serverMessage: responseMessage,
          cause: error,
        );
      case 401:
        return AppException(
          type: AppExceptionType.unauthorized,
          messageKey:
              handleUnauthorized ? 'session_expired' : 'invalid_credentials',
          statusCode: statusCode,
          serverMessage: handleUnauthorized ? null : responseMessage,
          cause: error,
        );
      case 403:
        return AppException(
          type: AppExceptionType.forbidden,
          messageKey: 'access_denied',
          statusCode: statusCode,
          serverMessage: responseMessage,
          cause: error,
        );
      case 404:
        return AppException(
          type: AppExceptionType.notFound,
          messageKey: 'not_found',
          statusCode: statusCode,
          serverMessage: responseMessage,
          cause: error,
        );
      case 429:
        return AppException(
          type: AppExceptionType.validation,
          messageKey: 'too_many_requests',
          statusCode: statusCode,
          serverMessage: responseMessage,
          cause: error,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return AppException(
          type: AppExceptionType.server,
          messageKey: 'server_error',
          statusCode: statusCode,
          serverMessage: responseMessage,
          cause: error,
        );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppException(
          type: AppExceptionType.timeout,
          messageKey: 'connection_timeout',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return AppException(
          type: AppExceptionType.network,
          messageKey: 'network_error',
          cause: error,
        );
      case DioExceptionType.badCertificate:
        return AppException(
          type: AppExceptionType.certificate,
          messageKey: 'certificate_error',
          cause: error,
        );
      case DioExceptionType.cancel:
        return AppException(
          type: AppExceptionType.cancelled,
          messageKey: 'request_cancelled',
          cause: error,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return AppException(
          type: AppExceptionType.unknown,
          messageKey: 'unexpected_error',
          serverMessage: responseMessage,
          cause: error,
        );
    }
  }

  String? _extractResponseMessage(dynamic body) {
    if (body is String) {
      final value = body.trim();
      return value.isEmpty ? null : value;
    }

    if (body is! Map) {
      return null;
    }

    const directKeys = [
      'Message',
      'message',
      'Error',
      'error',
      'Title',
      'title',
    ];

    for (final key in directKeys) {
      final value = body[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final errors = body['Errors'] ?? body['errors'];
    if (errors is List) {
      final messages = errors
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    if (errors is Map) {
      final messages = <String>[];
      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(
            value
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty),
          );
        } else {
          final message = value?.toString().trim() ?? '';
          if (message.isNotEmpty) {
            messages.add(message);
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return null;
  }

  Future<void> _notifySessionExpired() async {
    if (_isNotifyingSessionExpiration) {
      return;
    }

    _isNotifyingSessionExpiration = true;
    await deleteToken();
    _sessionExpiredController.add(null);

    Future<void>.delayed(const Duration(seconds: 1), () {
      _isNotifyingSessionExpiration = false;
    });
  }

  static String? _readEnvironmentValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }
}
