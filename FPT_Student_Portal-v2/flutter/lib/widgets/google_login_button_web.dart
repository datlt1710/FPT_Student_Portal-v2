import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

// Google Web bắt buộc dùng nút do Google Identity Services render.
// Đăng nhập thành công được nhận qua authenticationEvents ở LoginScreen.
class GoogleLoginButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const GoogleLoginButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Center(child: web.renderButton());
  }
}
