import 'package:carwash/core/network/api_client.dart';
import 'package:carwash/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'does not reuse cached authorization after token provider signs out',
    () async {
      String? token = 'signed-in-token';
      final headers = <String?>[];
      final client = ApiClient(
        tokenProvider: () async => token,
        httpClient: MockClient((request) async {
          headers.add(request.headers['Authorization']);
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      );
      await client.get('/v1/me');
      token = null;
      await client.get('/v1/me');
      expect(headers, ['Bearer signed-in-token', null]);
    },
  );
  test(
    'rejects HTML success responses from an incorrectly configured API URL',
    () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => http.Response('<html>App</html>', 200),
        ),
      );
      await expectLater(
        client.get('/v1/me'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'PARSE_ERROR'),
        ),
      );
    },
  );
}
