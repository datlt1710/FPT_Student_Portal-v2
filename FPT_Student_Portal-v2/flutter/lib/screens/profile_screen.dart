import 'package:flutter/material.dart';

import '../widgets/student_info_builder.dart';

import '../settings/app_settings.dart';

class ProfileScreen extends StatelessWidget {
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onDarkModeChanged,
    required this.onNotificationsChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, child) {
        final background = isDarkMode ? darkBackground : lightBackground;
        final cardColor = isDarkMode ? darkCard : Colors.white;
        final textColor = isDarkMode ? darkText : lightText;

        final subtitleColor = isDarkMode
            ? const Color(0xFF9BAAC0)
            : const Color(0xFF64748B);

        return Container(
          color: background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
            children: [
              _sectionCard(
                cardColor: cardColor,
                children: [
                  _sectionTitle('Student ID', orangeColor, textColor),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF475569),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'lib/assets/student_qr.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 180,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StudentInfoBuilder(
                    builder: (context, student) {
                      final code = student['StudentCode']?.toString() ?? '';
                      return Center(
                        child: Text(
                          code,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show this QR code to verify your student identity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          size: 46,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check information online',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'https://fap.fpt.edu.vn',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF172033),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionCard(
                cardColor: cardColor,
                children: [
                  _sectionTitle(
                    'Appearance',
                    const Color(0xFF9333EA),
                    textColor,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _iconBox(Icons.dark_mode, const Color(0xFF9333EA)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isDarkMode
                                  ? 'Dark theme is active'
                                  : 'Light theme is active',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: onDarkModeChanged,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<bool>(
                valueListenable: notificationsNotifier,
                builder: (context, notificationsEnabled, child) {
                  return _sectionCard(
                    cardColor: cardColor,
                    children: [
                      _sectionTitle(
                        'Notification Settings',
                        const Color(0xFF06B6D4),
                        textColor,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _iconBox(
                            Icons.notifications,
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Push Notifications',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notificationsEnabled ? 'Enabled' : 'Disabled',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: notificationsEnabled,
                            onChanged: onNotificationsChanged,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Nova Student Portal v1.0.0',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required Color cardColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String title, Color accentColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 28,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}
