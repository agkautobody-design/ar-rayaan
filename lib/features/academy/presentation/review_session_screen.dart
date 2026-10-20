/// Review session — one card at a time, dignity-first.
///
/// Front: the word as it appears in the Quran + its ayah context.
/// Tap anywhere to flip: gloss, root, occurrences. Self-grade with
/// Again / Good / Easy — wrong-feeling taps reteach gently, nothing
/// is timed, nothing is red (Simplicity Charter).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/academy_providers.dart';
import '../application/academy_strings.dart';
import '../application/family_service.dart';
import '../application/sfx_provider.dart';
import '../application/word_deck_provider.dart';
import '../domain/academy_models.dart';
import '../domain/course_manifest.dart';
import '../domain/sfx.dart';
import '../domain/spaced_repetition.dart';
import '../domain/word_deck.dart';
import 'wasia_lessons.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState
    extends ConsumerState<ReviewSessionScreen> {
  // Cards graded in this sitting. The provider recomputes the session after
  // every grade (a graded card leaves it), so the card on screen is always
  // session.first; indexing by a counter used to skip every other card.
  int _graded = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final List<WordCard> session = ref.watch(todaySessionProvider);
    final List<ReviewCard> lessonDue = ref.watch(lessonReviewsDueProvider);

    // Lessons due for recall come first; when none are due the word deck
    // takes over. Both lists shrink as cards are graded.
    if (lessonDue.isNotEmpty) {
      return ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: AcademyStrings.get('academy.title')),
              const SizedBox(height: 4),
              Text(
                '${AcademyStrings.get('academy.lessonReviews')} · '
                '${lessonDue.length}',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _LessonReviewCard(
                key: ValueKey<String>(lessonDue.first.wordKey),
                card: lessonDue.first,
              ),
            ],
          ),
        ),
      );
    }

    return ScenicScaffold.pattern(
      body: SafeArea(
        child: session.isEmpty
            ? _EmptyState(onDone: () => Navigator.of(context).maybePop())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  ScreenHeader(
                    title: AcademyStrings.get('academy.title'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_graded + 1} / ${_graded + session.length}',
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _ReviewCardView(
                    card: session.first,
                    flipped: _flipped,
                    onFlip: () => setState(() => _flipped = !_flipped),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      for (final (ReviewGrade g, String label, IconData ic)
                          in <(ReviewGrade, String, IconData)>[
                        (ReviewGrade.again, 'Again', Icons.refresh),
                        (ReviewGrade.hard, 'Hard', Icons.trending_flat),
                        (ReviewGrade.good, 'Good', Icons.check),
                        (ReviewGrade.easy, 'Easy', Icons.auto_awesome),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _GradeButton(
                              label: label,
                              icon: ic,
                              onPressed: () => _grade(g),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _grade(ReviewGrade g) async {
    final List<WordCard> session = ref.read(todaySessionProvider);
    if (session.isEmpty) return;
    await SfxPlayer.play(Sfx.wordGraded, ref.read(soundSettingsProvider).tier);
    await ref
        .read(wordDeckProvider.notifier)
        .grade(session.first.key, g);
    if (!mounted) return;
    setState(() {
      _flipped = false;
      _graded++;
    });
  }
}

class _ReviewCardView extends StatelessWidget {
  const _ReviewCardView({
    required this.card,
    required this.flipped,
    required this.onFlip,
  });

  final WordCard card;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: GlassCard(
        strong: true,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: Column(
            children: <Widget>[
              SelectableText(
                card.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 44,
                  height: 1.4,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 10),
              if (card.sourceAyah != null)
                Text(
                  'Qur’an ${card.sourceAyah!.surah}:${card.sourceAyah!.ayah}',
                  style: AppText.caption,
                ),
              if (flipped) ...<Widget>[
                const Divider(height: 24),
                if (card.hasMeaning)
                  Text(card.gloss,
                      style: AppText.titleMedium, textAlign: TextAlign.center)
                else
                  Text(
                    card.sourceAyah != null
                        ? 'Meaning not verified yet \u2014 read this word in '
                            'its verse (${card.sourceAyah!.surah}:${card.sourceAyah!.ayah}).'
                        : 'Meaning not verified yet.',
                    style: AppText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                if (card.root != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Root: ${card.root}',
                      style: AppText.bodyMuted, textAlign: TextAlign.center),
                ],
                Text(
                  card.occurrences > 1
                      ? 'Appears ${card.occurrences} times in the Qur’an'
                      : 'Unique in the Qur’an',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ] else ...<Widget>[
                const SizedBox(height: 12),
                Text('Tap to reveal meaning',
                    style: AppText.caption, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Four buttons share one row (Again / Hard / Good / Easy), so the icon
    // sits above a short label instead of beside it.
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        minimumSize: const Size(0, 52),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          strong: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.auto_awesome,
                  color: AppColors.gold, size: 36),
              const SizedBox(height: 12),
              Text('All caught up', style: AppText.titleMedium),
              const SizedBox(height: 6),
              Text(
                'No words due today. Every step counts — no matter how small.',
                style: AppText.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onDone, child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
  }
}


/// One lesson due for recall: say what you remember, optionally re-open the
/// lesson, then grade yourself. Good/Easy marks the lesson mastered on this
/// device (and for the active child, in the Family Wing, if it is a letters
/// lesson); Again brings it back tomorrow. Nothing is ever a fail state.
class _LessonReviewCard extends ConsumerWidget {
  const _LessonReviewCard({super.key, required this.card});

  final ReviewCard card;

  String get _lessonId => card.wordKey;
  bool get _isLetters => _lessonId.startsWith('letters-');

  Future<void> _grade(WidgetRef ref, ReviewGrade g) async {
    await ref.read(reviewQueueProvider.notifier).grade(_lessonId, g);
    if (_isLetters &&
        (g == ReviewGrade.good || g == ReviewGrade.easy)) {
      final FamilyService fam = ref.read(familyServiceProvider);
      final String? child = await fam.activeChildId();
      if (child != null) await fam.recordMastery(child, _lessonId, 'mastered');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = _lessonId;
    String? route;
    final AcademyLesson? lesson = findLessonById(_lessonId);
    if (lesson != null) {
      title = AcademyStrings.get(lesson.titleKey);
      route = '/academy/lesson/${lesson.courseId}/${lesson.unitId}/${lesson.id}';
    } else if (_isLetters) {
      route = '/academy/letters/lesson/$_lessonId';
      final List<Lesson>? letters =
          ref.watch(lettersLessonsProvider).valueOrNull;
      if (letters != null) {
        for (final Lesson l in letters) {
          if (l.id == _lessonId) title = l.title;
        }
      }
    }
    final String? openRoute = route;
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppText.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Before you open it: say aloud what this lesson taught. '
            'Then check yourself and grade how it went.',
            style: AppText.bodyMuted.copyWith(height: 1.5),
          ),
          if (openRoute != null) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(openRoute),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open the lesson'),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              for (final (ReviewGrade g, String label, IconData ic)
                  in <(ReviewGrade, String, IconData)>[
                (ReviewGrade.again, 'Again', Icons.refresh),
                (ReviewGrade.hard, 'Hard', Icons.trending_flat),
                (ReviewGrade.good, 'Good', Icons.check),
                (ReviewGrade.easy, 'Easy', Icons.auto_awesome),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _GradeButton(
                      label: label,
                      icon: ic,
                      onPressed: () => _grade(ref, g),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
