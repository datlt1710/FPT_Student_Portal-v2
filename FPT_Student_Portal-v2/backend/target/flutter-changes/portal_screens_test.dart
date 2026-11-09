import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_3/screens/nova_extra_screens.dart';
import 'package:flutter_application_3/screens/portal_detail_screen.dart';
import 'package:flutter_application_3/screens/exam_schedule_view.dart';

void main() {
  testWidgets('Not passed is red in course list and mark details', (tester) async {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
    final course = {'EnrollmentID': 14, 'SubjectCode': 'DBI202', 'SubjectName': 'Database Systems',
      'ClassName': 'SE1941', 'Semester': 'Fall 2026', 'AverageMark': 4.0, 'GradeStatus': 'NOT PASSED',
      'Assessments': [{'AssessmentName': 'Final exam', 'Score': 4.0, 'Weight': 1.0}]};
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: NovaExtraScreen(page: 'Mark Report', studentId: 7)));
      await tester.pumpAndSettle();
      expect(find.text('NOT PASSED'), findsOneWidget);
      await tester.tap(find.text('DBI202'));
      await tester.pumpAndSettle();
      expect(find.text('Not passed'), findsNWidgets(2));
      final status = tester.widget<Text>(find.text('Not passed').first);
      expect(status.style?.color, Colors.redAccent);
      expect(find.text('Average: 4.0'), findsOneWidget);
      expect(find.text('Final exam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async => http.Response(
      jsonEncode(request.url.path.endsWith('/14') ? course : [course]), 200)));
  });

  testWidgets('Past exams use gray cards and Đã thi badges; upcoming stays green', (tester) async {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ExamScheduleView(studentId: 7))));
      await tester.pumpAndSettle();
      expect(find.text('Đã thi'), findsOneWidget);
      expect(find.text('Sắp tới'), findsOneWidget);
      final date = tester.widget<Text>(find.text('Date: 28/10/2026'));
      expect(date.style?.color, portalMuted);
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.any((c) => c.decoration is BoxDecoration &&
        (c.decoration as BoxDecoration).color == const Color(0xFF334155)), isTrue);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response(jsonEncode([
      {'Semester': 'Fall 2026', 'SubjectCode': 'KOR411', 'ExamDate': '2026-10-28', 'ExamTime': '07:30', 'Room': 'DE-C208', 'ExamType': 'ME', 'ExamStatus': 'PAST'},
      {'Semester': 'Fall 2026', 'SubjectCode': 'SWP391', 'ExamDate': '2026-11-16', 'ExamTime': '12:50', 'Room': 'DE-C309', 'ExamType': 'FE', 'ExamStatus': 'UPCOMING'},
    ]), 200)));
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'access_token': 'test-token'}),
  );

  testWidgets('Tapping a course fetches authenticated mark details', (
    tester,
  ) async {
    final calls = <String>[];
    final course = {
      'EnrollmentID': 12,
      'SubjectCode': 'PRM392',
      'SubjectName': 'Mobile Programming',
      'ClassName': 'SE1941',
      'Semester': 'Fall 2026',
      'AverageMark': 7.5,
      'GradeStatus': 'PASSED',
      'Assessments': [
        {'AssessmentName': 'Project', 'Weight': 1.0, 'Score': 7.5},
      ],
    };
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NovaExtraScreen(page: 'Mark Report', studentId: 7),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('PRM392'));
        await tester.pumpAndSettle();
        expect(find.text('Mark Details'), findsOneWidget);
        expect(find.text('Project'), findsOneWidget);
        expect(calls, contains('/api/students/7/portal/marks/12'));
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        calls.add(request.url.path);
        return http.Response(
          jsonEncode(request.url.path.endsWith('/12') ? course : [course]),
          200,
        );
      }),
    );
  });

  testWidgets(
    'Attendance keeps missing records separate from absence on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            const MaterialApp(
              home: PortalDetailScreen(
                studentId: 7,
                enrollmentId: 12,
                section: 'attendance',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Attended: 0/1'), findsOneWidget);
          expect(find.text('Chưa ghi nhận'), findsNWidgets(2));
          expect(find.text('09:00–11:00'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'SubjectCode': 'KOR321',
              'SubjectName': 'Intermediate Korean Language 2',
              'ClassCode': 'SE1941',
              'TotalSessions': 1,
              'Attended': 0,
              'Absent': 0,
              'Future': 0,
              'Unrecorded': 1,
              'Sessions': [
                {
                  'SessionDate': '2026-11-08',
                  'StartTime': '09:00',
                  'EndTime': '11:00',
                  'Room': 'A101',
                  'AttendanceStatus': 'Unrecorded',
                },
              ],
            }),
            200,
          ),
        ),
      );
    },
  );

  testWidgets('Exams filter real semesters and count the visible rows', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ExamScheduleView(studentId: 7)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Number of exams: 2'), findsOneWidget);
        await tester.tap(find.text('FALL2026'));
        await tester.pumpAndSettle();
        expect(find.text('Number of exams: 1'), findsOneWidget);
        expect(find.textContaining('PRM392'), findsOneWidget);
        expect(find.textContaining('DBI202'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'Semester': 'Fall 2026',
              'SubjectCode': 'PRM392',
              'ExamDate': '2026-12-10',
              'ExamTime': '09:00',
              'ExamStatus': 'UPCOMING',
            },
            {
              'Semester': 'Summer 2026',
              'SubjectCode': 'DBI202',
              'ExamDate': '2026-07-01',
              'ExamTime': '07:30',
              'ExamStatus': 'PAST',
            },
          ]),
          200,
        ),
      ),
    );
  });

  testWidgets('Exam error can retry and show an empty response', (
    tester,
  ) async {
    var attempt = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ExamScheduleView(studentId: 7)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Không tải được lịch thi'), findsOneWidget);
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có lịch thi'), findsOneWidget);
      },
      () => MockClient(
        (_) async => ++attempt == 1
            ? http.Response('{"message":"Unavailable"}', 503)
            : http.Response('[]', 200),
      ),
    );
  });
}
