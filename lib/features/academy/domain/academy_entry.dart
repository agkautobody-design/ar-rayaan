/// How a person enters the Academy: the front door, the learning track, and
/// which school rows open a tracked course.
///
/// Pure Dart, so the rules can be tested without a screen.
library;

import 'academy_models.dart';
import 'course_manifest.dart';
import 'next_lesson.dart';

/// The three doors on a first visit.
enum AcademyDoor { newToIslam, myChild, returning }

const String kDoorPref = 'ar.academy.door.v1';

extension AcademyDoorX on AcademyDoor {
  String get prefValue => switch (this) {
        AcademyDoor.newToIslam => 'new',
        AcademyDoor.myChild => 'child',
        AcademyDoor.returning => 'returning',
      };

  /// The learning track this door starts on, or null to leave it as it is.
  String? get track => switch (this) {
        AcademyDoor.newToIslam => 'teen',
        AcademyDoor.myChild => 'child',
        AcademyDoor.returning => null,
      };

  /// Where this door goes next, or null to stay on the Academy home.
  String? get route => switch (this) {
        AcademyDoor.newToIslam => lessonRoute(
            kAcademyCourses
                .firstWhere((AcademyCourse c) => c.id == 'the-path')
                .units
                .first
                .lessons
                .first,
          ),
        AcademyDoor.myChild => '/academy/letters',
        AcademyDoor.returning => null,
      };
}

AcademyDoor? doorFromPref(String? v) {
  for (final AcademyDoor d in AcademyDoor.values) {
    if (d.prefValue == v) return d;
  }
  return null;
}

/// The door the first-run screen offers first, from what the person picked
/// during onboarding (`ar.need`): "I am new to Islam" or "Teaching my
/// children". Anything else has no suggestion.
AcademyDoor? suggestedDoor(String? onboardingNeed) => switch (onboardingNeed) {
      'new' => AcademyDoor.newToIslam,
      'children' => AcademyDoor.myChild,
      _ => null,
    };

/// What the Academy home shows for a learning track. On the Child track the
/// other schools sit behind the parent check and so does switching to another
/// track (the Family Wing uses the same check); on Teen and Parent every
/// school is open. The check is the parent PIN; the full lock is child mode.
class TrackLayout {
  const TrackLayout({
    required this.lettersFirst,
    required this.foldSchools,
    required this.familyCard,
    required this.simpleCopy,
  });

  /// The top of the page is the next letter lesson, not the Path.
  final bool lettersFirst;

  /// The long list of schools sits behind one "more schools" row.
  final bool foldSchools;

  /// A card at the top leading to the Family Wing.
  final bool familyCard;

  /// Short, plain wording for the headings and the Today strip.
  final bool simpleCopy;

  static TrackLayout of(String track) => switch (track) {
        'child' => const TrackLayout(
            lettersFirst: true,
            foldSchools: true,
            familyCard: false,
            simpleCopy: true,
          ),
        'parent' => const TrackLayout(
            lettersFirst: false,
            foldSchools: false,
            familyCard: true,
            simpleCopy: false,
          ),
        _ => const TrackLayout(
            lettersFirst: false,
            foldSchools: false,
            familyCard: false,
            simpleCopy: false,
          ),
      };
}

/// The id of the first Letters lesson not yet finished, or null when all are
/// ([lessonIds] in lesson order).
String? firstUnfinishedLetterLesson(
  List<String> lessonIds,
  Map<String, LessonProgress> progress,
) {
  for (final String id in lessonIds) {
    if (!(progress[id]?.completed ?? false)) return id;
  }
  return null;
}

/// School rows on the Academy home whose static reading page has a tracked
/// course behind it. The row now opens the course (lessons, questions, saved
/// progress); the static page stays reachable from the course screen.
const Map<String, String> kSchoolRouteToCourse = <String, String>{
  '/academy/arabic-language': 'arabic-language',
  '/academy/hifz': 'hifz',
  '/academy/aqeedah': 'aqeedah',
  '/academy/character': 'character',
  '/academy/family-life': 'family',
  '/academy/youth': 'youth',
  '/academy/womens': 'womens',
  '/academy/transactions': 'transactions',
  '/academy/end-of-life': 'endoflife',
  '/academy/dawah': 'dawah',
  '/academy/health': 'health',
  '/academy/understanding': 'understanding',
};

/// The route of a course's overview screen.
String courseRoute(String courseId) => '/academy/course/$courseId';

/// The static page a course screen links to ("the full page"), with the
/// words on its button. Nothing is deleted: these pages keep working.
class CourseStaticLink {
  const CourseStaticLink(this.label, this.route);

  final String label;
  final String route;
}

CourseStaticLink? staticLinkFor(String courseId) {
  for (final MapEntry<String, String> e in kSchoolRouteToCourse.entries) {
    if (e.value != courseId) continue;
    return CourseStaticLink(
      courseId == 'hifz' ? 'Open the Hifz Planner' : 'Read the full page',
      e.key,
    );
  }
  return null;
}
