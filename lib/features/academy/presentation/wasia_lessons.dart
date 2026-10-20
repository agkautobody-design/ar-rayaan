import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/speak_button.dart';
import '../application/academy_providers.dart';
import '../application/family_service.dart';
import '../application/wasia_controller.dart';
import '../domain/academy_models.dart' show LessonProgress;
import '../domain/letters_meta.dart';
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
  const LessonStep({required this.type, this.text, this.arabic, this.translit,
      this.note, this.question, this.options, this.answer, this.why});

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
  return [
    for (final u in data['units'] as List<dynamic>)
      for (final l in u['lessons'] as List<dynamic>)
        Lesson.fromJson(l as Map<String, dynamic>),
  ];
});

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
                'Wasia teaches every lesson, asks a gentle question, and records your child\u2019s growth.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
            ),
            const SizedBox(height: 16),
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
                            Expanded(child: Text(lesson.title, style: AppText.body.copyWith(
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
                            Text('${(e['questions'] as List<dynamic>).length} questions \u00b7 pass at ${e['pass']} \u00b7 recorded to your child',
                                style: AppText.bodyMuted.copyWith(fontSize: 11)),
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
  // True once any quiz in this run was answered wrongly (drives 'walked').
  bool _quizMissed = false;
  bool _finishing = false;

  /// Record the lesson: device-level progress + review queue always, and
  /// the Family Wing (lesson done + mastery 'met', plus 'walked' when every
  /// quiz was right) for the active child. Without this nothing a child
  /// finished was ever stored.
  Future<void> _finish(Lesson lesson) async {
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
    if (mounted) context.go('/academy/letters');
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lettersLessonsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: lessons.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load the lesson.', style: AppText.bodyMuted)),
        data: (list) {
          final lesson = list.where((l) => l.id == widget.lessonId).firstOrNull;
          if (lesson == null) {
            return Center(child: Text('Lesson not found.',
                style: AppText.bodyMuted));
          }
          final steps = lesson.steps;
          final current = steps[_step];
          final last = _step == steps.length - 1;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ScreenHeader(title: lesson.title, close: true),
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
                        SpeakButton(text: current.text ?? ''),
                      ]),
                      const SizedBox(height: 8),
                      Text(current.text ?? '',
                          style: AppText.body.copyWith(height: 1.65, fontSize: 14.5)),
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
                        Text('SAY IT WITH WASIA', style: AppText.eyebrow.copyWith(fontSize: 8.5)),
                        const SizedBox(height: 4),
                        Text('Repeat the letter three times, slowly — then tap the voice above to hear your teacher say it.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(fontSize: 11, height: 1.5)),
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
                      const SizedBox(height: 12),
                      for (var o = 0; o < (current.options?.length ?? 0); o++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            onTap: _picked == null
                                ? () => setState(() {
                                      _picked = o;
                                      if (o != current.answer) _quizMissed = true;
                                    })
                                : null,
                            child: Row(children: [
                              Expanded(child: Text(current.options![o],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Amiri',
                                      fontSize: 26, color: Color(0xFFEAD9A8)))),
                            ]),
                          ),
                        ),
                      if (_picked != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _picked == current.answer
                              ? 'Correct, ma sha Allah! ${current.why ?? ''}'
                              : 'Not quite — ${current.why ?? ''}',
                          style: AppText.bodyMuted.copyWith(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              if (!(last && current.type == 'quiz' && _picked == null))
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      if (last) {
                        _finish(lesson);
                        return;
                      }
                      setState(() {
                        _picked = null;
                        _step++;
                      });
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppColors.gold),
                    label: Text(last ? 'Finish' : 'Next',
                        style: AppText.bodyMuted),
                  ),
                ),
              if (last)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: GlassCard(
                    strong: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASK WASIA', style: AppText.eyebrow),
                        const SizedBox(height: 6),
                        Text(
                          'Anything about this lesson — ask your teacher. '
                          '(Uses the AI connection set up for H\u0101di; your child\u2019s name is never sent.)',
                          style: AppText.bodyMuted.copyWith(fontSize: 11.5),
                        ),
                        const _WasiaBox(),
                      ],
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

class _WasiaBox extends ConsumerStatefulWidget {
  const _WasiaBox();
  @override
  ConsumerState<_WasiaBox> createState() => _WasiaBoxState();
}

class _WasiaBoxState extends ConsumerState<_WasiaBox> {
  final _input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(wasiaControllerProvider).isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: AppText.body,
            decoration: const InputDecoration(hintText: 'Ask Wasia\u2026'),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.gold,
          child: IconButton(
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
                  },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const WasiaThread(),
    ]);
  }
}
