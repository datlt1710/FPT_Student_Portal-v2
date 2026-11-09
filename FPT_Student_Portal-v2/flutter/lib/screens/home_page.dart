import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../models/card_data.dart';
import '../widgets/home/student_header.dart';
import '../widgets/home/service_menu_card.dart';
import '../widgets/home/home_bottom_navigation.dart';
import 'profile_screen.dart';
import 'timetable_screen.dart';
import 'semester_schedule_screen.dart';
import 'nova_extra_screens.dart';

class HomePage extends StatefulWidget {
  final int studentId;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.studentId,
    required this.onDarkModeChanged,
    required this.onNotificationsChanged,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, child) {
        final background = isDarkMode ? darkBackground : lightBackground;
        final cardColor = isDarkMode ? darkCard : Colors.white;
        final textColor = isDarkMode ? darkText : lightText;

        final pages = <Widget>[
          _buildHomePage(cardColor, textColor),
          _buildChatPage(textColor, isDarkMode),
          ProfileScreen(
            onDarkModeChanged: widget.onDarkModeChanged,
            onNotificationsChanged: widget.onNotificationsChanged,
            onLogout: _confirmLogout,
          ),
        ];

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: currentIndex, children: pages),
          ),
          bottomNavigationBar: HomeBottomNavigation(
            currentIndex: currentIndex,
            isDarkMode: isDarkMode,
            onSelectTab: _selectBottomTab,
          ),
        );
      },
    );
  }

  // HOME CONTENT

  Widget _buildHomePage(Color cardColor, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final horizontalPadding = width <= 320
            ? 10.0
            : width <= 360
            ? 13.0
            : width <= 600
            ? 16.0
            : width <= 900
            ? 28.0
            : 40.0;

        return Column(
          children: [
            StudentHeader(
              onLogout: _confirmLogout,
              onNotificationsTap: () => _openMenu(
                const CardData(
                  title: 'Notification',
                  icon: Icons.notifications,
                  iconColor: Color(0xFFFF9800),
                  iconBackground: Color(0xFFFFF2DE),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'NOTIFICATION AND APPLICATION STATUS',
                          textColor,
                        ),
                        const SizedBox(height: 16),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Notification',
                            icon: Icons.notifications,
                            iconColor: Color(0xFFFF9800),
                            iconBackground: Color(0xFFFFF2DE),
                          ),
                          right: const CardData(
                            title: 'Application status',
                            icon: Icons.contact_page,
                            iconColor: Color(0xFF2676C5),
                            iconBackground: Color(0xFFE6F0FF),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _sectionTitle('INFORMATION ACCESS', textColor),
                        const SizedBox(height: 16),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Weekly timetable',
                            icon: Icons.calendar_month,
                            iconColor: Color(0xFF13A8E5),
                            iconBackground: Color(0xFFE0F3FF),
                          ),
                          right: const CardData(
                            title: 'Exam schedule',
                            icon: Icons.article,
                            iconColor: Color(0xFFE84C4C),
                            iconBackground: Color(0xFFFFE3E3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Semester Schedule',
                            icon: Icons.calendar_month,
                            iconColor: Color(0xFF8D5CF5),
                            iconBackground: Color(0xFFF0E9FF),
                          ),
                          right: null,
                        ),
                        const SizedBox(height: 30),
                        _sectionTitle('REPORTS', textColor),
                        const SizedBox(height: 16),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Attendance report',
                            icon: Icons.playlist_add_check,
                            iconColor: Color(0xFF10B981),
                            iconBackground: Color(0xFFD8F8E9),
                          ),
                          right: const CardData(
                            title: 'Mark Report',
                            icon: Icons.bar_chart,
                            iconColor: Color(0xFFFFA000),
                            iconBackground: Color(0xFFFFF2C8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Student Fee',
                            icon: Icons.account_balance_wallet,
                            iconColor: Color(0xFFEF5656),
                            iconBackground: Color(0xFFFFE2E2),
                          ),
                          right: null,
                        ),
                        const SizedBox(height: 30),
                        _sectionTitle('OTHERS', textColor),
                        const SizedBox(height: 16),
                        _cardRow(
                          cardColor: cardColor,
                          textColor: textColor,
                          left: const CardData(
                            title: 'Contact',
                            icon: Icons.contact_phone,
                            iconColor: Color(0xFF6366E8),
                            iconBackground: Color(0xFFE9E8FF),
                          ),
                          right: const CardData(
                            title: 'Service review',
                            icon: Icons.star,
                            iconColor: Color(0xFFFFA000),
                            iconBackground: Color(0xFFFFF2C8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Điều hướng về tab của màn hình chính từ các màn hình phụ.
  void _selectTabFromExtra(int index) {
    if (!mounted) return;
    setState(() => currentIndex = index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // HEADER

  Widget _sectionTitle(String title, Color textColor) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: 19,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _cardRow({
    required Color cardColor,
    required Color textColor,
    required CardData left,
    required CardData? right,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ServiceMenuCard(
            data: left,
            cardColor: cardColor,
            textColor: textColor,
            onTap: () => _openMenu(left),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: right == null
              ? const SizedBox()
              : ServiceMenuCard(
                  data: right,
                  cardColor: cardColor,
                  textColor: textColor,
                  onTap: () => _openMenu(right),
                ),
        ),
      ],
    );
  }

  void _openMenu(CardData data) {
    if (data.title == 'Semester Schedule') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SemesterScheduleScreen(studentId: widget.studentId),
        ),
      );
      return;
    }
    if (data.title == 'Weekly timetable') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => TimetableScreen(studentId: widget.studentId),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NovaExtraScreen(
          page: data.title,
          studentId: widget.studentId,
          onSelectTab: _selectTabFromExtra,
        ),
      ),
    );
  }

  // CHAT PAGE

  Widget _buildChatPage(Color textColor, bool isDarkMode) {
    final subtitleColor = isDarkMode
        ? const Color(0xFF9BAAC0)
        : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 76, color: subtitleColor),
            const SizedBox(height: 16),
            Text(
              'Messages',
              style: TextStyle(
                color: textColor,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION

  Future<void> _selectBottomTab(int index) async {
    if (index == 1) {
      // Hiện Messages thật, không dùng trang placeholder.
      setState(() => currentIndex = 1);
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => NovaExtraScreen(
            page: 'Messages',
            studentId: widget.studentId,
            onSelectTab: _selectTabFromExtra,
          ),
        ),
      );
      // Khi người dùng bấm Back, trở lại trạng thái tab Home.
      // Nếu đã chọn Profile từ màn hình Messages thì giữ Profile.
      if (mounted && currentIndex == 1) {
        setState(() => currentIndex = 0);
      }
    } else {
      setState(() => currentIndex = index);
    }
  }
}
