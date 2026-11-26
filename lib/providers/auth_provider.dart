import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/google_identity_service.dart';
import '../services/hive_service.dart';
import 'categories_provider.dart';
import 'daily_challenge_provider.dart';
import 'leaderboard_provider.dart';
import 'dashboard_provider.dart';
import 'learning_provider.dart';
import 'learning_tracks_provider.dart';
import 'learning_journey_provider.dart';
import 'learner_presence_provider.dart';
import 'problem_details_provider.dart';
import 'problems_provider.dart';
import 'notification_provider.dart';
import 'premium_analytics_provider.dart';
import 'premium_reports_provider.dart';
import 'stage_category_access_provider.dart';
import 'student_badges_provider.dart';
import 'social_link_status_provider.dart';
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
class AuthNotifier extends StateNotifier<AuthState>
    with WidgetsBindingObserver {
  final Ref _ref;
  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionSubscription;
  bool _refreshingProfile = false;

  AuthNotifier(
    this._ref,
    this._repository,
    ApiClient apiClient,
  ) : super(const AuthState.checking()) {
    _sessionSubscription = apiClient.sessionExpiredStream.listen((_) {
      _handleExpiredSession();
    });
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> login(String email, String password, {String? captchaToken}) async {
    _resetAccountScopedState();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      sessionExpired: false,
    );
    try {
      final user = await _repository.login(email, password, captchaToken: captchaToken);
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
      final wasCancelled = error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled;
      // A rejected backend login must not pin the next attempt to the
      // previous Google SDK account on a shared phone.
      if (!wasCancelled) {
        await GoogleIdentityService.signOutIfInitialized();
      }
      final appError = error is AppException
          ? error
          : AppException(
              type: wasCancelled
                  ? AppExceptionType.cancelled
                  : AppExceptionType.unknown,
              messageKey: wasCancelled
                  ? 'social_login_cancelled'
                  : 'social_login_failed',
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
    try {
      final token = await GoogleIdentityService.requestIdToken();
      await _repository.linkGoogle(token);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AppException(
          type: AppExceptionType.cancelled,
          messageKey: 'social_login_cancelled',
          cause: error,
        );
      }
      // A rejected identity must not silently remain selected for retries.
      await GoogleIdentityService.signOutIfInitialized();
      rethrow;
    } catch (_) {
      await GoogleIdentityService.signOutIfInitialized();
      rethrow;
    }
  }

  Future<void> register(
    String fullName,
    String email,
    String password,
    int? stageId, {
    String? captchaToken,
  }) async {
    _resetAccountScopedState();
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      sessionExpired: false,
    );
    try {
      final user = await _repository.register(fullName, email, password, stageId, captchaToken: captchaToken);
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

  /// Update the cached subscription only after a confirmed server-side
  /// Premium gift redemption. The backend remains the source of truth.
  Future<void> confirmPremiumGiftRedeemed() async {
    final current = state.user;
    if (current == null || !state.isAuthenticated) return;
    final updated = current.copyWith(subscriptionType: 'Premium');
    state = state.copyWith(user: updated);
    try {
      await HiveService.saveUser(updated.toCacheJson());
    } catch (_) {
      // The authenticated backend grant already succeeded; a local cache
      // write failure must not incorrectly report redemption as failed.
    }
  }

  /// Refresh account entitlements and stage after an Admin change or gift.
  /// Network failures keep the last known authenticated session.
  Future<void> refreshProfile() async {
    if (_refreshingProfile || !state.isAuthenticated) return;
    final previous = state.user;
    if (previous == null) return;
    _refreshingProfile = true;
    try {
      final latest = await _repository.restoreSession();
      if (!mounted || !state.isAuthenticated || state.user?.id != previous.id) {
        return;
      }
      if (latest == null) return;
      final changed = latest.subscriptionType != previous.subscriptionType ||
          latest.currentStageId != previous.currentStageId;
      state = state.copyWith(user: latest);
      if (changed) {
        _ref.invalidate(categoriesProvider);
        _ref.invalidate(stageCategoriesProvider);
        _ref.invalidate(stageCategoryAccessProvider);
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(learningJourneyProvider);
        _ref.invalidate(problemsProvider);
        _ref.invalidate(problemDetailsProvider);
        _ref.invalidate(premiumAnalyticsProvider);
        _ref.invalidate(filteredPremiumAnalyticsProvider);
        _ref.invalidate(premiumProgressReportProvider);
      }
    } catch (_) {
      // Do not end a valid session because a background refresh failed.
    } finally {
      _refreshingProfile = false;
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
      // Stage changes affect far more than the summary dashboard. Clearing
      // all stage-specific state prevents the old stage's free topics,
      // challenge, statistics and problems showing up under the new stage.
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(stageCategoriesProvider);
      _ref.invalidate(stageCategoryAccessProvider);
      _ref.invalidate(dashboardProvider);
      _ref.invalidate(learningJourneyProvider);
      _ref.invalidate(dailyChallengeProvider);
      _ref.invalidate(leaderboardProvider);
      _ref.invalidate(studentBadgesProvider);
      _ref.invalidate(problemsProvider);
      _ref.invalidate(problemDetailsProvider);
      _ref.invalidate(problemAttemptHistoryProvider);
      _ref.invalidate(errorNotebookProvider);
      _ref.invalidate(favoritesProvider);
      _ref.invalidate(solvedProvider);
      _ref.invalidate(premiumAnalyticsProvider);
        _ref.invalidate(filteredPremiumAnalyticsProvider);
        _ref.invalidate(premiumProgressReportProvider);
      _ref.invalidate(learnerPresenceServiceProvider);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<void> changePassword(String current, String password, String confirmation) async {
    if (!state.isAuthenticated) throw StateError('Sign in before changing a password.');
    final actorId = state.user?.id;
    await _repository.changePassword(current, password, confirmation);
    // The server already revoked the old token. Do not send an explicit
    // sign-out using it, and do not clear a different account after a race.
    if (!mounted || state.user?.id != actorId) return;
    _resetAccountScopedState();
    try {
      await _repository.clearSession();
      await GoogleIdentityService.signOutIfInitialized();
    } finally {
      if (mounted) {
        _resetAccountScopedState();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> logout() async {
    // Only explicit logout is logged; session expiry/device termination
    // must never be labelled as a confirmed sign-out.
    await _repository.recordExplicitSignOut();
    try {
      await _ref.read(learnerPresenceServiceProvider)
          .close().timeout(const Duration(milliseconds: 1000));
    } catch (_) {
      // A network failure cannot prevent account logout.
    }
    _resetAccountScopedState();
    await _repository.clearSession();
    await GoogleIdentityService.signOutIfInitialized();
    _resetAccountScopedState();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _handleExpiredSession() async {
    _resetAccountScopedState();
    await _repository.clearSession();
    // Expired MathWorld JWTs also clear the optional Google SDK account.
    // On shared devices, a fresh login must not inherit that SDK selection.
    await GoogleIdentityService.signOutIfInitialized();
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
    _ref.invalidate(trackSelectionProvider);
    _ref.invalidate(trackProgressProvider);
    _ref.invalidate(trackPracticeProvider);
    _ref.invalidate(stagesProvider);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(stageCategoriesProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(learningJourneyProvider);
    _ref.invalidate(dailyChallengeProvider);
    _ref.invalidate(leaderboardProvider);
    _ref.invalidate(learnerPresenceServiceProvider);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(solvedProvider);
    _ref.invalidate(problemsProvider);
    _ref.invalidate(problemDetailsProvider);
    _ref.invalidate(problemAttemptHistoryProvider);
    _ref.invalidate(errorNotebookProvider);
    // Account-isolated API caches must not show the previous user's
    // subscription, notifications, private reports or achievements.
    _ref.invalidate(studentPremiumProvider);
    _ref.invalidate(stageCategoryAccessProvider);
    _ref.invalidate(notificationInboxProvider);
    _ref.invalidate(premiumAnalyticsProvider);
        _ref.invalidate(filteredPremiumAnalyticsProvider);
        _ref.invalidate(premiumProgressReportProvider);
    _ref.invalidate(studentBadgesProvider);
    _ref.invalidate(googleLinkedProvider);
  }

  void consumeSessionExpired() {
    if (state.sessionExpired) {
      state = state.copyWith(sessionExpired: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription.cancel();
    super.dispose();
  }
}
