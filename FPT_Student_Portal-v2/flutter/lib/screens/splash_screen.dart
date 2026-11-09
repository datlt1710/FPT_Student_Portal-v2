import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onFinished,
    this.duration = const Duration(seconds: 4),
  });

  // Thông báo cho main.dart khi loading kết thúc.
  final VoidCallback? onFinished;

  // Thời gian hiển thị loading.
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Timer? _timer;

  static const Color orange = Color(0xFFFF9800);
  static const Color background = Color(0xFF50596B);

  @override
  void initState() {
    super.initState();

    // Thanh tiến trình chạy từ 0 đến 100%.
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    // Loading kết thúc thì báo cho main.dart.
    // main.dart sẽ tự quyết định mở LoginScreen hay HomePage.
    _timer = Timer(widget.duration, () {
      if (!mounted) return;

      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    // Hủy timer và animation khi màn hình bị hủy.
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  // Tạo các mảng màu trang trí.
  Widget _blob({
    required double width,
    required double height,
    required Color color,
    required double radius,
  }) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Nền chính.
              const ColoredBox(color: background),

              // Mảng màu phía trên bên trái.
              Positioned(
                top: -height * 0.08,
                left: -width * 0.20,
                child: _blob(
                  width: width * 0.92,
                  height: height * 0.36,
                  color: const Color(0xFF55402E),
                  radius: 150,
                ),
              ),

              // Mảng màu phía trên.
              Positioned(
                top: height * 0.04,
                left: -width * 0.42,
                child: _blob(
                  width: width * 1.08,
                  height: height * 0.30,
                  color: const Color(0xFF5B606D),
                  radius: 170,
                ),
              ),

              // Mảng màu phía trên bên phải.
              Positioned(
                top: -height * 0.02,
                right: -width * 0.48,
                child: _blob(
                  width: width * 0.72,
                  height: height * 0.34,
                  color: const Color(0xFF4B352B),
                  radius: 180,
                ),
              ),

              // Mảng màu phía dưới bên phải.
              Positioned(
                bottom: -height * 0.12,
                right: -width * 0.40,
                child: _blob(
                  width: width,
                  height: height * 0.46,
                  color: const Color(0xFF4F3C25),
                  radius: 220,
                ),
              ),

              // Mảng màu phía dưới bên trái.
              Positioned(
                bottom: -height * 0.08,
                left: -width * 0.45,
                child: _blob(
                  width: width * 0.78,
                  height: height * 0.32,
                  color: const Color(0xFF4C3B2C),
                  radius: 180,
                ),
              ),

              // Nội dung chính.
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 5),

                    // LOGO.
                    Container(
                      width: (width * 0.235).clamp(112.0, 170.0),
                      height: (width * 0.235).clamp(112.0, 170.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'lib/assets/fpt_portal_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.info_rounded,
                            color: orange,
                            size: 82,
                          );
                        },
                      ),
                    ),

                    SizedBox(height: height * 0.030),

                    // TÊN TRƯỜNG.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'FPT UNIVERSITY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (width * 0.073).clamp(30.0, 58.0),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TIÊU ĐỀ PHỤ.
                    Text(
                      'ACADEMIC PORTAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: orange,
                        fontSize: (width * 0.041).clamp(18.0, 32.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),

                    const Spacer(flex: 5),

                    // THANH TIẾN TRÌNH.
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.075),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              height: 5,
                              child: LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor: Colors.white.withValues(alpha: 0.20),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // PHIÊN BẢN.
                    Text(
                      'Version 2.0.6',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: (width * 0.039).clamp(17.0, 28.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: height * 0.055),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
