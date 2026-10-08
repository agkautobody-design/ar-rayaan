/// Hifz planner — memorize with a pace, revise on the 3-part cycle.
///
/// Traditional method: new memorization (sabaq), recent revision
/// (sabqi), and long-range revision (manzil) — the structure used in
/// South Asian and other hifz circles for generations. [Interpretive:
/// method framing; a teacher sets your actual pace.]
library;

class HifzPlan {
  const HifzPlan({
    required this.targetSurah,
    required this.dailyNewAyat,
    this.revisionWindowDays = 7,
  });

  final int targetSurah;
  final int dailyNewAyat;
  final int revisionWindowDays;

  /// Projected completion date for [totalAyat] starting [from].
  DateTime projectedCompletion(int totalAyat, DateTime from) {
    final int days = (totalAyat / dailyNewAyat).ceil();
    return from.add(Duration(days: days));
  }

  /// The three daily lanes, in order of priority.
  List<String> todaysLanes() => <String>[
        'New: $dailyNewAyat ayat of Surah $targetSurah',
        'Recent revision: last $revisionWindowDays days of memorization',
        'Long-range: one completed section (manzil)',
      ];
}

abstract final class HifzProgressEngine {
  /// Simple spaced rotation for revision: today revises the block
  /// finished [offsetDays] ago. Deterministic, testable.
  static List<int> revisionTargets({
    required int totalAyatMemorized,
    required int blockSize,
    required int daysSinceStart,
    int cycleDays = 7,
  }) {
    if (totalAyatMemorized == 0) return <int>[];
    final int today = daysSinceStart % cycleDays;
    // Walk backwards in 1-day slices of memorization history.
    final List<int> targets = <int>[];
    for (int d = 0; d < cycleDays; d++) {
      final int age = today + d * cycleDays;
      final int ayahIndex = totalAyatMemorized - 1 - age * blockSize;
      if (ayahIndex < 0) break;
      targets.add(ayahIndex);
    }
    // Rotate so the most recent block is always included.
    if (!targets.contains(totalAyatMemorized - 1)) {
      targets.insert(0, totalAyatMemorized - 1);
    }
    return targets;
  }
}
