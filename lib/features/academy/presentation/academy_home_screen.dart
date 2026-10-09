import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/academy_providers.dart';
import '../application/word_deck_provider.dart';
import '../application/academy_strings.dart';
import '../domain/academy_models.dart';

/// Al-Wasia Academy of Sacred Knowledge — home (Wave 1).
/// Locked look: Playfair header · continue hero · The Path card ·
/// 2×2 school grid (coming-soon schools are honest, never paywalled) ·
/// gentle Today strip · daily verse. Simplicity Charter: ≤5 visible
/// items per region, icon+label, three taps to anything core.
class AcademyHomeScreen extends ConsumerStatefulWidget {
  const AcademyHomeScreen({super.key});

  @override
  ConsumerState<AcademyHomeScreen> createState() =>
      _AcademyHomeScreenState();
}

class _AcademyHomeScreenState
    extends ConsumerState<AcademyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wordDeckProvider.notifier).seedFromPack();
    });
  }


  static const String _verseRef = 'Qur’an 39:9';
  static const String _verseText =
      'Say: Are those who know equal to those who do not know?';

  @override
  Widget build(BuildContext context) {
    final List<AcademyCourse> courses = ref.watch(academyCoursesProvider);
    final AcademyCourse path = courses.firstWhere(
      (AcademyCourse c) => c.id == 'the-path',
    );
    final List<AcademyCourse> schools = courses
        .where((AcademyCourse c) => c.id != 'the-path')
        .toList();
    final AcademyLesson? cont = ref.watch(continueLessonProvider);
    final int done = ref.watch(lessonsDoneProvider);
    final String s = AcademyStrings.get('academy.title');

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: s),
              const SizedBox(height: 8),

              // Continue hero -------------------------------------------------
              if (cont != null)
                GlassCard(
                  strong: true,
                  onTap: () => context.go(
                    '/academy/lesson/${cont.courseId}/${cont.unitId}/${cont.id}',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AcademyStrings.get('academy.continue'),
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AcademyStrings.get(cont.titleKey),
                        style: AppText.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress(ref, cont),
                          minHeight: 4,
                          backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GlassCard(
                  strong: true,
                  onTap: () {
                    final AcademyLesson first = path.units.first.lessons.first;
                    context.go(
                      '/academy/lesson/${first.courseId}/${first.unitId}/${first.id}',
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.route_outlined,
                        color: AppColors.gold,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AcademyStrings.get('path.title'),
                              style: AppText.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AcademyStrings.get('path.subtitle'),
                              style: AppText.bodyMuted,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // The knowledge banner ------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '\u0642\u064f\u0644\fa \u0647\u064e\u0644\fa \u064a\u064e\u0633\u0652\u062a\u064e\u0648\u0650\u064a \u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e \u0648\u064e\u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u0644\u0627 \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 19,
                        height: 1.9,
                        color: Color(0xFFEAD9A8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\u201cAre those who know equal to those who do not '
                      'know?\u201d \u2014 Qur\u2019an 39:9',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMuted.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // The schools -----------------------------------------------------
              Text(AcademyStrings.get('academy.schoolsEyebrow'), style: AppText.eyebrow),
              const SizedBox(height: 10),
              _SchoolRow(
                icon: Icons.edit_outlined,
                arabic: '\u0627\u0644\u062d\u064f\u0631\u064f\u0648\u0641',
                title: AcademyStrings.get('school.letters.title'),
                subtitle: AcademyStrings.get('school.letters.body'),
                route: '/academy/letters',
                live: true,
              ),
              _SchoolRow(
                icon: Icons.graphic_eq,
                arabic: '\u0627\u0644\u062a\u0651\u064e\u0644\u064e\u0627\u0648\u064e\u0629',
                title: AcademyStrings.get('school.recitation.title'),
                subtitle: AcademyStrings.get('school.recitation.body'),
                route: '/academy/recitation',
                live: true,
              ),
              _SchoolRow(
                icon: Icons.menu_book_outlined,
                arabic: '\u0627\u0644\u0639\u064e\u0631\u064e\u0628\u0650\u064a\u064e\u0629 \u0627\u0644\u0642\u064f\u0631\u0670\u0646\u0650\u064a\u064e\u0629',
                title: AcademyStrings.get('school.quranicArabic.title'),
                subtitle: AcademyStrings.get('school.quranicArabic.body'),
                route: '/academy/quranic-arabic',
                live: true,
              ),
              _SchoolRow(
                icon: Icons.lightbulb_outline,
                arabic: '\u0627\u0644\u0641\u0650\u0642\u0647 \u0648\u064e\u0627\u0644\u0645\u064e\u0639\u0652\u0631\u0650\u0641\u064e\u0629',
                title: AcademyStrings.get('school.understanding.title'),
                subtitle: AcademyStrings.get('school.understanding.body'),
                route: '/academy/understanding',
                live: false,
              ),
              const SizedBox(height: 18),

              // The school's library --------------------------------------------
              Text('THE SCHOOL\u2019S LIBRARY', style: AppText.eyebrow),
              const SizedBox(height: 10),
              _LibraryRow(icon: Icons.auto_stories_outlined, title: 'Stories of the Prophets, the Women, the Seerah', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.bookmark_border, title: 'Daily Duas \u00b7 with Arabic', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.wb_twilight, title: 'Hadiths for Our Times', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.mic_none, title: 'Khutbahs for the classics and today', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.nightlight_round, title: 'Al-Ghayb \u00b7 the Unseen', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.menu_book_outlined, title: 'Huda \u00b7 worship guides', route: AppRoutes.huda),
              _LibraryRow(icon: Icons.account_tree_outlined, title: 'The Messengers\u2019 Tree \u00b7 lineage', route: AppRoutes.familyTree),
              _LibraryRow(icon: Icons.spa_outlined, title: 'The 99 Names \u00b7 memory deck', route: AppRoutes.names99),
              _LibraryRow(icon: Icons.favorite_border, title: 'For Your Heart \u00b7 guided by feeling', route: AppRoutes.feelings),
              _LibraryRow(icon: Icons.family_restroom_outlined, title: 'The Family Wing \u00b7 parents & progress', route: '/academy/family'),
              Text('THE PRACTICE ROOMS', style: AppText.eyebrow),
              const SizedBox(height: 10),
              _LibraryRow(icon: Icons.bookmark_border, title: 'The Hifz Planner \u00b7 memorization', route: '/academy/hifz'),
              _LibraryRow(icon: Icons.back_hand_outlined, title: 'The Dua School', route: '/academy/dua'),
              _LibraryRow(icon: Icons.graphic_eq, title: 'Recitation Audio Packs', route: '/academy/audio-packs'),
              _LibraryRow(icon: Icons.self_improvement, title: 'The Dhikr School', route: '/academy/dhikr'),
              _LibraryRow(icon: Icons.replay_outlined, title: 'Review Session \u00b7 spaced repetition', route: '/academy/review'),
              const SizedBox(height: 8),
              const SizedBox(height: 16),

              // Today strip ----------------------------------------------------
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _TodayStat(
                      label: AcademyStrings.get('academy.lessonsDone'),
                      value: '$done',
                    ),
                    _TodayStat(
                      label: AcademyStrings.get('academy.wordsReviewed'),
                      value: ref
                          .watch(wordsDueProvider)
                          .toString(),
                    ),
                    _TodayStat(
                      label: AcademyStrings.get('academy.ayatListened'),
                      value: '0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily verse -----------------------------------------------------
              GlassCard(
                onTap: () => context.go('/quran/39'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AcademyStrings.get('academy.dailyVerse'),
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 8),
                    Text(_verseText, style: AppText.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      '$_verseRef · ${AcademyStrings.get('academy.translationCredit')}',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progress(WidgetRef ref, AcademyLesson lesson) {
    final LessonProgress p = ref.watch(
      academyProgressProvider.select(
        (Map<String, LessonProgress> m) =>
            m[lesson.id] ?? const LessonProgress(),
      ),
    );
    final int total = lesson.steps.length;
    if (total == 0) return 0;
    final int idx = p.lastStep.clamp(0, total - 1);
    return p.completed ? 1 : (idx + 1) / total;
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.course});

  final AcademyCourse course;

  static const Map<String, IconData> _icons = <String, IconData>{
    'letters': Icons.edit_outlined,
    'recitation': Icons.graphic_eq,
    'quranic-arabic': Icons.abc,
    'understanding': Icons.account_tree_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final IconData icon = _icons[course.id] ?? Icons.menu_book_outlined;
    return GlassCard(
      onTap: course.available && course.units.isNotEmpty
          ? () => context.go('/academy/${course.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: AppColors.gold, size: 26),
          const SizedBox(height: 10),
          Text(
            AcademyStrings.get(course.titleKey),
            style: AppText.titleMedium.copyWith(color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              course.available
                  ? AcademyStrings.get(course.subtitleKey)
                  : AcademyStrings.get('academy.comingSoon'),
              style: AppText.bodyMuted,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  const _TodayStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: AppText.displayMedium.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppText.bodyMuted, textAlign: TextAlign.center),
      ],
    );
  }
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.icon,
    required this.arabic,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.live,
  });

  final IconData icon;
  final String arabic;
  final String title;
  final String subtitle;
  final String route;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => context.go(route),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, size: 19, color: AppColors.goldLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    arabic,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      color: Color(0xFFEAD9A8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMuted.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                ),
                child: Text('LIVE',
                    style: TextStyle(fontSize: 8.5, color: AppColors.goldLight)),
              )
            else
              Text('SOON',
                  style: TextStyle(
                      fontSize: 8.5,
                      color: AppColors.sand.withValues(alpha: 0.6))),
            const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => context.go(route),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 17, color: AppColors.goldLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppText.body.copyWith(fontSize: 13)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gold, size: 16),
          ],
        ),
      ),
    );
  }
}
