import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/config/api_config.dart';

void main() {
  test('default base URL targets the on-premises API', () {
    expect(ApiConfig.baseUrl, 'http://172.16.0.44:8000/api');
    expect(ApiConfig.environmentLabel, 'lan');
    expect(ApiConfig.resolvedHost, '172.16.0.44');
    expect(ApiConfig.isCleartext, isTrue);
  });

  test('login path composes to the mounted Express route', () {
    expect('${ApiConfig.baseUrl}/auth/login',
        'http://172.16.0.44:8000/api/auth/login');
  });
}
