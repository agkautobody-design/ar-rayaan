/// "Where should I start in The Path?": a short check built from the Path's
/// own lesson questions. See `path_placement.dart`.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/academy_providers.dart';
import '../../application/academy_strings.dart';
import '../../application/lessons_v3_provider.dart';
import '../../domain/academy_models.dart';
import '../../domain/course_manifest.dart';
import '../../domain/learner_path.dart';
import '../../domain/next_lesson.dart';
import '../../domain/path_placement.dart';
import '../../domain/review_questions.dart';
import '../../domain/v3/lesson_v3_model.dart';
import '../../domain/v3/lesson_v3_review.dart';
import '../../domain/v3/lessons_v3.dart';

/// One lesson of the ladder, with the questions asked about it.
class PlacementRung {
  const PlacementRung({
    required this.title,
    required this.route,
    required this.questions,
  });
  final String title;
  final String route;
  final List<ReviewQuestion> questions;
}

Future<void> showPathPlacement(BuildContext context) => showDialog<void>(
      context: context,
      builder: (BuildContext c) => const PathPlacementDialog(),
    );

/// Loads the lessons, then shows the check. If the lessons cannot be loaded
/// it says so and offers the Path itself: it never leaves a dead end.
class PathPlacementDialog extends ConsumerWidget {
  const PathPlacementDialog({super.key});

  static List<PlacementRung> rungsFrom(LessonsV3 v3) {
    final List<PlacementRung> out = <PlacementRung>[];
    for (final String id in kPathLadder) {
      final LessonV3? l = v3[id];
      final AcademyLesson? m = findLessonById(id);
      if (l == null || m == null) continue;
      final List<ReviewQuestion> qs = v3ReviewQuestions(
        l,
        v3.resolver,
        count: kPlacementPerLesson,
      );
      if (qs.isEmpty) continue;
      out.add(PlacementRung(
        title: AcademyStrings.get(m.titleKey),
        route: lessonRoute(m),
        questions: qs,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LessonsV3> v3 = ref.watch(lessonsV3Provider);
    return v3.when(
      loading: () => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
      ),
      error: (Object e, StackTrace s) => _unavailable(context),
      data: (LessonsV3 data) {
        final List<PlacementRung> rungs = rungsFrom(data);
        if (rungs.isEmpty) return _unavailable(context);
        return PathPlacementView(
          rungs: rungs,
          onAccept: (LearnerLevel l) =>
              ref.read(learnerLevelProvider.notifier).set(l),
        );
      },
    );
  }

  Widget _unavailable(BuildContext context) => AlertDialog(
        title: const Text('Where to begin'),
        content: const Text(
            'The check is not available right now. You can start at the '
            'beginning of The Path, and open any lesson you like.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              final GoRouter r = GoRouter.of(context);
              Navigator.of(context).pop();
              r.go('/academy/course/the-path');
            },
            child: const Text('Open The Path'),
          ),
        ],
      );
}

/// The questions, one at a time, then where to start. No answer is marked.
class PathPlacementView extends StatefulWidget {
  const PathPlacementView({
    super.key,
    required this.rungs,
    required this.onAccept,
  });

  final List<PlacementRung> rungs;
  final void Function(LearnerLevel level) onAccept;

  @override
  State<PathPlacementView> createState() => _PathPlacementViewState();
}

class _PathPlacementViewState extends State<PathPlacementView> {
  late final List<List<bool>> _answers =
      <List<bool>>[for (final PlacementRung _ in widget.rungs) <bool>[]];
  int _rung = 0;

  int get _total =>
      widget.rungs.fold(0, (int n, PlacementRung r) => n + r.questions.length);
  int get _asked => _answers.fold(0, (int n, List<bool> a) => n + a.length);

  void _answer(bool right) => setState(() {
        _answers[_rung].add(right);
        if (_answers[_rung].length >= widget.rungs[_rung].questions.length &&
            _rung < widget.rungs.length - 1) {
          _rung++;
        }
      });

  @override
  Widget build(BuildContext context) {
    if (_asked >= _total) return _result(context);
    final PlacementRung r = widget.rungs[_rung];
    final ReviewQuestion q = r.questions[_answers[_rung].length];
    return AlertDialog(
      semanticLabel: 'Question ${_asked + 1} of $_total',
      title: Text('Question ${_asked + 1} of $_total'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (q.glyph != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(q.glyph!, style: const TextStyle(fontSize: 26)),
                ),
              ),
            Text(q.prompt),
            const SizedBox(height: 12),
            for (int k = 0; k < q.options.length; k++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: ValueKey<String>('pp-opt-$k'),
                    onPressed: () => _answer(k == q.answer),
                    child: Text(q.options[k]),
                  ),
                ),
              ),
            TextButton(
              key: const ValueKey<String>('pp-skip'),
              // "I do not know" is a fine answer; it is never a wrong one.
              onPressed: () => _answer(false),
              child: const Text('I am not sure'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _result(BuildContext context) {
    final PathPlacementOutcome o = placementFor(_answers);
    final PlacementRung? start =
        o.startIndex == null ? null : widget.rungs[o.startIndex!];
    return AlertDialog(
      semanticLabel: 'Where to begin',
      title: const Text('Where to begin'),
      content: Text(
        start == null
            ? o.line
            : '${o.line}\n\nStart with: ${start.title}. You can still open any lesson.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          key: const ValueKey<String>('pp-go'),
          onPressed: () {
            final GoRouter router = GoRouter.of(context);
            widget.onAccept(o.level);
            Navigator.of(context).pop();
            router.go(start?.route ?? '/academy/understanding');
          },
          child: Text(start == null ? 'Go deeper' : 'Start there'),
        ),
      ],
    );
  }
}
