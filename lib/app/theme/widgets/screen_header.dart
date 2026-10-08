import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';
import '../app_colors.dart';
import '../app_typography.dart';

/// Shared screen header: round back (or close) button · Playfair title ·
/// round settings button — per the locked screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, super.key, this.close = false});

  final String title;

  /// Shows an ✕ instead of ← (Explore / Menu panels).
  final bool close;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _RoundButton(
            icon: close ? Icons.close : Icons.arrow_back,
            onTap: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          Expanded(
            child: Text(
              title,
              style: AppText.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          _RoundButton(icon: Icons.settings_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.sand.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
