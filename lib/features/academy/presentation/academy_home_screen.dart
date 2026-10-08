import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/academy_providers.dart';
import '../application/word_deck_provider.dart';
import '../application/academy_strings.dart';
import '../domain/academy_models.dart';

/// Al-Wasia Academy of Sacred Knowledge — home (Wave 1).
/// Locked look: Playfair header · continue hero · The Path card ·
/// 2×2 school grid (coming-soon schools are honest, never paywalled) ·
/// gentle Today strip · daily verse. Simplicity Charter: ≤5 visible
/// items per region, icon+label, three taps to anything core.
class AcademyHomeScreen extends ConsumerStatefulWidget {
  const AcademyHomeScreen({super.key});

  @override
  ConsumerState<AcademyHomeScreen> createState() =>
      _AcademyHomeScreenState();
}

class _AcademyHomeScreenState
    extends ConsumerState<AcademyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wordDeckProvider.notifier).seedFromPack();
    });
  }


  static const String _verseRef = 'Qur’an 39:9';
  static const String _verseText =
      'Say: Are those who know equal to those who do not know?';

  @override
  Widget build(BuildContext context) {
    final List<AcademyCourse> courses = ref.watch(academyCoursesProvider);
    final AcademyCourse path = courses.firstWhere(
      (AcademyCourse c) => c.id == 'the-path',
    );
    final List<AcademyCourse> schools = courses
        .where((AcademyCourse c) => c.id != 'the-path')
        .toList();
    final AcademyLesson? cont = ref.watch(continueLessonProvider);
    final int done = ref.watch(lessonsDoneProvider);
    final String s = AcademyStrings.get('academy.title');

    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              ScreenHeader(title: s),
              const SizedBox(height: 8),

              // Continue hero -------------------------------------------------
              if (cont != null)
                GlassCard(
                  strong: true,
                  onTap: () => context.go(
                    '/academy/lesson/${cont.courseId}/${cont.unitId}/${cont.id}',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AcademyStrings.get('academy.continue'),
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AcademyStrings.get(cont.titleKey),
                        style: AppText.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress(ref, cont),
                          minHeight: 4,
                          backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GlassCard(
                  strong: true,
                  onTap: () {
                    final AcademyLesson first = path.units.first.lessons.first;
                    context.go(
                      '/academy/lesson/${first.courseId}/${first.unitId}/${first.id}',
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.route_outlined,
                        color: AppColors.gold,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AcademyStrings.get('path.title'),
                              style: AppText.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AcademyStrings.get('path.subtitle'),
                              style: AppText.bodyMuted,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // School grid (2×2) --------------------------------------------
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: <Widget>[
                  for (final AcademyCourse school in schools)
                    _SchoolCard(course: school),
                ],
              ),
              const SizedBox(height: 16),

              // Today strip ----------------------------------------------------
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _TodayStat(
                      label: AcademyStrings.get('academy.lessonsDone'),
                      value: '$done',
                    ),
                    _TodayStat(
                      label: AcademyStrings.get('academy.wordsReviewed'),
                      value: ref
                          .watch(wordsDueProvider)
                          .toString(),
                    ),
                    _TodayStat(
                      label: AcademyStrings.get('academy.ayatListened'),
                      value: '0',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily verse -----------------------------------------------------
              GlassCard(
                onTap: () => context.go('/quran/39'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AcademyStrings.get('academy.dailyVerse'),
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 8),
                    Text(_verseText, style: AppText.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      '$_verseRef · ${AcademyStrings.get('academy.translationCredit')}',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progress(WidgetRef ref, AcademyLesson lesson) {
    final LessonProgress p = ref.watch(
      academyProgressProvider.select(
        (Map<String, LessonProgress> m) =>
            m[lesson.id] ?? const LessonProgress(),
      ),
    );
    final int total = lesson.steps.length;
    if (total == 0) return 0;
    final int idx = p.lastStep.clamp(0, total - 1);
    return p.completed ? 1 : (idx + 1) / total;
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.course});

  final AcademyCourse course;

  static const Map<String, IconData> _icons = <String, IconData>{
    'letters': Icons.edit_outlined,
    'recitation': Icons.graphic_eq,
    'quranic-arabic': Icons.abc,
    'understanding': Icons.account_tree_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final IconData icon = _icons[course.id] ?? Icons.menu_book_outlined;
    return GlassCard(
      onTap: course.available && course.units.isNotEmpty
          ? () => context.go('/academy/${course.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: AppColors.gold, size: 26),
          const SizedBox(height: 10),
          Text(
            AcademyStrings.get(course.titleKey),
            style: AppText.titleMedium.copyWith(color: AppColors.gold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              course.available
                  ? AcademyStrings.get(course.subtitleKey)
                  : AcademyStrings.get('academy.comingSoon'),
              style: AppText.bodyMuted,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  const _TodayStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: AppText.displayMedium.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppText.bodyMuted, textAlign: TextAlign.center),
      ],
    );
  }
}
