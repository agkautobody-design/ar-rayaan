import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/needs_internet_view.dart';
import '../../../app/theme/widgets/not_found_view.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/academy_providers.dart';
import '../application/child_age_band.dart';
import '../application/family_service.dart';
import '../application/wasia_controller.dart';
import '../domain/academy_models.dart' show LessonProgress;
import '../domain/letter_drills.dart';
import '../domain/letters_meta.dart';
import 'widgets/active_child_banner.dart';
import 'widgets/path_ux_widgets.dart';
import 'widgets/wasia_thread.dart';

class LessonStep {
  final String type;
  final String? text;
  final String? arabic;
  final String? translit;
  final String? note;
  final String? question;
  final List<String>? options;
  final int? answer;
  final String? why;

  /// A big letter shown above a quiz's options (generated drills only).
  final String? glyph;
  const LessonStep({required this.type, this.text, this.arabic, this.translit,
      this.note, this.question, this.options, this.answer, this.why,
      this.glyph});

  factory LessonStep.fromJson(Map<String, dynamic> j) => LessonStep(
        type: j['type'] as String,
        text: j['text'] as String?,
        arabic: j['arabic'] as String?,
        translit: j['translit'] as String?,
        note: j['note'] as String?,
        question: j['question'] as String?,
        options: (j['options'] as List<dynamic>?)?.cast<String>(),
        answer: j['answer'] as int?,
        why: j['why'] as String?,
      );
}

class Lesson {
  final String id, title, arabic;
  final List<LessonStep> steps;
  const Lesson({required this.id, required this.title, required this.arabic,
      required this.steps});
  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: j['title'] as String,
        arabic: j['arabic'] as String,
        steps: (j['steps'] as List<dynamic>)
            .map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final lettersCurriculumProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final raw =
      await rootBundle.loadString('assets/academy/letters_curriculum.json');
  Map<String, dynamic>? v2;
  try {
    v2 = json.decode(await rootBundle
            .loadString('assets/academy/letters_v2_curriculum.json'))
        as Map<String, dynamic>;
  } catch (_) {
    v2 = null; // units 1-4 still work on their own
  }
  return mergeLettersCurriculum(json.decode(raw) as Map<String, dynamic>, v2);
});

final lettersLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final data = await ref.watch(lettersCurriculumProvider.future);
  return withLetterDrills([
    for (final u in data['units'] as List<dynamic>)
      for (final l in u['lessons'] as List<dynamic>)
        Lesson.fromJson(l as Map<String, dynamic>),
  ]);
});

/// The 28 letter lessons end with one question that can be answered by
/// looking at the card two steps earlier ("Which letter did we meet
/// today?"). Replace it with [buildLetterDrills]: today's letter, then
/// earlier letters coming back. Every other lesson is returned untouched.
List<Lesson> withLetterDrills(List<Lesson> lessons) {
  final List<LetterCardInfo> alphabet = <LetterCardInfo>[];
  final Map<String, int> indexOf = <String, int>{};
  for (final Lesson l in lessons) {
    final bool trivial = l.steps.any((LessonStep s) =>
        s.type == 'quiz' && s.question == kTrivialLetterQuestion);
    final LessonStep? card =
        l.steps.where((LessonStep s) => s.type == 'card').firstOrNull;
    if (!trivial || card == null) continue;
    indexOf[l.id] = alphabet.length;
    alphabet.add(LetterCardInfo(card.arabic ?? '', card.translit ?? ''));
  }
  return <Lesson>[
    for (final Lesson l in lessons)
      if (indexOf.containsKey(l.id))
        Lesson(
          id: l.id,
          title: l.title,
          arabic: l.arabic,
          steps: <LessonStep>[
            for (final LessonStep s in l.steps)
              if (s.type == 'quiz' && s.question == kTrivialLetterQuestion)
                for (final LetterDrill d in buildLetterDrills(
                    lessonId: l.id,
                    alphabet: alphabet,
                    index: indexOf[l.id]!))
                  LessonStep(
                    type: 'quiz',
                    question: d.question,
                    glyph: d.glyph,
                    options: d.options,
                    answer: d.answer,
                    why: d.why,
                  )
              else
                s,
          ],
        )
      else
        l,
  ];
}

