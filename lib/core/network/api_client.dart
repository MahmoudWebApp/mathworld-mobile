import 'package:dio/dio.dart';

/// Defines the network operations required by repositories.
abstract interface class ApiClient {
  Stream<void> get sessionExpiredStream;

  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> deleteToken();

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  });

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool handleUnauthorized = true,
  });

  Future<Response<dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool handleUnauthorized = true,
  });

  Future<Response<dynamic>> delete(
    String path, {
    bool handleUnauthorized = true,
  });
}
