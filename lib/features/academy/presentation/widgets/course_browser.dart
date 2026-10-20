import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/widgets/glass_card.dart';
import '../../application/academy_providers.dart';
import '../../application/academy_strings.dart';
import '../../domain/academy_models.dart';

/// Every manifest lesson, by course and unit, each one tappable. Before this
/// existed, lessons beyond the first were reachable only by finishing the
/// previous one in order ("Continue"); now any lesson can be opened and the
/// learner always sees what is done. Only courses that really carry lessons
/// are listed (see [AcademyCourse.hasLessons]) - a course with nothing in it
/// is never shown as if it were live.
class CourseBrowser extends ConsumerWidget {
  const CourseBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AcademyCourse> courses = ref
        .watch(academyCoursesProvider)
        .where((AcademyCourse c) => c.hasLessons)
        .toList();
    final Map<String, LessonProgress> progress =
        ref.watch(academyProgressProvider);
    return Column(
      children: <Widget>[
        for (final AcademyCourse c in courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey<String>('course-${c.id}'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  iconColor: AppColors.gold,
                  collapsedIconColor: AppColors.gold,
                  title: Text(
                    AcademyStrings.get(c.titleKey),
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_done(c, progress)} / ${_total(c)} lessons',
                    style: AppText.caption,
                  ),
                  children: <Widget>[
                    for (final AcademyUnit u in c.units)
                      if (u.lessons.isNotEmpty) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AcademyStrings.get(u.titleKey).toUpperCase(),
                              style: AppText.eyebrow,
                            ),
                          ),
                        ),
                        for (final AcademyLesson l in u.lessons)
                          InkWell(
                            onTap: () => context.go(
                              '/academy/lesson/${l.courseId}/${l.unitId}/${l.id}',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    (progress[l.id]?.completed ?? false)
                                        ? Icons.check_circle_outline
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: AppColors.goldLight,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AcademyStrings.get(l.titleKey),
                                      style: AppText.bodyMuted,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: AppColors.gold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static int _total(AcademyCourse c) =>
      c.units.fold<int>(0, (int a, AcademyUnit u) => a + u.lessons.length);

  static int _done(AcademyCourse c, Map<String, LessonProgress> p) => c.units
      .fold<int>(
        0,
        (int a, AcademyUnit u) =>
            a +
            u.lessons
                .where((AcademyLesson l) => p[l.id]?.completed ?? false)
                .length,
      );
}