/// The School of Letters — a path of lessons, each taught by Wasia.
class LettersLessonsScreen extends ConsumerWidget {
  const LettersLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lettersCurriculumProvider);
    // Device-level completion: a tick on every letter lesson finished here,
    // whether or not a child is active in the Family Wing.
    // The ticks are decoration: if device storage is not wired (a bare test
    // harness) the list still renders, just without them.
    Map<String, LessonProgress> progress = const <String, LessonProgress>{};
    try {
      progress = ref.watch(academyProgressProvider);
    } catch (_) {}
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: lessons.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load the lessons.', style: AppText.bodyMuted)),
        data: (data) {
          final units = data['units'] as List<dynamic>;
          final exams = (data['exams'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: 'School of Letters', close: true),
            Text('مَدْرَسَةُ الْحُرُوفِ',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 26,
                    color: Color(0xFFEAD9A8))),
            const SizedBox(height: 4),
            Center(child: Text('THE FULL CURRICULUM \u00b7 TAUGHT BY WASIA',
                style: AppText.eyebrow)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Seven units: the twenty-eight letters, then vowels, sukun, shaddah, tanween and joining, with an exam at the end of each unit. '
                'Wasia teaches every lesson and asks a gentle question. When a child is chosen, finished lessons and exams are saved to them.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
            ),
            const SizedBox(height: 16),
            const ActiveChildBanner(),
            const PlacementQuizCard(),
            const SizedBox(height: 12),
            for (final u in units)
              ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Text((u['title'] as String).toUpperCase(),
                      style: AppText.eyebrow),
                ),
                for (final l in (u['lessons'] as List<dynamic>))
                  Builder(builder: (ctx) {
                    final lesson =
                        Lesson.fromJson(l as Map<String, dynamic>);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () =>
                            context.go('/academy/letters/lesson/${lesson.id}'),
                        child: Row(
                          children: [
                            Container(
                              width: 46, height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.4)),
                              ),
                              child: Text(lesson.arabic,
                                  style: const TextStyle(fontFamily: 'Amiri',
                                      fontSize: 22, color: Color(0xFFEAD9A8))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: arabicAwareText(lesson.title, AppText.body.copyWith(
                                fontSize: 13.5, fontWeight: FontWeight.w600))),
                            if (progress[lesson.id]?.completed ?? false)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_circle_outline,
                                    color: AppColors.goldLight, size: 18),
                              ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.gold, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ...exams.where((e) => e['unit'] == u['id']).map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () => context.go('/academy/exam/${e['id']}'),
                      child: Row(children: [
                        const Icon(Icons.fact_check_outlined,
                            color: AppColors.goldLight, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] as String,
                                style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 13.5)),
                            Text('${(e['questions'] as List<dynamic>).length} questions \u00b7 pass at ${e['pass']} \u00b7 your best is kept (with the active child, or on this device)',
                                style: AppText.bodyMuted.copyWith(fontSize: 12)),
                          ],
                        )),
                        const Icon(Icons.chevron_right,
                            color: AppColors.gold, size: 18),
                      ]),
                    ),
                  )),
              ],
          ],
        );
        },
      ),
    );
  }
}

/// One lesson: Wasia's script, step by step, with a live Ask-Wasia box.
class LessonRunnerScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonRunnerScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonRunnerScreen> createState() => _LessonRunnerState();
}

class _LessonRunnerState extends ConsumerState<LessonRunnerScreen> {
  int _step = 0;
  int? _picked;
  // The current quiz is answered correctly. A wrong pick can be retried, so
  // nobody gets past a question by skipping it or by guessing once.
  bool _solved = false;

  /// Ask Wasia is open on a step that is not the last.
  bool _askOpen = false;

  /// The active child's age band (parent-set), which decides how much of a
  /// teaching step is shown at first. Read once; nothing else is read.
  String _band = ChildAgeBand.fallback;

