import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
}

enum AuthLoadingType {
  splash,
  login,
  logout,
  session,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.failureDetail,
    this.loadingType,
    this.showFailureAlert = false,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? failureDetail;
  final AuthLoadingType? loadingType;
  final bool showFailureAlert;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? failureDetail,
    AuthLoadingType? loadingType,
    bool? showFailureAlert,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failureDetail: clearError ? null : (failureDetail ?? this.failureDetail),
      loadingType: loadingType ?? this.loadingType,
      showFailureAlert: showFailureAlert ?? this.showFailureAlert,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, errorMessage, failureDetail, loadingType, showFailureAlert];
}
