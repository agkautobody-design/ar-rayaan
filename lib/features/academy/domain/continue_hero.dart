/// What the Academy home "Continue" card should say and show.
///
/// A lesson nobody has opened must not read "Continue where you left off"
/// with a part-filled bar: the old bar computed (lastStep + 1) / steps, so a
/// first-time learner saw 25% on a lesson they had never started.
library;

import 'academy_models.dart';

class ContinueHero {
  const ContinueHero({required this.started, required this.progress});

  /// True once the learner has moved past the first step of this lesson.
  final bool started;

  /// 0..1. Zero for a lesson not yet started.
  final double progress;
}

ContinueHero continueHeroFor(LessonProgress? saved, int totalSteps) {
  if (saved == null || totalSteps <= 0) {
    return const ContinueHero(started: false, progress: 0);
  }
  if (saved.completed) return const ContinueHero(started: true, progress: 1);
  if (saved.lastStep <= 0) {
    return const ContinueHero(started: false, progress: 0);
  }
  final int idx = saved.lastStep.clamp(0, totalSteps - 1);
  return ContinueHero(started: true, progress: (idx + 1) / totalSteps);
}
