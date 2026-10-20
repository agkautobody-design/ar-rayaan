/// Generated recall checks for manifest lessons (see
/// `domain/recall_check.dart` for the method and its limits).
///
/// This file only gathers each lesson's own strings and caches the result;
/// the question itself comes from [RecallCheckBuilder].
library;

import '../domain/academy_models.dart';
import '../domain/assessment_engine.dart';
import '../domain/course_manifest.dart';
import '../domain/recall_check.dart';
import 'academy_strings.dart';

abstract final class RecallChecks {
  static const String idPrefix = 'recall:';

  static final Map<String, RecallCheck?> _cache = <String, RecallCheck?>{};
  static List<String>? _poolSorted;

  /// True when a lesson ends in a hand-written check already.
  static bool hasHandWrittenCheck(AcademyLesson lesson) => lesson.steps.any(
        (AcademyStep s) => s.kind == AcademyStepKind.check,
      );

  static String _stepText(AcademyStep s) =>
      '${AcademyStrings.get(s.titleKey)} ${AcademyStrings.get(s.bodyKey)}';

  static String fullTextOf(AcademyLesson lesson) =>
      '${AcademyStrings.get(lesson.titleKey)} '
      '${lesson.steps.map(_stepText).join(' ')}';

  static List<String> _teachingText(AcademyLesson lesson) => <String>[
        for (final AcademyStep s in lesson.steps)
          if (s.kind == AcademyStepKind.text && s.bodyKey.isNotEmpty)
            AcademyStrings.get(s.bodyKey),
      ];

  static List<String> _pool() {
    final List<String>? have = _poolSorted;
    if (have != null) return have;
    final Set<String> words = <String>{};
    for (final AcademyCourse c in kAcademyCourses) {
      for (final AcademyUnit u in c.units) {
        for (final AcademyLesson l in u.lessons) {
          words.addAll(RecallCheckBuilder.poolWords(fullTextOf(l)));
        }
      }
    }
    final List<String> sorted = words.toList()..sort();
    _poolSorted = sorted;
    return sorted;
  }

  /// The generated check for [lesson], or null when the lesson has a
  /// hand-written check or offers no suitable sentence.
  static RecallCheck? forLesson(AcademyLesson lesson) {
    if (_cache.containsKey(lesson.id)) return _cache[lesson.id];
    RecallCheck? built;
    if (!hasHandWrittenCheck(lesson)) {
      built = RecallCheckBuilder.build(
        lessonId: lesson.id,
        teachingText: _teachingText(lesson),
        fullText: fullTextOf(lesson),
        poolSorted: _pool(),
      );
    }
    _cache[lesson.id] = built;
    return built;
  }

  /// The lesson's steps with its recall check appended as a final `check`
  /// step when one exists.
  static List<AcademyStep> stepsWithRecall(AcademyLesson lesson) {
    if (forLesson(lesson) == null) return lesson.steps;
    return <AcademyStep>[
      ...lesson.steps,
      AcademyStep(
        kind: AcademyStepKind.check,
        titleKey: 'recall.title',
        assessmentId: '$idPrefix${lesson.id}',
      ),
    ];
  }

  /// Items for a check step: a hand-written assessment, or a generated recall
  /// check (`recall:<lessonId>`). Null when the id is unknown.
  static List<AssessmentItem>? itemsFor(String assessmentId) {
    if (assessmentId.startsWith(idPrefix)) {
      final AcademyLesson? lesson =
          findLessonById(assessmentId.substring(idPrefix.length));
      if (lesson == null) return null;
      final RecallCheck? rc = forLesson(lesson);
      return rc == null ? null : <AssessmentItem>[rc.toItem()];
    }
    return kAssessments[assessmentId];
  }
}
