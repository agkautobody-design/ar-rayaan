/// FSRS-6 — the Academy's spaced-repetition scheduler (own pinned
/// implementation; no third-party package).
///
/// Why our own: the pub.dev `fsrs` package has an unverified uploader and an
/// unstated algorithm version (research 4, section 3.1). The algorithm is
/// small, public and MIT-licensed in its reference implementations, so it is
/// written out here and pinned to fixed test vectors.
///
/// PINNED TO: the FSRS-6 formulae and the 21 default weights of
/// `py-fsrs` 6.3.2 (MIT, https://github.com/open-spaced-repetition/py-fsrs),
/// `Scheduler(learning_steps=(), relearning_steps=(), enable_fuzzing=False)`.
/// `test/fsrs_test.dart` replays vectors produced by that exact reference.
///
/// Deliberate choices for a daily-review app:
///  * No intra-day learning steps: a first review goes straight to a
///    day-granular schedule (an "Again" comes back the next day).
///  * No fuzzing: the schedule is deterministic (and testable).
///  * Desired retention 0.9, maximum interval 36 500 days.
///  * Dart's `round()` rounds .5 away from zero where Python rounds half to
///    even; the two can differ only on an interval that is exactly x.5.
///
/// Dignity-first (Charter): "Again" never punishes — it schedules sooner. No
/// streak is lost, no red UI.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'spaced_repetition.dart';

/// The 21 FSRS-6 default weights (py-fsrs 6.3.2 `DEFAULT_PARAMETERS`).
const List<double> kFsrs6DefaultWeights = <double>[
  0.212,
  1.2931,
  2.3065,
  8.2956,
  6.4133,
  0.8334,
  3.0194,
  0.001,
  1.8722,
  0.1666,
  0.796,
  1.4835,
  0.0614,
  0.2629,
  1.6483,
  0.6014,
  1.8729,
  0.5425,
  0.0912,
  0.0658,
  0.1542,
];

/// Tunable scheduler settings.
class FsrsParameters {
  const FsrsParameters({
    this.weights = kFsrs6DefaultWeights,
    this.desiredRetention = 0.9,
    this.maximumInterval = 36500,
  });

  /// Exactly 21 weights.
  final List<double> weights;

  /// Target probability of recall when a card comes due (0.7 to 0.97).
  final double desiredRetention;

  /// Longest interval, in days.
  final int maximumInterval;
}

abstract final class Fsrs {
  static const FsrsParameters defaults = FsrsParameters();

  static const double _stabilityMin = 0.001;
  static const double _difficultyMin = 1.0;
  static const double _difficultyMax = 10.0;

  static double _pow(double a, double b) => math.pow(a, b).toDouble();
  static double _exp(double x) => math.exp(x);

  /// FSRS rating number: Again 1, Hard 2, Good 3, Easy 4.
  static int ratingOf(ReviewGrade g) => switch (g) {
        ReviewGrade.again => 1,
        ReviewGrade.hard => 2,
        ReviewGrade.good => 3,
        ReviewGrade.easy => 4,
      };

  static double _decay(FsrsParameters p) => -p.weights[20];

  static double _factor(FsrsParameters p) =>
      _pow(0.9, 1 / _decay(p)) - 1;

  /// Probability of recall after [elapsedDays] for a card of [stability].
  static double retrievability({
    required double stability,
    required int elapsedDays,
    FsrsParameters params = defaults,
  }) {
    final int days = elapsedDays < 0 ? 0 : elapsedDays;
    return _pow(
      1 + _factor(params) * days / stability,
      _decay(params),
    );
  }

  static double _clampDifficulty(double d) =>
      d < _difficultyMin ? _difficultyMin : (d > _difficultyMax ? _difficultyMax : d);

  static double _clampStability(double s) => s < _stabilityMin ? _stabilityMin : s;

  static double initialStability(int rating, FsrsParameters p) =>
      _clampStability(p.weights[rating - 1]);

