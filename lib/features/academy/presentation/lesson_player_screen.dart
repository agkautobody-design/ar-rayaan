import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/academy_providers.dart';
import '../application/academy_strings.dart';
import '../domain/academy_models.dart';
import '../domain/assessment_engine.dart';
import '../domain/course_manifest.dart';

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
  final List<int> _answers = <int>[];
  bool _checkSubmitted = false;
  AssessmentResult? _result;

  @override
  void initState() {
    super.initState();
    _lesson = findLesson(widget.courseId, widget.unitId, widget.lessonId) ??
        kAcademyCourses.first.units.first.lessons.first;
    final LessonProgress saved = ref
        .read(academyProgressProvider.notifier)
        .of(_lesson.id);
    _index = saved.completed
        ? 0
        : saved.lastStep.clamp(0, _lesson.steps.length - 1);
  }

  AcademyStep get _step => _lesson.steps[_index];
  bool get _isLast => _index == _lesson.steps.length - 1;

  Future<void> _next() async {
    final notifier = ref.read(academyProgressProvider.notifier);
    if (_isLast) {
      await notifier.complete(_lesson.id);
      if (mounted) {
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/academy');
                    },
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

  @override
  Widget build(BuildContext context) {
    final AcademyStep step = _step;
    final double progress = _lesson.steps.isEmpty
        ? 0
        : (_index + 1) / _lesson.steps.length;

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
                        IconButton(
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
                        Text(
                          '${_index + 1}/${_lesson.steps.length}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                      onSelect: (int itemIdx, int choiceIdx) {
                        setState(() {
                          if (_answers.length <= itemIdx) {
                            _answers.length = itemIdx + 1;
                          }
                          _answers[itemIdx] = choiceIdx;
                        });
                      },
                      onSubmit: _submitCheck,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (step.kind == AcademyStepKind.check &&
                          !_checkSubmitted) {
                        final List<AssessmentItem> items =
                            kAssessments[step.assessmentId!]!;
                        if (_answers.length == items.length &&
                            !_answers.contains(-1)) {
                          _submitCheck(items);
                        }
                        return;
                      }
                      _next();
                    },
                    child: Text(
                      step.kind == AcademyStepKind.check && !_checkSubmitted
                          ? AcademyStrings.get('check.continue')
                          : AcademyStrings.get('common.next'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  });

  final AcademyStep step;
  final String lessonId;
  final bool submitted;
  final AssessmentResult? result;
  final List<int> answers;
  final void Function(int itemIdx, int choiceIdx) onSelect;
  final void Function(List<AssessmentItem> items) onSubmit;

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
              Text(
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
              Text(
                AcademyStrings.get(step.bodyKey),
                style: AppText.bodyMuted.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.go(step.route!),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(AcademyStrings.get('common.open')),
              ),
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
              Text(
                AcademyStrings.get(step.bodyKey),
                style: AppText.bodyMuted.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              if (route != null)
                FilledButton.icon(
                  onPressed: () => context.go(route),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(AcademyStrings.get('common.open')),
                )
              else
                Text(step.ref ?? '', style: AppText.caption),
            ],
          ),
        );

      case AcademyStepKind.check:
        final List<AssessmentItem> items = kAssessments[step.assessmentId!]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AcademyStrings.get(step.titleKey),
              style: AppText.titleMedium,
            ),
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
                      child: Text(
                        AcademyStrings.get(
                          result!.passed ? 'check.passed' : 'check.tryAgain',
                        ),
                        style: AppText.body,
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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AcademyStrings.get(item.promptKey), style: AppText.body),
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
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: c,
                    title: Text(
                      AcademyStrings.get(item.choices[c]),
                      style: AppText.bodyMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (submitted && selected != item.correctIndex)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AcademyStrings.get(item.reteachKey),
                style: AppText.caption.copyWith(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}
