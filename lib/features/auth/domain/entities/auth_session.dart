import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final User user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