  static double initialDifficulty(int rating, FsrsParameters p,
      {required bool clamp}) {
    final double d =
        p.weights[4] - _exp(p.weights[5] * (rating - 1)) + 1;
    return clamp ? _clampDifficulty(d) : d;
  }

  /// Next interval in whole days for [stability] at the desired retention.
  static int nextInterval(double stability, FsrsParameters p) {
    final double raw = (stability / _factor(p)) *
        (_pow(p.desiredRetention, 1 / _decay(p)) - 1);
    int days = raw.round();
    if (days < 1) days = 1;
    if (days > p.maximumInterval) days = p.maximumInterval;
    return days;
  }

  static double shortTermStability(double stability, int rating, FsrsParameters p) {
    double increase = _exp(p.weights[17] * (rating - 3 + p.weights[18])) *
        _pow(stability, -p.weights[19]);
    if (rating >= 2 && increase < 1.0) increase = 1.0;
    return _clampStability(stability * increase);
  }

  static double nextDifficulty(double d, int rating, FsrsParameters p) {
    final double arg1 = initialDifficulty(4, p, clamp: false);
    final double delta = -(p.weights[6] * (rating - 3));
    final double arg2 = d + (10.0 - d) * delta / 9.0;
    final double next = p.weights[7] * arg1 + (1 - p.weights[7]) * arg2;
    return _clampDifficulty(next);
  }

  static double nextForgetStability(
      double d, double s, double r, FsrsParameters p) {
    final double longTerm = p.weights[11] *
        _pow(d, -p.weights[12]) *
        (_pow(s + 1, p.weights[13]) - 1) *
        _exp((1 - r) * p.weights[14]);
    final double shortTerm = s / _exp(p.weights[17] * p.weights[18]);
    return longTerm < shortTerm ? longTerm : shortTerm;
  }

