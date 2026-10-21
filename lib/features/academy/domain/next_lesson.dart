/// "What comes next" after a lesson, in the order a learner meets them.
library;

import 'academy_models.dart';
import 'course_manifest.dart';

/// The lesson that follows [lessonId] inside its own course (units in order,
/// lessons in order), or null when it is the last one or is not found.
/// Only the same course: finishing the last lesson of a school should not
/// silently drop the learner into another school.
AcademyLesson? nextLessonAfter(String lessonId) {
  for (final AcademyCourse c in kAcademyCourses) {
    final List<AcademyLesson> flat = <AcademyLesson>[
      for (final AcademyUnit u in c.units) ...u.lessons,
    ];
    final int i = flat.indexWhere((AcademyLesson l) => l.id == lessonId);
    if (i < 0) continue;
    return i + 1 < flat.length ? flat[i + 1] : null;
  }
  return null;
}

/// The app route for a manifest lesson.
String lessonRoute(AcademyLesson l) =>
    '/academy/lesson/${l.courseId}/${l.unitId}/${l.id}';
