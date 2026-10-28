/// The Academy v3 lesson player.
///
/// Renders a [LessonV3] step by step: teaching cards, Arabic with its
/// transliteration and meaning (and real recitation audio where it exists),
/// and the steps that gate the lesson (check, arrange, match). A wrong answer
/// re-teaches and offers the step that taught it; after two misses the answer
/// is shown and the learner moves on. Nothing here counts points or streaks.
library;

import 'dart:async' show unawaited;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/scholar_review.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../share/application/share_service.dart';
import '../../share/presentation/share_actions.dart';
import '../application/academy_providers.dart';
import '../application/academy_strings.dart';
import '../application/lessons_v3_provider.dart';
import '../application/recitation_player_provider.dart';
import '../domain/academy_models.dart';
import '../domain/lesson_grounding.dart';
import '../domain/lesson_provenance.dart';
import '../domain/next_lesson.dart';
import '../domain/v3/lesson_v3_model.dart';
import '../domain/v3/lesson_v3_review.dart';
import '../domain/v3/lesson_v3_state.dart';
import '../domain/v3/lessons_v3.dart';
import '../domain/v3/phrase_resolver.dart';
import 'lesson_player_screen.dart';
import 'v3/v3_gates.dart';
import 'v3/v3_steps.dart';
import 'v3/v3_widgets.dart';
import '../../../app/theme/widgets/focus_ring.dart';
import '../../../app/theme/widgets/named_sheet.dart';

/// Opens a lesson: the v3 player when a v3 lesson replaces it, otherwise the
/// manifest lesson player, exactly as before. Any failure to load v3 falls
/// back to the manifest lesson.
class LessonEntryScreen extends ConsumerWidget {
  const LessonEntryScreen({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
  });

  final String courseId;
  final String unitId;
  final String lessonId;