  static double nextRecallStability(
      double d, double s, double r, int rating, FsrsParameters p) {
    final double hardPenalty = rating == 2 ? p.weights[15] : 1.0;
    final double easyBonus = rating == 4 ? p.weights[16] : 1.0;
    return s *
        (1 +
            _exp(p.weights[8]) *
                (11 - d) *
                _pow(s, -p.weights[9]) *
                (_exp((1 - r) * p.weights[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  static double nextStability(
      double d, double s, double r, int rating, FsrsParameters p) {
    final double next = rating == 1
        ? nextForgetStability(d, s, r, p)
        : nextRecallStability(d, s, r, rating, p);
    return _clampStability(next);
  }

  /// A card with no FSRS state yet but a legacy SM-2 schedule is brought
  /// across by seeding stability from its current interval (Anki's own advice
  /// is to continue from the interval, not to reschedule history) and
  /// difficulty from its easiness factor (the default 2.5 maps to about 3.65).
  static ReviewCard migrateLegacy(ReviewCard card) {
    if (card.stability != null && card.difficulty != null) return card;
    if (card.intervalDays <= 0) return card; // a new card: nothing to carry
    final double d = _clampDifficulty(
        10.0 - (card.easiness - 1.3) / 1.7 * 9.0);
    return ReviewCard(
      wordKey: card.wordKey,
      easiness: card.easiness,
      intervalDays: card.intervalDays,
      repetitions: card.repetitions,
      dueDate: card.dueDate,
      stability: card.intervalDays.toDouble(),
      difficulty: d,
      lastReviewed: card.dueDate.subtract(Duration(days: card.intervalDays)),
      lapses: card.lapses,
    );
  }

  /// Legacy display value kept in step with difficulty so saved data and the
  /// doctor probe (easiness >= 1.3) stay valid: difficulty 1 -> 3.0,
  /// difficulty 10 -> 1.3.
  static double easinessFor(double difficulty) {
    final double e = 1.3 + (10.0 - difficulty) / 9.0 * 1.7;
    return double.parse(e.toStringAsFixed(4));
  }

  /// Schedule the next review of [card] answered with [grade] at [now].
  static ReviewCard schedule(
    ReviewCard card,
    ReviewGrade grade,
    DateTime now, {
    FsrsParameters params = defaults,
  }) {
    final int rating = ratingOf(grade);
    final ReviewCard c = migrateLegacy(card);

    double stability;
    double difficulty;
    final bool first = c.stability == null ||
        c.difficulty == null ||
        c.lastReviewed == null;
    if (first) {
      stability = initialStability(rating, params);
      difficulty = initialDifficulty(rating, params, clamp: true);
    } else {
      final double s0 = c.stability!;
      final double d0 = c.difficulty!;
      int elapsed = now.difference(c.lastReviewed!).inDays;
      if (elapsed < 0) elapsed = 0;
      if (elapsed < 1) {
        stability = shortTermStability(s0, rating, params);
      } else {
        final double r = retrievability(
            stability: s0, elapsedDays: elapsed, params: params);
        stability = nextStability(d0, s0, r, rating, params);
      }
      difficulty = nextDifficulty(d0, rating, params);
    }

    final int interval = nextInterval(stability, params);
    final bool forgot = grade == ReviewGrade.again;
    return ReviewCard(
      wordKey: c.wordKey,
      easiness: easinessFor(difficulty),
      intervalDays: interval,
      repetitions: forgot ? 0 : c.repetitions + 1,
      dueDate: now.add(Duration(days: interval)),
      stability: stability,
      difficulty: difficulty,
      lastReviewed: now,
      lapses: (forgot && !first) ? c.lapses + 1 : c.lapses,
    );
  }

  /// Cards due at [now], oldest first.
  static List<ReviewCard> dueQueue(List<ReviewCard> cards, DateTime now) =>
      Sm2Engine.dueQueue(cards, now);

  /// Cards never reviewed.
  static List<ReviewCard> freshCards(List<ReviewCard> cards) =>
      Sm2Engine.freshCards(cards);
}

/// One answered review. The log is what lets the parameters be re-fitted
/// later (research 4: "no review log is stored"). On-device only.
class ReviewLogEntry {
  const ReviewLogEntry({
    required this.cardId,
    required this.grade,
    required this.at,
    required this.scheduledDays,
  });

  final String cardId;
  final ReviewGrade grade;
  final DateTime at;
  final int scheduledDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': cardId,
        'g': Fsrs.ratingOf(grade),
        'at': at.toIso8601String(),
        'd': scheduledDays,
      };

  factory ReviewLogEntry.fromJson(Map<String, dynamic> j) {
    final int g = (j['g'] as num?)?.toInt() ?? 3;
    final int idx = g < 1 ? 0 : (g > 4 ? 3 : g - 1);
    return ReviewLogEntry(
      cardId: j['id'] as String,
      grade: ReviewGrade.values[idx],
      at: DateTime.parse(j['at'] as String),
      scheduledDays: (j['d'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Pure helpers for the persisted review log (the app stores the JSON string
/// in SharedPreferences under [prefKey]).
abstract final class ReviewLog {
  static const String prefKey = 'ar.academy.reviewlog.v1';

  /// Entries kept; the oldest are dropped first.
  static const int maxEntries = 5000;

  static List<ReviewLogEntry> decode(String? raw) {
    if (raw == null || raw.isEmpty) return <ReviewLogEntry>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return <ReviewLogEntry>[
        for (final dynamic e in list)
          ReviewLogEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return <ReviewLogEntry>[];
    }
  }

  static String encode(List<ReviewLogEntry> entries) => jsonEncode(
      entries.map((ReviewLogEntry e) => e.toJson()).toList());

  /// [raw] with [entry] appended, trimmed to [maxEntries].
  static String append(String? raw, ReviewLogEntry entry) {
    final List<ReviewLogEntry> all = decode(raw)..add(entry);
    final List<ReviewLogEntry> kept = all.length > maxEntries
        ? all.sublist(all.length - maxEntries)
        : all;
    return encode(kept);
  }
}
