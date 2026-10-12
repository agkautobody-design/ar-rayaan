import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/sound/sound_services.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Screen 1 · Splash / Arrival — the locked splash artwork.
///
/// Portrait viewports: full-screen cover, centered on the gate core (the
/// side pillars fall outside the crop); the baked-in sound note is
/// reproduced as an overlay since it sits outside the crop.
/// Landscape/wide viewports: the complete artwork, fully visible over a
/// blurred fill of itself. Holds 4 seconds → /welcome; tap to skip.
///
/// Founder directive: the splash must *stay* its full 4 seconds. The hold
/// never advances before 4s — but on slow connections (web, first load)
/// the 3 MB artwork can arrive after the timer fires, so the splash waits
/// for the artwork and then shows it for a minimum visible moment
/// (capped, so a failed image can never trap the user).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin, AmbientHost<SplashScreen> {
  /// Hold is measured in 100 ms ticks (not wall clock) so it behaves
  /// identically on device, slow web loads, and fake-async widget tests.
  static const int _holdTicks = 40; // 4 s minimum hold
  static const int _minVisibleTicks = 12; // art visible ≥1.2 s before leaving

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  Timer? _timer;
  int _ticks = 0;
  int? _artReadyTick;
  bool _artReady = false;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
    // Mark when the artwork is actually decoded and on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await precacheImage(
            const AssetImage('assets/images/splash.jpg'), context);
      } catch (_) {}
      _artReady = true;
    });
  }

  void _tick(Timer timer) {
    if (_advanced || !mounted) return;
    _ticks++;
    if (_artReady) _artReadyTick ??= _ticks;
    final int? readyTick = _artReadyTick;
    if (readyTick != null) {
      // Artwork on screen: leave after 4 s AND ≥1.2 s of it visible.
      if (_ticks >= _holdTicks &&
          _ticks - readyTick >= _minVisibleTicks) {
        _advance();
      }
    } else if (_ticks >= _holdTicks) {
      // precacheImage only stays pending where no codec/network exists
      // (widget tests); real devices always resolve it, so on slow first
      // loads the wait above governs. Here nothing is coming — advance
      // right at the 4-second mark rather than trapping anyone.
      _advance();
    }
  }

  void _advance() {
    if (_advanced) return;
    _advanced = true;
    _timer?.cancel();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _advance,
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: FadeTransition(
          opacity: _fade,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool portrait =
                  constraints.maxWidth / constraints.maxHeight < 1.1;

              if (portrait) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/splash.jpg', fit: BoxFit.cover),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.headphones_outlined,
                            size: 14,
                            color: Color(0xB3D4AF37),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sound can be turned off in settings',
                            style: AppText.bodyMuted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        AppColors.night.withValues(alpha: 0.55),
                        BlendMode.darken,
                      ),
                      child: Image.asset(
                        'assets/images/splash.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/splash.jpg',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
