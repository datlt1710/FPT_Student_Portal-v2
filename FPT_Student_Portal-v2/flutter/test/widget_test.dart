import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/screens/splash_screen.dart';

void main() {
  testWidgets('App shows splash while starting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NovaStudentApp());
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Dispose the startup timer and animation before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
