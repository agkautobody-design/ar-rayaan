import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_text.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../habits/presentation/habits_card.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../application/journey_providers.dart';
import '../domain/journey_progress.dart';
import 'saved_stories_sheet.dart';

/// Screen 8 · My Journey — progress ring + what you have done + My Path.
///
/// The ring is REAL progress and says what it measures (see
/// [kRingExplanation]); under it, plain counts of what the app has recorded.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  static const List<(IconData, String, String?)> _path = [
    (Icons.auto_stories_outlined, 'My Reflections', AppRoutes.noorReflections),
    (Icons.school_outlined, 'My Learning', AppRoutes.academy),
    (Icons.self_improvement_outlined, 'Dhikr Sessions', '/academy/dhikr'),
    (Icons.psychology_outlined, 'Memorise (Hifz Planner)', '/academy/hifz'),
    (Icons.replay_circle_filled_outlined, 'Review Cards', '/academy/review'),
    (Icons.edit_note, 'Gratitude Journal', AppRoutes.notes),
    (Icons.bookmark_outline, 'Bookmarks', _bookmarks),
  ];

  /// Sentinel route: Bookmarks opens the saved-stories sheet, not a page.
  static const String _bookmarks = '#bookmarks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<JourneyStats> stats = ref.watch(journeyStatsProvider);
    final JourneyStats? s = stats.valueOrNull;
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: 'My Journey'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starter progress',
                                style: AppText.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kRingExplanation,
                                key: const Key('journey-ring-explained'),
                                style: AppText.bodyMuted.copyWith(
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ProgressRing(value: s?.progress ?? 0),
                      ],
                    ),
                  ),
                  if (s != null) _DoneCard(stats: s),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 24, bottom: 8),
                    child: Text('MY PATH', style: AppText.eyebrow),
                  ),
                  GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < _path.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.1),
                              indent: 64,
                            ),
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: _path[i].$3 == null
                                  ? null
                                  : _path[i].$3 == _bookmarks
                                      ? () => showSavedStories(context)
                                      : () => context.open(_path[i].$3!),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    IconTile(icon: _path[i].$1),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _path[i].$2,
                                        style: AppText.body.copyWith(
                                          color: AppColors.sand.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.gold.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const HabitsCard(),
                  const SizedBox(height: 32),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'وَقُل رَّبِّ زِدْنِي عِلْمًا',
                      style: AppText.arabicLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.gold.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (context, v, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
              Center(
                child: GoldText(
                  '${(v * 100).round()}%',
                  style: AppText.titleMedium.copyWith(fontSize: 20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// Plain counts of what the app has recorded, each one a door to where it
/// happens. Nothing here is estimated: if the app does not record it, it is
/// not shown (it does not count ayahs read, only surahs opened).
class _DoneCard extends ConsumerWidget {
  const _DoneCard({required this.stats});

  final JourneyStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SurahMeta> index =
        ref.watch(quranIndexProvider).valueOrNull ?? const <SurahMeta>[];
    final ReadingPosition? place = stats.place;
    String? placeText;
    if (place != null) {
      String name = 'Surah ${place.surah}';
      for (final SurahMeta m in index) {
        if (m.number == place.surah) name = m.transliteration;
      }
      placeText = '$name, ayah ${place.ayah}';
    }
    final List<RingPart> parts = ringParts(
      RingInputs(
        adhkarDone: stats.adhkarDone,
        adhkarTotal: stats.adhkarTotal,
        openedSurah: stats.readingStarted,
        reflections: stats.reflections,
        lessonsDone: stats.lessonsDone,
      ),
    );
    final List<(String, String, String)> rows = <(String, String, String)>[
      (
        'Surahs opened',
        '${stats.surahsOpened} of 114',
        AppRoutes.quran,
      ),
      if (place != null && placeText != null)
        (
          'Your place in the Qur’an',
          placeText,
          AppRoutes.surahAt(place.surah, place.ayah),
        ),
      (
        'Ayahs bookmarked',
        '${stats.ayahBookmarks}',
        AppRoutes.quranBookmarks,
      ),
      ('Stories saved', '${stats.savedStories}', AppRoutes.stories),
      (
        'Ayat you marked as memorised',
        '${stats.ayatMemorised}',
        '/academy/hifz',
      ),
      ('Review cards due now', '${stats.reviewsDue}', '/academy/review'),
      ('Lessons finished', '${stats.lessonsDone}', AppRoutes.academy),
      (
        'Adhkar counted today',
        '${stats.adhkarDone} of ${stats.adhkarTotal}',
        AppRoutes.adhkar,
      ),
      ('Reflections saved', '${stats.reflections}', AppRoutes.noorReflections),
      (
        'Days you learned (last 7)',
        daysThisWeekText(stats.daysThisWeek),
        AppRoutes.academy,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 24, bottom: 8),
          child: Text('WHAT YOU HAVE DONE', style: AppText.eyebrow),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              for (final RingPart p in parts)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        p.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: AppColors.gold.withValues(
                          alpha: p.done ? 1 : 0.6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${p.label} (${(p.weight * 100).round()}%)',
                          style: AppText.body.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              Divider(color: AppColors.gold.withValues(alpha: 0.15)),
              for (final (String, String, String) r in rows)
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => context.open(r.$3),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                r.$1,
                                style: AppText.body.copyWith(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                r.$2,
                                key: Key('journey-${r.$1}'),
                                textAlign: TextAlign.end,
                                style: AppText.body.copyWith(
                                  fontSize: 14,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.gold.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Counted on this device only. The app records which '
                  'surahs you open, not how many ayahs you read, and the '
                  'memorised list is your own: a teacher confirms it.',
                  style: AppText.caption.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
