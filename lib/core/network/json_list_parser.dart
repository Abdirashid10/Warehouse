/// Parses list payloads from Logistics WMS API responses.
abstract final class JsonListParser {
  static List<Map<String, dynamic>> extractMaps(
    dynamic data, {
    List<String> keys = const [
      'tasks',
      'orders',
      'items',
      'movements',
      'warehouses',
      'data',
    ],
  }) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
      }
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return extractMaps(nested, keys: keys);
      }
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  static Map<String, dynamic>? extractMap(
    dynamic data, {
    String nestedKey = 'data',
  }) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('summary') ||
          data.containsKey('widgets') ||
          data.containsKey('user')) {
        return data;
      }
      final nested = data[nestedKey];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return null;
  }
}
