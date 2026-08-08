import 'package:logisticsmobile/core/auth/auth_debug_log.dart';
import 'package:logisticsmobile/core/storage/session_storage.dart';
import 'package:logisticsmobile/features/auth/data/models/user_model.dart';
import 'package:logisticsmobile/features/auth/domain/entities/auth_session.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<void> saveSession(AuthSession session) async {
    await _sessionStorage.saveAccessToken(session.accessToken);
    if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
      await _sessionStorage.saveRefreshToken(session.refreshToken!);
    }
    await _sessionStorage.saveUserRole(session.user.role.name);
    final userModel = UserModel(
      id: session.user.id,
      fullName: session.user.fullName,
      email: session.user.email,
      role: session.user.role,
      warehouse: session.user.warehouse,
      permissions: session.user.permissions,
    );
    await _sessionStorage.saveUserJson(userModel.toJsonString());

    final readBack = await _sessionStorage.getAccessToken();
    final ok = readBack != null &&
        readBack.isNotEmpty &&
        readBack == session.accessToken;
    AuthDebugLog.tokenSaveResult(
      success: ok,
      detail: ok
          ? 'read-back matches (${readBack.length} chars)'
          : 'read-back mismatch or empty',
    );
  }

  Future<UserModel?> getCachedUser() async {
    final json = await _sessionStorage.getUserJson();
    if (json == null || json.isEmpty) return null;
    try {
      return UserModel.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAccessToken() => _sessionStorage.getAccessToken();

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() => _sessionStorage.clearSession();
}
