import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/qibla_direction.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bearing = QiblaDirection.bearingToKaaba(
      QiblaDirection.defaultLocation,
    );
    final String compass = _compassPoint(bearing);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const ScenicBackground.home(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const ScreenHeader(title: 'Qibla', close: true),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'DIRECTION TO THE KAABA \u00b7 MAKKAH',
                    style: AppText.eyebrow,
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: SizedBox(
                    width: 272,
                    height: 272,
                    child: _QiblaDial(bearing: bearing),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${bearing.round()}\u00b0 $compass',
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'clockwise from true North',
                        style: AppText.bodyMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'from ${QiblaDirection.defaultLocationName} to the Kaaba',
                        style: AppText.bodyMuted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW TO USE', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(
                        'Stand facing the needle \u2014 the top of the dial points to the '
                        'Kaaba from ${QiblaDirection.defaultLocationName}. The sunnah is to face '
                        'the qiblah in every prescribed prayer; when travelling, Allah says: '
                        '"Wherever you turn, there is the Face of Allah" (2:115) \u2014 the '
                        'concession of prayer on the move is vast.',
                        style: AppText.bodyMuted.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  strong: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A NOTE ON PRECISION', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(
                        'This dial is computed by great-circle mathematics \u2014 exact, and '
                        'fully offline. A live, sensor-driven compass that turns with your '
                        'phone arrives with the native app builds, in shaa Allah.',
                        style: AppText.body.copyWith(height: 1.55, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back,
                        size: 14, color: AppColors.gold),
                    label: Text('Back to Home', style: AppText.bodyMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _compassPoint(double bearing) {
    const points = <String>[
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    return points[((bearing % 360) / 22.5).round() % 16];
  }
}

class _QiblaDial extends StatelessWidget {
  final double bearing;
  const _QiblaDial({required this.bearing});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 272,
          height: 272,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xC00A0F18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.08),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        CustomPaint(size: const Size(272, 272), painter: _TicksPainter()),
        // cardinal letters
        ..._cardinals(),
        // rotating needle pointing to the Kaaba
        Transform.rotate(
          angle: bearing * math.pi / 180,
          child: SizedBox(
            width: 272,
            height: 272,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 26,
                  child: Icon(
                    Icons.mosque,
                    size: 30,
                    color: AppColors.goldLight,
                  ),
                ),
                Container(
                  width: 4,
                  height: 190,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        AppColors.goldLight,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const CircleAvatar(
                  radius: 6,
                  backgroundColor: AppColors.goldLight,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xE60A0F18),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mosque, size: 26, color: AppColors.goldLight),
                const SizedBox(height: 4),
                Text(
                  'QIBLA',
                  style: AppText.eyebrow,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _cardinals() {
    const letters = <String>['N', 'E', 'S', 'W'];
    final List<Widget> out = [];
    for (var i = 0; i < 4; i++) {
      final double ang = i * math.pi / 2;
      out.add(Positioned(
        left: 136 + math.sin(ang) * 118 - 8,
        top: 136 - math.cos(ang) * 118 - 8,
        child: Text(
          letters[i],
          style: AppText.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: i == 0 ? AppColors.goldLight : AppColors.sand,
          ),
        ),
      ));
    }
    return out;
  }
}

class _TicksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i < 72; i++) {
      final double a = i * math.pi / 36;
      final bool major = i % 6 == 0;
      final double inner = radius - (major ? 12 : 6);
      canvas.drawLine(
        center + Offset(math.sin(a) * inner, -math.cos(a) * inner),
        center + Offset(math.sin(a) * radius, -math.cos(a) * radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
