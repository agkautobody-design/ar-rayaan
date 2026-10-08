import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adhkar/application/adhkar_providers.dart';
import '../../adhkar/domain/adhkar_models.dart';
import '../../noor/application/noor_providers.dart';
import '../../quran/application/quran_providers.dart';

/// Real progress signals from the shipped modules — no placeholders.
class JourneyStats {
  const JourneyStats({
    required this.progress,
    required this.adhkarDone,
    required this.adhkarTotal,
    required this.readingStarted,
    required this.reflections,
  });

  /// Composite 0..1: adhkar completion today (70%), Qur'an reading
  /// started (15%), at least one reflection saved (15%).
  final double progress;

  /// Repetitions completed today across all adhkar sets.
  final int adhkarDone;
  final int adhkarTotal;

  /// A reading position exists (the Qur'an journey has begun).
  final bool readingStarted;

  /// Saved NOOR reflections.
  final int reflections;
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
      final bool readingStarted = ref.watch(readingPositionProvider) != null;
      final int reflections = ref.watch(noorReflectionsProvider).length;

      final double adhkarFraction = total == 0 ? 0 : done / total;
      final double progress =
          adhkarFraction * 0.70 +
          (readingStarted ? 0.15 : 0) +
          (reflections > 0 ? 0.15 : 0);

      return JourneyStats(
        progress: progress,
        adhkarDone: done,
        adhkarTotal: total,
        readingStarted: readingStarted,
        reflections: reflections,
      );
    });