  /// The step whose full text the child has asked for ("Tell me more").
  int _moreFor = -1;

  @override
  void initState() {
    super.initState();
    ChildAgeBand.active().then((String b) {
      if (mounted) setState(() => _band = b);
    });
  }
  // True once any quiz in this run was answered wrongly (drives 'walked').
  bool _quizMissed = false;
  bool _finishing = false;

  /// Record the lesson: device-level progress + review queue always, and
  /// the Family Wing (lesson done + mastery 'met', plus 'walked' when every
  /// quiz was right) for the active child. Without this nothing a child
  /// finished was ever stored.
  Future<void> _finish(Lesson lesson, {String? nextId}) async {
    if (_finishing) return;
    _finishing = true;
    await ref.read(academyProgressProvider.notifier).complete(lesson.id);
    ref.read(reviewQueueProvider.notifier).addLesson(lesson.id);
    try {
      final FamilyService fam = ref.read(familyServiceProvider);
      final String? child = await fam.activeChildId();
      if (child != null) {
        await fam.markLessonDone(child, lesson.id, quizCorrect: !_quizMissed);
        await fam.recordMastery(child, lesson.id, 'met');
        if (!_quizMissed) await fam.recordMastery(child, lesson.id, 'walked');
        ref.invalidate(progressProvider);
      }
    } catch (_) {
      // The device-level record above is already saved; never trap the
      // learner on the last step because the family record failed.
    }
    if (!mounted) return;
    // Lesson to lesson REPLACES the page (and its browser history entry):
    // with go() every lesson added an entry, so getting back to the list
    // took one Back press per lesson done.
    if (nextId == null) {
      context.go('/academy/letters');
    } else {
      context.pushReplacement('/academy/letters/lesson/$nextId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lettersLessonsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: lessons.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Column(children: [
          const ScreenHeader(title: 'Lesson', close: true),
          Expanded(
            child: NeedsInternetView(
              what: 'This lesson',
              onRetry: () => ref.invalidate(lettersLessonsProvider),
            ),
          ),
        ]),
        data: (list) {
          final lesson = list.where((l) => l.id == widget.lessonId).firstOrNull;
          if (lesson == null) {
            return const NotFoundView(
              message: 'That lesson is not here.',
              title: 'Lesson',
            );
          }
          final steps = lesson.steps;
          final current = steps[_step];
          final last = _step == steps.length - 1;
          final int at = list.indexWhere((Lesson l) => l.id == lesson.id);
          final String? nextId =
              at >= 0 && at + 1 < list.length ? list[at + 1].id : null;
          // A quiz must be answered correctly before the lesson moves on.
          final bool blocked = current.type == 'quiz' && !_solved;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // The header holds a short fixed title; the lesson's own (long)
              // title is written in full below, so it is never clipped.
              const ScreenHeader(title: 'Letters lesson', close: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: arabicAwareText(lesson.title, AppText.titleMedium),
              ),
              const ActiveChildBanner(),
              Row(children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(height: 3,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                        color: i <= _step ? AppColors.gold
                            : AppColors.sand.withValues(alpha: 0.18))),
                  )),
              ]),
              const SizedBox(height: 16),
              if (current.type == 'teach')
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text('WASIA \u00b7 YOUR TEACHER', style: AppText.eyebrow)),
                        SpeakButton(
                          text: current.text ?? '',
                          minTapTarget: SpeakButton.minTarget,
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Builder(builder: (BuildContext _) {
                        final String full = current.text ?? '';
                        final String shown = _moreFor == _step
                            ? full
                            : ageFitTeaching(full, _band);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(shown,
                                style: AppText.body.copyWith(height: 1.65, fontSize: 14.5)),
                            if (shown.length < full.length)
                              TextButton(
                                key: const Key('lesson-tell-me-more'),
                                onPressed: () => setState(() => _moreFor = _step),
                                child: const Text('Tell me more'),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                )
              else if (current.type == 'card')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Column(children: [
                    Text(current.arabic ?? '',
                        semanticsLabel: current.translit ?? '',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 64,
                            color: Color(0xFFEAD9A8))),
                    const SizedBox(height: 8),
                    Text(current.translit ?? '', style: AppText.titleMedium),
                    if ((current.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(current.note!, textAlign: TextAlign.center,
                          style: AppText.bodyMuted),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Text('SAY IT OUT LOUD', style: AppText.eyebrow.copyWith(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_step <= 1
                            ? 'Look at the shape and say its name out loud, slowly. A teacher you trust can say it with you.'
                            : 'Now say the sound again, in your own time. Say it with someone if you can.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5)),
                      ]),
                    ),
                  ]),
                )
              else if (current.type == 'quiz')
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WASIA ASKS', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text(current.question ?? '', style: AppText.body.copyWith(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                      if ((current.glyph ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(current.glyph!,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(fontFamily: 'Amiri',
                                  fontSize: 64, color: Color(0xFFEAD9A8))),
                        ),
                      ],
                      const SizedBox(height: 12),
                      for (var o = 0; o < (current.options?.length ?? 0); o++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            semanticsLabel:
                                'Answer ${o + 1}: ${current.options![o]}',
                            onTap: _solved
                                ? null
                                : () => setState(() {
                                      _picked = o;
                                      if (o == current.answer) {
                                        _solved = true;
                                      } else {
                                        _quizMissed = true;
                                      }
                                    }),
                            child: Row(children: [
                              Expanded(child: Text(current.options![o],
                                  key: Key('quiz-option-$o'),
                                  textAlign: TextAlign.center,
                                  style: quizOptionStyle(current.options![o]))),
                            ]),
                          ),
                        ),
                      if (_picked != null) ...[
                        const SizedBox(height: 6),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _solved
                                ? 'Correct, ma sha Allah! ${current.why ?? ''}'
                                : 'Not quite \u2014 look again and try once more.',
                            key: const Key('quiz-feedback'),
                            style: AppText.bodyMuted
                                .copyWith(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              // Room between the card and the button: the next step's answer
              // options appear under the card, and a quick second tap on Next
              // must not land on one of them.
              const SizedBox(height: 28),
              if (!blocked)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      FilledButton.icon(
                        key: const Key('lesson-next'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.night,
                          minimumSize: const Size(160, 52),
                        ),
                        onPressed: () {
                          if (last) {
                            _finish(lesson);
                            return;
                          }
                          setState(() {
                            _picked = null;
                            _solved = false;
                            _step++;
                          });
                        },
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        label: Text(
                          last ? 'Finish' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (last && nextId != null)
                        TextButton.icon(
                          key: const Key('finish-next-lesson'),
                          onPressed: () => _finish(lesson, nextId: nextId),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.skip_next,
                              size: 16, color: AppColors.gold),
                          label: Text('Finish and go to the next lesson',
                              style: AppText.bodyMuted),
                        ),
                    ],
                  ),
                ),
              if (last || _askOpen)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASK WASIA', style: AppText.eyebrow),
                        const SizedBox(height: 6),
                        const WasiaAiCaption(),
                        const WasiaAskBox(),
                      ],
                    ),
                  ),
                ),
              // Any step, not only the last: a child can ask when the
              // question comes, and the box can be put away again.
              if (!last)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('lesson-ask-wasia-toggle'),
                    onPressed: () => setState(() => _askOpen = !_askOpen),
                    icon: Icon(
                      _askOpen ? Icons.expand_less : Icons.chat_bubble_outline,
                      size: 18,
                    ),
                    label: Text(_askOpen ? 'Hide Ask Wasia' : 'Ask Wasia a question'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// What the Ask Wasia box says about the AI, true to the parent's switch: off
/// means Wasia answers only from her lesson shelf, on this device.
class WasiaAiCaption extends StatefulWidget {
  const WasiaAiCaption({this.inLesson = true, super.key});

  /// False on the Kids Corner page, where there is no lesson open.
  final bool inLesson;

  @override
  State<WasiaAiCaption> createState() => WasiaAiCaptionState();
}

class WasiaAiCaptionState extends State<WasiaAiCaption> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    WasiaController.childLlmAllowed().then((bool v) {
      if (mounted) setState(() => _on = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String subject = widget.inLesson
        ? 'Anything about this lesson \u2014 ask your teacher.'
        : 'Ask your teacher about your letters, your lessons or how you feel.';
    return Text(
      _on
          ? '$subject (A parent has allowed the AI connection for this; your '
              'name is never sent.)'
          : '$subject Wasia answers from her own lessons on this device. '
              'No AI is used.',
      key: const Key('wasia-ai-caption'),
      style: AppText.bodyMuted.copyWith(fontSize: 12),
    );
  }
}

/// How much of a teaching step is shown first, by age band: a child of 5-8
/// gets the first two sentences with "Tell me more" for the rest; older
/// children and teenagers get the whole step. Only the text is cut; nothing is
/// rewritten. EDUCATOR REVIEW NEEDED (`academy.letters.age-fit`).
String ageFitTeaching(String text, String band) {
  if (band != '5-8') return text;
  final List<RegExpMatch> ends = RegExp(r'[.!?](\s+|$)').allMatches(text).toList();
  if (ends.length <= 2) return text;
  return text.substring(0, ends[1].end).trimRight();
}

/// A title with Arabic letters in it (for example the lesson about the Alif):
/// the Arabic runs are drawn in Amiri with enough line height that the tall
/// letters are not clipped, the rest in the given style.
Widget arabicAwareText(String text, TextStyle style, {Key? key}) {
  final RegExp run = RegExp('[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF][\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\u064B-\u065F ]*');
  if (!run.hasMatch(text)) return Text(text, key: key, style: style);
  final List<InlineSpan> spans = <InlineSpan>[];
  int at = 0;
  for (final RegExpMatch m in run.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    // One letter (the Alif in "Lesson 1: Alif") is drawn large: a single
    // stroke at body size was too small to teach with.
    final bool oneLetter = m.group(0)!.trim().runes.length <= 3;
    spans.add(TextSpan(
      text: m.group(0),
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: (style.fontSize ?? 18) * (oneLetter ? 2.1 : 1.15),
        height: oneLetter ? 1.4 : 1.8,
      ),
    ));
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text.rich(TextSpan(children: spans), key: key, style: style.copyWith(height: 1.6)),
  );
}

final RegExp _arabicScript = RegExp('[\u0600-\u06FF]');

/// Arabic options are drawn large in Amiri; Latin names (the shape to name
/// drills) in the normal body face.
TextStyle quizOptionStyle(String option) => _arabicScript.hasMatch(option)
    ? const TextStyle(
        fontFamily: 'Amiri', fontSize: 26, color: Color(0xFFEAD9A8))
    : AppText.body.copyWith(fontSize: 18, fontWeight: FontWeight.w600);

class WasiaAskBox extends ConsumerStatefulWidget {
  const WasiaAskBox({super.key});
  @override
  ConsumerState<WasiaAskBox> createState() => WasiaAskBoxState();
}

class WasiaAskBoxState extends ConsumerState<WasiaAskBox> {
  final _input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(wasiaControllerProvider).isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Semantics(label: 'Ask Wasia\u2026', child: TextField(
            controller: _input,
            style: AppText.body,
            decoration: const InputDecoration(hintText: 'Ask Wasia\u2026'),
          )),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.gold,
          child: IconButton(tooltip: 'Send to Wasia',
            icon: busy
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Color(0xFF0A0F18)))
                : const Icon(Icons.send, size: 17, color: Color(0xFF0A0F18)),
            onPressed: busy
                ? null
                : () async {
                    final q = _input.text.trim();
                    if (q.isEmpty) return;
                    await ref
                        .read(wasiaControllerProvider.notifier)
                        .ask(q);
                    // The answer, or the reason there is none, is in the
                    // thread below. Keep the words only when Wasia could not
                    // answer, so a retry is one tap.
                    if (!mounted) return;
                    if (ref.read(wasiaControllerProvider).notice == null) {
                      _input.clear();
                    }
                  },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const WasiaThread(),
    ]);
  }
}
