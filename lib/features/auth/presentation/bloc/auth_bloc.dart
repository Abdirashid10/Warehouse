import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/validate_session_usecase.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/routes/role_route_helper.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RestoreSessionUseCase restoreSession,
    required ValidateSessionUseCase validateSession,
    required LoginUseCase login,
    required LogoutUseCase logout,
  })  : _restoreSession = restoreSession,
        _validateSession = validateSession,
        _login = login,
        _logout = logout,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthFailureAcknowledged>(_onFailureAcknowledged);
  }

  final RestoreSessionUseCase _restoreSession;
  final ValidateSessionUseCase _validateSession;
  final LoginUseCase _login;
  final LogoutUseCase _logout;

  /// Monotonic counter for async auth operations. A captured value is compared
  /// before each [emit] so a stale async operation (e.g. a queued session check
  /// that finishes after a fresh login) can never override newer auth state.
  int _authOp = 0;

  bool _isStale(int op) => op != _authOp;

  void _emitFailure(
    Emitter<AuthState> emit, {
    required String message,
    String? detail,
  }) {
    AuthDebugLog.blocTransition(
      from: state.status.name,
      to: 'unauthenticated',
      detail: detail ?? message,
    );
    emit(
      AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
        failureDetail: detail ?? message,
        showFailureAlert: true,
      ),
    );
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Never barge into an in-flight sign-in/sign-out. A remounted SplashScreen
    // re-fires AuthCheckRequested; if it runs during login it could clear a
    // valid session and bounce the user back to login.
    if (state.status == AuthStatus.loading &&
        (state.loadingType == AuthLoadingType.login ||
            state.loadingType == AuthLoadingType.logout)) {
      AuthDebugLog.sessionCheckSkipped('during login/logout — ignored');
      return;
    }

    if (state.status == AuthStatus.authenticated && state.user != null) {
      AuthDebugLog.sessionCheckSkipped('already authenticated');
      return;
    }

    final op = ++_authOp;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        loadingType: AuthLoadingType.splash,
        clearError: true,
        showFailureAlert: false,
      ),
    );

    try {
      final cachedUser = await _restoreSession();
      if (_isStale(op)) return;
      if (cachedUser != null) {
        AuthDebugLog.parsedUser(cachedUser);
        final validatedUser = await _validateSession();
        if (_isStale(op)) return;
        if (validatedUser != null) {
          final route = RoleRouteHelper.dashboardPathForRole(validatedUser.role);
          AuthDebugLog.navigationRoute(route, reason: 'splash session restore');
          emit(
            AuthState(
              status: AuthStatus.authenticated,
              user: validatedUser,
            ),
          );
          return;
        }
        _emitFailure(
          emit,
          message: 'Session could not be validated',
          detail:
              'Token was present but GET /profile/me failed or returned invalid data.\n'
              'See console logs (6)–(9). Automatic logout is disabled for debugging.',
        );
        return;
      }
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on ApiException catch (e, st) {
      if (_isStale(op)) return;
      AuthDebugLog.exception('AuthCheckRequested', e, st);
      _emitFailure(
        emit,
        message: ErrorMessageMapper.fromApiException(e),
        detail: 'Splash session check ApiException: ${e.type.name}\n${e.message}',
      );
    } catch (e, st) {
      if (_isStale(op)) return;
      AuthDebugLog.exception('AuthCheckRequested', e, st);
      _emitFailure(
        emit,
        message: 'Session check failed',
        detail: 'Splash session check: $e',
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final op = ++_authOp;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        loadingType: AuthLoadingType.login,
        clearError: true,
        showFailureAlert: false,
      ),
    );

    try {
      final session = await _login(
        email: event.email,
        password: event.password,
      );
      if (_isStale(op)) return;
      final route = RoleRouteHelper.dashboardPathForRole(session.user.role);
      AuthDebugLog.parsedUser(session.user);
      AuthDebugLog.navigationRoute(route, reason: 'login success → emit authenticated');
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
    } on ApiException catch (e, st) {
      if (_isStale(op)) return;
      AuthDebugLog.exception('AuthLoginRequested', e, st);
      final message = e.type == ApiExceptionType.unauthorized
          ? 'Sign-in failed. Check your email and password, then try again.'
          : ErrorMessageMapper.fromApiException(e);
      _emitFailure(
        emit,
        message: message,
        detail:
            'Login ApiException (${e.type.name}): ${e.message}\n'
            'HTTP status: ${e.statusCode ?? "n/a"}',
      );
    } catch (e, st) {
      if (_isStale(op)) return;
      AuthDebugLog.exception('AuthLoginRequested', e, st);
      _emitFailure(
        emit,
        message: 'Something went wrong during sign-in',
        detail: 'Login error: $e',
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final op = ++_authOp;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        loadingType: AuthLoadingType.logout,
        clearError: true,
      ),
    );

    try {
      await _logout();
    } finally {
      if (!_isStale(op)) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    }
  }

  void _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) {
    if (state.status == AuthStatus.loading &&
        state.loadingType == AuthLoadingType.login) {
      AuthDebugLog.sessionCheckSkipped('session expiry ignored during sign-in');
      return;
    }
    _emitFailure(
      emit,
      message: 'Session expired',
      detail:
          'AuthSessionExpired was fired (usually 401 on an API call).\n'
          'If disableAutomaticLogout is true, this should not happen — '
          'check which code path still called notifySessionExpired.',
    );
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true, showFailureAlert: false));
  }

  void _onFailureAcknowledged(
    AuthFailureAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(showFailureAlert: false));
  }
}
