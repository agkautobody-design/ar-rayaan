import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
import '../domain/magnetic_declination.dart';
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
                Center(
                  child: _LiveQibla(
                    bearing: bearing,
                    latitude: loc.latitude,
                    longitude: loc.longitude,
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
                        '2 · A PHYSICAL COMPASS — compasses point to MAGNETIC North, which differs from true North by your local magnetic declination (for example about 10° west in Toronto in 2026; it differs by city and drifts every year). The live compass below applies your declination for you, from the World Magnetic Model. With a separate compass: with a WEST declination add it to ${bearing.round()}°, with an EAST declination subtract it.',
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
                        'magnetic sensor (in the Android and iPhone apps directly, and '
                        'through the browser on a phone over https), so it is only as '
                        'good as the sensor: keep away from metal and magnets, hold the '
                        'phone flat, and confirm with the sun method above when it '
                        'matters. A few degrees of error is normal. Desktop computers '
                        'usually have no compass and show the static dial.',
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
///
/// The compass reads MAGNETIC north. The declination that turns it into true
/// north comes from the World Magnetic Model 2025 for the prayer location
/// (computed offline); the user can override it with their own number and
/// return to the automatic value at any time.
class _LiveQibla extends ConsumerStatefulWidget {
  const _LiveQibla({
    required this.bearing,
    required this.latitude,
    required this.longitude,
  });

  final double bearing;
  final double latitude;
  final double longitude;

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

  /// The last readings, for the "unsteady compass" warning.
  final List<double> _recent = <double>[];
  bool _wasAligned = false;

  /// The user's own declination (degrees, east positive), or null to use the
  /// model's.
  double? _manual;

  @override
  void initState() {
    super.initState();
    try {
      _manual = ref.read(sharedPreferencesProvider).getDouble(_declKey);
    } catch (_) {
      _manual = null;
    }
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    final StreamSubscription<double>? sub = _sub;
    if (sub != null) unawaited(sub.cancel());
    super.dispose();
  }

  MagneticDeclination get _model => MagneticModel.declination(
    latitude: widget.latitude,
    longitude: widget.longitude,
    date: DateTime.now(),
  );

  double get _declination => _manual ?? _model.degrees;

  Future<void> _start() async {
    setState(() => _status = _CompassStatus.starting);
    final bool granted = await DeviceHeading.requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _status = _CompassStatus.denied);
      return;
    }
    _magnetic = null;
    _recent.clear();
    _sub = DeviceHeading.headings().listen((double h) {
      if (!mounted) return;
      _recent.add(h);
      if (_recent.length > 16) _recent.removeAt(0);
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
      _wasAligned = false;
      _recent.clear();
    });
  }

  Future<void> _setManual(double? value) async {
    final double? v = value?.clamp(-60, 60).toDouble();
    setState(() => _manual = v);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (v == null) {
        await prefs.remove(_declKey);
      } else {
        await prefs.setDouble(_declKey, v);
      }
    } catch (_) {
      // Kept in memory for this visit.
    }
  }

  String _declLabel() {
    final double d = _declination;
    final int r = d.abs().round();
    if (r == 0) return '0\u00b0';
    return '$r\u00b0 ${d > 0 ? 'E' : 'W'}';
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
    final bool aligned = offset != null && offset.abs() <= 3;
    if (aligned && !_wasAligned) {
      unawaited(HapticFeedback.selectionClick());
    }
    _wasAligned = aligned;
    final bool erratic = CompassMath.isErratic(_recent);
    final MagneticDeclination model = _model;

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
          if (erratic) ...[
            const SizedBox(height: 4),
            Text(
              'The compass is unsteady. Move away from metal, magnets and '
              'cases with magnets, then wave the phone slowly in a figure '
              'of eight to recalibrate it.',
              style: AppText.bodyMuted.copyWith(
                fontSize: 11.5,
                color: AppColors.goldLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _manual == null
                ? 'Magnetic declination ${_declLabel()} \u00b7 automatic, from '
                      'the World Magnetic Model for your location'
                : 'Magnetic declination ${_declLabel()} \u00b7 set by you '
                      '(west is negative)',
            style: AppText.bodyMuted.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          if (_manual == null && !model.withinValidity)
            Text(
              'This model was issued for 2025\u20132030 and today is outside '
              'that span, so the number may be off. You can set your own.',
              style: AppText.bodyMuted.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Declination 1\u00b0 more west',
                onPressed: () => _setManual(_declination - 1),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              IconButton(
                tooltip: 'Declination 1\u00b0 more east',
                onPressed: () => _setManual(_declination + 1),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.gold,
              ),
              if (_manual != null)
                TextButton(
                  onPressed: () => _setManual(null),
                  child: Text(
                    'Use automatic',
                    style: AppText.bodyMuted.copyWith(color: AppColors.gold),
                  ),
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
          Text(
            'Declination: World Magnetic Model 2025, produced by NOAA/NCEI '
            'and the British Geological Survey.',
            style: AppText.bodyMuted.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ] else if (!DeviceHeading.isSupported)
          Text(
            'Live compass is not available here \u2014 use the dial '
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
              'sensor (and an https page in a browser); desktops usually '
              'have none.',
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
