import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_3/services/api_access.dart';

void main() {
  test('Decodes UTF-8 student information', () {
    final response = http.Response.bytes(
      utf8.encode(jsonEncode({'FullName': 'Nguyễn Văn An'})),
      200,
    );
    expect(ApiAccess.decode(response)['FullName'], 'Nguyễn Văn An');
  });

  test('Preserves the backend error message', () {
    final response = http.Response('{"message":"Session expired"}', 401);
    expect(
      () => ApiAccess.decode(response),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Session expired'),
        ),
      ),
    );
  });

  test('Rejects HTML responses instead of supplying fake data', () {
    expect(
      () => ApiAccess.decode(http.Response('<html>Unavailable</html>', 502)),
      throwsFormatException,
    );
  });
}
