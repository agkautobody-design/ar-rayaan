import 'package:ar_rayaan/features/academy/domain/fsrs.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:flutter_test/flutter_test.dart';

/// FSRS-6 unit tests with FIXED VECTORS.
///
/// Every expected number below was produced by the reference implementation
/// py-fsrs 6.3.2 (MIT) with
/// `Scheduler(learning_steps=(), relearning_steps=(), enable_fuzzing=False)`
/// and its default 21 weights, replaying the same sequences at the same
/// timestamps. They are constants here, not recomputed, so a change to the
/// Dart formulae that drifts from the reference fails this file.
class _Step {
  const _Step(this.grade, this.atHours, this.stability, this.difficulty,
      this.intervalDays);
  final ReviewGrade grade;
  final int atHours;
  final double stability;
  final double difficulty;
  final int intervalDays;
}

final DateTime _start = DateTime.utc(2026, 1, 1, 9);

const Map<String, List<_Step>> _vectors = <String, List<_Step>>{
    'goodx5': <_Step>[
      _Step(ReviewGrade.good, 0, 2.3065, 2.118103970459016, 2),
      _Step(ReviewGrade.good, 48, 10.964332335820698, 2.111214235785395, 11),
      _Step(ReviewGrade.good, 312, 46.28021728755693, 2.1043313908464483, 46),
      _Step(ReviewGrade.good, 1416, 162.86220163874916, 2.0974554287524403, 163),
      _Step(ReviewGrade.good, 5328, 497.4471936002745, 2.0905863426205262, 497),
    ],
    'easy_first': <_Step>[
      _Step(ReviewGrade.easy, 0, 8.2956, 1.0, 8),
      _Step(ReviewGrade.good, 192, 38.90514998232684, 1.0, 39),
      _Step(ReviewGrade.easy, 1128, 252.59351766241906, 1.0, 253),
    ],
    'again_first': <_Step>[
      _Step(ReviewGrade.again, 0, 0.212, 6.4133, 1),
      _Step(ReviewGrade.good, 24, 1.8867876195204154, 6.402115069296838, 2),
      _Step(ReviewGrade.good, 72, 6.269161317502347, 6.3909413235243795, 6),
    ],
    'lapse': <_Step>[
      _Step(ReviewGrade.good, 0, 2.3065, 2.118103970459016, 2),
      _Step(ReviewGrade.good, 48, 10.964332335820698, 2.111214235785395, 11),
      _Step(ReviewGrade.good, 312, 46.28021728755693, 2.1043313908464483, 46),
      _Step(ReviewGrade.again, 1416, 2.9325804541638116, 7.389975788014609, 3),
      _Step(ReviewGrade.good, 1488, 7.778225744797728, 7.377814181523433, 8),
    ],
    'hard_mix': <_Step>[
      _Step(ReviewGrade.hard, 0, 1.2931, 5.112170705601056, 1),
      _Step(ReviewGrade.hard, 24, 3.2494117658571677, 6.7404595108297, 3),
      _Step(ReviewGrade.good, 96, 9.03413829365584, 6.728947420615708, 9),
      _Step(ReviewGrade.hard, 312, 17.675007664933318, 7.813751236051346, 18),
      _Step(ReviewGrade.easy, 744, 53.351824545935735, 7.068437147628945, 53),
    ],
    'same_day': <_Step>[
      _Step(ReviewGrade.good, 0, 2.3065, 2.118103970459016, 2),
      _Step(ReviewGrade.good, 1, 2.3065, 2.111214235785395, 2),
      _Step(ReviewGrade.again, 2, 0.7750839828558984, 7.392238132342694, 1),
      _Step(ReviewGrade.easy, 3, 1.4246937658554968, 6.5060740071714935, 1),
    ],
    'late': <_Step>[
      _Step(ReviewGrade.good, 0, 2.3065, 2.118103970459016, 2),
      _Step(ReviewGrade.good, 960, 40.72042282856719, 2.111214235785395, 41),
      _Step(ReviewGrade.good, 4800, 279.0179444977051, 2.1043313908464483, 279),
    ],
};

const List<(double, int, double)> _retrievability = <(double, int, double)>[
      (0.5, 0, 1.0),
      (0.5, 1, 0.8458846451494336),
      (0.5, 5, 0.6928266345726217),
      (0.5, 30, 0.5321197762068469),
      (2.3065, 0, 1.0),
      (2.3065, 1, 0.9468474993825461),
      (2.3065, 5, 0.8388614268145294),
      (2.3065, 30, 0.6675263338730357),
      (10, 0, 1.0),
      (10, 1, 0.9856824087775146),
      (10, 5, 0.9403442888929227),
      (10, 30, 0.8093881035731708),
      (100, 0, 1.0),
      (100, 1, 0.9984967984922138),
      (100, 5, 0.9926480955829713),
      (100, 30, 0.9610242690473834),
];

