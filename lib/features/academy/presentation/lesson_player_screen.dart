import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'avatar_clip_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../habits/application/return_loop.dart';
import '../../habits/presentation/quiet_done.dart';
import '../application/academy_providers.dart';
import '../application/academy_strings.dart';
import '../application/recall_checks.dart';
import '../application/wasia_controller.dart';
import '../domain/academy_models.dart';
import '../domain/assessment_engine.dart';
import '../domain/course_manifest.dart';
import '../domain/lesson_grounding.dart';
import '../domain/lesson_provenance.dart';
import '../domain/next_lesson.dart';
import '../../share/application/share_service.dart';
import '../../share/domain/handout.dart';
import '../../share/presentation/handout_screen.dart';
import '../../share/presentation/share_actions.dart';
import 'widgets/glossary_text.dart';
import 'widgets/wasia_checkin_card.dart';
import 'widgets/wasia_thread.dart';

/// The teach/check/reflect lesson player. One idea per step, exact-step
/// resume, inline knowledge checks with dignity-first feedback, and a
/// quiet gold completion (no noise — Simplicity Charter).
class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
  });

  final String courseId;
  final String unitId;
  final String lessonId;

  @override
  ConsumerState<LessonPlayerScreen> createState() =>
      _LessonPlayerScreenState();
}

