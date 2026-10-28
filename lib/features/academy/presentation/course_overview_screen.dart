import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/academy_providers.dart';
import '../application/academy_strings.dart';
import '../domain/academy_entry.dart';
import '../domain/academy_models.dart';
import '../domain/course_manifest.dart';
import '../domain/lesson_provenance.dart';
import '../domain/next_lesson.dart';
import '../../../app/theme/widgets/focus_ring.dart';

/// One tracked course: its lessons, what is done, one button to continue.
///
/// This is where a school row on the Academy home leads. The static reading
/// page of the same school is one button away (it is kept, not replaced), and
/// The Path also links to the 30-day New Muslim road.
class CourseOverviewScreen extends ConsumerWidget {
  const CourseOverviewScreen({super.key, required this.courseId});

  final String courseId;

  static AcademyCourse? courseOf(String id) {
    for (final AcademyCourse c in kAcademyCourses) {
      if (c.id == id && c.hasLessons) return c;
    }
    return null;
  }

  /// The lesson the main button opens: the first one not finished, or the
  /// first of the course when every lesson is done.
  static AcademyLesson nextIn(
    AcademyCourse course,
    Map<String, LessonProgress> progress,
  ) {
    final List<AcademyLesson> all = <AcademyLesson>[
      for (final AcademyUnit u in course.units) ...u.lessons,
    ];
    for (final AcademyLesson l in all) {
      if (!(progress[l.id]?.completed ?? false)) return l;
    }
    return all.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AcademyCourse? course = courseOf(courseId);
    if (course == null) {
      return Scaffold(
        body: ScenicScaffold.pattern(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                const ScreenHeader(title: 'Course'),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'This course is not available.',
                    style: AppText.body,
                  ),
                ),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.academy),
                  child: const Text('Back to the Academy'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Map<String, LessonProgress> progress =
        ref.watch(academyProgressProvider);
    final List<AcademyLesson> all = <AcademyLesson>[
      for (final AcademyUnit u in course.units) ...u.lessons,
    ];
    final int done = all
        .where((AcademyLesson l) => progress[l.id]?.completed ?? false)
        .length;
    final AcademyLesson next = nextIn(course, progress);
    final bool allDone = done == all.length;
    final bool started = done > 0 || (progress[next.id]?.lastStep ?? 0) > 0;
    final CourseStaticLink? link = staticLinkFor(course.id);
    final Set<String> labels = <String>{
      for (final AcademyLesson l in all)
        provenanceOf(l.id)?.label ?? kNotYetReviewedLabel,
    };

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  ScreenHeader(title: AcademyStrings.get(course.titleKey)),
                  Text(
                    AcademyStrings.get(course.subtitleKey),
                    style: AppText.bodyMuted.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$done / ${all.length} lessons · ${labels.join(' · ')}',
                    key: const Key('course-progress-line'),
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    strong: true,
                    onTap: () => context.push(lessonRoute(next)),
                    semanticsLabel: allDone
                        ? 'Go through the course again, starting with '
                            '${AcademyStrings.get(next.titleKey)}'
                        : '${started ? 'Continue' : 'Start'}: '
                            '${AcademyStrings.get(next.titleKey)}',
                    child: Row(
                      key: const Key('course-start'),
                      children: <Widget>[
                        const Icon(Icons.play_circle_outline,
                            color: AppColors.gold, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                allDone
                                    ? 'Go through it again'
                                    : (started ? 'Continue' : 'Start here'),
                                style: AppText.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AcademyStrings.get(next.titleKey),
                                style: AppText.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (link != null)
                    OutlinedButton.icon(
                      key: const Key('course-static-link'),
                      onPressed: () => context.push(link.route),
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(link.label),
                    ),
                  if (course.id == 'the-path') ...<Widget>[
                    OutlinedButton.icon(
                      key: const Key('course-30day'),
                      onPressed: () => context.push(AppRoutes.newMuslimPath),
                      icon: const Icon(Icons.calendar_month_outlined,
                          size: 18),
                      label: const Text('The 30-day New Muslim road'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'The same ground, as one short reading a day. '
                        'Walk either one, or both.',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final AcademyUnit u in course.units)
                    if (u.lessons.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Text(
                          AcademyStrings.get(u.titleKey).toUpperCase(),
                          style: AppText.eyebrow,
                        ),
                      ),
                      for (final AcademyLesson l in u.lessons)
                        _LessonRow(
                          lesson: l,
                          done: progress[l.id]?.completed ?? false,
                        ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.done});

  final AcademyLesson lesson;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final String title = AcademyStrings.get(lesson.titleKey);
    return Semantics(
      button: true,
      label: '$title, ${done ? 'done' : 'not done yet'}',
      excludeSemantics: true,
      onTap: () => context.push(lessonRoute(lesson)),
      child: FocusRing(borderRadius: 12, child: InkWell(
        onTap: () => context.push(lessonRoute(lesson)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  done
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: AppColors.goldLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.body,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.gold),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
