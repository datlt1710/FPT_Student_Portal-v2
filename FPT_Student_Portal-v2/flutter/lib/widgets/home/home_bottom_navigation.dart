import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.isDarkMode,
    required this.onSelectTab,
  });
  final int currentIndex;
  final bool isDarkMode;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A3455) : const Color(0xFFE2E8F0),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bottomItem(Icons.home, 0, isDarkMode),
          _bottomItem(Icons.chat_bubble, 1, isDarkMode),
          _bottomItem(Icons.person, 2, isDarkMode),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, int index, bool isDarkMode) {
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () => onSelectTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? (isDarkMode ? const Color(0xFF3B4148) : const Color(0xFFCBD5E1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Icon(
          icon,
          size: 30,
          color: selected
              ? orangeColor
              : (isDarkMode
                    ? const Color(0xFF9BAAC0)
                    : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}
