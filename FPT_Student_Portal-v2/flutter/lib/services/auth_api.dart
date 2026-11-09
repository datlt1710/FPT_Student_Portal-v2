import 'api_access.dart';

class AuthApi {
  static Map<String, dynamic> _object(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> currentStudent() async =>
      _object(await ApiAccess.getJson('/api/auth/me'));

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final data = _object(
      await ApiAccess.postJson('/api/auth/google', {'idToken': idToken}),
    );
    if (data['success'] != true || data['student'] is! Map) {
      throw FormatException(
        data['message']?.toString() ?? 'Invalid login response',
      );
    }
    await ApiAccess.saveSession((data['accessToken'] ?? '').toString());
    return Map<String, dynamic>.from(data['student']);
  }

  static Future<Map<String, dynamic>> studentAccount({
    required bool forgotPassword,
    required bool confirm,
    required Map<String, dynamic> body,
  }) async {
    final operation = forgotPassword ? 'forgot' : 'register';
    final step = confirm ? 'confirm' : 'start';
    return _object(
      await ApiAccess.postJson('/api/auth/student/$operation/$step', body),
    );
  }
}
