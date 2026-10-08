import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Round gold icon chip used across list rows and tiles.
class IconTile extends StatelessWidget {
  const IconTile({required this.icon, super.key, this.size = 36, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effective = color ?? AppColors.gold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effective.withValues(alpha: 0.10),
        border: Border.all(color: effective.withValues(alpha: 0.30)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: effective),
    );
  }
}
