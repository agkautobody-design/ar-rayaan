/// Spaced repetition — the SM-2 scheduling engine for the word deck.
///
/// Classic SuperMemo-2 (1987, public domain algorithm), implemented
/// against our domain: each [ReviewCard] tracks easiness factor,
/// interval days, and due date. Grades map to SM-2 quality 0–5.
///
/// Dignity-first (Charter): "Again" never punishes emotionally — it
/// simply schedules sooner. No streaks lost, no red UI.
library;

/// The learner's self-grade on a review card.
enum ReviewGrade { again, good, easy }

/// Scheduling state for one card.
class ReviewCard {
  const ReviewCard({
    required this.wordKey,
    this.easiness = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.dueDate,
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

  ReviewCard copyWith({
    double? easiness,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
  }) =>
      ReviewCard(
        wordKey: wordKey,
        easiness: easiness ?? this.easiness,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        dueDate: dueDate ?? this.dueDate,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'wordKey': wordKey,
        'easiness': easiness,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'dueDate': dueDate.toIso8601String(),
      };

  factory ReviewCard.fromJson(Map<String, dynamic> json) => ReviewCard(
        wordKey: json['wordKey'] as String,
        easiness: (json['easiness'] as num?)?.toDouble() ?? 2.5,
        intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
        repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
        dueDate: DateTime.parse(json['dueDate'] as String),
      );
}

abstract final class Sm2Engine {
  /// SM-2 minimum easiness (a card never gets "harder" than 1.3).
  static const double minEasiness = 1.3;

  static const Map<ReviewGrade, int> _quality = <ReviewGrade, int>{
    ReviewGrade.again: 1,
    ReviewGrade.good: 3,
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
