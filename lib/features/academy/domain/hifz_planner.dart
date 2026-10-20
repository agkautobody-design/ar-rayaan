/// Hifz planner — memorize with a pace, revise on the 3-part cycle.
///
/// Traditional method: new memorization (sabaq), recent revision
/// (sabqi), and long-range revision (manzil) — the structure used in
/// South Asian and other hifz circles for generations. [Interpretive:
/// method framing; a teacher sets your actual pace.]
library;

/// Number of ayat in each surah (index 0 = Al-Fatihah ... 113 = An-Nas).
/// Generated from assets/quran/quran.json; a test checks it against that
/// asset so it can never drift.
const List<int> kAyahCounts = <int>[
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98,
  135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88,
  75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29,
  22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31,
  50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8,
  19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
];

/// Ayat in [surah] (1..114); 0 for anything out of range.
int ayatInSurah(int surah) =>
    surah >= 1 && surah <= kAyahCounts.length ? kAyahCounts[surah - 1] : 0;

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
