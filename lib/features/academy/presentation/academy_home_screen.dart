import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/academy_providers.dart';
import '../application/word_deck_provider.dart';
import '../application/academy_strings.dart';
import '../domain/academy_entry.dart';
import '../domain/academy_models.dart';
import '../domain/continue_hero.dart';
import '../domain/daily_verse.dart';
import 'wasia_lessons.dart' show Lesson, lettersLessonsProvider;
import 'widgets/course_browser.dart';
import 'widgets/parent_gate.dart';
import 'widgets/path_ux_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<AcademyCourse> courses = ref.watch(academyCoursesProvider);
    final AcademyCourse path = courses.firstWhere(
      (AcademyCourse c) => c.id == 'the-path',
    );
    
    final AcademyLesson? cont = ref.watch(continueLessonProvider);
    final ContinueHero hero = cont == null
        ? const ContinueHero(started: false, progress: 0)
        : _hero(ref, cont);
    final int done = ref.watch(lessonsDoneProvider);
    final String track = ref.watch(academyTrackProvider);
    final TrackLayout layout = TrackLayout.of(track);
    final AcademyDoor? door = ref.watch(academyDoorProvider);
    // First visit only: nobody has chosen a door and nothing is finished.
    final bool showDoor = door == null && done == 0;
    final String s = AcademyStrings.get(
        layout.simpleCopy ? 'child.title' : 'academy.title');
    final DailyVerse verse = dailyVerseFor(DateTime.now());

    final List<Widget> browse = <Widget>[
              // The schools -----------------------------------------------------
              Text(AcademyStrings.get('academy.schoolsEyebrow'), style: AppText.eyebrow),
              const SizedBox(height: 10),
              _SchoolRow(
                icon: Icons.route_outlined,
                arabic: '\u0627\u0644\u0637\u0651\u064e\u0631\u0650\u064a\u0642',
                title: AcademyStrings.get('path.title'),
                subtitle: AcademyStrings.get('path.subtitle'),
                route: courseRoute('the-path'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.edit_outlined,
                arabic: '\u0627\u0644\u062d\u064f\u0631\u064f\u0648\u0641',
                title: AcademyStrings.get('school.letters.title'),
                subtitle: AcademyStrings.get('school.letters.subtitle'),
                route: '/academy/letters',
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.back_hand_outlined,
                arabic: '\u0627\u0644\u062f\u0651\u064f\u0639\u0627\u0621',
                title: AcademyStrings.get('school.dua.title'),
                subtitle: AcademyStrings.get('school.dua.body'),
                route: '/academy/dua',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.translate,
                arabic: '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
                title: AcademyStrings.get('school.arabiclang.title'),
                subtitle: AcademyStrings.get('school.arabiclang.body'),
                route: courseRoute('arabic-language'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.auto_stories,
                arabic: '\u0627\u0644\u062d\u0641\u0638',
                title: AcademyStrings.get('school.hifz.title'),
                subtitle: AcademyStrings.get('school.hifz.body'),
                route: courseRoute('hifz'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.brightness_5,
                arabic: 'العقيدة',
                title: AcademyStrings.get('school.aqeedah.title'),
                subtitle: AcademyStrings.get('school.aqeedah.body'),
                route: courseRoute('aqeedah'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.menu_book,
                arabic: 'الحديث',
                title: AcademyStrings.get('school.hadith.title'),
                subtitle: AcademyStrings.get('school.hadith.body'),
                route: '/academy/hadith',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.route,
                arabic: 'السيرة',
                title: AcademyStrings.get('school.seerah.title'),
                subtitle: AcademyStrings.get('school.seerah.body'),
                route: '/academy/seerah',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.account_balance,
                arabic: 'التاريخ',
                title: AcademyStrings.get('school.history.title'),
                subtitle: AcademyStrings.get('school.history.body'),
                route: '/academy/history',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.auto_stories_outlined,
                arabic: 'القصص',
                title: AcademyStrings.get('school.stories.title'),
                subtitle: AcademyStrings.get('school.stories.body'),
                route: '/academy/stories',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.favorite_outline,
                arabic: 'الأخلاق',
                title: AcademyStrings.get('school.character.title'),
                subtitle: AcademyStrings.get('school.character.body'),
                route: courseRoute('character'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.home_outlined,
                arabic: 'الأسرة',
                title: AcademyStrings.get('school.family.title'),
                subtitle: AcademyStrings.get('school.family.body'),
                route: courseRoute('family'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.school_outlined,
                arabic: 'الشباب',
                title: AcademyStrings.get('school.youth.title'),
                subtitle: AcademyStrings.get('school.youth.body'),
                route: courseRoute('youth'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.woman,
                arabic: 'النساء',
                title: AcademyStrings.get('school.womens.title'),
                subtitle: AcademyStrings.get('school.womens.body'),
                route: courseRoute('womens'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.payments_outlined,
                arabic: 'المعاملات',
                title: AcademyStrings.get('school.transactions.title'),
                subtitle: AcademyStrings.get('school.transactions.body'),
                route: courseRoute('transactions'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.wb_twilight,
                arabic: 'آخر العمر',
                title: AcademyStrings.get('school.endoflife.title'),
                subtitle: AcademyStrings.get('school.endoflife.body'),
                route: courseRoute('endoflife'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.record_voice_over,
                arabic: 'الدعوة',
                title: AcademyStrings.get('school.dawah.title'),
                subtitle: AcademyStrings.get('school.dawah.body'),
                route: courseRoute('dawah'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.healing,
                arabic: 'الصحة',
                title: AcademyStrings.get('school.health.title'),
                subtitle: AcademyStrings.get('school.health.body'),
                route: courseRoute('health'),
                kind: _RowKind.lessons,
              ),
              _SchoolRow(
                icon: Icons.shield_outlined,
                arabic: 'حصن المسلم',
                title: AcademyStrings.get('hisn.title'),
                subtitle: AcademyStrings.get('hisn.body'),
                route: '/academy/hisn',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.directions_walk,
                arabic: 'الحج',
                title: AcademyStrings.get('hajjpack.title'),
                subtitle: AcademyStrings.get('hajjpack.body'),
                route: '/academy/hajj-umrah-pack',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.nightlight_round,
                arabic: 'رمضان',
                title: AcademyStrings.get('ramadan.title'),
                subtitle: AcademyStrings.get('ramadan.body'),
                route: '/academy/ramadan-mode',
                kind: _RowKind.tool,
              ),
              _SchoolRow(
                icon: Icons.style,
                arabic: 'الآيات',
                title: AcademyStrings.get('versecards.title'),
                subtitle: AcademyStrings.get('versecards.body'),
                route: '/share',
                kind: _RowKind.tool,
              ),
              _SchoolRow(
                icon: Icons.quiz_outlined,
                arabic: 'الأسئلة',
                title: AcademyStrings.get('qabank.title'),
                subtitle: AcademyStrings.get('qabank.body'),
                route: '/academy/qa',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.graphic_eq,
                arabic: '\u0627\u0644\u062a\u0651\u064e\u0644\u064e\u0627\u0648\u064e\u0629',
                title: AcademyStrings.get('school.recitation.title'),
                subtitle: AcademyStrings.get('school.recitation.subtitle'),
                route: '/academy/recitation',
                kind: _RowKind.reading,
              ),
              _SchoolRow(
                icon: Icons.lightbulb_outline,
                arabic: '\u0627\u0644\u0641\u0650\u0642\u0647 \u0648\u064e\u0627\u0644\u0645\u064e\u0639\u0652\u0631\u0650\u0641\u064e\u0629',
                title: AcademyStrings.get('school.understanding.title'),
                subtitle: AcademyStrings.get('school.understanding.subtitle'),
                route: courseRoute('understanding'),
                kind: _RowKind.lessons,
              ),
              const SizedBox(height: 18),

              // Every manifest lesson, by course ------------------------------
              Text('COURSES \u00b7 LESSON BY LESSON', style: AppText.eyebrow),
              const SizedBox(height: 10),
              const CourseBrowser(),
              const SizedBox(height: 18),

              // The school's library --------------------------------------------
              Text('THE SCHOOL\u2019S LIBRARY', style: AppText.eyebrow),
              const SizedBox(height: 10),
              _LibraryRow(icon: Icons.auto_stories_outlined, title: 'Stories of the Prophets, the Women, the Seerah', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.bookmark_border, title: 'Daily Duas \u00b7 with Arabic (Stories shelf)', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.wb_twilight, title: 'Hadiths for Our Times (Stories shelf)', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.mic_none, title: 'Khutbahs for the classics and today (Stories shelf)', route: AppRoutes.stories),
              _LibraryRow(icon: Icons.nightlight_round, title: 'Al-Ghayb \u00b7 the Unseen (Stories shelf)', route: AppRoutes.stories),
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
    ];

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              // No Settings gear on the Child track: Settings holds account
              // deletion and the AI switches.
              ScreenHeader(title: s, showSettings: !layout.simpleCopy),
              const _TrackSwitcher(),
              const SizedBox(height: 8),
              if (layout.familyCard && !showDoor) ...<Widget>[
                const _FamilyCard(),
                const SizedBox(height: 12),
              ],

              // Continue hero -------------------------------------------------
              if (showDoor)
                const _FrontDoorCard()
              else if (layout.lettersFirst)
                const _LettersHero()
              else if (cont != null)
                GlassCard(
                  strong: true,
                  onTap: () => context.go(
                    '/academy/lesson/${cont.courseId}/${cont.unitId}/${cont.id}',
                  ),
                  semanticsLabel:
                      '${AcademyStrings.get(hero.started ? 'academy.continue' : 'academy.startHere')}: '
                      '${AcademyStrings.get(cont.titleKey)}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AcademyStrings.get(hero.started
                            ? 'academy.continue'
                            : 'academy.startHere'),
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
                          value: hero.progress,
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
              const SizedBox(height: 12),
              const WeeklyRhythmCard(),
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
                      '\u0642\u064f\u0644\u0652 \u0647\u064e\u0644\u0652 \u064a\u064e\u0633\u0652\u062a\u064e\u0648\u0650\u064a \u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e \u0648\u064e\u0627\u0644\u0651\u064e\u0630\u0650\u064a\u0646\u064e \u0644\u0627 \u064a\u064e\u0639\u0652\u0644\u064e\u0645\u064f\u0648\u0646\u064e',
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
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (layout.foldSchools)
                _MoreSchools(children: browse)
              else
                ...browse,

              // Today strip ----------------------------------------------------
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _TodayStat(
                      label: AcademyStrings.get(layout.simpleCopy
                          ? 'child.today.done'
                          : 'academy.lessonsDone'),
                      value: '$done',
                    ),
                    if (!layout.simpleCopy)
                      _TodayStat(
                        label: AcademyStrings.get('academy.wordsDue'),
                        value: ref
                            .watch(wordsDueProvider)
                            .toString(),
                      ),
                    _TodayStat(
                      label: AcademyStrings.get(layout.simpleCopy
                          ? 'child.today.review'
                          : 'academy.reviewsDue'),
                      value: ref
                          .watch(lessonReviewsDueProvider)
                          .length
                          .toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily verse -----------------------------------------------------
              GlassCard(
                onTap: () => context.go('/quran/${verse.surah}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AcademyStrings.get('academy.dailyVerse'),
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 8),
                    Text('\u201c${verse.text}\u201d',
                        style: AppText.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Qur\u2019an ${verse.ref} · ${AcademyStrings.get('academy.translationCredit')}',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ContinueHero _hero(WidgetRef ref, AcademyLesson lesson) {
    final LessonProgress? saved = ref.watch(
      academyProgressProvider.select(
        (Map<String, LessonProgress> m) => m[lesson.id],
      ),
    );
    return continueHeroFor(saved, lesson.steps.length);
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

/// What a school row really is. Every row used to say LIVE, including pages
/// that only show text and keep no progress.
enum _RowKind {
  /// Tracked lessons with questions and saved progress.
  lessons('LESSONS'),

  /// A page to read. No questions, no saved progress.
  reading('READ'),

  /// An interactive tool (planner, mode, card maker), not a course.
  tool('TOOL');

  const _RowKind(this.label);
  final String label;
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({
    required this.icon,
    required this.arabic,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.kind,
  });

  final IconData icon;
  final String arabic;
  final String title;
  final String subtitle;
  final String route;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => context.go(route),
        semanticsLabel: '$title, ${kind.label.toLowerCase()}. $subtitle',
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
                    style: AppText.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
              ),
              child: Text(kind.label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.goldLight)),
            ),
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

/// Three tracks, one school system. The track changes what the home page
/// shows (a child sees the next letter first and the other schools folded
/// away; a parent sees the Family Wing first). On the Child track the other
/// schools and the other tracks open only after the parent check; on the
/// Teen and Parent tracks every school is open.
class _TrackSwitcher extends ConsumerWidget {
  const _TrackSwitcher();

  static const List<String> _tracks = <String>['child', 'teen', 'parent'];

  /// Switching TO the Child track is free; switching away from it is for a
  /// grown-up, so it asks the parent check first.
  static Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    String current,
    String next,
  ) async {
    if (next == current) return;
    if (current == 'child' && !await requireParent(context, ref)) return;
    await ref.read(academyTrackProvider.notifier).set(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String current = ref.watch(academyTrackProvider);
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border:
                  Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: <Widget>[
                for (final String t in _tracks)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: current == t,
                      label: '${AcademyStrings.get('track.eyebrow')}: '
                          '${AcademyStrings.get('track.$t')}',
                      excludeSemantics: true,
                      onTap: () => unawaited(_choose(context, ref, current, t)),
                      child: InkWell(
                        key: Key('track-$t'),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () =>
                            unawaited(_choose(context, ref, current, t)),
                        child: AnimatedContainer(
                          duration: still
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          constraints: const BoxConstraints(minHeight: 48),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: current == t
                                ? AppColors.gold.withValues(alpha: 0.9)
                                : Colors.transparent,
                          ),
                          child: Text(
                            AcademyStrings.get('track.$t'),
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(
                              fontSize: 14,
                              color: current == t ? AppColors.night : null,
                              fontWeight: current == t
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(AcademyStrings.get('track.hint'), style: AppText.caption),
        ],
      ),
    );
  }
}

/// The first-visit card: three plain doors instead of a long page.
class _FrontDoorCard extends ConsumerWidget {
  const _FrontDoorCard();

  Future<void> _go(BuildContext context, WidgetRef ref, AcademyDoor d) async {
    await ref.read(academyDoorProvider.notifier).choose(d);
    final String? route = d.route;
    if (route != null && context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AcademyDoor? suggested;
    try {
      suggested = suggestedDoor(
          ref.read(sharedPreferencesProvider).getString('ar.need'));
    } catch (_) {}
    Widget door(AcademyDoor d, String titleKey, String bodyKey, Key key) {
      final bool primary = d == suggested;
      final String title = AcademyStrings.get(titleKey);
      final String body = AcademyStrings.get(bodyKey);
      final Widget label = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppText.label.copyWith(
              color: primary ? AppColors.night : AppColors.goldLight)),
          Text(body, style: AppText.caption.copyWith(
              color: primary ? AppColors.night : null)),
        ],
      );
      final ButtonStyle style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 56)),
        alignment: Alignment.centerLeft,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: primary
              ? FilledButton(
                  key: key,
                  style: style.merge(FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.night,
                  )),
                  onPressed: () => _go(context, ref, d),
                  child: label,
                )
              : OutlinedButton(
                  key: key,
                  style: style,
                  onPressed: () => _go(context, ref, d),
                  child: label,
                ),
        ),
      );
    }

    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(AcademyStrings.get('door.title'),
                style: AppText.titleMedium),
          ),
          const SizedBox(height: 12),
          door(AcademyDoor.newToIslam, 'door.new', 'door.newBody',
              const Key('door-new')),
          door(AcademyDoor.myChild, 'door.child', 'door.childBody',
              const Key('door-child')),
          door(AcademyDoor.returning, 'door.returning', 'door.returningBody',
              const Key('door-returning')),
          Text(AcademyStrings.get('door.note'), style: AppText.caption),
        ],
      ),
    );
  }
}

/// The child's home starts here: the next unfinished Letters lesson.
class _LettersHero extends ConsumerWidget {
  const _LettersHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Lesson> list =
        ref.watch(lettersLessonsProvider).valueOrNull ?? const <Lesson>[];
    final Map<String, LessonProgress> progress =
        ref.watch(academyProgressProvider);
    final String? nextId = firstUnfinishedLetterLesson(
      <String>[for (final Lesson l in list) l.id],
      progress,
    );
    final bool started =
        list.any((Lesson l) => progress[l.id]?.completed ?? false);
    final bool allDone = list.isNotEmpty && nextId == null;
    String? nextTitle;
    for (final Lesson l in list) {
      if (l.id == nextId) nextTitle = l.title;
    }
    final String heading = allDone
        ? AcademyStrings.get('child.lettersDone')
        : AcademyStrings.get(
            started ? 'child.lettersContinue' : 'child.lettersStart');
    return GlassCard(
      key: const Key('letters-hero'),
      strong: true,
      onTap: () => context.go(nextId == null
          ? '/academy/letters'
          : '/academy/letters/lesson/$nextId'),
      semanticsLabel:
          nextTitle == null ? heading : '$heading. $nextTitle',
      child: Row(
        children: <Widget>[
          const Icon(Icons.edit_outlined, color: AppColors.gold, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AcademyStrings.get('child.lettersTitle'),
                    style: AppText.caption),
                const SizedBox(height: 4),
                Text(heading, style: AppText.titleMedium),
                if (nextTitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(nextTitle,
                      style: AppText.bodyMuted.copyWith(fontSize: 14)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
  }
}

/// A parent's home starts with the Family Wing.
class _FamilyCard extends StatelessWidget {
  const _FamilyCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const Key('family-card'),
      onTap: () => context.go('/academy/family'),
      semanticsLabel: '${AcademyStrings.get('parent.familyTitle')}. '
          '${AcademyStrings.get('parent.familyBody')}',
      child: Row(
        children: <Widget>[
          const Icon(Icons.family_restroom_outlined,
              color: AppColors.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AcademyStrings.get('parent.familyTitle'),
                    style: AppText.titleMedium),
                const SizedBox(height: 4),
                Text(AcademyStrings.get('parent.familyBody'),
                    style: AppText.bodyMuted.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gold),
        ],
      ),
    );
  }
}

/// Every other school, folded behind one row on the child track. Opening the
/// row needs the parent check (the rows lead to adult material: marriage,
/// transactions, end of life, and so on).
class _MoreSchools extends ConsumerStatefulWidget {
  const _MoreSchools({required this.children});

  final List<Widget> children;

  @override
  ConsumerState<_MoreSchools> createState() => _MoreSchoolsState();
}

class _MoreSchoolsState extends ConsumerState<_MoreSchools> {
  bool _open = false;

  Future<void> _toggle() async {
    if (_open) {
      setState(() => _open = false);
      return;
    }
    if (!await requireParent(context, ref)) return;
    if (!mounted) return;
    setState(() => _open = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GlassCard(
          key: const Key('more-schools'),
          onTap: () => unawaited(_toggle()),
          semanticsLabel: '${AcademyStrings.get('child.more')}. '
              '${AcademyStrings.get('child.moreBody')}',
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AcademyStrings.get('child.more'),
                        style: AppText.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(AcademyStrings.get('child.moreBody'),
                        style: AppText.caption),
                  ],
                ),
              ),
              Icon(
                _open ? Icons.expand_less : Icons.lock_outline,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
        if (_open) ...widget.children,
      ],
    );
  }
}
