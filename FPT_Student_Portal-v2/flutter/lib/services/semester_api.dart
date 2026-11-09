import 'portal_api.dart';

class AcademicSemester {
  const AcademicSemester({
    required this.id,
    required this.code,
    required this.name,
    required this.start,
    required this.end,
    this.firstSession,
  });
  final int id;
  final String code, name;
  final DateTime start, end;
  final DateTime? firstSession;

  factory AcademicSemester.fromJson(Map<String, dynamic> row) {
    DateTime date(dynamic value) {
      final parsed = DateTime.parse('$value');
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final start = date(row['StartDate']);
    final end = date(row['EndDate']);
    if (end.isBefore(start)) {
      throw const FormatException('Ngày kết thúc kỳ trước ngày bắt đầu');
    }
    return AcademicSemester(
      id: (row['SemesterID'] as num).toInt(),
      code: '${row['SemesterCode']}',
      name: '${row['SemesterName']}',
      start: start,
      end: end,
      firstSession: row['FirstSessionDate'] == null
          ? null
          : date(row['FirstSessionDate']),
    );
  }

  bool contains(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  DateTime openingDate(DateTime now) {
    if (contains(now)) return DateTime(now.year, now.month, now.day);
    return firstSession != null && contains(firstSession!)
        ? firstSession!
        : start;
  }
}

class SemesterApi {
  static Future<List<AcademicSemester>> list(int studentId) async =>
      (await PortalApi.list(
        studentId,
        'semesters',
      )).map(AcademicSemester.fromJson).toList();

  static AcademicSemester initial(List<AcademicSemester> terms, DateTime now) =>
      terms.firstWhere((term) => term.contains(now), orElse: () => terms.first);
}
