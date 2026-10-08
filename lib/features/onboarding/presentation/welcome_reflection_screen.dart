import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';

/// Screen 2 · Welcome Reflection — "A One Time Experience" (locked artwork).
///
/// The Founder's approved design is rendered as a single full-screen image.
/// The baked Continue button is not interactive, so a transparent hotspot is
/// positioned over it — computed from the displayed image rect, exact at any
/// aspect ratio. Continues → /home.
///
/// ATTRIBUTION CORRECTION (honesty, verified 2026-07): the artwork cites the
/// du'a as "Sahih Muslim 2677". Takhrij shows that is wrong — the hadith
/// scholars (al-ʿIrāqī, Ibn al-Subkī) found no chain for this wording as a
/// Prophetic hadith; it is a beloved TRANSMITTED supplication (duʿāʾ
/// maʾthūr), attributed by al-Buhūtī to ʿUmar (ra), cited by Ibn Kathīr
/// without isnād. (Sahih Muslim 2577 is a different hadith entirely.)
/// Until regenerated artwork is approved, an overlay replaces the line with
/// an honest attribution. Original artwork file is untouched.
class WelcomeReflectionScreen extends StatelessWidget {
  const WelcomeReflectionScreen({super.key});

  // Artwork: 853×1689. Baked Continue button rect within it:
  // x 135–715, y 1490–1590 (fractions below).
  static const double _imgW = 853;
  static const double _imgH = 1689;
  static const double _btnLeft = 135 / _imgW;
  static const double _btnTop = 1490 / _imgH;
  static const double _btnWidth = 580 / _imgW;
  static const double _btnHeight = 100 / _imgH;

  // Baked (incorrect) attribution line rect within the artwork (fractions).
  static const double _attrLeft = 0.30;
  static const double _attrTop = 0.535;
  static const double _attrWidth = 0.40;
  static const double _attrHeight = 0.033;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          final double scale = (w / _imgW) < (h / _imgH)
              ? (w / _imgW)
              : (h / _imgH);
          final double dispW = _imgW * scale;
          final double dispH = _imgH * scale;
          final double offX = (w - dispW) / 2;
          final double offY = (h - dispH) / 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Complete artwork, never cropped; gaps filled by a blurred echo
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.night.withValues(alpha: 0.6),
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
              // Honest attribution overlay (see class doc).
              Positioned(
                left: offX + _attrLeft * dispW,
                top: offY + _attrTop * dispH,
                width: _attrWidth * dispW,
                height: _attrHeight * dispH,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.night.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '— A beloved transmitted supplication',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: AppColors.sand.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const Key('welcome-continue'),
                left: offX + _btnLeft * dispW,
                top: offY + _btnTop * dispH,
                width: _btnWidth * dispW,
                height: _btnHeight * dispH,
                child: Semantics(
                  button: true,
                  label: 'Continue',
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.home),
                      borderRadius: BorderRadius.circular(999),
                      splashColor: AppColors.gold.withValues(alpha: 0.25),
                      highlightColor: AppColors.gold.withValues(alpha: 0.12),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
