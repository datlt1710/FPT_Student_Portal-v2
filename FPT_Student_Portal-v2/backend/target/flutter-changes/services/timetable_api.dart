import 'api_config.dart';

import 'api_access.dart';

import '../models/timetable_item.dart';

class TimetableApi {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<TimetableItem>> fetchTimetable({
    required int studentId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await fetchRows(studentId: studentId, start: start, end: end);
    return rows.map(TimetableItem.fromJson).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchRows({
    required int studentId,
    required DateTime start,
    required DateTime end,
    String? semester,
  }) async {
    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    final decoded = await ApiAccess.getJson(
      '/api/students/$studentId/timetable',
      query: {'start': startDate, 'end': endDate,
        if (semester != null && semester.isNotEmpty) 'semester': semester},
    );
    if (decoded is! List || decoded.any((row) => row is! Map)) {
      throw const FormatException('Invalid timetable response');
    }
    return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
