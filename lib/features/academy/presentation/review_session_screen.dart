/// Review session — one card at a time, dignity-first.
///
/// Front: the word as it appears in the Quran + its ayah context.
/// Tap anywhere to flip: gloss, root, occurrences. Self-grade with
/// Again / Good / Easy — wrong-feeling taps reteach gently, nothing
/// is timed, nothing is red (Simplicity Charter).
library;

import 'dart:math';

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
import '../application/lessons_v3_provider.dart';
import '../application/recall_checks.dart';
import '../application/sfx_provider.dart';
import '../application/word_deck_provider.dart';
import '../domain/academy_models.dart';
import '../domain/assessment_engine.dart' show AssessmentItem;
import '../domain/course_manifest.dart';
import '../domain/letter_drills.dart' show LetterCardInfo;
import '../domain/letters_meta.dart';
import '../domain/recall_check.dart' show RecallCheckBuilder;
import '../domain/review_questions.dart';
import '../domain/sfx.dart';
import '../domain/spaced_repetition.dart';
import '../domain/v3/lesson_v3_model.dart' show LessonV3;
import '../domain/v3/lesson_v3_review.dart' show v3ReviewQuestions;
import '../domain/v3/lessons_v3.dart' show LessonsV3;
import '../domain/word_deck.dart';
import 'wasia_lessons.dart';
import '../../../app/theme/widgets/focus_safe_semantics.dart';

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
                key: ValueKey<String>(
                    '${lessonDue.first.wordKey}@${lessonDue.first.lastReviewed?.millisecondsSinceEpoch ?? 0}'),
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
                if (card.root != null && card.hasSource) ...<Widget>[
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


/// The questions a review of [lessonId] asks, or an empty list when the
/// lesson has no question of its own (the review is then a self-grade, and
/// says so).
///
///  * a manifest lesson asks the check it already ends with, hand-written or
///    generated;
///  * one of the 28 letter lessons asks about THAT letter (its name from its
///    shape, its shape from its name);
///  * the vowel, sukun, shaddah, tanween and joining lessons ask their own
///    quiz steps.
///
/// [letters] is the loaded Letters curriculum (null while it loads or in a
/// test that does not need it). [round] varies the order of the choices from
/// one review to the next.
List<ReviewQuestion> reviewQuestionsForLesson(
  String lessonId, {
  List<Lesson>? letters,
  int round = 0,
}) {
  final Random rng =
      Random(RecallCheckBuilder.seedOf('$lessonId#order#$round'));
  final AcademyLesson? manifest = findLessonById(lessonId);
  if (manifest != null) {
    final List<ReviewQuestion> out = <ReviewQuestion>[];
    for (final AcademyStep step in RecallChecks.stepsWithRecall(manifest)) {
      final String? id = step.assessmentId;
      if (step.kind != AcademyStepKind.check || id == null) continue;
      final List<AssessmentItem> items =
          RecallChecks.itemsFor(id) ?? const <AssessmentItem>[];
      for (final AssessmentItem item in items) {
        final ReviewQuestion q =
            ReviewQuestion.fromAssessment(item, AcademyStrings.get);
        if (q.isValid) out.add(q.shuffled(rng));
      }
    }
    return out;
  }
  final List<Lesson>? all = letters;
  if (all == null || !lessonId.startsWith('letters-')) {
    return const <ReviewQuestion>[];
  }
  final int? n = int.tryParse(lessonId.substring('letters-'.length));
  if (n == null) return const <ReviewQuestion>[];
  if (n >= 1 && n <= kLettersAlphabetCount) {
    final List<LetterCardInfo> alphabet = <LetterCardInfo>[];
    int index = -1;
    for (final Lesson l in all) {
      final int? ln = int.tryParse(l.id.replaceFirst('letters-', ''));
      if (ln == null || ln < 1 || ln > kLettersAlphabetCount) continue;
      LessonStep? card;
      for (final LessonStep s in l.steps) {
        if (s.type == 'card') {
          card = s;
          break;
        }
      }
      if (card == null) continue;
      if (l.id == lessonId) index = alphabet.length;
      alphabet.add(LetterCardInfo(card.arabic ?? '', card.translit ?? ''));
    }
    if (index < 0) return const <ReviewQuestion>[];
    return letterReviewQuestions(
      lessonId: lessonId,
      alphabet: alphabet,
      index: index,
      round: round,
    );
  }
  for (final Lesson l in all) {
    if (l.id != lessonId) continue;
    final List<ReviewQuestion> out = <ReviewQuestion>[];
    for (final LessonStep s in l.steps) {
      if (s.type != 'quiz') continue;
      final ReviewQuestion q = ReviewQuestion(
        prompt: s.question ?? '',
        glyph: s.glyph,
        options: s.options ?? const <String>[],
        answer: s.answer ?? -1,
        why: s.why ?? '',
      );
      if (q.isValid && q.prompt.isNotEmpty) out.add(q.shuffled(rng));
    }
    return out;
  }
  return const <ReviewQuestion>[];
}

/// One lesson due for review. The lesson's own question is asked and the
/// answers grade it (all right = Good, any miss = Again); only a lesson with
/// no question of its own is graded by the learner. Good marks the lesson
/// mastered on this device (and for the active child, in the Family Wing, if
/// it is a letters lesson); Again brings it back soon. Never a fail state.
class _LessonReviewCard extends ConsumerStatefulWidget {
  const _LessonReviewCard({super.key, required this.card});

  final ReviewCard card;

  @override
  ConsumerState<_LessonReviewCard> createState() => _LessonReviewCardState();
}

class _LessonReviewCardState extends ConsumerState<_LessonReviewCard> {
  int _q = 0;
  int? _picked;
  final List<bool> _results = <bool>[];
  bool _grading = false;

  String get _lessonId => widget.card.wordKey;
  bool get _isLetters => _lessonId.startsWith('letters-');

  Future<void> _grade(ReviewGrade g) async {
    if (_grading) return;
    _grading = true;
    await ref.read(reviewQueueProvider.notifier).grade(_lessonId, g);
    if (_isLetters && (g == ReviewGrade.good || g == ReviewGrade.easy)) {
      final FamilyService fam = ref.read(familyServiceProvider);
      final String? child = await fam.activeChildId();
      if (child != null) await fam.recordMastery(child, _lessonId, 'mastered');
    }
  }

  void _pick(int i, ReviewQuestion q) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      _results.add(i == q.answer);
    });
  }

  Future<void> _advance(int total) async {
    if (_q + 1 < total) {
      setState(() {
        _q++;
        _picked = null;
      });
      return;
    }
    await _grade(gradeForAnswers(_results));
  }

  @override
  Widget build(BuildContext context) {
    String title = _lessonId;
    String? route;
    final AcademyLesson? lesson = findLessonById(_lessonId);
    final AsyncValue<List<Lesson>> lettersAsync = _isLetters
        ? ref.watch(lettersLessonsProvider)
        : const AsyncValue<List<Lesson>>.data(<Lesson>[]);
    final List<Lesson>? letters = lettersAsync.valueOrNull;
    if (lesson != null) {
      title = AcademyStrings.get(lesson.titleKey);
      route = '/academy/lesson/${lesson.courseId}/${lesson.unitId}/${lesson.id}';
    } else if (_isLetters) {
      route = '/academy/letters/lesson/$_lessonId';
      if (letters != null) {
        for (final Lesson l in letters) {
          if (l.id == _lessonId) title = l.title;
        }
      }
    }
    final String? openRoute = route;
    // A v3 lesson asks its own hand-written check items (a few at a time, a
    // different few each round); FSRS still decides when it comes back.
    final AsyncValue<bool> hasV3 = ref.watch(hasLessonV3Provider(_lessonId));
    final bool isV3 = hasV3.valueOrNull ?? false;
    final AsyncValue<LessonsV3>? v3Async =
        isV3 ? ref.watch(lessonsV3Provider) : null;
    final LessonsV3? v3 = v3Async?.valueOrNull;
    final LessonV3? v3Lesson = v3?[_lessonId];
    final int round = widget.card.repetitions + widget.card.lapses;
    final bool loading = (_isLetters && lettersAsync.isLoading) ||
        hasV3.isLoading ||
        (v3Async?.isLoading ?? false);
    final List<ReviewQuestion> questions = loading
        ? const <ReviewQuestion>[]
        : (v3Lesson != null && v3 != null
            ? v3ReviewQuestions(v3Lesson, v3.resolver, round: round)
            : reviewQuestionsForLesson(
                _lessonId,
                letters: letters,
                round: round,
              ));
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppText.titleMedium),
          const SizedBox(height: 8),
          if (loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
          else if (questions.isEmpty)
            _selfGrade(openRoute)
          else
            _asking(questions, openRoute),
        ],
      ),
    );
  }

  Widget _openButton(String? openRoute) {
    if (openRoute == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () => context.push(openRoute),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Open the lesson'),
      ),
    );
  }

  /// A lesson with no question of its own: say so, then the four buttons.
  Widget _selfGrade(String? openRoute) {
    return Column(
      key: const Key('review-self-grade'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This lesson has no question of its own, so you grade it yourself. '
          'Say aloud what it taught, then choose how it went.',
          style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
        ),
        _openButton(openRoute),
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
                    onPressed: () => _grade(g),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _asking(List<ReviewQuestion> questions, String? openRoute) {
    final int at = _q.clamp(0, questions.length - 1);
    final ReviewQuestion q = questions[at];
    final int? picked = _picked;
    final bool last = at + 1 >= questions.length;
    return Column(
      key: const Key('review-question'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Question ${at + 1} of ${questions.length}',
            style: AppText.caption),
        const SizedBox(height: 8),
        Text(q.prompt,
            style: AppText.body.copyWith(
                fontSize: 16, height: 1.5, fontWeight: FontWeight.w600)),
        if ((q.glyph ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Center(
            child: Text(q.glyph!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 64,
                    color: Color(0xFFEAD9A8))),
          ),
        ],
        const SizedBox(height: 12),
        for (int o = 0; o < q.options.length; o++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FocusSafeSemantics(
              button: true,
              selected: picked == o,
              label: q.options[o],
              excludeSemantics: true,
              onTap: picked == null ? () => _pick(o, q) : null,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: Key('review-option-$o'),
                  onPressed: picked == null ? () => _pick(o, q) : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: BorderSide(
                      color: picked == null
                          ? AppColors.gold.withValues(alpha: 0.4)
                          : (o == q.answer
                              ? AppColors.gold
                              : AppColors.gold.withValues(alpha: 0.15)),
                      width: picked != null && o == q.answer ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    q.options[o],
                    textAlign: TextAlign.center,
                    style: quizOptionStyle(q.options[o]),
                  ),
                ),
              ),
            ),
          ),
        if (picked != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            picked == q.answer
                ? 'Correct, ma sha Allah! ${q.why}'
                : 'Not quite. ${q.why}',
            key: const Key('review-feedback'),
            style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('review-next'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => _advance(questions.length),
              child: Text(last ? 'Finish' : 'Next question'),
            ),
          ),
        ],
        _openButton(openRoute),
        const SizedBox(height: 10),
        Text(
          'Graded by your answers: every answer right marks the lesson as '
          'recalled; a miss brings it back soon.',
          style: AppText.caption,
        ),
      ],
    );
  }
}
