import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 5, 9);

  WordCard card(String key, {int rank = 0}) => WordCard(
        key: key,
        arabic: 'كِتَاب',
        gloss: 'book / scripture',
        root: 'ك ت ب',
        occurrences: 260,
        frequencyRank: rank,
        sourceAyah: const AyahRef(2, 2),
        review: ReviewCard(wordKey: key, dueDate: now),
      );

  group('WordCard', () {
    test('json round-trip preserves all fields incl. Arabic', () {
      final original = card('2:2:كِتَاب', rank: 12);
      final restored = WordCard.fromJson(original.toJson());
      expect(restored.key, original.key);
      expect(restored.arabic, 'كِتَاب');
      expect(restored.root, 'ك ت ب');
      expect(restored.occurrences, 260);
      expect(restored.frequencyRank, 12);
      expect(restored.sourceAyah, const AyahRef(2, 2));
      expect(restored.review.easiness, 2.5);
      expect(restored.review.wordKey, original.key,
          reason: 'review identity repaired on load');
    });
  });

  group('WordDeckEngine', () {
    test('addCard adds once, never duplicates', () {
      var deck = <String, WordCard>{};
      deck = WordDeckEngine.addCard(deck, card('a'));
      deck = WordDeckEngine.addCard(deck, card('a'));
      deck = WordDeckEngine.addCard(deck, card('b'));
      expect(deck.length, 2);
    });

    test('buildSession: due reviews first, then fresh, capped', () {
      var deck = <String, WordCard>{};
      // 3 fresh cards.
      deck = WordDeckEngine.addCard(deck, card('fresh1'));
      deck = WordDeckEngine.addCard(deck, card('fresh2'));
      deck = WordDeckEngine.addCard(deck, card('fresh3'));
      // 2 learned cards; one due now (Again made it 1 day, and a day passed).
      deck = WordDeckEngine.grade(
          deck: deck, key: 'fresh1', grade: ReviewGrade.good, now: now);
      final tomorrow = now.add(const Duration(days: 2));
      deck = WordDeckEngine.grade(
          deck: deck, key: 'fresh2', grade: ReviewGrade.good, now: tomorrow);

      final session = WordDeckEngine.buildSession(deck: deck, now: tomorrow);
      // fresh1: graded 2 days ago, 1-day interval elapsed -> DUE, first.
      // fresh2: graded TODAY at 'tomorrow' -> due the day after, absent.
      // fresh3: never reviewed -> fresh lane.
      expect(session.map((c) => c.key).toList(),
          <String>['fresh1', 'fresh3']);
    });

    test('buildSession caps at sessionCap', () {
      var deck = <String, WordCard>{};
      for (var i = 0; i < 30; i++) {
        deck = WordDeckEngine.addCard(deck, card('w$i'));
      }
      final session = WordDeckEngine.buildSession(
          deck: deck, now: now, sessionCap: 15);
      expect(session.length, 15);
    });

    test('grade schedules through the deck (SM-2 wired end to end)', () {
      var deck = <String, WordCard>{};
      deck = WordDeckEngine.addCard(deck, card('a'));
      deck = WordDeckEngine.grade(
          deck: deck, key: 'a', grade: ReviewGrade.good, now: now);
      expect(deck['a']!.review.intervalDays, 1);
      deck = WordDeckEngine.grade(
          deck: deck, key: 'a', grade: ReviewGrade.again, now: now);
      expect(deck['a']!.review.repetitions, 0,
          reason: 'Again resets gently via the deck');
    });
  });
}
