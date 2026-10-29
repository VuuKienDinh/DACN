import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DailyFitBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DailyFitBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavSpec> _tabs = [
    _NavSpec(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    _NavSpec(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Gợi ý',
    ),
    _NavSpec(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom_rounded,
      label: 'Tủ đồ',
    ),
    _NavSpec(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Lịch đồ',
    ),
    _NavSpec(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Hồ sơ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset > 0 ? bottomInset : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.95),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final selected = index == currentIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? tab.activeIcon : tab.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
