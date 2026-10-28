import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/router.dart';

import '../../academy/application/academy_providers.dart';
import '../../menu/presentation/menu_screen.dart' show isAcademyRoute;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';

/// Home, page two - the quick-access hall. Everything dear, one tap away.
class HomeQuickScreen extends ConsumerWidget {
  const HomeQuickScreen({super.key});

  static const _tiles = [
    ('For Children', 'Letters, games & stories', 'assets/images/tiles/tile_knowledge.jpg', '/kids'),
    ('Wasia Academy', 'Learn with your teacher', 'assets/images/tiles/tile_quran.jpg', '/academy/gate'),
    ('Naat Player', 'Adhan, naats & nasheeds', 'assets/images/tiles/tile_noor.jpg', '/player'),
    ('Games', 'Chess, Ludo, quizzes & puzzles', 'assets/images/tiles/tile_knowledge.jpg', '/games'),
    ('Elder Care', 'Big words, gentle hearts', 'assets/images/tiles/tile_dhikr.jpg', '/elder-care'),
    ('Comfort & Calm', 'Sakina rooms, not therapy', 'assets/images/tiles/tile_hadith.jpg', '/sakina'),
    ('Support & Help', 'Hard times, and who to call', 'assets/images/tiles/tile_hadith.jpg', '/support'),
    ('Quick Hadith', 'A hadith in a breath', 'assets/images/tiles/tile_prayer.jpg', '/hadith'),
    ('Quick Khutbah', 'Sermons, in the Library', 'assets/images/tiles/tile_journey.jpg', '/stories'),
    ('Daily Duas', 'Du\u2019a & dhikr for the day', 'assets/images/tiles/tile_calendar.jpg', '/adhkar'),
    ('Tayyib Finance', 'Zakat \u00b7 sadaqah \u00b7 halal stocks', 'assets/images/tiles/tile_prayer.jpg', '/finance'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kill switch: ar.flag.academy=false removes every Academy entry point.
    final bool showAcademy = ref.watch(academyFlagProvider).valueOrNull ?? true;
    final tiles = [
      for (final t in _tiles)
        if (showAcademy || !isAcademyRoute(t.$4)) t,
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'Quick Access', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('EVERYTHING DEAR, ONE TAP AWAY', style: AppText.eyebrow),
          ),
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                for (var k = i; k < i + 2 && k < tiles.length; k++)
                  Expanded(child: Padding(
                    padding: EdgeInsetsDirectional.only(
                        end: k == i ? 5 : 0, start: k == i ? 0 : 5),
                    child: _QuickTile(
                      title: tiles[k].$1, subtitle: tiles[k].$2,
                      image: tiles[k].$3, route: tiles[k].$4,
                    ),
                  )),
              ]),
            ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title, subtitle, image, route;
  const _QuickTile({required this.title, required this.subtitle,
      required this.image, required this.route});

  @override
  Widget build(BuildContext context) {
    // Grows with the system text size so the caption never overflows.
    final double textScale =
        (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);
    return FocusSafeSemantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      onTap: () => context.open(route),
      child: FocusableTap(
      onTap: () => context.open(route),
      child: Container(
        height: 118 * textScale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [0.2, 0.65, 1],
              colors: [Colors.transparent, Color(0x9905090F), Color(0xF205090F)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldLight,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
              Text(subtitle, style: AppText.bodyMuted.copyWith(fontSize: 12,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)])),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
