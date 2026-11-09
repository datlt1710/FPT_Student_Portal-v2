import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_3/services/semester_api.dart';
import 'package:flutter_application_3/screens/timetable_screen.dart';
import 'package:flutter_application_3/screens/semester_schedule_screen.dart';

List<Map<String, dynamic>> semesterFixture() {
  final year = DateTime.now().year;
  return [
    {
      'SemesterID': 90,
      'SemesterCode': 'CURRENT-CUSTOM',
      'SemesterName': 'Current academic term',
      'StartDate': '$year-01-01',
      'EndDate': '$year-12-31',
    },
    {
      'SemesterID': 77,
      'SemesterCode': 'ARCHIVED-TERM',
      'SemesterName': 'Archived academic term',
      'StartDate': '2020-01-01',
      'EndDate': '2020-04-30',
      'FirstSessionDate': '2020-01-13',
    },
  ];
}

void main() {
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'access_token': 'test-token'}),
  );

  test('Opening an old semester uses its actual first class instead of the current month', () {
    final term = AcademicSemester.fromJson(semesterFixture()[1]);
    expect(term.openingDate(DateTime.now()), DateTime(2020, 1, 13));
    final noClasses = AcademicSemester.fromJson({
      ...semesterFixture()[1],
      'FirstSessionDate': null,
    });
    expect(noClasses.openingDate(DateTime.now()), DateTime(2020, 1, 1));
    expect(
      SemesterApi.initial(
        semesterFixture().map(AcademicSemester.fromJson).toList(),
        DateTime.now(),
      ).id,
      90,
    );
  });

  testWidgets(
    'Weekly timetable loads semester metadata and changes week when switching term',
    (tester) async {
      final requests = <Uri>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: TimetableScreen(studentId: 7)),
          );
          await tester.pumpAndSettle();
          expect(find.text('CURRENT-CUSTOM'), findsOneWidget);
          expect(find.text('FALL2026'), findsNothing);
          await tester.tap(find.text('ARCHIVED-TERM'));
          await tester.pumpAndSettle();
          final request = requests.last;
          expect(request.queryParameters['semester'], '77');
          expect(request.queryParameters['start'], '2020-01-13');
          expect(request.queryParameters['end'], '2020-01-19');
          expect(find.text('Archived Course'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          requests.add(request.url);
          if (request.url.path.endsWith('/semesters')) {
            return http.Response(jsonEncode(semesterFixture()), 200);
          }
          return http.Response(
            jsonEncode(
              request.url.queryParameters['semester'] == '77'
                  ? [
                      {
                        'sessionDate': '2020-01-13',
                        'subjectName': 'Archived Course',
                        'subjectCode': 'ARC101',
                        'startTime': '07:30',
                        'endTime': '09:50',
                        'slotNumber': 1,
                        'attendanceStatus': 'Present',
                      },
                    ]
                  : [],
            ),
            200,
          );
        }),
      );
    },
  );

  testWidgets(
    'Monthly schedule uses semester id and opens the month of its first class',
    (tester) async {
      final requests = <Uri>[];
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(home: SemesterScheduleScreen(studentId: 7)),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('ARCHIVED-TERM'));
          await tester.pumpAndSettle();
          expect(requests.last.queryParameters['semester'], '77');
          expect(requests.last.queryParameters['start'], '2020-01-01');
          expect(requests.last.queryParameters['end'], '2020-01-31');
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/semesters') ? semesterFixture() : [],
            ),
            200,
          );
        }),
      );
    },
  );
}
