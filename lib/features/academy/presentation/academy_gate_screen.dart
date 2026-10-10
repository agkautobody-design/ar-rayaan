import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// The gate of Wasia Academy — entered the way Ar-Rayaan itself is entered:
/// a threshold of light. Bismillah in calligraphy, the knowledge verse,
/// one tap to step inside.
class AcademyGateScreen extends StatelessWidget {
  const AcademyGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => context.go(AppRoutes.academy),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFF05090F).withValues(alpha: 0.30),
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/images/welcome-reflection-full.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Image.asset(
                'assets/images/welcome-reflection-full.jpg',
                fit: BoxFit.contain,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x5505090F),
                    Color(0xAA05090F),
                    Color(0xF205090F),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064e\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 34,
                        height: 1.8,
                        color: Color(0xFFEAD9A8),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'WASIA ACADEMY',
                      style: AppText.eyebrow.copyWith(letterSpacing: 6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The school that carries her name',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '\u0642\u064f\u0644\fa \u0647\u064e\u0644\fa \u064a\u064e\u0633\u0652\u062a\u064e\u0648\u0650\u064a \u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e \u0648\u064e\u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u0644\u0627 \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 21,
                              height: 1.9,
                              color: Color(0xFFEAD9A8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\u201cAre those who know equal to those who '
                            'do not know?\u201d \u2014 Qur\u2019an 39:9',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    Text(
                      'TAP TO ENTER',
                      style: AppText.eyebrow.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
