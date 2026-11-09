import '../services/auth_api.dart';

import 'package:flutter/material.dart';

/// Self-service student signup and email-based password recovery.
class StudentAccountScreen extends StatefulWidget {
  final bool forgotPassword;
  const StudentAccountScreen({super.key, this.forgotPassword = false});
  @override
  State<StudentAccountScreen> createState() => _StudentAccountScreenState();
}

class _StudentAccountScreenState extends State<StudentAccountScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final studentCode = TextEditingController();
  final fullName = TextEditingController();
  final verificationCode = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool codeSent = false;
  bool loading = false;
  String? message;
  bool obscure = true;
  static const background = Color(0xFF0B1426);
  static const surface = Color(0xFF1D2A40);
  static const accent = Color(0xFFFFA000);

  @override
  void dispose() {
    email.dispose();
    studentCode.dispose();
    fullName.dispose();
    verificationCode.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() {
      loading = true;
      message = null;
    });
    final Map<String, dynamic> body = {'email': email.text.trim()};
    if (codeSent) {
      body['code'] = verificationCode.text.trim();
      body['password'] = password.text;
    } else if (!widget.forgotPassword) {
      body['studentCode'] = studentCode.text.trim();
      body['fullName'] = fullName.text.trim();
    }
    try {
      final data = await AuthApi.studentAccount(
        forgotPassword: widget.forgotPassword,
        confirm: codeSent,
        body: body,
      );
      if (!mounted) return;
      if (codeSent) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${data['message']}')));
        Navigator.of(context).pop();
      } else {
        setState(() {
          codeSent = true;
          message = '${data['message']}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => message = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration decor(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: accent),
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
  );
  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool hidden = false,
    String? Function(String?)? validate,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      obscureText: hidden && obscure,
      keyboardType: controller == email
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator:
          validate ??
          (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $label' : null,
      decoration: decor(label, icon).copyWith(
        suffixIcon: hidden
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
              )
            : null,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final title = widget.forgotPassword ? 'Quên mật khẩu' : 'Đăng ký sinh viên';
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: background,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    widget.forgotPassword ? Icons.lock_reset : Icons.school,
                    size: 58,
                    color: accent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    codeSent ? 'Nhập mã xác minh' : title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    codeSent
                        ? 'Nhập mã 6 số nhận qua email và tạo mật khẩu mới.'
                        : widget.forgotPassword
                        ? 'Nhận mã xác minh để đặt lại mật khẩu.'
                        : 'Tạo tài khoản mới. Hệ thống tự lưu hồ sơ sau khi xác minh email.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  field(
                    email,
                    'Email sinh viên',
                    Icons.email_outlined,
                    validate: (v) =>
                        v == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())
                        ? 'Email không hợp lệ'
                        : null,
                  ),
                  if (!codeSent && !widget.forgotPassword) ...[
                    field(fullName, 'Họ và tên', Icons.person_outline),
                    field(studentCode, 'Mã sinh viên', Icons.badge_outlined),
                  ],
                  if (codeSent) ...[
                    field(
                      verificationCode,
                      'Mã xác minh 6 số',
                      Icons.pin_outlined,
                      validate: (v) =>
                          v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())
                          ? 'Nhập 6 chữ số'
                          : null,
                    ),
                    field(
                      password,
                      'Mật khẩu mới',
                      Icons.lock_outline,
                      hidden: true,
                      validate: (v) =>
                          v == null ||
                              v.length < 8 ||
                              !RegExp(r'[A-Za-z]').hasMatch(v) ||
                              !RegExp(r'\d').hasMatch(v)
                          ? 'Tối thiểu 8 ký tự, gồm chữ và số'
                          : null,
                    ),
                    field(
                      confirmation,
                      'Nhập lại mật khẩu',
                      Icons.lock_reset,
                      hidden: true,
                      validate: (v) =>
                          v != password.text ? 'Mật khẩu chưa khớp' : null,
                    ),
                  ],
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        message!,
                        style: const TextStyle(color: Colors.amberAccent),
                      ),
                    ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: background,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              codeSent ? 'XÁC NHẬN' : 'GỬI MÃ XÁC MINH',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (codeSent)
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                              codeSent = false;
                              message = null;
                            }),
                      child: const Text(
                        'Gửi mã mới',
                        style: TextStyle(color: accent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
