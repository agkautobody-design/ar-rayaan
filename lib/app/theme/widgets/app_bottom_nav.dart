import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_colors.dart';

/// Locked bottom navigation: Home · Faith · Family · Hādi · You.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const List<(IconData, String)> _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.menu_book_outlined, 'Faith'),
    (Icons.people_outline, 'Family'),
    (Icons.auto_awesome, 'Hādi'),
    (Icons.person_outline, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.night.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].$1,
                      label: _items[i].$2,
                      active: shell.currentIndex == i,
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.gold : const Color(0x73EAD6B4);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
              shadows: active
                  ? const [Shadow(color: AppColors.gold, blurRadius: 8)]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
