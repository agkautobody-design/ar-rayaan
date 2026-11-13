/// A placement for grown-ups who already know some of it: where in The Path
/// to begin.
///
/// Built ONLY from the questions the Path's own lessons already ask, which
/// have been through the lesson audit (sources named, answers checked against
/// the lesson text). No question is written here, so this file carries no
/// religious claim. Two questions per lesson, in lesson order.
///
/// Dignity-first, as the rest of the Academy: nothing is timed, no answer is
/// marked wrong on screen, there is no score and nothing is stored but the
/// level the learner accepts. It only suggests; any lesson can be opened.
library;

import 'learner_path.dart';

/// The Path's lessons in the order a learner meets them.
const List<String> kPathLadder = <String>[
  'path.u0.l1',
  'path.u1.l1',
  'path.u2.l1',
  'path.u3.l1',
];

/// Questions asked per lesson.
const int kPlacementPerLesson = 2;

/// Where the check suggests starting.
class PathPlacementOutcome {
  const PathPlacementOutcome({
    required this.startIndex,
    required this.level,
    required this.line,
  });

  /// Index into the ladder to start at, or null when every question was right.
  final int? startIndex;

  /// The level this suggests (the learner decides whether to accept it).
  final LearnerLevel level;

  /// A kind sentence for the result, without the lesson's name.
  final String line;
}

/// [byLesson] holds, per ladder lesson, whether each question was right at
/// the first pick. A lesson with no questions counts as known only if every
/// earlier lesson was, so a missing question never sends a learner backwards.
PathPlacementOutcome placementFor(List<List<bool>> byLesson) {
  for (int i = 0; i < byLesson.length; i++) {
    final List<bool> a = byLesson[i];
    if (a.isNotEmpty && a.any((bool right) => !right)) {
      return PathPlacementOutcome(
        startIndex: i,
        level: i == 0 ? LearnerLevel.fresh : LearnerLevel.basics,
        line: i == 0
            ? 'Starting at the beginning is a good place to be.'
            : 'You already know the earlier lessons. This is a good place to pick up.',
      );
    }
  }
  return const PathPlacementOutcome(
    startIndex: null,
    level: LearnerLevel.deeper,
    line: 'You know the foundations in The Path. You are ready to go deeper.',
  );
}
