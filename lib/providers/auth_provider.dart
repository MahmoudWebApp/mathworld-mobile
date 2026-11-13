import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/google_identity_service.dart';
import 'categories_provider.dart';
import 'dashboard_provider.dart';
import 'learning_provider.dart';
import 'problem_details_provider.dart';
import 'problems_provider.dart';
import 'repositories_provider.dart';
import 'stages_provider.dart';
import 'user_lists_provider.dart';

/// Describes the current authentication lifecycle.
enum AuthStatus { checking, authenticated, unauthenticated }

/// Stores authentication status, user data, and transient session events.
class AuthState {
  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final AppException? error;
  final bool sessionExpired;

  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.error,
    this.sessionExpired = false,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
    bool? sessionExpired,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref,
    ref.watch(authRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

/// Manages authentication and reacts to centralized 401 session events.
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionSubscription;

  AuthNotifier(
    this._ref,
    this._repository,
    ApiClient apiClient,
  ) : super(const AuthState.checking()) {
    _sessionSubscription = apiClient.sessionExpiredStream.listen((_) {
      _handleExpiredSession();
    });
    initialize();
  }

  Future<void> initialize() async {
    state = const AuthState.checking();
    try {
      final user = await _repository.restoreSession();
      state = AuthState(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
      );
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(
              type: AppExceptionType.unknown,
              messageKey: 'unexpected_error',
              cause: error,
            );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: appError,
      );
    }
  }

  Future<void> login(String email, String password) async {
    _resetAccountScopedState();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      sessionExpired: false,
    );
    try {
      final user = await _repository.login(email, password);
      _resetAccountScopedState();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(
              type: AppExceptionType.unknown,
              messageKey: 'unexpected_error',
              cause: error,
            );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        error: appError,
      );
      throw appError;
    }
  }

  Future<void> loginWithGoogle() async {
    _resetAccountScopedState();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      sessionExpired: false,
    );
    try {
      final googleToken = await GoogleIdentityService.requestIdToken();
      final user = await _repository.googleLogin(googleToken);
      _resetAccountScopedState();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(
              type: AppExceptionType.unknown,
              messageKey: 'social_login_failed',
              cause: error,
            );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        error: appError,
      );
      throw appError;
    }
  }

  Future<void> linkGoogle() async {
    if (!state.isAuthenticated) {
      throw StateError('Sign in to MathWorld before linking Google.');
    }
    final token = await GoogleIdentityService.requestIdToken();
    await _repository.linkGoogle(token);
  }

  Future<void> register(
    String fullName,
    String email,
    String password,
  ) async {
    _resetAccountScopedState();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      sessionExpired: false,
    );
    try {
      final user = await _repository.register(fullName, email, password);
      _resetAccountScopedState();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      final appError = error is AppException
          ? error
          : AppException(
              type: AppExceptionType.unknown,
              messageKey: 'unexpected_error',
              cause: error,
            );
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        error: appError,
      );
      throw appError;
    }
  }

  Future<void> chooseLearningStage(int stageId) async {
    final current = state.user;
    if (current == null) {
      throw StateError('Select a stage after login.');
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _repository.chooseLearningStage(current, stageId);
      state = state.copyWith(user: updated, isSubmitting: false);
      _ref.invalidate(dashboardProvider);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    _resetAccountScopedState();
    await _repository.clearSession();
    _resetAccountScopedState();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _handleExpiredSession() async {
    _resetAccountScopedState();
    await _repository.clearSession();
    _resetAccountScopedState();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      sessionExpired: true,
    );
  }

  /// Drops every provider whose result belongs to the authenticated account.
  ///
  /// Riverpod providers live above the Navigator, so removing routes alone is
  /// not enough when a different user signs in during the same app process.
  void _resetAccountScopedState() {
    _ref.invalidate(stagesProvider);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(stageCategoriesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(solvedProvider);
    _ref.invalidate(problemsProvider);
    _ref.invalidate(problemDetailsProvider);
    _ref.invalidate(problemAttemptHistoryProvider);
    _ref.invalidate(errorNotebookProvider);
  }

  void consumeSessionExpired() {
    if (state.sessionExpired) {
      state = state.copyWith(sessionExpired: false);
    }
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }
}
