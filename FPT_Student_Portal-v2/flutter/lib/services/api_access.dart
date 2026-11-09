import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Single HTTP gateway. Never silently return mock data on network failures.
class ApiAccess {
  static final sessionExpired = ValueNotifier<int>(0);
  static Uri uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Future<Map<String, String>> headers({bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async =>
      http.get(url, headers: {...await ApiAccess.headers(), ...?headers});

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async => http.post(
    url,
    headers: {...await ApiAccess.headers(json: true), ...?headers},
    body: body,
  );

  static dynamic decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw FormatException(
        'Invalid API response (HTTP ${response.statusCode})',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['message'] ?? data['detail'] ?? data['error'])
          : null;
      throw Exception(message ?? 'HTTP ${response.statusCode}');
    }
    return data;
  }

  static Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await get(uri(path).replace(queryParameters: query))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) sessionExpired.value++;
    return decode(response);
  }

  static Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await post(
      uri(path),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 && !path.startsWith('/api/auth/')) {
      sessionExpired.value++;
    }
    return decode(response);
  }

  static Future<void> saveSession(String token) async {
    if (token.isEmpty) {
      throw const FormatException('Thiếu accessToken trong API đăng nhập');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      try {
        await http
            .post(
              uri('/api/auth/logout'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        /* Still sign out locally if offline. */
      }
    }
    await prefs.remove('access_token');
  }
}
