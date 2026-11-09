import '../services/auth_api.dart';

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/google_login_button.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<int> onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Web: localhost trỏ về máy tính.
  // Android Emulator: 10.0.2.2 trỏ về máy tính chạy backend.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '575300277989-2hu6jrrb3qh2cl61suk86lqvcaqhgb1s.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSubscription;

  // Chia sẻ Future khởi tạo để tránh gọi initialize nhiều lần.
  static Future<void>? _googleInitialization;

  String _campus = 'HN';
  static const Map<String, String> campuses = {
    'HN': 'Cơ sở Hà Nội',
    'HCM': 'Cơ sở TP. Hồ Chí Minh',
    'DN': 'Cơ sở Đà Nẵng',
    'CT': 'Cơ sở Cần Thơ',
    'QN': 'Cơ sở Quy Nhơn',
  };

  bool _isLoading = false;
  bool _googleReady = false;
  bool _googleStarting = false;
  bool _loginCompleted = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  // ============================================================
  // INITIALIZE GOOGLE SIGN-IN
  // ============================================================

  // Google SDK chỉ chọn tài khoản; backend phải xác thực ID token.
  Future<void> _initializeGoogleSignIn() async {
    try {
      _googleInitialization ??= _googleSignIn.initialize(
        clientId: kIsWeb ? googleClientId : null,
        serverClientId: kIsWeb ? null : googleClientId,
      );
      try {
        await _googleInitialization!;
      } catch (_) {
        _googleInitialization = null;
        rethrow;
      }
      if (!mounted) return;
      _googleSubscription = _googleSignIn.authenticationEvents.listen(
        (event) async {
          if (event is GoogleSignInAuthenticationEventSignIn &&
              !_loginCompleted &&
              mounted) {
            await _completeGoogleAccountLogin(event.user);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('GOOGLE EVENT ERROR: $error');
          _showError('Google Sign-In thất bại: $error');
        },
      );
      if (mounted) setState(() => _googleReady = true);
    } catch (error) {
      _showError('Không thể khởi tạo Google Sign-In: $error');
    }
  }

  // Never use email returned by the client as proof of identity. Backend
  // verifies the signed Google ID token, its audience and verified email.
  Future<void> _completeGoogleAccountLogin(GoogleSignInAccount account) async {
    if (_isLoading || _loginCompleted || !mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const FormatException(
          'Google không trả ID token. Kiểm tra Web Client ID và cấu hình OAuth Android.',
        );
      }
      final student = await AuthApi.googleLogin(idToken);
      await _completeLogin(student);
    } catch (e) {
      _showError('Không thể đăng nhập bằng Google: $e');
    } finally {
      if (mounted && !_loginCompleted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Android/iOS: mở giao diện chọn tài khoản do Google cung cấp.
  // Web: nút Google được render bởi SDK trong google_login_button_web.dart.
  Future<void> _startGoogleSignIn() async {
    if (_isLoading || _loginCompleted || _googleStarting || !_googleReady) {
      return;
    }
    if (kIsWeb) return;
    setState(() {
      _googleStarting = true;
      _errorMessage = null;
    });
    try {
      final account = await _googleSignIn.authenticate();
      if (mounted && !_loginCompleted) {
        await _completeGoogleAccountLogin(account);
      }
    } catch (error) {
      _showError('Không thể đăng nhập Google: $error');
    } finally {
      if (mounted && !_loginCompleted) setState(() => _googleStarting = false);
    }
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  void _showError(String message) {
    if (!mounted || _loginCompleted) return;

    setState(() {
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // SAVE STUDENT INFORMATION
  // ============================================================

  Future<int> _saveStudent(Map<String, dynamic> student) async {
    final rawStudentId = student['StudentID'];

    final int? studentId = rawStudentId is int
        ? rawStudentId
        : int.tryParse(rawStudentId?.toString() ?? '');

    if (studentId == null) {
      throw const FormatException('Backend không trả về StudentID hợp lệ.');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('student_id', studentId);

    await prefs.setString(
      'student_name',
      student['FullName']?.toString() ?? '',
    );

    await prefs.setString(
      'student_code',
      student['StudentCode']?.toString() ?? '',
    );

    await prefs.setString('student_email', student['Email']?.toString() ?? '');

    await prefs.setString('selected_campus', _campus);

    await prefs.setBool('is_logged_in', true);

    debugPrint('LOGIN: Đã lưu studentId=$studentId');

    return studentId;
  }

  // ============================================================
  // COMPLETE LOGIN
  // ============================================================

  Future<void> _completeLogin(Map<String, dynamic> student) async {
    final studentId = await _saveStudent(student);

    if (!mounted) return;

    _loginCompleted = true;

    setState(() {
      _isLoading = false;
      _googleStarting = false;
      _errorMessage = null;
    });

    debugPrint('LOGIN: Chuyển sang trang chủ');

    widget.onLoginSuccess(studentId);
  }

  // Google Web requires the official GIS button rendered by google_sign_in_web.
  // Campus must be picked before that button can be interacted with.
  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _googleStarting || _loginCompleted;
    return Scaffold(
      backgroundColor: const Color(0xFF111C31),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: constraints.maxHeight > 730
                        ? constraints.maxHeight * 0.47
                        : 310,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3D4E67),
                          Color(0xFF655038),
                          Color(0xFF314763),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Image.asset(
                              'lib/assets/fpt_portal_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Nova Student Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Academic Portal',
                            style: TextStyle(
                              color: Color(0xFFDCE2EA),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 640),
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Choose your campus and login method',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 23),
                          const Text(
                            'CAMPUS',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _campus,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            dropdownColor: Colors.white,
                            iconEnabledColor: const Color(0xFF334155),
                            iconDisabledColor: const Color(0xFF64748B),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF334155),
                              ),
                            ),
                            items: campuses.entries
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _campus = value);
                                    }
                                  },
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (busy)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          if (_googleReady)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFD5D9E0),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: GoogleLoginButton(
                                enabled: !busy,
                                onPressed: _startGoogleSignIn,
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          const SizedBox(height: 18),
                          const Text(
                            'Đăng nhập Google • Xác thực qua Spring Boot • Dữ liệu Microsoft Access',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
