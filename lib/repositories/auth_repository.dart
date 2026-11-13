import '../config/constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_envelope.dart';
import '../models/user.dart';
import '../core/network/api_client.dart';
import '../services/hive_service.dart';

/// Coordinates authentication, secure token storage, and cached user data.
class AuthRepository {
  final ApiClient _apiService;

  const AuthRepository(this._apiService);

  Future<User?> restoreSession() async {
    final token = await _apiService.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiService.get(ApiConstants.userProfile);
      final user = User.fromJson(ApiEnvelope.map(response.data));
      await HiveService.saveUser(user.toCacheJson());
      return user;
    } on AppException catch (error) {
      if (error.isSessionExpired) {
        await clearSession();
        return null;
      }

      if (error.canUseCachedData) {
        final cached = HiveService.getUser();
        return cached == null ? null : User.fromJson(cached);
      }

      rethrow;
    }
  }

  Future<User> login(String email, String password) async {
    await clearSession();
    final response = await _apiService.post(
      ApiConstants.login,
      data: {'Email': email, 'Password': password},
      handleUnauthorized: false,
    );
    return _parseAndSaveAuthResult(response.data);
  }

  Future<User> register(
    String fullName,
    String email,
    String password,
  ) async {
    await clearSession();
    final response = await _apiService.post(
      ApiConstants.register,
      data: {
        'FullName': fullName,
        'Email': email,
        'Password': password,
      },
      handleUnauthorized: false,
    );
    return _parseAndSaveAuthResult(response.data);
  }

  Future<User> googleLogin(String idToken) async {
    await clearSession();
    final response = await _apiService.post(
      ApiConstants.socialGoogle,
      data: {'Provider': 'Google', 'AccessToken': idToken},
      handleUnauthorized: false,
    );
    return _parseAndSaveAuthResult(response.data);
  }

  Future<void> linkGoogle(String idToken) async {
    final response = await _apiService.post(
      ApiConstants.socialLinkGoogle,
      data: {'Provider': 'Google', 'AccessToken': idToken},
    );
    final data = ApiEnvelope.map(response.data);
    if (data['Linked'] != true && data['linked'] != true) {
      throw const AppException(
        type: AppExceptionType.invalidResponse,
        messageKey: 'invalid_response',
      );
    }
  }

  Future<User> _parseAndSaveAuthResult(dynamic responseData) async {
    try {
      return await _saveAuthResult(
        AuthResult.fromJson(ApiEnvelope.map(responseData)),
      );
    } on FormatException catch (error) {
      throw AppException(
        type: AppExceptionType.invalidResponse,
        messageKey: 'invalid_response',
        cause: error,
      );
    }
  }

  Future<User> _saveAuthResult(AuthResult result) async {
    await _apiService.saveToken(result.token);
    try {
      await HiveService.saveUser(result.user.toCacheJson());
      return result.user;
    } catch (_) {
      await _apiService.deleteToken();
      rethrow;
    }
  }

  Future<User> chooseLearningStage(User user, int stageId) async {
    final response = await _apiService.put(
      ApiConstants.userLearningStage,
      data: {'StageId': stageId},
    );
    final stage = ApiEnvelope.map(response.data);
    final returned = stage['StageId'] ?? stage['stageId'];
    final confirmed = returned is int
        ? returned
        : int.tryParse(returned?.toString() ?? '');
    if (confirmed == null || confirmed != stageId) {
      throw const AppException(
        type: AppExceptionType.invalidResponse,
        messageKey: 'invalid_response',
      );
    }
    final updated = user.copyWith(currentStageId: stageId);
    await HiveService.saveUser(updated.toCacheJson());
    return updated;
  }

  Future<void> clearSession() async {
    await _apiService.deleteToken();
    await HiveService.clearAuth();
    await HiveService.clearCache();
  }
}
