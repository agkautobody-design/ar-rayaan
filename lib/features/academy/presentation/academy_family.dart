import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/family_service.dart';
import '../application/wasia_controller.dart';
import 'widgets/wasia_thread.dart';
import 'wasia_lessons.dart';

/// The Family Wing — parents add children, watch their growth, and speak
/// with Wasia about each child's learning.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  Future<void> _addChild(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('Add a child', style: AppText.titleMedium),
        content: TextField(
          controller: name,
          style: AppText.body,
          decoration: const InputDecoration(hintText: 'Child\u2019s name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add',
                  style: TextStyle(color: AppColors.goldLight))),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(familyServiceProvider).addChild(name.text);
      ref.invalidate(childrenProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0F18),
        onPressed: () => _addChild(context, ref),
        icon: const Icon(Icons.child_care_outlined, size: 18),
        label: const Text('Add child'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
        children: [
          const ScreenHeader(title: 'The Family Wing', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('PARENTS \u00b7 WATCH THEM GROW', style: AppText.eyebrow),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Add your children, follow their lessons and exams, and ask Wasia '
              'how to help them. Progress lives on this device and syncs to your '
              'parent account when the family cloud is on.',
              style: AppText.bodyMuted,
            ),
          ),
          children.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
            ),
            error: (e, _) => GlassCard(
                child: Text('Could not load children.', style: AppText.bodyMuted)),
            data: (list) => Column(children: [
              if (list.isEmpty)
                GlassCard(
                  child: Text(
                    'No children added yet. Tap \u201cAdd child\u201d — then their '
                    'lessons, quiz answers, and exam scores will appear here, '
                    'and Wasia will help you coach them.',
                    style: AppText.bodyMuted,
                  ),
                ),
              for (final c in list) _ChildCard(child: c),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  final Map<String, dynamic> child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider(child['id'] as String));
    final name = child['name'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        strong: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                  child: Text(name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(color: AppColors.goldLight)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: AppText.titleMedium.copyWith(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(familyServiceProvider)
                        .setActiveChild(child['id'] as String);
                    if (context.mounted) context.go('/academy/letters');
                  },
                  child: const Text('Switch to learning',
                      style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            progress.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (p) {
                final lessons = (p['lessons'] as Map).length;
                final exams = (p['exams'] as Map).values
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
                // Best single exam as a true percentage (score / total).
                int bestPct = 0;
                for (final e in exams) {
                  final int sc = (e['score'] as num? ?? 0).toInt();
                  final int tot = (e['total'] as num? ?? 0).toInt();
                  if (tot > 0) {
                    final int pct = (sc * 100 / tot).round();
                    if (pct > bestPct) bestPct = pct;
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$lessons / 28 letters lessons \u00b7 ${exams.length} exam(s) '
                      '${exams.isNotEmpty ? '\u00b7 best $bestPct%' : ''}',
                      style: AppText.bodyMuted,
                    ),
                    if (exams.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final e in (p['exams'] as Map).entries)
                        Builder(builder: (_) {
                          final v = Map<String, dynamic>.from(e.value as Map);
                          return Text(
                            '\u2022 ${v['score']}/${v['total']} \u00b7 ${_examTitle(e.key as String)}',
                            style: AppText.bodyMuted.copyWith(fontSize: 11.5),
                          );
                        }),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            _ParentWasiaBox(childName: name, childId: child['id'] as String),
          ],
        ),
      ),
    );
  }

  String _examTitle(String id) => id.replaceAll('-exam', '').toUpperCase();
}

/// Parents speak with Wasia here — she coaches with the child's real stats.
class _ParentWasiaBox extends ConsumerStatefulWidget {
  final String childName;
  final String childId;
  const _ParentWasiaBox({required this.childName, required this.childId});

  @override
  ConsumerState<_ParentWasiaBox> createState() => _ParentWasiaBoxState();
}

class _ParentWasiaBoxState extends ConsumerState<_ParentWasiaBox> {
  final _input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(wasiaControllerProvider).isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ASK WASIA ABOUT ${widget.childName.toUpperCase()}',
          style: AppText.eyebrow.copyWith(fontSize: 9.5)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: AppText.body.copyWith(fontSize: 13),
            decoration: const InputDecoration(hintText: 'How is my child doing? What should we practice?'),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.gold,
          radius: 20,
          child: IconButton(
            icon: busy
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Color(0xFF0A0F18)))
                : const Icon(Icons.send, size: 16, color: Color(0xFF0A0F18)),
            onPressed: busy
                ? null
                : () async {
                    final q = _input.text.trim();
                    if (q.isEmpty) return;
                    final p = await ref
                        .read(familyServiceProvider)
                        .progress(widget.childId);
                    final lessons = (p['lessons'] as Map).length;
                    final exams = (p['exams'] as Map).length;
                    await ref
                        .read(wasiaControllerProvider.notifier)
                        .ask(q,
                            persona: WasiaPersona.parent,
                            lessonsDone: lessons,
                            examsTaken: exams);
                  },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const WasiaThread(),
    ]);
  }
}

/// Teachers' corner — pedagogy voice on the same Wasia brain.
class _TeacherWasiaBox extends ConsumerStatefulWidget {
  const _TeacherWasiaBox();

  @override
  ConsumerState<_TeacherWasiaBox> createState() => _TeacherWasiaBoxState();
}

