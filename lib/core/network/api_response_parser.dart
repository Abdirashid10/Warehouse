/// Normalizes common Logistics WMS API envelope shapes.
abstract final class ApiResponseParser {
  /// Unwraps `{ data: ... }`, `{ result: ... }`, or returns [json] as-is.
  static Map<String, dynamic> unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    final result = json['result'];
    if (result is Map<String, dynamic>) return result;
    return json;
  }

  /// Extracts a user object from login/profile payloads.
  ///
  /// Login: `{ token, user }`. Profile: `{ profile, permissions, ... }`.
  static Map<String, dynamic>? extractUser(Map<String, dynamic> json) {
    final root = unwrap(json);
    for (final key in ['user', 'profile']) {
      final value = root[key];
      if (value is Map<String, dynamic>) return value;
    }
    if (root.containsKey('email') && root.containsKey('role')) {
      return root;
    }
    final nested = root['data'];
    if (nested is Map<String, dynamic>) {
      for (final key in ['user', 'profile']) {
        final value = nested[key];
        if (value is Map<String, dynamic>) return value;
      }
    }
    return null;
  }

  /// Extracts JWT from login payloads.
  static String? extractToken(Map<String, dynamic> json) {
    final root = unwrap(json);
    for (final key in ['token', 'accessToken', 'access_token', 'jwt']) {
      final value = root[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static String? extractRefreshToken(Map<String, dynamic> json) {
    final root = unwrap(json);
    for (final key in ['refreshToken', 'refresh_token']) {
      final value = root[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
