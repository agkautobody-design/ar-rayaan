import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/academy_models.dart';
import '../domain/learner_path.dart';
import '../domain/next_lesson.dart';
import 'academy_providers.dart';
import 'academy_strings.dart';
import 'child_age_band.dart';
import 'family_service.dart';
import 'wasia_controller.dart' show WasiaPersona;

/// One coaching turn: the reply, built on the device.
class CoachTurn {
  const CoachTurn(this.reply);
  final CoachReply reply;
}

/// Builds a coaching reply from this learner's own numbers.
///
/// This lives apart from the controller on purpose. The controller never
/// reads a child's progress (a test guards that); this file does, and its
/// result is only ever shown on screen: the caller marks the messages
/// sensitive, so none of it is part of what an AI service is sent.
///
/// A parent is not given a child's numbers; a parent is pointed to the
/// Family Wing, which shows them.
Future<CoachTurn> wasiaCoachTurn(
  Ref ref,
  CoachAsk ask,
  WasiaPersona persona,
) async {
  if (persona == WasiaPersona.parent) {
    return const CoachTurn(CoachReply(
      'The Family Wing shows each child’s lessons, and gives one small '
      'activity to do together. Pick one and keep it short.',
      route: '/academy/family',
      routeLabel: 'Open the Family Wing',
    ));
  }
  final LearnerLevel? level = ref.read(learnerLevelProvider);
  final String? childId = await ChildAgeBand.activeId();
  int lettersDone = 0;
  String? band;
  if (childId != null) {
    band = await ChildAgeBand.active();
    try {
      final Map<String, dynamic> p =
          await ref.read(progressProvider(childId).future);
      lettersDone = (p['lessons'] as Map).length;
    } catch (_) {}
  }
  final AcademyLesson? cont = ref.read(continueLessonProvider);
  final LearnerSnapshot snap = LearnerSnapshot(
    level: level,
    lessonsDone: ref.read(lessonsDoneProvider),
    lettersDone: lettersDone,
    reviewsDue: ref.read(lessonReviewsDueProvider).length,
    childBand: band,
    nextLessonTitle: cont == null ? null : AcademyStrings.get(cont.titleKey),
    nextLessonRoute: cont == null ? null : lessonRoute(cont),
  );
  final CoachReply r = LearnerCoach.reply(ask, snap);
  // A child's level stays with the parent; only a grown-up's is changed here.
  if (r.setLevel != null && childId == null) {
    await ref.read(learnerLevelProvider.notifier).set(r.setLevel!);
  }
  return CoachTurn(r);
}