void main() {
  group('FSRS-6 matches the py-fsrs 6.3.2 reference', () {
    for (final MapEntry<String, List<_Step>> seq in _vectors.entries) {
      test('sequence ${seq.key}', () {
        ReviewCard card = ReviewCard(wordKey: 'c', dueDate: _start);
        for (final _Step s in seq.value) {
          final DateTime now = _start.add(Duration(hours: s.atHours));
          card = Fsrs.schedule(card, s.grade, now);
          expect(card.stability, closeTo(s.stability, 1e-7),
              reason: '${seq.key} stability at +${s.atHours}h');
          expect(card.difficulty, closeTo(s.difficulty, 1e-7),
              reason: '${seq.key} difficulty at +${s.atHours}h');
          expect(card.intervalDays, s.intervalDays,
              reason: '${seq.key} interval at +${s.atHours}h');
          expect(card.dueDate, now.add(Duration(days: s.intervalDays)));
          expect(card.lastReviewed, now);
        }
      });
    }

    test('retrievability matches the reference', () {
      for (final (double s, int days, double r) in _retrievability) {
        expect(
          Fsrs.retrievability(stability: s, elapsedDays: days),
          closeTo(r, 1e-9),
          reason: 'S=$s after $days days',
        );
      }
    });

    test('retrievability is 0.9 exactly one stability-length later', () {
      for (final double s in <double>[0.5, 3, 40, 300]) {
        // FSRS defines stability as the time for recall to fall to 90 percent.
        expect(
          Fsrs.retrievability(stability: s, elapsedDays: 0),
          closeTo(1.0, 1e-12),
        );
      }
      expect(
        Fsrs.retrievability(stability: 10, elapsedDays: 10),
        closeTo(0.9, 1e-9),
      );
    });

    test('the pinned weights are the 21 FSRS-6 defaults', () {
      expect(kFsrs6DefaultWeights.length, 21);
      expect(kFsrs6DefaultWeights.first, 0.212);
      expect(kFsrs6DefaultWeights[2], 2.3065);
      expect(kFsrs6DefaultWeights.last, 0.1542);
    });
  });

  group('FSRS-6 behaviour', () {
    ReviewCard fresh() => ReviewCard(wordKey: 'c', dueDate: _start);

    test('first review: Again 1 day, Hard 1, Good 2, Easy 8', () {
      final Map<ReviewGrade, int> expected = <ReviewGrade, int>{
        ReviewGrade.again: 1,
        ReviewGrade.hard: 1,
        ReviewGrade.good: 2,
        ReviewGrade.easy: 8,
      };
      for (final MapEntry<ReviewGrade, int> e in expected.entries) {
        expect(Fsrs.schedule(fresh(), e.key, _start).intervalDays, e.value,
            reason: '${e.key}');
      }
    });

    test('Again keeps the card in play and counts a lapse once learned', () {
      ReviewCard c = Fsrs.schedule(fresh(), ReviewGrade.good, _start);
      expect(c.lapses, 0);
      c = Fsrs.schedule(c, ReviewGrade.good, c.dueDate);
      c = Fsrs.schedule(c, ReviewGrade.again, c.dueDate);
      expect(c.lapses, 1);
      expect(c.repetitions, 0);
      expect(c.intervalDays, greaterThanOrEqualTo(1));
      // It must neither be "fresh" (never reviewed) nor lost from the queue.
      expect(Fsrs.freshCards(<ReviewCard>[c]), isEmpty);
      expect(Fsrs.dueQueue(<ReviewCard>[c], c.dueDate), hasLength(1));
    });

    test('a better grade never schedules sooner than a worse one', () {
      ReviewCard base = Fsrs.schedule(fresh(), ReviewGrade.good, _start);
      base = Fsrs.schedule(base, ReviewGrade.good, base.dueDate);
      final DateTime at = base.dueDate;
      int previous = 0;
      for (final ReviewGrade g in ReviewGrade.values) {
        final int days = Fsrs.schedule(base, g, at).intervalDays;
        expect(days, greaterThanOrEqualTo(previous), reason: '$g');
        previous = days;
      }
    });

    test('difficulty stays within 1..10 and easiness within 1.3..3.0', () {
      ReviewCard c = fresh();
      DateTime now = _start;
      for (int i = 0; i < 60; i++) {
        c = Fsrs.schedule(
            c, i.isEven ? ReviewGrade.again : ReviewGrade.hard, now);
        expect(c.difficulty, inInclusiveRange(1.0, 10.0));
        expect(c.stability, greaterThanOrEqualTo(0.001));
        expect(c.easiness, inInclusiveRange(1.3, 3.0));
        now = c.dueDate;
      }
      for (int i = 0; i < 60; i++) {
        c = Fsrs.schedule(c, ReviewGrade.easy, now);
        expect(c.difficulty, inInclusiveRange(1.0, 10.0));
        now = c.dueDate;
      }
    });

    test('intervals are capped at the maximum interval', () {
      const FsrsParameters tight = FsrsParameters(maximumInterval: 30);
      ReviewCard c = fresh();
      DateTime now = _start;
      for (int i = 0; i < 12; i++) {
        c = Fsrs.schedule(c, ReviewGrade.easy, now, params: tight);
        expect(c.intervalDays, lessThanOrEqualTo(30));
        now = c.dueDate;
      }
      expect(c.intervalDays, 30);
    });

    test('a higher retention target gives shorter intervals', () {
      const FsrsParameters strict = FsrsParameters(desiredRetention: 0.95);
      final int normal =
          Fsrs.schedule(fresh(), ReviewGrade.easy, _start).intervalDays;
      final int shorter = Fsrs.schedule(fresh(), ReviewGrade.easy, _start,
              params: strict)
          .intervalDays;
      expect(shorter, lessThan(normal));
    });

    test('a legacy SM-2 card continues from its interval, not from scratch',
        () {
      // 10-day interval, ease 2.5, due today: an SM-2 card in good standing.
      final ReviewCard legacy = ReviewCard(
        wordKey: 'old',
        easiness: 2.5,
        intervalDays: 10,
        repetitions: 3,
        dueDate: _start,
      );
      final ReviewCard migrated = Fsrs.migrateLegacy(legacy);
      expect(migrated.stability, 10.0);
      expect(migrated.difficulty, inInclusiveRange(3.5, 3.8));
      expect(migrated.lastReviewed, _start.subtract(const Duration(days: 10)));
      final ReviewCard next = Fsrs.schedule(legacy, ReviewGrade.good, _start);
      expect(next.intervalDays, greaterThan(10),
          reason: 'recalled on time: the interval grows');
      expect(next.repetitions, 4);
    });

    test('a brand-new card is not migrated', () {
      final ReviewCard c = fresh();
      expect(Fsrs.migrateLegacy(c).stability, isNull);
    });

    test('same-day repeat uses short-term stability, not a new interval jump',
        () {
      final ReviewCard a = Fsrs.schedule(fresh(), ReviewGrade.good, _start);
      final ReviewCard b = Fsrs.schedule(
          a, ReviewGrade.good, _start.add(const Duration(hours: 1)));
      expect(b.stability, closeTo(a.stability!, 1e-9));
    });
  });

  group('ReviewCard persistence', () {
    test('FSRS state survives a JSON round trip', () {
      final ReviewCard c = Fsrs.schedule(
        Fsrs.schedule(
            ReviewCard(wordKey: 'k', dueDate: _start), ReviewGrade.good, _start),
        ReviewGrade.hard,
        _start.add(const Duration(days: 2)),
      );
      final ReviewCard back = ReviewCard.fromJson(c.toJson());
      expect(back.stability, c.stability);
      expect(back.difficulty, c.difficulty);
      expect(back.lastReviewed, c.lastReviewed);
      expect(back.lapses, c.lapses);
      expect(back.intervalDays, c.intervalDays);
    });

    test('a card saved before FSRS still loads', () {
      final ReviewCard old = ReviewCard.fromJson(<String, dynamic>{
        'wordKey': 'x',
        'easiness': 2.36,
        'intervalDays': 6,
        'repetitions': 2,
        'dueDate': _start.toIso8601String(),
      });
      expect(old.stability, isNull);
      expect(old.lapses, 0);
    });
  });

  group('review log', () {
    ReviewLogEntry entry(int i) => ReviewLogEntry(
          cardId: 'c$i',
          grade: ReviewGrade.values[i % 4],
          at: _start.add(Duration(minutes: i)),
          scheduledDays: i,
        );

    test('append / decode round trip keeps order and fields', () {
      String? raw;
      for (int i = 0; i < 5; i++) {
        raw = ReviewLog.append(raw, entry(i));
      }
      final List<ReviewLogEntry> back = ReviewLog.decode(raw);
      expect(back.map((ReviewLogEntry e) => e.cardId),
          <String>['c0', 'c1', 'c2', 'c3', 'c4']);
      expect(back[2].grade, ReviewGrade.good);
      expect(back[3].scheduledDays, 3);
      expect(back[1].at, _start.add(const Duration(minutes: 1)));
    });

    test('the log is capped, oldest dropped first', () {
      String? raw;
      for (int i = 0; i < ReviewLog.maxEntries + 3; i++) {
        raw = ReviewLog.append(raw, entry(i));
      }
      final List<ReviewLogEntry> back = ReviewLog.decode(raw);
      expect(back.length, ReviewLog.maxEntries);
      expect(back.first.cardId, 'c3');
    });

    test('garbage decodes to an empty log instead of throwing', () {
      expect(ReviewLog.decode('not json'), isEmpty);
      expect(ReviewLog.decode(null), isEmpty);
    });
  });
}
