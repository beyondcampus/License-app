import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class AppBottomNavItem {
  const AppBottomNavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom navigation matching the HTML `.bottom-nav`: 5 items, nav background,
/// top border, 10px labels.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = [
    AppBottomNavItem(Icons.home_outlined, Icons.home, AppStrings.navHome),
    AppBottomNavItem(
        Icons.menu_book_outlined, Icons.menu_book, AppStrings.navChapters),
    AppBottomNavItem(Icons.edit_note_outlined, Icons.edit_note,
        AppStrings.navPractice),
    AppBottomNavItem(
        Icons.insights_outlined, Icons.insights, AppStrings.navStats),
    AppBottomNavItem(Icons.style_outlined, Icons.style, AppStrings.navCards),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.navBackground,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == currentIndex,
                    label: items[i].label,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: AppRadius.mdAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i == currentIndex
                                  ? items[i].activeIcon
                                  : items[i].icon,
                              size: 22,
                              color: i == currentIndex
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[i].label,
                              style: AppTypography.navLabel.copyWith(
                                color: i == currentIndex
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
