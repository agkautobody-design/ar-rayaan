import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 5, 9);

  ReviewCard fresh(String key) => ReviewCard(
        wordKey: key,
        dueDate: now,
      );

  group('Sm2Engine.schedule', () {
    test('first Good: 1 day, repetition 1', () {
      final c = Sm2Engine.schedule(fresh('a'), ReviewGrade.good, now);
      expect(c.intervalDays, 1);
      expect(c.repetitions, 1);
      expect(c.dueDate, now.add(const Duration(days: 1)));
    });

    test('second Good: 6 days, repetition 2', () {
      final c1 = Sm2Engine.schedule(fresh('a'), ReviewGrade.good, now);
      final c2 = Sm2Engine.schedule(c1, ReviewGrade.good, now);
      expect(c2.intervalDays, 6);
      expect(c2.repetitions, 2);
    });

    test('third Good multiplies by easiness', () {
      final c2 = Sm2Engine.schedule(
          Sm2Engine.schedule(fresh('a'), ReviewGrade.good, now),
          ReviewGrade.good,
          now);
      final c3 = Sm2Engine.schedule(c2, ReviewGrade.good, now);
      // SM-2: interval uses the EF computed THIS grade (ef dropped 2.36→2.22).
      expect(c3.intervalDays, (6 * c3.easiness).round());
      expect(c3.intervalDays, greaterThan(6));
    });

    test('Again resets gently: tomorrow, repetitions 0, EF drops', () {
      final learned = Sm2Engine.schedule(
          Sm2Engine.schedule(fresh('a'), ReviewGrade.good, now),
          ReviewGrade.good,
          now);
      final again = Sm2Engine.schedule(learned, ReviewGrade.again, now);
      expect(again.intervalDays, 1);
      expect(again.repetitions, 0);
      expect(again.easiness, lessThan(learned.easiness));
      expect(again.easiness, greaterThanOrEqualTo(Sm2Engine.minEasiness));
    });

    test('Easy raises EF and schedules far out', () {
      final c = Sm2Engine.schedule(fresh('a'), ReviewGrade.easy, now);
      expect(c.easiness, greaterThan(2.5));
      expect(c.intervalDays, 1); // first rep is still 1 day
      final c2 = Sm2Engine.schedule(c, ReviewGrade.easy, now);
      // rep3 interval = 6 × EF(2.7) = 16 days — far out, but honest SM-2.
      final c3 = Sm2Engine.schedule(c2, ReviewGrade.easy, now);
      expect(c3.intervalDays, greaterThan(10));
    });

    test('easiness never drops below 1.3 even under repeated Again', () {
      var c = fresh('a');
      for (var i = 0; i < 10; i++) {
        c = Sm2Engine.schedule(c, ReviewGrade.again, now);
      }
      expect(c.easiness, greaterThanOrEqualTo(Sm2Engine.minEasiness));
    });
  });

  group('dueQueue', () {
    test('returns only due cards, oldest first', () {
      final cards = <ReviewCard>[
        Sm2Engine.schedule(fresh('later'), ReviewGrade.good, now),
        fresh('now1'),
        fresh('now2'),
      ];
      final queue = Sm2Engine.dueQueue(cards, now);
      expect(queue.length, 2);
      expect(queue.every((c) => c.wordKey.startsWith('now')), isTrue);
    });

    test('future cards are not due', () {
      // A Good-graded card is due TOMORROW: not due now, not due yesterday.
      final graded = Sm2Engine.schedule(fresh('a'), ReviewGrade.good, now);
      expect(Sm2Engine.dueQueue(<ReviewCard>[graded], now), isEmpty);
      // The same card IS due when tomorrow arrives.
      expect(
        Sm2Engine.dueQueue(
            <ReviewCard>[graded], now.add(const Duration(days: 1))),
        isNotEmpty,
      );
      // An ungraded fresh card is due right now.
      expect(Sm2Engine.dueQueue(<ReviewCard>[fresh('b')], now), isNotEmpty);
    });
  });

  group('persistence', () {
    test('json round-trip preserves scheduling state', () {
      final c = Sm2Engine.schedule(
          Sm2Engine.schedule(fresh('كتاب'), ReviewGrade.easy, now),
          ReviewGrade.good,
          now);
      final restored = ReviewCard.fromJson(c.toJson());
      expect(restored.wordKey, 'كتاب');
      expect(restored.easiness, c.easiness);
      expect(restored.intervalDays, c.intervalDays);
      expect(restored.dueDate, c.dueDate);
    });
  });
}
