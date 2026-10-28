import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../academy/application/academy_providers.dart';
import '../../academy/application/hifz_providers.dart';
import '../../academy/application/word_deck_provider.dart';
import '../../academy/domain/hifz_planner.dart' show ayatInSurah, juzAmmaAyat;
import '../../academy/domain/hifz_progress.dart' show HifzState;
import '../../academy/domain/path_ux.dart';
import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../noor/application/noor_providers.dart';
import '../../quran/application/quran_marks_controller.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_marks.dart';
import '../../quran/domain/quran_models.dart';
import '../../stories/application/saved_stories_controller.dart';
import '../domain/journey_progress.dart';

/// Real progress signals from the shipped modules — no placeholders.
/// Only things the app actually records on this device are counted.
class JourneyStats {
  const JourneyStats({
    required this.progress,
    required this.adhkarDone,
    required this.adhkarTotal,
    required this.readingStarted,
    required this.reflections,
    this.lessonsDone = 0,
    this.surahsOpened = 0,
    this.place,
    this.ayahBookmarks = 0,
    this.savedStories = 0,
    this.ayatMemorised = 0,
    this.reviewsDue = 0,
    this.daysThisWeek = 0,
  });

  /// Composite 0..1 from [ringParts]: adhkar completion today (45%), a surah
  /// opened (10%), a reflection saved (15%), a lesson finished (15%), ayat
  /// written down as memorised (15%). Exactly 0 when none of these has
  /// happened.
  final double progress;

  /// Repetitions completed today across all adhkar sets.
  final int adhkarDone;
  final int adhkarTotal;

  /// A surah has been opened in the Qur'an reader.
  final bool readingStarted;

  /// Saved NOOR reflections.
  final int reflections;

  /// Academy lessons completed on this device.
  final int lessonsDone;

  /// Different surahs opened in the reader (the app records a place per
  /// surah, not how many ayahs were read).
  final int surahsOpened;

  /// The saved reading place (the last ayah tapped), if any.
  final ReadingPosition? place;

  /// Qur'an ayahs bookmarked, and stories saved.
  final int ayahBookmarks;
  final int savedStories;

  /// Ayat the person wrote down as memorised in the Hifz planner (their own
  /// list; the app does not test it).
  final int ayatMemorised;

  /// Review cards due now (Academy lessons and Qur'an words).
  final int reviewsDue;

  /// Days in the last seven on which the person finished an Academy lesson or
  /// answered a review.
  final int daysThisWeek;
}

final FutureProvider<JourneyStats> journeyStatsProvider =
    FutureProvider<JourneyStats>((ref) async {
      final List<AdhkarSet> sets = await ref.watch(adhkarSetsProvider.future);
      // Rebuild when any of the underlying signals change.
      ref.watch(adhkarProgressProvider);
      final AdhkarProgressController adhkar = ref.read(
        adhkarProgressProvider.notifier,
      );
      int done = 0;
      int total = 0;
      for (final AdhkarSet set in sets) {
        done += adhkar.completedInSet(set);
        total += set.totalRepetitions;
      }
      final ReadingPosition? place = ref.watch(readingPositionProvider);
      final bool readingStarted = place != null;
      final int surahsOpened = ref
          .read(readingPositionProvider.notifier)
          .surahsOpened;
      final int reflections = ref.watch(noorReflectionsProvider).length;

      int lessonsDone = 0;
      try {
        lessonsDone = ref.watch(lessonsDoneProvider);
      } catch (_) {
        // Academy progress unavailable (no prefs in a bare container).
      }

      int ayahBookmarks = 0;
      try {
        ayahBookmarks = ref
            .watch(quranMarksProvider)
            .marks
            .values
            .where((AyahMark m) => m.bookmarked)
            .length;
      } catch (_) {}

      int savedStories = 0;
      try {
        savedStories = ref.watch(savedStoriesProvider).length;
      } catch (_) {}

      int ayatMemorised = 0;
      int ayatPlanTotal = 0;
      int ayatInPlan = 0;
      try {
        final HifzState hifz = ref.watch(hifzStateProvider);
        ayatMemorised = hifz.totalMemorised;
        ayatPlanTotal = hifz.juzAmma
            ? juzAmmaAyat()
            : ayatInSurah(hifz.targetSurah);
        ayatInPlan = hifz.juzAmma
            ? hifz.juzAmmaMemorised
            : hifz.memorisedIn(hifz.targetSurah);
      } catch (_) {}

      int reviewsDue = 0;
      try {
        reviewsDue =
            ref.watch(lessonReviewsDueProvider).length +
            ref.watch(wordsDueProvider);
      } catch (_) {}

      int daysThisWeek = 0;
      try {
        daysThisWeek = WeeklyRhythm.of(
          ActivityLog.decode(
            ref.read(sharedPreferencesProvider).getString(ActivityLog.prefKey),
          ),
          DateTime.now(),
        ).count;
      } catch (_) {}

      final double progress = ringValue(
        RingInputs(
          adhkarDone: done,
          adhkarTotal: total,
          openedSurah: readingStarted,
          reflections: reflections,
          lessonsDone: lessonsDone,
          ayatMemorised: ayatInPlan,
          ayatPlanTotal: ayatPlanTotal,
        ),
      );

      return JourneyStats(
        progress: progress,
        adhkarDone: done,
        adhkarTotal: total,
        readingStarted: readingStarted,
        reflections: reflections,
        lessonsDone: lessonsDone,
        surahsOpened: surahsOpened,
        place: place,
        ayahBookmarks: ayahBookmarks,
        savedStories: savedStories,
        ayatMemorised: ayatMemorised,
        reviewsDue: reviewsDue,
        daysThisWeek: daysThisWeek,
      );
    });
