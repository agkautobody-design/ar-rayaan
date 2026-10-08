import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../domain/qibla_direction.dart';

/// Qibla Finder — compass dial with the gold Qibla marker at the computed
/// bearing to the Kaaba. Pure offline math.
///
/// NOTE (engineering, pending O-11 + mobile build): the dial is North-up and
/// static in the preview — web has no magnetometer. In the mobile build a
/// live compass heading will rotate the dial so the marker points the way.
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bearing = QiblaDirection.bearingToKaaba(
      QiblaDirection.defaultLocation,
    );
    final String point = QiblaDirection.compassPoint(bearing);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Qibla Finder'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'القِبْلَة',
                          style: AppText.arabicLarge.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DIRECTION TO THE KAABA · MAKKAH',
                          style: AppText.eyebrow.copyWith(
                            color: AppColors.sand.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _CompassDial(bearing: bearing),
                        const SizedBox(height: 20),
                        Text(
                          '${bearing.toStringAsFixed(1)}° $point',
                          style: AppText.displayMedium.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'clockwise from true North',
                          style: AppText.bodyMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtKm(QiblaDirection.distanceToKaabaKm(
                              QiblaDirection.defaultLocation)),
                          style: AppText.bodyMuted,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Computed for ${QiblaDirection.defaultLocationName} '
                            '(default location). Face North, then turn '
                            '${bearing.toStringAsFixed(0)}° toward the East — '
                            'the gold marker is your Qibla.',
                            style: AppText.bodyMuted.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LIVE COMPASS ARRIVES WITH THE MOBILE BUILD · LOCATION SETTINGS PENDING',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// '10370' -> '10,370 km' (manual separator; no intl dependency).
String _fmtKm(double km) {
  final String s = km.round().toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b km';
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 264,
      height: 264,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(264, 264),
            painter: _DialPainter(bearing: bearing),
          ),
          const _Cardinal('N', Alignment.topCenter),
          const _Cardinal('E', Alignment.centerRight),
          const _Cardinal('S', Alignment.bottomCenter),
          const _Cardinal('W', Alignment.centerLeft),
          Center(
            child: Transform.rotate(
              // Kaaba marker sits on the gold needle at the Qibla bearing.
              angle: bearing * math.pi / 180,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 34),
                  child: Icon(Icons.mosque, size: 22, color: AppColors.gold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.bearing});

  final double bearing;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2;

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.gold.withValues(alpha: 0.35);
    canvas.drawCircle(c, r - 1, ring);
    canvas.drawCircle(
      c,
      r - 46,
      ring..color = ring.color.withValues(alpha: 0.15),
    );

    // Degree ticks — gold every 90°, faint otherwise.
    for (int deg = 0; deg < 360; deg += 10) {
      final bool cardinal = deg % 90 == 0;
      final double a = (deg - 90) * math.pi / 180;
      final double outer = r - 6;
      final double inner = outer - (cardinal ? 14 : 7);
      final Paint tick = Paint()
        ..strokeWidth = cardinal ? 2 : 1
        ..color = cardinal
            ? AppColors.gold
            : AppColors.sand.withValues(alpha: 0.25);
      canvas.drawLine(
        Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)),
        Offset(c.dx + outer * math.cos(a), c.dy + outer * math.sin(a)),
        tick,
      );
    }

    // Gold Qibla needle at the bearing.
    final double qa = (bearing - 90) * math.pi / 180;
    final Paint needle = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gold;
    canvas.drawLine(
      c,
      Offset(c.dx + (r - 52) * math.cos(qa), c.dy + (r - 52) * math.sin(qa)),
      needle,
    );
    canvas.drawCircle(c, 5, Paint()..color = AppColors.gold);
    canvas.drawCircle(
      Offset(c.dx + (r - 52) * math.cos(qa), c.dy + (r - 52) * math.sin(qa)),
      6,
      Paint()..color = AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.bearing != bearing;
}

class _Cardinal extends StatelessWidget {
  const _Cardinal(this.letter, this.alignment);

  final String letter;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final bool north = letter == 'N';
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          letter,
          style: AppText.label.copyWith(
            color: north
                ? AppColors.gold
                : AppColors.sand.withValues(alpha: 0.55),
            fontWeight: north ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
