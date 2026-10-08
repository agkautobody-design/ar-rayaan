import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Full-bleed atmospheric background per the LOCKED screens board:
/// golden-hour paradise scenery behind the content (Home, Community),
/// dark navy + gold arabesque for utility screens (Journey, Menu, Explore,
/// Hādi, Profile, and readers). Artwork generated from the Founder's own
/// locked art as reference — swap-in replacement anytime.
/// Drop-in Scaffold replacement that layers a [ScenicBackground] behind the
/// body: `ScenicScaffold.pattern(body: …)` mirrors `Scaffold(body: …)`.
class ScenicScaffold extends StatelessWidget {
  const ScenicScaffold._(this._background, {required this.body, super.key});

  const ScenicScaffold.home({required Widget body, Key? key})
    : this._(const ScenicBackground.home(), body: body, key: key);

  const ScenicScaffold.community({required Widget body, Key? key})
    : this._(const ScenicBackground.community(), body: body, key: key);

  const ScenicScaffold.pattern({required Widget body, Key? key})
    : this._(const ScenicBackground.pattern(), body: body, key: key);

  final ScenicBackground _background;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [_background, body]));
  }
}

class ScenicBackground extends StatelessWidget {
  const ScenicBackground._(this.asset, this._stops, this._colors, {super.key});

  /// Golden-hour mosque garden (Screen 4 · Home).
  const ScenicBackground.home({Key? key})
    : this._(
        'assets/images/bg_home.jpg',
        const [0.0, 0.30, 0.62, 1.0],
        const [
          Color(0x0005090F),
          Color(0x1405090F),
          Color(0x3305090F),
          Color(0x8005090F),
        ],
        key: key,
      );

  /// Lantern-lit arches (Screen 9 · Community).
  const ScenicBackground.community({Key? key})
    : this._(
        'assets/images/bg_community.jpg',
        const [0.0, 0.28, 0.58, 1.0],
        const [
          Color(0x0F05090F),
          Color(0x4205090F),
          Color(0xA605090F),
          Color(0xC705090F),
        ],
        key: key,
      );

  /// Dark navy + gold arabesque (Journey, Menu, Explore, Hādi, readers…).
  const ScenicBackground.pattern({Key? key})
    : this._(
        'assets/images/bg_pattern.jpg',
        const [0.0, 1.0],
        const [Color(0x1F05090F), Color(0x5C05090F)],
        key: key,
      );

  final String asset;
  final List<double> _stops;
  final List<Color> _colors;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.night),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.12),
              BlendMode.screen,
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: _stops,
                colors: _colors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
