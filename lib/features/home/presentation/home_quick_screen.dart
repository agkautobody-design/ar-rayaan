import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// Home, page two - the quick-access hall. Everything dear, one tap away.
class HomeQuickScreen extends StatelessWidget {
  const HomeQuickScreen({super.key});

  static const _tiles = [
    ('Wasia Academy', 'Learn with your teacher', 'assets/images/tiles/tile_quran.jpg', '/academy/gate'),
    ('Naat Player', 'Adhan, naats & nasheeds', 'assets/images/tiles/tile_noor.jpg', '/player'),
    ('Games', 'Shatranj, Ludo & five more', 'assets/images/tiles/tile_knowledge.jpg', '/games'),
    ('Elder Care', 'Big words, gentle hearts', 'assets/images/tiles/tile_dhikr.jpg', '/elder-care'),
    ('Islamic Therapy', 'Comfort rooms (Sakina)', 'assets/images/tiles/tile_hadith.jpg', '/sakina'),
    ('Quick Hadith', 'A hadith in a breath', 'assets/images/tiles/tile_prayer.jpg', '/hadith'),
    ('Quick Khutbah', 'Sermons for today', 'assets/images/tiles/tile_journey.jpg', '/stories'),
    ('Daily Duas', 'For every moment', 'assets/images/tiles/tile_calendar.jpg', '/stories'),
  ];

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < _tiles.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                for (var k = i; k < i + 2 && k < _tiles.length; k++)
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(right: k == i ? 5 : 0, left: k == i ? 0 : 5),
                    child: _QuickTile(
                      title: _tiles[k].$1, subtitle: _tiles[k].$2,
                      image: _tiles[k].$3, route: _tiles[k].$4,
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
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        height: 118,
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
              Text(subtitle, style: AppText.bodyMuted.copyWith(fontSize: 9.5,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 5)])),
            ],
          ),
        ),
      ),
    );
  }
}
