/// Al-Wasia Academy of Sacred Knowledge — domain models (Wave 1).
///
/// The Academy FORMATS existing Ar-Rayaan modules; it does not duplicate
/// them. A lesson step is a *reference*: text it teaches, an action that
/// opens a feature route, an embed of another module's content, or a
/// knowledge check. One idea per step (Simplicity Charter).
library;

enum AcademyStepKind { text, action, embed, check }

/// One teach/check/reflect beat. 30-90 seconds of attention, then action.
class AcademyStep {
  const AcademyStep({
    required this.kind,
    required this.titleKey,
    this.bodyKey = '',
    this.route,
    this.ref,
    this.assessmentId,
    this.honestyLabel,
  });

  final AcademyStepKind kind;

  /// Key into AcademyStrings.
  final String titleKey;
  final String bodyKey;

  /// `action` steps: an AppRoutes path the button opens.
  final String? route;

  /// `embed` steps: `owner.feature` reference (e.g. `prayer.times`).
  final String? ref;

  /// `check` steps: id into the assessment catalog.
  final String? assessmentId;

  /// Optional honesty label: '[Established]' / '[Interpretive]' / '[Reflection]'.
  final String? honestyLabel;
}

class AcademyLesson {
  const AcademyLesson({
    required this.id,
    required this.unitId,
    required this.courseId,
    required this.titleKey,
    required this.steps,
  });

  final String id;
  final String unitId;
  final String courseId;
  final String titleKey;
  final List<AcademyStep> steps;
}

class AcademyUnit {
  const AcademyUnit({
    required this.id,
    required this.courseId,
    required this.titleKey,
    required this.subtitleKey,
    required this.lessons,
  });

  final String id;
  final String courseId;
  final String titleKey;
  final String subtitleKey;
  final List<AcademyLesson> lessons;
}

class AcademyCourse {
  const AcademyCourse({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.units,

    /// False -> rendered as "Coming soon - insha'Allah" (never a paywall).
    this.available = true,
  });

  final String id;
  final String titleKey;
  final String subtitleKey;
  final List<AcademyUnit> units;
  final bool available;
}

/// Per-lesson resume/completion state. Persisted on-device only.
class LessonProgress {
  const LessonProgress({this.lastStep = 0, this.completed = false});

  final int lastStep;
  final bool completed;

  LessonProgress copyWith({int? lastStep, bool? completed}) => LessonProgress(
    lastStep: lastStep ?? this.lastStep,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lastStep': lastStep,
    'completed': completed,
  };

  factory LessonProgress.fromJson(Map<String, dynamic> json) =>
      LessonProgress(
        lastStep: (json['lastStep'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
