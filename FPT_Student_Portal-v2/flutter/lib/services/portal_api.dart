import 'api_access.dart';

class PortalApi {
  static Future<Map<String, dynamic>> detail(
    int studentId,
    String section,
    int enrollmentId,
  ) async {
    final data = await ApiAccess.getJson(
      '${_path(studentId, section)}/$enrollmentId',
    );
    if (data is! Map) throw const FormatException('Expected a JSON object');
    return Map<String, dynamic>.from(data);
  }

  static String _path(int studentId, String section) =>
      '/api/students/$studentId/portal/$section';

  static Future<List<Map<String, dynamic>>> list(
    int studentId,
    String section,
  ) async {
    final data = await ApiAccess.getJson(_path(studentId, section));
    if (data is! List || data.any((row) => row is! Map)) {
      throw const FormatException('Expected a JSON list of objects');
    }
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static Future<void> submit(
    int studentId,
    String section,
    Map<String, dynamic> body,
  ) async {
    await ApiAccess.postJson(_path(studentId, section), body);
  }
}
