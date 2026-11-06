import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';

class QBNavItem {
  const QBNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class QBBottomNavigation extends StatelessWidget {
  const QBBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<QBNavItem>? items;

  static const List<QBNavItem> employeeCrmItems = [
    QBNavItem(
      label: 'Home',
      icon: Remix.home_5_line,
      activeIcon: Remix.home_5_fill,
    ),
    QBNavItem(
      label: 'Data Capture',
      icon: Remix.add_circle_line,
      activeIcon: Remix.add_circle_fill,
    ),
    QBNavItem(
      label: 'Leads',
      icon: Remix.user_search_line,
      activeIcon: Remix.user_search_fill,
    ),
    QBNavItem(
      label: 'Customers',
      icon: Remix.building_2_line,
      activeIcon: Remix.building_2_fill,
    ),
    QBNavItem(
      label: 'Profile',
      icon: Remix.user_3_line,
      activeIcon: Remix.user_3_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? employeeCrmItems;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < navItems.length; i++)
                _NavItem(
                  index: i,
                  currentIndex: currentIndex,
                  label: navItems[i].label,
                  icon: navItems[i].icon,
                  activeIcon: navItems[i].activeIcon,
                  onTap: onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final ValueChanged<int> onTap;

  bool get isSelected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