class _LessonPlayerScreenState
    extends ConsumerState<LessonPlayerScreen> {
  late int _index;
  late final AcademyLesson _lesson;

  /// The lesson's steps plus its generated recall check (when it has one).
  late final List<AcademyStep> _steps;
  final List<int> _answers = <int>[];
  bool _checkSubmitted = false;
  AssessmentResult? _result;

  @override
  void initState() {
    super.initState();
    _lesson = findLesson(widget.courseId, widget.unitId, widget.lessonId) ??
        kAcademyCourses.first.units.first.lessons.first;
    _steps = RecallChecks.stepsWithRecall(_lesson);
    final LessonProgress saved = ref
        .read(academyProgressProvider.notifier)
        .of(_lesson.id);
    _index = saved.completed
        ? 0
        : saved.lastStep.clamp(0, _steps.length - 1);
  }

  AcademyStep get _step => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;

  /// "Show me again": hop back to the nearest earlier teach beat
  /// (text / embed / demo). Falls back to the lesson start. Never fails.
  void _showAgain() {
    for (int i = _index - 1; i >= 0; i--) {
      final AcademyStepKind kind = _steps[i].kind;
      if (kind == AcademyStepKind.text ||
          kind == AcademyStepKind.embed ||
          kind == AcademyStepKind.demo) {
        setState(() {
          _index = i;
          _checkSubmitted = false;
          _result = null;
          _answers.clear();
        });
        return;
      }
    }
    setState(() {
      _index = 0;
      _checkSubmitted = false;
      _result = null;
      _answers.clear();
    });
  }

  Future<void> _next() async {
    final notifier = ref.read(academyProgressProvider.notifier);
    if (_isLast) {
      await notifier.complete(_lesson.id);
      ref.read(reviewQueueProvider.notifier).addLesson(_lesson.id);
      unawaited(noteReturn(ref, ReturnAct.lesson));
      final bool firstLesson = ref.read(lessonsDoneProvider) == 1;
      if (mounted) {
        final AcademyLesson? next = nextLessonAfter(_lesson.id);
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              strong: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.gold,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AcademyStrings.get('lesson.completeTitle'),
                    style: AppText.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AcademyStrings.get('lesson.completeBody'),
                    style: AppText.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  if (firstLesson && kQuietDoneEnabled) ...<Widget>[
                    const SizedBox(height: 8),
                    const Text(
                      kQuietDoneText,
                      key: Key('quiet-done-text'),
                      style: AppText.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (next != null) ...<Widget>[
                    FilledButton(
                      key: const Key('next-lesson'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(lessonRoute(next));
                      },
                      child: Text(
                          '${AcademyStrings.get('lesson.nextLesson')}: '
                          '${AcademyStrings.get(next.titleKey)}',
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 8),
                  ],
                  next == null
                      ? FilledButton(
                          onPressed: () => _leave(context),
                          child: Text(AcademyStrings.get('common.done')),
                        )
                      : TextButton(
                          onPressed: () => _leave(context),
                          child: Text(AcademyStrings.get('common.done')),
                        ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }
    setState(() {
      _index++;
      _checkSubmitted = false;
      _result = null;
      _answers.clear();
    });
    await notifier.advance(_lesson.id, _index);
  }

  /// Leave a finished lesson. Opened from the review queue (pushed on top of
  /// it) the learner goes back there; otherwise to the Academy home.
  void _leave(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/academy');
    }
  }

  /// The lesson Wasia is grounded to: this lesson's own words, nothing else.
  LessonGrounding get _grounding => LessonGrounding(
        id: _lesson.id,
        title: AcademyStrings.get(_lesson.titleKey),
        text: RecallChecks.fullTextOf(_lesson),
      );

  Future<void> _askWasia() async {
    final LessonGrounding g = _grounding;
    ref.read(wasiaControllerProvider.notifier).openLesson(g.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _LessonWasiaSheet(lesson: g),
      ),
    );
  }

  /// Provenance sheet: where the text comes from, its review status and every
  /// Qur'an / hadith reference written in it.
  Future<void> _showSources() async {
    final LessonProvenance? prov = provenanceOf(_lesson.id);
    final List<LessonSource> sources =
        extractSources(RecallChecks.fullTextOf(_lesson));
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          strong: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(prov?.label ?? kNotYetReviewedLabel,
                  style: AppText.eyebrow.copyWith(color: AppColors.gold)),
              const SizedBox(height: 8),
              Text(prov?.origin ?? '', style: AppText.bodyMuted),
              const SizedBox(height: 12),
              Text(
                sources.isEmpty
                    ? 'This lesson cites no Qur\u2019an or hadith reference.'
                    : 'Cited in this lesson: '
                        '${sources.map((LessonSource s) => s.toString()).join(' \u00b7 ')}',
                style: AppText.body,
              ),
              if (sources.any((LessonSource s) => s.kind == 'hadith'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Hadith are listed as the lesson states them; their grade '
                    'is not shown here. Treat anything ungraded with care and '
                    'ask a scholar before relying on it.',
                    style: AppText.caption,
                  ),
                ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AcademyStrings.get('common.done')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _back() {
    if (_index == 0) {
      context.go('/academy');
      return;
    }
    setState(() {
      _index--;
      _checkSubmitted = false;
      _result = null;
      _answers.clear();
    });
  }

  void _submitCheck(List<AssessmentItem> items) {
    final AssessmentResult r = AssessmentEngine.evaluate(items, _answers);
    setState(() {
      _checkSubmitted = true;
      _result = r;
    });
  }

  /// True when every question of the check has an answer.
  bool _allAnswered(List<AssessmentItem> items) =>
      items.isNotEmpty &&
      _answers.length == items.length &&
      !_answers.contains(-1);

  void _retryCheck() => setState(() {
        _checkSubmitted = false;
        _result = null;
        _answers.clear();
      });

  /// The bottom button. A check GATES the lesson: it advances only after every
  /// answer is right (the audit found a failed check still let the lesson
  /// complete). A wrong answer re-teaches under the question and offers
  /// "Try once more" or "Show me again"; nothing is timed or scored.
  Widget _bottomBar(AcademyStep step) {
    final bool isCheck = step.kind == AcademyStepKind.check;
    final List<AssessmentItem> items = isCheck
        ? (RecallChecks.itemsFor(step.assessmentId!) ??
            const <AssessmentItem>[])
        : const <AssessmentItem>[];
    final bool failed = isCheck && _checkSubmitted && _result?.passed != true;
    // A check with no questions cannot be answered, so it must not trap the
    // learner: it behaves like a plain step.
    final bool ready =
        !isCheck || _checkSubmitted || items.isEmpty || _allAnswered(items);
    final String label;
    if (!isCheck || items.isEmpty) {
      label = AcademyStrings.get('common.next');
    } else if (!_checkSubmitted) {
      label = AcademyStrings.get('check.continue');
    } else if (failed) {
      label = AcademyStrings.get('check.retry');
    } else {
      label = AcademyStrings.get('common.next');
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isCheck && !_checkSubmitted && !ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AcademyStrings.get('check.answerAll'),
                key: const Key('check-answer-all'),
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
            ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton(
                key: const Key('check-show-again'),
                onPressed: _showAgain,
                child: Text(AcademyStrings.get('try.again')),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('lesson-bottom-button'),
              onPressed: !ready
                  ? null
                  : () {
                      if (isCheck && !_checkSubmitted && items.isNotEmpty) {
                        _submitCheck(items);
                        return;
                      }
                      if (failed) {
                        _retryCheck();
                        return;
                      }
                      _next();
                    },
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AcademyStep step = _step;
    final double progress =
        _steps.isEmpty ? 0 : (_index + 1) / _steps.length;

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(tooltip: 'Back',
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          onPressed: _back,
                        ),
                        Expanded(
                          child: Text(
                            AcademyStrings.get(_lesson.titleKey),
                            style: AppText.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          key: const Key('ask-wasia'),
                          tooltip: 'Ask Wasia about this lesson',
                          icon: const Icon(Icons.forum_outlined,
                              color: AppColors.gold, size: 22),
                          onPressed: _askWasia,
                        ),
                        Text(
                          '${_index + 1}/${_steps.length}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: _showSources,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.info_outline,
                                      size: 14, color: AppColors.gold),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${provenanceOf(_lesson.id)?.label ?? kNotYetReviewedLabel}'
                                      ' \u00b7 sources',
                                      style: AppText.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ShareButton(
                          doc: lessonShareDoc(_lesson),
                          subject: 'this lesson',
                        ),
                        IconButton(
                          key: const Key('lesson-handout'),
                          tooltip: 'Make a handout',
                          constraints: const BoxConstraints(
                              minWidth: 48, minHeight: 48),
                          icon: const Icon(Icons.print_outlined,
                              color: AppColors.gold, size: 20),
                          onPressed: () =>
                              openHandout(context, lessonHandout(_lesson)),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    _StepBody(
                      step: step,
                      lessonId: _lesson.id,
                      submitted: _checkSubmitted,
                      result: _result,
                      answers: _answers,
                      onShowAgain: _showAgain,
                      onAdvance: () => _next(),
                      onSelect: (int itemIdx, int choiceIdx) {
                        setState(() {
                          while (_answers.length <= itemIdx) {
                            _answers.add(-1);
                          }
                          _answers[itemIdx] = choiceIdx;
                        });
                      },
                      onSubmit: _submitCheck,
                      onRetry: () => setState(() {
                        _checkSubmitted = false;
                        _result = null;
                        _answers.clear();
                      }),
                    ),
                  ],
                ),
              ),
              if (step.kind != AcademyStepKind.try_)
                _bottomBar(step),
            ],
          ),
        ),
      ),
    );
  }
}

/// A printable handout of a lesson, built only from what the lesson already
/// says: each step's title and text, its Try prompts as questions, its
/// review label and the Qur\u2019an and hadith references it cites.
HandoutData lessonHandout(AcademyLesson lesson) {
  final LessonProvenance? prov = provenanceOf(lesson.id);
  final List<LessonSource> cited =
      extractSources(RecallChecks.fullTextOf(lesson));
  return HandoutData(
    title: AcademyStrings.get(lesson.titleKey),
    reviewKey: 'lesson-v1.${lesson.id}',
    notice: '${prov?.label ?? kNotYetReviewedLabel}. ${prov?.origin ?? ''}'
        .trim(),
    sections: <HandoutSection>[
      for (final AcademyStep st in lesson.steps)
        if (st.kind != AcademyStepKind.check &&
            st.kind != AcademyStepKind.try_ &&
            (AcademyStrings.get(st.titleKey).trim().isNotEmpty ||
                AcademyStrings.get(st.bodyKey).trim().isNotEmpty))
          HandoutSection(
            heading: AcademyStrings.get(st.titleKey),
            body: AcademyStrings.get(st.bodyKey),
          ),
    ],
    sources: <String>[
      for (final LessonSource src in cited) src.toString(),
    ],
    questions: <String>[
      for (final AcademyStep st in lesson.steps)
        if (st.kind == AcademyStepKind.try_) tryPromptFor(st),
    ],
  );
}

/// What a lesson TEACHES, for sharing: its own text, sources and questions,
/// from the same content as the handout. It never says that anyone did,
/// finished or is studying the lesson.
ShareDoc lessonShareDoc(AcademyLesson lesson) {
  final HandoutData h = lessonHandout(lesson);
  final List<String> blocks = <String>[];
  for (final HandoutSection s in h.sections) {
    final String text = <String>[
      if (s.heading.trim().isNotEmpty) s.heading.trim(),
      if (s.body.trim().isNotEmpty) s.body.trim(),
    ].join('\n');
    if (text.isNotEmpty) blocks.add(text);
  }
  if (h.questions.isNotEmpty) {
    final StringBuffer q = StringBuffer('To talk about');
    for (int i = 0; i < h.questions.length; i++) {
      q.write('\n${i + 1}. ${h.questions[i].trim()}');
    }
    blocks.add(q.toString());
  }
  return ShareDoc.lesson(
    title: h.title,
    body: blocks.join('\n\n'),
    source: h.sources.isEmpty ? null : h.sources.join('; '),
    note: h.notice,
    reviewKey: 'lesson-v1.${lesson.id}',
  );
}

/// The text a Try card shows. Some lessons keep their whole prompt in the
/// step title and have no body; the card used to show an empty box there
/// (13 lessons). Fall back to the title, never to a blank.
String tryPromptFor(AcademyStep step) {
  final String body = AcademyStrings.get(step.bodyKey);
  return body.trim().isNotEmpty ? body : AcademyStrings.get(step.titleKey);
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.lessonId,
    required this.submitted,
    required this.result,
    required this.answers,
    required this.onSelect,
    required this.onSubmit,
    this.onShowAgain,
    this.onAdvance,
    this.onRetry,
  });

  final AcademyStep step;
  final String lessonId;
  final bool submitted;
  final AssessmentResult? result;
  final List<int> answers;
  final void Function(int itemIdx, int choiceIdx) onSelect;
  final void Function(List<AssessmentItem> items) onSubmit;
  final VoidCallback? onShowAgain;
  final VoidCallback? onAdvance;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (step.kind) {
      case AcademyStepKind.text:
        return GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (step.honestyLabel != null)
                Text(
                  step.honestyLabel!,
                  style: AppText.eyebrow.copyWith(color: AppColors.gold),
                ),
              if (step.honestyLabel != null) const SizedBox(height: 6),
              Text(AcademyStrings.get(step.titleKey), style: AppText.titleMedium),
              const SizedBox(height: 10),
              GlossaryText(
                AcademyStrings.get(step.bodyKey),
                style: AppText.body.copyWith(height: 1.6),
              ),
            ],
          ),
        );

      case AcademyStepKind.action:
        return GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AcademyStrings.get(step.titleKey), style: AppText.titleMedium),
              const SizedBox(height: 8),
              GlossaryText(
                AcademyStrings.get(step.bodyKey),
                style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
              ),
              // Real-world tasks (give in secret, forgive someone) have no
              // screen to open — the step is the task itself.
              if (step.route != null) ...<Widget>[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.push(step.route!),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(AcademyStrings.get('common.open')),
                ),
              ],
            ],
          ),
        );

      case AcademyStepKind.embed:
        final String? route = kEmbedRoutes[step.ref];
        return GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AcademyStrings.get(step.titleKey), style: AppText.titleMedium),
              const SizedBox(height: 8),
              GlossaryText(
                AcademyStrings.get(step.bodyKey),
                style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (route != null)
                FilledButton.icon(
                  onPressed: () => context.push(route),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(AcademyStrings.get('common.open')),
                )
              else
                Text(step.ref ?? '', style: AppText.caption),
            ],
          ),
        );

      case AcademyStepKind.try_:
        return GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AcademyStrings.get('try.title'), style: AppText.eyebrow),
              const SizedBox(height: 8),
              GlossaryText(
                tryPromptFor(step),
                key: const Key('try-prompt'),
                style: AppText.body.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onShowAgain,
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48)),
                      child: Text(
                        AcademyStrings.get('try.again'),
                        style: AppText.bodyMuted.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAdvance,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.night,
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        AcademyStrings.get('try.remembered'),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case AcademyStepKind.demo:
        return GlassCard(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(AcademyStrings.get('demo.eyebrow'), style: AppText.eyebrow),
              const SizedBox(height: 8),
              Text(AcademyStrings.get(step.bodyKey),
                  style: AppText.titleMedium),
              const SizedBox(height: 8),
              AvatarClipPlayer(clipId: step.clipId ?? ''),
              const SizedBox(height: 8),
              Text(
                AcademyStrings.get('demo.stageCaption'),
                style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        );

      case AcademyStepKind.check:
        final List<AssessmentItem> items =
            RecallChecks.itemsFor(step.assessmentId!) ??
                const <AssessmentItem>[];
        final bool isRecall =
            step.assessmentId!.startsWith(RecallChecks.idPrefix);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AcademyStrings.get(step.titleKey),
              style: AppText.titleMedium,
            ),
            if (isRecall) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                AcademyStrings.get('recall.note'),
                style: AppText.caption,
              ),
            ],
            const SizedBox(height: 12),
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CheckItem(
                  item: items[i],
                  itemIdx: i,
                  submitted: submitted,
                  selected: i < answers.length ? answers[i] : -1,
                  onSelect: onSelect,
                ),
              ),
            if (submitted && result != null)
              GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      result!.passed
                          ? Icons.check_circle_outline
                          : Icons.refresh,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            AcademyStrings.get(
                              result!.passed
                                  ? 'check.passed'
                                  : 'check.tryAgain',
                            ),
                            style: AppText.body,
                          ),
                          if (!result!.passed && onRetry != null)
                            TextButton(
                              onPressed: onRetry,
                              child: Text(AcademyStrings.get('check.retry')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.item,
    required this.itemIdx,
    required this.submitted,
    required this.selected,
    required this.onSelect,
  });

  final AssessmentItem item;
  final int itemIdx;
  final bool submitted;
  final int selected;
  final void Function(int itemIdx, int choiceIdx) onSelect;

  /// Display text: a string key, or the text itself for generated checks.
  String _label(String keyOrText) =>
      item.literal ? keyOrText : AcademyStrings.get(keyOrText);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_label(item.promptKey),
              style: AppText.body.copyWith(fontSize: 15, height: 1.5)),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: selected,
            onChanged: (int? v) {
              if (!submitted && v != null) onSelect(itemIdx, v);
            },
            child: Column(
              children: <Widget>[
                for (int c = 0; c < item.choices.length; c++)
                  RadioListTile<int>(
                    key: Key('check-option-$itemIdx-$c'),
                    contentPadding: EdgeInsets.zero,
                    value: c,
                    title: Text(
                      _label(item.choices[c]),
                      style: AppText.body.copyWith(fontSize: 15),
                    ),
                  ),
              ],
            ),
          ),
          if (submitted && selected != item.correctIndex)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _label(item.reteachKey),
                style: AppText.caption.copyWith(
                    fontSize: 14, color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the "Ask Wasia" sheet for [lesson] (shared by the v3 lesson player).
Future<void> showLessonWasiaSheet(
  BuildContext context,
  WidgetRef ref,
  LessonGrounding lesson,
) async {
  ref.read(wasiaControllerProvider.notifier).openLesson(lesson.id);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _LessonWasiaSheet(lesson: lesson),
    ),
  );
}

