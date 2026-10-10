import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../lamha/domain/lamha.dart';
import '../../prayer/application/prayer_providers.dart';
import '../../prayer/domain/prayer_times.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../../academy/domain/atmosphere.dart';
import '../../academy/presentation/atmosphere_layer.dart';

/// Screen 4 · Home — greeting, nine core tiles, "Today for You".
///
/// Tile subtitles are LIVE (locked visuals): next prayer, real reading
/// position, adhkar remaining today, and the honest Forty-Hadith label
/// (O-5 deviation, pending Founder ruling).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Live tile subtitles -------------------------------------------------
    final String prayerSub = ref
        .watch(prayerTimesProvider)
        .when(
          data: (PrayerTimes t) {
            final (String name, DateTime time) = t.nextPrayer(DateTime.now());
            return '$name · ${DateFormat.jm().format(time)}';
          },
          loading: () => 'Loading times…',
          error: (_, _) => 'Times unavailable',
        );

    final ReadingPosition? pos = ref.watch(readingPositionProvider);
    String quranSub = 'Begin Reading · Al-Fatihah';
    if (pos != null) {
      final List<SurahMeta>? index = ref.watch(quranIndexProvider).valueOrNull;
      final SurahMeta? meta = index
          ?.where((s) => s.number == pos.surah)
          .firstOrNull;
      quranSub = meta == null
          ? 'Continue Reading'
          : 'Continue · ${meta.transliteration} ${pos.surah}:${pos.ayah}';
    }

    String dhikrSub = 'Morning Adhkar';
    final List<AdhkarSet>? sets = ref.watch(adhkarSetsProvider).valueOrNull;
    if (sets != null && sets.isNotEmpty) {
      ref.watch(adhkarProgressProvider);
      final AdhkarSet morning = sets.first;
      final int done = ref
          .read(adhkarProgressProvider.notifier)
          .completedInSet(morning);
      dhikrSub =
          'Morning Adhkar · ${morning.totalRepetitions - done} remaining';
    }

    final List<(IconData, String, String, String?)> tiles = [
      (
        Icons.nights_stay_outlined,
        'Prayer Times',
        prayerSub,
        AppRoutes.prayerTimes,
      ),
      (Icons.menu_book_outlined, 'Qur’an', quranSub, AppRoutes.quran),
      (Icons.wb_sunny_outlined, 'Dhikr & Du’a', dhikrSub, AppRoutes.adhkar),
      (
        Icons.article_outlined,
        'Hadith',
        'The Forty Hadith · An-Nawawi',
        AppRoutes.hadith,
      ),
      (
        Icons.auto_awesome,
        'Today’s NOOR',
        'A fresh light for your heart',
        AppRoutes.noor,
      ),
      (
        Icons.lightbulb_outline,
        'Hādi',
        'Ask anything · Get guidance',
        AppRoutes.hadi,
      ),
      (
        Icons.calendar_month_outlined,
        'Islamic Calendar',
        'Events & Observances',
        AppRoutes.calendar,
      ),
      (Icons.school_outlined, 'Knowledge', 'Articles, Lessons & Courses', null),
      (
        Icons.trending_up,
        'My Journey',
        'Track, Reflect & Grow',
        AppRoutes.journey,
      ),
    ];

    return Scaffold(
      body: AtmosphereLayer(
              emotion: AtmosphereEngine.resolve(now: DateTime.now()).emotion,
              child: Stack(
        children: [
          const ScenicBackground.home(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Color(0xE605090F),
                      Color(0xA605090F),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      _HeaderIcon(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.hadi),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.glassFill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: AppColors.gold.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ask Hādi anything..',
                                    style: AppText.bodyMuted.copyWith(
                                      color: AppColors.sand.withValues(alpha: 0.85),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.mic_none,
                                  size: 16,
                                  color: AppColors.gold.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: AppColors.gold.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HeaderIcon(
                        icon: Icons.menu,
                        onTap: () => context.push(AppRoutes.menu),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // Greeting sits directly on the scenery (locked board).
                      SizedBox(
                        height: 178,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'As-Salaamu Alaikum,',
                                style: AppText.bodyMuted.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              GoldText(
                                'Welcome Home',
                                style: AppText.displayMedium.copyWith(
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'May Allah make this a source of\nbarakah in your day!',
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                onTap: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.setBool('ar.elder.mode', true);
                  if (mounted) context.go('/home/elder');
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.2),
                    color: const Color(0x2405090F),
                  ),
                  child: Row(children: [
                    const Icon(Icons.elderly_outlined, color: AppColors.goldLight, size: 26),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ELDER MODE', style: AppText.body.copyWith(
                            fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.goldLight,
                            letterSpacing: 1.2)),
                        Text('One tap \u2014 the app opens here for them every time. Big words. Three doors. Nothing else.',
                            style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
                      ],
                    )),
                    const Icon(Icons.chevron_right, color: AppColors.gold, size: 22),
                  ]),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/home/quick'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    color: const Color(0x1A05090F),
                  ),
                  child: Row(children: [
                    const Icon(Icons.dashboard_outlined, color: AppColors.goldLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Access', style: AppText.body.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.goldLight)),
                        Text('Academy \u00b7 Naats \u00b7 Games \u00b7 Elder Care \u00b7 Therapy \u00b7 Duas',
                            style: AppText.bodyMuted.copyWith(fontSize: 10.5)),
                      ],
                    )),
                    const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                  ]),
                ),
              ),
              GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.0,
                        children: [
                          for (final (_, title, sub, route) in tiles)
                            _PictureTile(
                              image: _tileImage(title),
                              title: title,
                              subtitle: sub,
                              onTap: () =>
                                  context.go(route ?? AppRoutes.explore),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        strong: true,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Today for You',
                                  style: AppText.body.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.noor),
                                  child: Text(
                                    'View All',
                                    style: AppText.bodyMuted.copyWith(
                                      fontSize: 10,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          'وَاذْكُر رَّبَّكَ إِذَا نَسِيتَ',
                                          style: AppText.arabicLarge.copyWith(
                                            fontSize: 20,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'And remember your Lord when you forget.',
                                        style: AppText.bodyMuted.copyWith(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'QUR’AN 18:24',
                                        style: AppText.eyebrow.copyWith(
                                          fontSize: 9,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/today-quran.png',
                                    width: 104,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Lamha — the gentle Sunnah glance (max 2/week by
                      // constitution; nothing shows on quiet days).
                      if (LamhaEngine.forDate(DateTime.now()) != null) ...[
                        const SizedBox(height: 16),
                        _LamhaCard(moment: LamhaEngine.forDate(DateTime.now())!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

/// The Lamha strip — one sourced glance, dismissible by simply scrolling
/// past; never stacked, never loud.
class _LamhaCard extends StatelessWidget {
  const _LamhaCard({required this.moment});

  final LamhaMoment moment;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LAMHA · ${moment.title.toUpperCase()}',
                  style: AppText.eyebrow.copyWith(
                    color: AppColors.gold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            moment.body,
            style: AppText.body.copyWith(
              fontSize: 12.5,
              height: 1.6,
              color: AppColors.sand.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moment.source,
            style: AppText.eyebrow.copyWith(
              fontSize: 8,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.sand.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}


String _tileImage(String t) {
  const base = 'assets/images/tiles';
  if (t.startsWith('Prayer')) return '$base/tile_prayer.jpg';
  if (t.startsWith('Qur')) return '$base/tile_quran.jpg';
  if (t.startsWith('Dhikr')) return '$base/tile_dhikr.jpg';
  if (t.startsWith('Hadith')) return '$base/tile_hadith.jpg';
  if (t.startsWith('Today')) return '$base/tile_noor.jpg';
  if (t.startsWith('H\u0101di') || t.startsWith('Hadi')) {
    return '$base/tile_hadi.jpg';
  }
  if (t.startsWith('Islamic')) return '$base/tile_calendar.jpg';
  if (t.startsWith('Knowledge')) return '$base/tile_knowledge.jpg';
  return '$base/tile_journey.jpg';
}

class _PictureTile extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PictureTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.16, 0.55, 1.0],
              colors: const [
                Colors.transparent,
                Color(0xB805090F),
                Color(0xFA05090F),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.body.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMuted.copyWith(
                  fontSize: 8.5,
                  height: 1.3,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
