import 'package:flutter/material.dart';

import 'app.dart';

export 'app.dart' show NovaStudentApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaStudentApp());
}
