import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String configured = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/+$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8086'; // Android emulator
    }
    return 'http://localhost:8086';
  }
}
