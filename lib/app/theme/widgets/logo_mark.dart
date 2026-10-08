import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Gold crescent-star mark used on Welcome / onboarding screens.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.40)),
        boxShadow: const [BoxShadow(color: Color(0x40D4AF37), blurRadius: 30)],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.nights_stay_outlined,
        size: size * 0.5,
        color: AppColors.gold,
      ),
    );
  }
}
