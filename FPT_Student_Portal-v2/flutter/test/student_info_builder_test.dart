import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_3/widgets/student_info_builder.dart';

void main() {
  testWidgets('Retry reloads student after failure without setState error', (
    tester,
  ) async {
    final first = Completer<Map<String, dynamic>>();
    final retry = Completer<Map<String, dynamic>>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentInfoBuilder(
            loadStudent: () => ++calls == 1 ? first.future : retry.future,
            builder: (_, student) => Text(student['FullName'] as String),
          ),
        ),
      ),
    );
    first.completeError(Exception('Temporary failure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cannot load student. Retry'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(calls, 2);
    retry.complete({'FullName': 'Student from API'});
    await tester.pumpAndSettle();
    expect(find.text('Student from API'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
