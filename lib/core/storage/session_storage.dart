import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logisticsmobile/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure persistence for JWT and session metadata (flutter_secure_storage).
abstract class SessionStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> saveUserRole(String role);
  Future<String?> getUserRole();
  Future<void> saveUserJson(String json);
  Future<String?> getUserJson();
  Future<void> clearSession();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _secure;

  /// In-memory cache so the token is available immediately after login
  /// (avoids secure-storage read lag before the next API call).
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  static bool _migrated = false;

  /// One-time migration from legacy SharedPreferences token keys.
  static Future<SecureSessionStorage> create() async {
    final storage = SecureSessionStorage();
    await storage._migrateFromSharedPreferencesIfNeeded();
    return storage;
  }

  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    if (_migrated) return;
    _migrated = true;
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(StorageKeys.accessToken);
    if (access == null || access.isEmpty) return;

    final existing = await _secure.read(key: StorageKeys.accessToken);
    if (existing != null && existing.isNotEmpty) return;

    await saveAccessToken(access);
    final refresh = prefs.getString(StorageKeys.refreshToken);
    if (refresh != null) await saveRefreshToken(refresh);
    final userJson = prefs.getString(StorageKeys.userJson);
    if (userJson != null) await saveUserJson(userJson);
    final role = prefs.getString(StorageKeys.userRole);
    if (role != null) await saveUserRole(role);

    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.refreshToken);
    await prefs.remove(StorageKeys.userJson);
    await prefs.remove(StorageKeys.userRole);
  }

  Future<String?> _read(String key) => _secure.read(key: key);

  Future<void> _write(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<void> _delete(String key) => _secure.delete(key: key);

  @override
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    final stored = await _read(StorageKeys.accessToken);
    _cachedAccessToken = stored;
    return stored;
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }
    final stored = await _read(StorageKeys.refreshToken);
    _cachedRefreshToken = stored;
    return stored;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    await _write(StorageKeys.accessToken, token);
    if (kDebugMode) {
      debugPrint(
        'Auth: access token saved (${token.length} chars, '
        'prefix: ${_tokenPreview(token)})',
      );
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _write(StorageKeys.refreshToken, token);
  }

  static String _tokenPreview(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}…';
  }

  @override
  Future<void> saveUserRole(String role) => _write(StorageKeys.userRole, role);

  @override
  Future<String?> getUserRole() => _read(StorageKeys.userRole);

  @override
  Future<void> saveUserJson(String json) => _write(StorageKeys.userJson, json);

  @override
  Future<String?> getUserJson() => _read(StorageKeys.userJson);

  @override
  Future<void> clearSession() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    await _delete(StorageKeys.accessToken);
    await _delete(StorageKeys.refreshToken);
    await _delete(StorageKeys.userJson);
    await _delete(StorageKeys.userRole);
    if (kDebugMode) {
      debugPrint('Auth: session cleared');
    }
  }
}
