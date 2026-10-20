/// Spaced repetition — the review-card model and the legacy SM-2 engine.
///
/// SCHEDULING NOW RUNS ON FSRS (see `fsrs.dart`): every grade in the app goes
/// through `Fsrs.schedule`. [Sm2Engine] is kept (nothing is deleted) for its
/// queue helpers ([Sm2Engine.dueQueue], [Sm2Engine.freshCards]) and so old
/// saved cards can still be read; its `schedule` is no longer called by the
/// app. Each [ReviewCard] still carries easiness / interval / repetitions so
/// saved decks and the doctor probe keep working, and now also the FSRS state
/// (stability, difficulty, last review, lapses).
///
/// Dignity-first (Charter): "Again" never punishes emotionally — it
/// simply schedules sooner. No streaks lost, no red UI.
library;

/// The learner's self-grade on a review card (FSRS's four buttons).
enum ReviewGrade { again, hard, good, easy }

/// Scheduling state for one card.
class ReviewCard {
  const ReviewCard({
    required this.wordKey,
    this.easiness = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.dueDate,
    this.stability,
    this.difficulty,
    this.lastReviewed,
    this.lapses = 0,
  });

  /// Stable identity — the deck word this card drills.
  final String wordKey;

  /// SM-2 easiness factor (>= 1.3).
  final double easiness;

  /// Current interval in days (0 = new card).
  final int intervalDays;

  /// Consecutive successful repetitions.
  final int repetitions;

  /// When the card comes due.
  final DateTime dueDate;

  /// FSRS stability in days (null until the first FSRS review, or until a
  /// legacy SM-2 card is migrated by `Fsrs.schedule`).
  final double? stability;

  /// FSRS difficulty, 1 (easy) to 10 (hard).
  final double? difficulty;

  /// When the card was last answered (null = never reviewed).
  final DateTime? lastReviewed;

  /// Times the card was forgotten after having been learned.
  final int lapses;

  ReviewCard copyWith({
    double? easiness,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
    double? stability,
    double? difficulty,
    DateTime? lastReviewed,
    int? lapses,
  }) =>
      ReviewCard(
        wordKey: wordKey,
        easiness: easiness ?? this.easiness,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        dueDate: dueDate ?? this.dueDate,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        lapses: lapses ?? this.lapses,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'wordKey': wordKey,
        'easiness': easiness,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'dueDate': dueDate.toIso8601String(),
        if (stability != null) 'stability': stability,
        if (difficulty != null) 'difficulty': difficulty,
        if (lastReviewed != null) 'lastReviewed': lastReviewed!.toIso8601String(),
        if (lapses != 0) 'lapses': lapses,
      };

  factory ReviewCard.fromJson(Map<String, dynamic> json) => ReviewCard(
        wordKey: json['wordKey'] as String,
        easiness: (json['easiness'] as num?)?.toDouble() ?? 2.5,
        intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
        repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
        dueDate: DateTime.parse(json['dueDate'] as String),
        stability: (json['stability'] as num?)?.toDouble(),
        difficulty: (json['difficulty'] as num?)?.toDouble(),
        lastReviewed: json['lastReviewed'] == null
            ? null
            : DateTime.parse(json['lastReviewed'] as String),
        lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      );
}

abstract final class Sm2Engine {
  /// SM-2 minimum easiness (a card never gets "harder" than 1.3).
  static const double minEasiness = 1.3;

  static const Map<ReviewGrade, int> _quality = <ReviewGrade, int>{
    ReviewGrade.again: 1,
    ReviewGrade.hard: 3,
    ReviewGrade.good: 4, // SM-2 "correct with hesitation" — keeps ease steady (3 drifted it down)
    ReviewGrade.easy: 5,
  };

  /// Schedule the next review. [now] is the answer moment.
  static ReviewCard schedule(
    ReviewCard card,
    ReviewGrade grade,
    DateTime now,
  ) {
    final int q = _quality[grade]!;
    double ef = card.easiness +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < minEasiness) ef = minEasiness;

    int repetitions;
    int interval;
    if (grade == ReviewGrade.again) {
      repetitions = 0;
      interval = 1; // back tomorrow, gently
    } else {
      repetitions = card.repetitions + 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (card.intervalDays * ef).round();
        if (interval < 1) interval = 1;
      }
    }

    return card.copyWith(
      easiness: double.parse(ef.toStringAsFixed(4)),
      intervalDays: interval,
      repetitions: repetitions,
      dueDate: now.add(Duration(days: interval)),
    );
  }

  /// Cards due at [now], ordered by due date (oldest first).
  static List<ReviewCard> dueQueue(List<ReviewCard> cards, DateTime now) {
    final List<ReviewCard> due = cards
        .where((ReviewCard c) =>
            !c.dueDate.isAfter(now))
        .toList();
    due.sort((ReviewCard a, ReviewCard b) => a.dueDate.compareTo(b.dueDate));
    return due;
  }

  /// New cards (never successfully reviewed) for first introduction.
  static List<ReviewCard> freshCards(List<ReviewCard> cards) => cards
      .where((ReviewCard c) => c.repetitions == 0 && c.intervalDays == 0)
      .toList();
}