class _TeacherWasiaBoxState extends ConsumerState<_TeacherWasiaBox> {
  final _input = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(wasiaControllerProvider).isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _input,
            style: AppText.body.copyWith(fontSize: 13),
            decoration: const InputDecoration(
                hintText: 'Sequence the letters? When to join? Exam tips?'),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.gold,
          radius: 20,
          child: IconButton(
            icon: busy
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Color(0xFF0A0F18)))
                : const Icon(Icons.send, size: 16, color: Color(0xFF0A0F18)),
            onPressed: busy
                ? null
                : () async {
                    final q = _input.text.trim();
                    if (q.isEmpty) return;
                    await ref
                        .read(wasiaControllerProvider.notifier)
                        .ask(q, persona: WasiaPersona.teacher);
                  },
          ),
        ),
      ]),
      const SizedBox(height: 8),
      const WasiaThread(),
    ]);
  }
}

/// The exam hall: unit exams, calm and unhurried, recorded to the child.
class ExamScreen extends ConsumerStatefulWidget {
  final String examId;
  const ExamScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _i = 0;
  int _score = 0;
  int? _picked;
  bool _done = false;
  // Whether this result was stored for an active child. Without one the
  // exam still runs, but the result screen must not claim it was recorded.
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(lettersCurriculumProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: data.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(
            child: Text('Could not load the exam.', style: AppText.bodyMuted)),
        data: (d) {
          final exam = (d['exams'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .firstWhere((e) => e['id'] == widget.examId,
                  orElse: () => const {});
          if (exam.isEmpty) {
            return Center(child: Text('Exam not found.', style: AppText.bodyMuted));
          }
          final qs = (exam['questions'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_done) {
            final pass = _score >= (exam['pass'] as num? ?? 7).toInt();
            return _result(pass, _score, qs.length);
          }
          final q = qs[_i];
          final options = (q['options'] as List<dynamic>).cast<String>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ScreenHeader(title: exam['title'] as String? ?? 'Exam', close: true),
              Text('QUESTION ${_i + 1} OF ${qs.length} \u00b7 SCORE $_score',
                  style: AppText.eyebrow),
              const SizedBox(height: 12),
              GlassCard(
                child: Text(q['q'] as String,
                    style: AppText.body.copyWith(fontSize: 16, height: 1.5)),
              ),
              const SizedBox(height: 14),
              for (var o = 0; o < options.length; o++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    onTap: _picked == null ? () => setState(() => _picked = o) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(options[o],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 30,
                              color: Color(0xFFEAD9A8))),
                    ),
                  ),
                ),
              if (_picked != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    (_picked == (q['answer'] as num).toInt()
                        ? 'Correct, ma sha Allah! '
                        : 'Not quite — ') + (q['why'] as String? ?? ''),
                    style: AppText.bodyMuted.copyWith(height: 1.5),
                  ),
                ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TEACHERS' CORNER", style: AppText.eyebrow),
                    const SizedBox(height: 4),
                    Text(
                      'Running a classroom or homeschool? Ask Wasia about sequencing, joining, exams, struggling students.',
                      style: AppText.bodyMuted.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    const _TeacherWasiaBox(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_picked != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final wasCorrect =
                          _picked == (q['answer'] as num).toInt();
                      if (wasCorrect) _score++;
                      if (_i + 1 >= qs.length) {
                        final child =
                            await ref.read(familyServiceProvider).activeChildId();
                        if (child != null) {
                          await ref.read(familyServiceProvider).recordExam(
                                child, widget.examId,
                                score: _score, total: qs.length,
                              );
                          ref.invalidate(progressProvider);
                        }
                        setState(() {
                          _recorded = child != null;
                          _done = true;
                        });
                      } else {
                        setState(() {
                          _picked = null;
                          _i++;
                        });
                      }
                    },
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 13, color: AppColors.gold),
                    label: Text(
                        _i + 1 >= qs.length ? 'See result' : 'Next',
                        style: AppText.bodyMuted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _result(bool pass, int score, int total) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('EXAM COMPLETE', style: AppText.eyebrow),
            const SizedBox(height: 10),
            Text('$score / $total',
                style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 46,
                    color: AppColors.goldLight)),
            const SizedBox(height: 8),
            Text(
              (pass
                      ? 'Passed, alhamdulillah! '
                      : 'Not yet — no sadness. Wasia says: rest, review the letters, and retake it when you are ready. Growth is patient. ') +
                  (_recorded
                      ? (pass
                          ? 'Wasia has recorded this in your child\u2019s growth (the best attempt is kept).'
                          : 'Your best attempt so far is kept in your child\u2019s growth.')
                      : 'No child is active, so this result was not saved — add a child in the Family Wing to keep a record.'),
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(height: 1.55),
            ),
            const SizedBox(height: 18),
            if (!pass)
              TextButton(
                onPressed: () => setState(() {
                  _i = 0;
                  _score = 0;
                  _picked = null;
                  _done = false;
                  _recorded = false;
                }),
                child: const Text('Retake the exam',
                    style: TextStyle(color: AppColors.goldLight)),
              ),
            TextButton(
              onPressed: () => context.go('/academy/letters'),
              child: const Text('Back to the School',
                  style: TextStyle(color: AppColors.goldLight)),
            ),
          ],
        ),
      ),
    );
  }
}
