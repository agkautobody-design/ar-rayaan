import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../prayer/application/location_providers.dart';
import '../../prayer/application/prayer_repository.dart';
import '../data/device_heading.dart';
import '../domain/compass_math.dart';
import '../domain/qibla_direction.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same location as Prayer Times (GPS or chosen city; Toronto only until
    // the user sets one).
    final PrayerLocation loc = ref.watch(prayerLocationControllerProvider);
    final double bearing = QiblaDirection.bearingToKaaba(
      (lat: loc.latitude, lng: loc.longitude),
    );
    final String place = loc.city;
    final bool isDefault =
        loc.latitude == PrayerLocationController.fallback.latitude &&
            loc.longitude == PrayerLocationController.fallback.longitude;
    final bool northern = loc.latitude >= 0;
    final bool tropics = loc.latitude.abs() < 23.5;
    final String compass = QiblaDirection.compassPoint(bearing);
    final double km = QiblaDirection.distanceToKaabaKm(
      (lat: loc.latitude, lng: loc.longitude),
    );
    final bool atMakkah = km < 20;
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
                Center(child: _LiveQibla(bearing: bearing)),
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
                        atMakkah
                            ? 'You are in or very near Makkah \u2014 face the Kaaba itself'
                            : 'from $place to the Kaaba \u00b7 about ${_km(km)} km',
                        style: AppText.bodyMuted.copyWith(fontSize: 11),
                      ),
                      if (isDefault) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.prayerTimes),
                          child: Text(
                            'Not in Toronto? Set your location in Prayer Times',
                            style: AppText.bodyMuted.copyWith(
                                fontSize: 12, color: AppColors.gold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TWO WAYS TO FACE THE KAABA', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(
                        tropics
                            ? '1 · THE EXACT BEARING (recommended) — the dial above is measured from true North by great-circle mathematics, fully offline. Near the equator the noon sun can stand north or south of you, so check true North with a map app or your phone\u2019s compass set to true North, then turn ${bearing.round()}° clockwise.'
                            : '1 · THE EXACT BEARING (recommended) — the dial above is measured from true North by great-circle mathematics, fully offline. No compass needed: at solar noon (when shadows are shortest) the sun is due ${northern ? 'south' : 'north'} of $place, so shadows point due ${northern ? 'NORTH' : 'SOUTH'}. ${northern ? 'Line your prayer mat along the shadow' : 'Face opposite the shadow to face North'}, then turn ${bearing.round()}° clockwise.',
                        style: AppText.bodyMuted.copyWith(height: 1.6, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2 · A PHYSICAL COMPASS — compasses point to MAGNETIC North, which differs from true North by your local magnetic declination (for example about 10° west in Toronto in 2026; it differs by city and drifts every year). Either switch your phone\u2019s compass app to show true North, or look up your declination (NOAA\u2019s magnetic field calculator) and correct for it: with a WEST declination add it to ${bearing.round()}°, with an EAST declination subtract it.',
                        style: AppText.bodyMuted.copyWith(height: 1.6, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If the two methods ever disagree, trust the sun at noon over any compass — it never has declination.',
                        style: AppText.body.copyWith(fontSize: 12,
                            color: AppColors.goldLight, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOW TO USE', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(
                        'The gold needle points toward the Kaaba from $place, '
                        'measured clockwise from true North (the N on the dial). '
                        'Turn your body until you face that direction. With the live '
                        'compass on, the dial turns with your phone: when the needle '
                        'points straight up, the top of your phone faces the Qibla. '
                        'The sunnah is to face '
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
                        'The bearing is computed by great-circle mathematics \u2014 exact, '
                        'and fully offline. The live compass reads your phone\u2019s '
                        'magnetic sensor through the browser, so it is only as good as '
                        'the sensor: keep away from metal and magnets, hold the phone '
                        'flat, and confirm with the sun method above when it matters. '
                        'It needs https and a phone with a compass; desktop browsers '
                        'and the native builds show the static dial until a sensor '
                        'plugin is added.',
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

  static String _km(double km) {
    final int n = km.round();
    final String digits = n.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}

/// The dial plus the optional live compass. The dial is north-up by default;
/// with the sensor on it turns so that its N follows true North.
class _LiveQibla extends ConsumerStatefulWidget {
  const _LiveQibla({required this.bearing});

  final double bearing;

  @override
  ConsumerState<_LiveQibla> createState() => _LiveQiblaState();
}

enum _CompassStatus { idle, starting, live, denied, noData }

class _LiveQiblaState extends ConsumerState<_LiveQibla> {
  static const String _declKey = 'ar.qibla.declination';

  StreamSubscription<double>? _sub;
  Timer? _watchdog;
  _CompassStatus _status = _CompassStatus.idle;
  double? _magnetic;

  /// Magnetic declination, degrees, east positive (set by the user).
  double _declination = 0;

  @override
  void initState() {
    super.initState();
    try {
      _declination =
          ref.read(sharedPreferencesProvider).getDouble(_declKey) ?? 0;
    } catch (_) {
      _declination = 0;
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    final StreamSubscription<double>? sub = _sub;
    if (sub != null) unawaited(sub.cancel());
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _status = _CompassStatus.starting);
    final bool granted = await DeviceHeading.requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _status = _CompassStatus.denied);
      return;
    }
    _magnetic = null;
    _sub = DeviceHeading.headings().listen((double h) {
      if (!mounted) return;
      final double? prev = _magnetic;
      setState(() {
        _magnetic = prev == null ? h : CompassMath.smooth(prev, h);
        _status = _CompassStatus.live;
      });
    });
    _watchdog = Timer(const Duration(seconds: 4), () {
      if (mounted && _magnetic == null) {
        setState(() => _status = _CompassStatus.noData);
      }
    });
  }

  Future<void> _stop() async {
    _watchdog?.cancel();
    final StreamSubscription<double>? sub = _sub;
    _sub = null;
    if (sub != null) await sub.cancel();
    if (!mounted) return;
    setState(() {
      _status = _CompassStatus.idle;
      _magnetic = null;
    });
  }

  Future<void> _setDeclination(double value) async {
    final double v = value.clamp(-60, 60).toDouble();
    setState(() => _declination = v);
    try {
      await ref.read(sharedPreferencesProvider).setDouble(_declKey, v);
    } catch (_) {
      // Kept in memory for this visit.
    }
  }

  String _declLabel() {
    final int d = _declination.abs().round();
    if (d == 0) return '0\u00b0';
    return '$d\u00b0 ${_declination > 0 ? 'E' : 'W'}';
  }

  @override
  Widget build(BuildContext context) {
    final double? magnetic = _magnetic;
    final double? trueHeading = magnetic == null
        ? null
        : CompassMath.trueHeading(magnetic, _declination);
    final double? offset = trueHeading == null
        ? null
        : CompassMath.offsetToQibla(
            qiblaBearing: widget.bearing,
            trueHeading: trueHeading,
          );
    final bool aligned = offset != null && offset.abs() <= 5;

    return Column(
      children: [
        SizedBox(
          width: 272,
          height: 272,
          child: Transform.rotate(
            angle: trueHeading == null ? 0 : -trueHeading * math.pi / 180,
            child: _QiblaDial(bearing: widget.bearing),
          ),
        ),
        const SizedBox(height: 14),
        if (_status == _CompassStatus.live && offset != null) ...[
          Text(
            aligned
                ? 'Facing the Qibla'
                : offset > 0
                ? 'Turn right ${offset.round()}\u00b0'
                : 'Turn left ${(-offset).round()}\u00b0',
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: aligned ? AppColors.goldLight : AppColors.sand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Magnetic declination ${_declLabel()} \u00b7 set it for your city '
            '(west is negative)',
            style: AppText.bodyMuted.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Declination 1\u00b0 more west',
                onPressed: () => _setDeclination(_declination - 1),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              IconButton(
                tooltip: 'Declination 1\u00b0 more east',
                onPressed: () => _setDeclination(_declination + 1),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              TextButton(
                onPressed: _stop,
                child: Text(
                  'Stop compass',
                  style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
        ] else if (!DeviceHeading.isSupported)
          Text(
            'Live compass is not available in this build \u2014 use the dial '
            'and the two methods below.',
            style: AppText.bodyMuted.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          )
        else ...[
          TextButton.icon(
            onPressed: _status == _CompassStatus.starting ? null : _start,
            icon: const Icon(Icons.explore_outlined, size: 16),
            label: Text(
              _status == _CompassStatus.starting
                  ? 'Starting\u2026'
                  : 'Start live compass',
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldLight),
          ),
          if (_status == _CompassStatus.denied)
            Text(
              'Motion access was refused. Allow it for this site in your '
              'browser settings, then try again.',
              style: AppText.bodyMuted.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          if (_status == _CompassStatus.noData)
            Text(
              'No compass data arrived. This needs a phone with a compass '
              'sensor and an https page; desktops usually have none.',
              style: AppText.bodyMuted.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
        ],
      ],
    );
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
