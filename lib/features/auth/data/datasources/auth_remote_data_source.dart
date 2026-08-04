import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/api_response_parser.dart';
import 'package:logisticsmobile/core/network/auth_request_extra.dart';
import 'package:logisticsmobile/features/auth/data/models/login_response_model.dart';
import 'package:logisticsmobile/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  String get _loginUrl => '${ApiConfig.baseUrl}${ApiConstants.login}';
  String get _profileUrl => '${ApiConfig.baseUrl}${ApiConstants.profileMe}';

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    AuthDebugLog.loginRequest(url: _loginUrl, email: email);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': email.trim(), 'password': password},
      );
      AuthDebugLog.loginHttpResponse(
        statusCode: response.statusCode,
        body: response.data,
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Empty response from server');
      }

      final token = ApiResponseParser.extractToken(data);
      AuthDebugLog.extractedToken(token);

      final model = LoginResponseModel.fromJson(data);
      AuthDebugLog.parsedUserObject(
        ApiResponseParser.extractUser(data),
      );
      AuthDebugLog.parsedRole(
        roleRaw: model.user.role.name,
        parsed: model.user.role,
      );
      return model;
    } on DioException catch (e) {
      AuthDebugLog.loginHttpResponse(
        statusCode: e.response?.statusCode,
        body: e.response?.data,
      );
      AuthDebugLog.exception('POST /auth/login', e, e.stackTrace);
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    } catch (e, st) {
      AuthDebugLog.exception('POST /auth/login', e, st);
      rethrow;
    }
  }

  Future<void> logout() async {}

  Future<UserModel> fetchCurrentUser() async {
    AuthDebugLog.step('GET /profile/me starting…');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.profileMe,
        options: Options(
          extra: {AuthRequestExtra.skipSessionExpiry: true},
        ),
      );
      final data = response.data;
      AuthDebugLog.profileHttpResponse(
        url: _profileUrl,
        statusCode: response.statusCode,
        body: data,
      );

      if (data == null) {
        throw ApiException.unauthorized('Profile response body was null');
      }
      final userJson = ApiResponseParser.extractUser(data);
      AuthDebugLog.parsedUserObject(userJson);
      if (userJson != null) {
        final roleRaw = userJson['role']?.toString();
        final model = UserModel.fromJson(userJson);
        AuthDebugLog.parsedRole(roleRaw: roleRaw, parsed: model.role);
        AuthDebugLog.parsedUser(model.toEntity());
        return model;
      }
      throw ApiException.unauthorized(
        'Profile response missing user/profile. Keys: ${data.keys}',
      );
    } on DioException catch (e) {
      AuthDebugLog.profileHttpResponse(
        url: _profileUrl,
        statusCode: e.response?.statusCode,
        body: e.response?.data,
      );
      AuthDebugLog.exception('GET /profile/me', e, e.stackTrace);
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    } catch (e, st) {
      AuthDebugLog.exception('GET /profile/me', e, st);
      rethrow;
    }
  }
}