/// Ask Wasia about THIS lesson. She answers from the lesson's own words (and,
/// where a parent has allowed the AI service for children, from the AI with
/// the lesson as the only ground, every reply checked first).
class _LessonWasiaSheet extends ConsumerStatefulWidget {
  const _LessonWasiaSheet({required this.lesson});

  final LessonGrounding lesson;

  @override
  ConsumerState<_LessonWasiaSheet> createState() => _LessonWasiaSheetState();
}

class _LessonWasiaSheetState extends ConsumerState<_LessonWasiaSheet> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String q = _input.text.trim();
    if (q.isEmpty) return;
    await ref
        .read(wasiaControllerProvider.notifier)
        .ask(q, lesson: widget.lesson);
    if (!mounted) return;
    // Keep the words when Wasia could not answer, so a retry is one tap.
    if (ref.read(wasiaControllerProvider).notice == null) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = ref.watch(wasiaControllerProvider).isLoading;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        strong: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const WasiaCheckinCard(),
              Text('ASK WASIA', style: AppText.eyebrow),
              const SizedBox(height: 4),
              Text(widget.lesson.title, style: AppText.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Wasia answers from the words of this lesson only. She does '
                'not give rulings: for those, ask H\u0101di or a scholar.',
                style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const Key('lesson-wasia-field'),
                      controller: _input,
                      style: AppText.body,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                          hintText: 'Ask about this lesson\u2026'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('lesson-wasia-send'),
                    tooltip: 'Ask',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.night,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: busy ? null : _send,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.night),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const WasiaThread(),
            ],
          ),
        ),
      ),
    );
  }
}