  Widget _legacy() => LessonPlayerScreen(
        courseId: courseId,
        unitId: unitId,
        lessonId: lessonId,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> has = ref.watch(hasLessonV3Provider(lessonId));
    return has.when(
      loading: () => const _Loading(),
      error: (Object e, StackTrace s) => _legacy(),
      data: (bool v) {
        if (!v) return _legacy();
        final AsyncValue<LessonsV3> all = ref.watch(lessonsV3Provider);
        return all.when(
          loading: () => const _Loading(),
          error: (Object e, StackTrace s) => _legacy(),
          data: (LessonsV3 data) => data.has(lessonId)
              ? LessonV3Screen(
                  key: ValueKey<String>('v3-$lessonId'),
                  data: data,
                  lessonId: lessonId,
                )
              : _legacy(),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}

class LessonV3Screen extends ConsumerStatefulWidget {
  const LessonV3Screen({super.key, required this.data, required this.lessonId});

  final LessonsV3 data;
  final String lessonId;

  @override
  ConsumerState<LessonV3Screen> createState() => _LessonV3ScreenState();
}

class _LessonV3ScreenState extends ConsumerState<LessonV3Screen> {
  late final LessonV3 _lesson;
  late final PhraseResolver _r;
  late final RecitationPlayerNotifier _player;
  int _index = 0;

  /// The gate the learner went back from; "Back to the question" returns here.
  int? _resumeAt;
  final GatedRun _run = GatedRun();
  final Set<String> _passed = <String>{};
  final Map<String, CheckStepState> _checks = <String, CheckStepState>{};
  final Map<String, ArrangeState> _arranges = <String, ArrangeState>{};
  final Map<String, MatchState> _matches = <String, MatchState>{};

  @override
  void initState() {
    super.initState();
    _lesson = widget.data[widget.lessonId]!;
    _r = widget.data.resolver;
    _player = ref.read(recitationPlayerProvider.notifier);
    final LessonProgress saved =
        ref.read(academyProgressProvider.notifier).of(_lesson.id);
    _index = saved.completed ? 0 : saved.lastStep.clamp(0, _lesson.steps.length - 1);
  }

  @override
  void dispose() {
    unawaited(_player.stop());
    super.dispose();
  }

  V3Step get _step => _lesson.steps[_index];
  bool get _isLast => _index == _lesson.steps.length - 1;

  bool _isGate(V3Step s) => s is CheckStep || s is ArrangeStep || s is MatchStep;

  void _goTo(int i) {
    unawaited(_player.stop());
    setState(() => _index = i);
  }

  Future<void> _next() async {
    if (_isLast) {
      await _complete();
      return;
    }
    if (_resumeAt == _index + 1) _resumeAt = null;
    _goTo(_index + 1);
    await ref.read(academyProgressProvider.notifier).advance(_lesson.id, _index);
  }

  void _back() {
    if (_index == 0) {
      context.go('/academy');
      return;
    }
    _goTo(_index - 1);
  }

  /// "Show me that step": jump to [stepId], remember the gate to come back to.
  void _goBackTo(String stepId) {
    final int j = _lesson.indexOfStep(stepId);
    if (j < 0 || j >= _index) return;
    _resumeAt = _index;
    _goTo(j);
  }

  void _backToQuestion() {
    final int? at = _resumeAt;
    if (at == null) return;
    _resumeAt = null;
    _goTo(at);
  }

  void _pass(String stepId) {
    if (_passed.contains(stepId)) return;
    setState(() => _passed.add(stepId));
  }

  /// What the lesson teaches, as text. Never that anyone finished it.
  ShareDoc _shareDoc() {
    String text = lessonPlainText(_lesson, _r);
    final String lead = '${_lesson.title}. ';
    if (text.startsWith(lead)) text = text.substring(lead.length);
    return ShareDoc.lesson(
      title: _lesson.title,
      body: text,
      reviewKey: 'lesson.${_lesson.id}',
    );
  }

  LessonGrounding get _grounding => LessonGrounding(
        id: _lesson.id,
        title: _lesson.title,
        text: lessonPlainText(_lesson, _r),
      );

  Future<void> _complete() async {
    final AcademyProgressNotifier notifier =
        ref.read(academyProgressProvider.notifier);
    await notifier.complete(_lesson.id);
    ref.read(reviewQueueProvider.notifier).addLesson(_lesson.id);
    if (!mounted) return;
    final AcademyLesson? next = nextLessonAfter(_lesson.id);
    await showNamedSheet<void>(
      label: AcademyStrings.get('lesson.completeTitle'),
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheet) => Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          strong: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.check_circle_outline,
                    color: AppColors.gold, size: 40),
                const SizedBox(height: 12),
                Text(AcademyStrings.get('lesson.completeTitle'),
                    style: AppText.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(AcademyStrings.get('lesson.completeBody'),
                    style: AppText.bodyMuted, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(t('v3.reviewLater'),
                    style: AppText.caption, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                if (next != null) ...<Widget>[
                  FilledButton(
                    key: const Key('next-lesson'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      context.pushReplacement(lessonRoute(next));
                    },
                    child: Text(
                      '${AcademyStrings.get('lesson.nextLesson')}: '
                      '${AcademyStrings.get(next.titleKey)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => _leave(sheet),
                  child: Text(AcademyStrings.get('common.done')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _leave(BuildContext sheet) {
    Navigator.of(sheet).pop();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/academy');
    }
  }

  Future<void> _showSources() async {
    final LessonProvenance? prov = provenanceOf(_lesson.id);
    final List<String> sources = lessonSources(_lesson, _r);
    final int flagged = _lesson.steps.where((V3Step s) => s.review != null).length;
    await showNamedSheet<void>(
      label: 'Where this lesson comes from',
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          strong: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(prov?.label ?? kNotYetReviewedLabel,
                    style: AppText.eyebrow.copyWith(color: AppColors.gold)),
                const SizedBox(height: 8),
                Text(t('v3.sourcesHonest'),
                    style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5)),
                if (flagged > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('$flagged ${t('v3.flagged')}',
                      style: AppText.bodyMuted.copyWith(fontSize: 14, height: 1.5)),
                ],
                const SizedBox(height: 12),
                Text(t('v3.citedHere'), style: AppText.eyebrow),
                const SizedBox(height: 6),
                for (final String s in sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(s, style: AppText.body.copyWith(height: 1.45)),
                  ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(AcademyStrings.get('common.done')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(V3Step s) {
    switch (s) {
      case TeachStep():
        return TeachView(step: s, resolver: _r);
      case SayStep():
        return SayView(step: s, resolver: _r);
      case ListenStep():
        return ListenView(step: s, resolver: _r);
      case HowToStep():
        return HowToView(step: s);
      case ContrastStep():
        return ContrastView(step: s);
      case RecapStep():
        return RecapView(step: s);
      case DoItStep():
        return DoItView(step: s);
      case CheckStep():
        final CheckStepState st =
            _checks.putIfAbsent(s.id, () => CheckStepState(s, _run));
        return CheckView(
          key: ValueKey<String>('check-${s.id}'),
          state: st,
          resolver: _r,
          onGoBack: _goBackTo,
          onPassed: () => _pass(s.id),
        );
      case ArrangeStep():
        final ArrangeState st =
            _arranges.putIfAbsent(s.id, () => ArrangeState(s, _run));
        return ArrangeView(
          key: ValueKey<String>('arrange-${s.id}'),
          state: st,
          onGoBack: _goBackTo,
          onPassed: () => _pass(s.id),
        );
      case MatchStep():
        final MatchState st =
            _matches.putIfAbsent(s.id, () => MatchState(s, _run));
        return MatchView(
          key: ValueKey<String>('match-${s.id}'),
          state: st,
          resolver: _r,
          onGoBack: _goBackTo,
          onPassed: () => _pass(s.id),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final V3Step step = _step;
    final bool open = !_isGate(step) || _passed.contains(step.id);
    final int total = _lesson.steps.length;
    final bool canReturn = _resumeAt != null && _index < _resumeAt!;
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
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.gold, size: 20),
                          onPressed: _back,
                        ),
                        Expanded(
                          child: Text(
                            _lesson.title,
                            style: AppText.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          key: const Key('ask-wasia'),
                          tooltip: 'Ask Wasia about this lesson',
                          icon: const Icon(Icons.forum_outlined,
                              color: AppColors.gold, size: 22),
                          onPressed: () =>
                              showLessonWasiaSheet(context, ref, _grounding),
                        ),
                        Text('${_index + 1}/$total', style: AppText.caption),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FocusRing(borderRadius: 12, child: InkWell(
                            onTap: _showSources,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.info_outline,
                                      size: 14, color: AppColors.gold),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${provenanceOf(_lesson.id)?.label ?? kNotYetReviewedLabel}'
                                      ' · ${t('v3.sources')}',
                                      style: AppText.caption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ),
                        ShareButton(
                          doc: _shareDoc(),
                          subject: 'this lesson',
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / total,
                        minHeight: 4,
                        backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: ValueKey<int>(_index),
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    if (step.review != null || step is ContrastStep)
                      ScholarReviewNote(
                        key: const Key('v3-step-review-note'),
                        reviewKey: 'lesson.${_lesson.id}.${step.id}',
                      ),
                    _body(step),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: <Widget>[
                    if (!open)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(t('v3.gateHint'), style: AppText.caption),
                      ),
                    if (canReturn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: const Key('v3-back-to-question'),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48)),
                            onPressed: _backToQuestion,
                            child: Text(t('v3.backToQuestion')),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('v3-next'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48)),
                        onPressed: open ? _next : null,
                        child: Text(
                          _isLast
                              ? t('v3.finish')
                              : AcademyStrings.get('common.next'),
                        ),
                      ),
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
}
