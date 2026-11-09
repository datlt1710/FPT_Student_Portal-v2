import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_access.dart';
import 'services/auth_api.dart';
import 'settings/app_settings.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class NovaStudentApp extends StatefulWidget {
  const NovaStudentApp({super.key});

  @override
  State<NovaStudentApp> createState() => _NovaStudentAppState();
}

class _NovaStudentAppState extends State<NovaStudentApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _endingSession = false;
  bool settingsLoaded = false;
  bool authChecked = false;
  bool splashCompleted = false;

  bool isDarkMode = true;
  bool isLoggedIn = false;

  int? loggedInStudentId;

  @override
  void initState() {
    super.initState();
    ApiAccess.sessionExpired.addListener(_handleSessionExpired);
    _loadSettings();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    ApiAccess.sessionExpired.removeListener(_handleSessionExpired);
    super.dispose();
  }

  Future<void> _handleSessionExpired() async {
    if (_endingSession || !mounted) return;
    _endingSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'access_token',
        'is_logged_in',
        'student_id',
        'student_name',
        'student_code',
        'student_email',
      ]) {
        await prefs.remove(key);
      }
      if (!mounted) return;
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      setState(() {
        isLoggedIn = false;
        loggedInStudentId = null;
        authChecked = true;
      });
    } finally {
      _endingSession = false;
    }
  }

  // ----------------------------------------------------------
  // LOAD SETTINGS
  // ----------------------------------------------------------

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedDarkMode = prefs.getBool('dark_mode') ?? true;
      final savedNotifications = prefs.getBool('push_notifications') ?? true;

      darkModeNotifier.value = savedDarkMode;
      notificationsNotifier.value = savedNotifications;

      if (!mounted) return;

      setState(() {
        isDarkMode = savedDarkMode;
        settingsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');

      if (!mounted) return;

      setState(() {
        settingsLoaded = true;
      });
    }
  }

  // ----------------------------------------------------------
  // CHECK LOGIN STATUS
  // ----------------------------------------------------------

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedLoginStatus = prefs.getBool('is_logged_in') ?? false;
      final savedStudentId = prefs.getInt('student_id');

      final hasSession =
          savedLoginStatus &&
          savedStudentId != null &&
          (prefs.getString('access_token')?.isNotEmpty ?? false);
      final student = hasSession ? await AuthApi.currentStudent() : null;

      if (!mounted) return;

      setState(() {
        loggedInStudentId = int.tryParse('${student?['StudentID'] ?? ''}');
        isLoggedIn = loggedInStudentId != null;
        authChecked = true;
      });
    } catch (e) {
      debugPrint('Error checking login status: $e');

      if (!mounted) return;

      setState(() {
        isLoggedIn = false;
        loggedInStudentId = null;
        authChecked = true;
      });
    }
  }

  // ----------------------------------------------------------
  // CHANGE DARK MODE
  // ----------------------------------------------------------

  Future<void> _changeDarkMode(bool value) async {
    if (!mounted) return;

    setState(() {
      isDarkMode = value;
    });

    darkModeNotifier.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', value);
    } catch (e) {
      debugPrint('Error saving dark mode: $e');
    }
  }

  // ----------------------------------------------------------
  // CHANGE NOTIFICATIONS
  // ----------------------------------------------------------

  Future<void> _changeNotifications(bool value) async {
    notificationsNotifier.value = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', value);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  // ----------------------------------------------------------
  // OPEN HOME AFTER LOGIN
  // Không sử dụng Navigator ở đây.
  // MaterialApp sẽ tự đổi màn hình dựa trên trạng thái.
  // ----------------------------------------------------------

  void _openHome(int studentId) {
    if (!mounted) return;

    debugPrint('APP: Nhận đăng nhập studentId=$studentId');

    setState(() {
      isLoggedIn = true;
      loggedInStudentId = studentId;
      authChecked = true;
    });
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await ApiAccess.clearSession();
      await prefs.remove('is_logged_in');
      await prefs.remove('student_id');
      await prefs.remove('student_name');
      await prefs.remove('student_code');
      await prefs.remove('student_email');
    } catch (e) {
      debugPrint('Error clearing login data: $e');
    }

    if (!mounted) return;

    setState(() {
      isLoggedIn = false;
      loggedInStudentId = null;
    });
  }

  // ----------------------------------------------------------
  // FINISH SPLASH SCREEN
  // ----------------------------------------------------------

  void _finishSplash() {
    if (!mounted || splashCompleted) return;

    setState(() {
      splashCompleted = true;
    });
  }

  // ----------------------------------------------------------
  // BUILD APPLICATION
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Nova Student Portal',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeColor,
          brightness: Brightness.light,
        ),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: headerColor,
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.grey,
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeColor,
          brightness: Brightness.dark,
        ),
        cardColor: darkCard,
        appBarTheme: const AppBarTheme(
          backgroundColor: headerColor,
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.grey,
          ),
        ),
      ),

      // Hiện splash trong lúc khởi động và kiểm tra trạng thái đăng nhập.
      // Chỉ chuyển màn hình khi splash đã kết thúc và dữ liệu đã sẵn sàng.
      home: !splashCompleted || !settingsLoaded || !authChecked
          ? SplashScreen(onFinished: _finishSplash)
          : isLoggedIn && loggedInStudentId != null
          ? HomePage(
              key: const ValueKey('home'),
              studentId: loggedInStudentId!,
              onDarkModeChanged: _changeDarkMode,
              onNotificationsChanged: _changeNotifications,
              onLogout: _logout,
            )
          : LoginScreen(
              key: const ValueKey('login'),
              onLoginSuccess: _openHome,
            ),
    );
  }
}
