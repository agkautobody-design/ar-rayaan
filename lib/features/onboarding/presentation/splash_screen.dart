import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (context.mounted) context.go(AppRoutes.home);
    });
    return Scaffold(
      backgroundColor: const Color(0xFF05090F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mosque_outlined, size: 64, color: AppColors.goldLight),
            const SizedBox(height: 16),
            const Text(
              'AR-RAYAAN',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 28,
                letterSpacing: 6,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'WHERE HEARTS FIND HOME',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3,
                color: AppColors.sand.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
