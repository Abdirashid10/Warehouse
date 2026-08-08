import 'package:logisticsmobile/core/network/api_response_parser.dart';
import 'package:logisticsmobile/features/auth/data/models/user_model.dart';
import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';

class LoginResponseModel {
  const LoginResponseModel({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final UserModel user;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final token = ApiResponseParser.extractToken(json);
    if (token == null || token.isEmpty) {
      throw const FormatException('Login response missing access token');
    }

    final userJson = ApiResponseParser.extractUser(json);
    if (userJson == null) {
      throw const FormatException('Login response missing user object');
    }

    return LoginResponseModel(
      accessToken: token,
      refreshToken: ApiResponseParser.extractRefreshToken(json),
      user: UserModel.fromJson(userJson),
    );
  }

  AuthSession toEntity() => AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user.toEntity(),
      );
}
