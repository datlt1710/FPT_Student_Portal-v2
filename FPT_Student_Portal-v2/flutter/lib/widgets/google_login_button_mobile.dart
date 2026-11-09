
import 'package:flutter/material.dart';

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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(
          Icons.account_circle_outlined,
          color: Color(0xFF4285F4),
          size: 24,
        ),
        label: const Text(
          'Đăng nhập bằng Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          disabledForegroundColor: const Color(0xFF94A3B8),
          side: const BorderSide(
            color: Color(0xFFCBD5E1),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
