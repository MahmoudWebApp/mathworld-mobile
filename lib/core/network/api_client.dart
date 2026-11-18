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

  /// Returns raw bytes using the authenticated client (JWT and 401 handling).
  /// Must not attempt UTF-8/JSON decoding of XLSX/PDF ZIP or binary files.
  Future<List<int>> getBinary(
    String path, {
    Map<String, dynamic>? queryParameters,
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
