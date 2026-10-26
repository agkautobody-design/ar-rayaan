import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ar_rayaan/features/games/data/game_history.dart';
import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/memory_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<MemoryName> names;

  setUpAll(() {
    names = <MemoryName>[
      for (final dynamic e in json
          .decode(File('assets/games/names99.json').readAsStringSync())
          as List<dynamic>)
        (
          n: (e as Map<String, dynamic>)['n'] as int,
          name: e['name'] as String,
          meaning: e['meaning'] as String,
          ref: e['ref'] as String,
          arabic: e['arabic'] as String?,
        ),
    ];
  });

  group('memory pairs', () {
    test('a deck is made of exact pairs: the Arabic and its spelling', () {
      for (int seed = 0; seed < 5; seed++) {
        final List<MemoryCard> deck = buildMemoryDeck(names, 10, Random(seed));
        expect(deck.length, 20);
        final Map<int, List<MemoryCard>> byPair = <int, List<MemoryCard>>{};
        for (final MemoryCard c in deck) {
          byPair.putIfAbsent(c.pairId, () => <MemoryCard>[]).add(c);
        }
        expect(byPair.length, 10);
        for (final List<MemoryCard> two in byPair.values) {
          expect(two.length, 2);
          expect(two.where((MemoryCard c) => c.isArabic).length, 1);
        }
        for (int i = 0; i < deck.length; i++) {
          expect(deck[i].id, i);
        }
      }
    });

    test('only Names that have Arabic are used', () {
      final List<MemoryName> some = <MemoryName>[
        (n: 1, name: 'A', meaning: 'm', ref: 'r', arabic: null),
        (n: 2, name: 'B', meaning: 'm', ref: 'r', arabic: 'ب'),
        (n: 3, name: 'C', meaning: 'm', ref: 'r', arabic: 'ج'),
      ];
      expect(memoryCandidates(some).length, 2);
      expect(buildMemoryDeck(some, 8, Random(1)).length, 4);
      expect(memoryPairChoices(7), <int>[6]);
      expect(memoryPairChoices(3), isEmpty);
    });

    test('a match keeps the turn, a miss passes it, no timer is needed', () {
      final List<MemoryCard> deck = buildMemoryDeck(names, 6, Random(4));
      final MemoryGame g = MemoryGame(cards: deck, players: 2);
      final MemoryCard a = deck.first;
      final MemoryCard b =
          deck.firstWhere((MemoryCard c) => c.pairId == a.pairId && c.id != a.id);
      expect(g.flip(a.id), FlipOutcome.first);
      expect(g.flip(a.id), FlipOutcome.ignored, reason: 'same card twice');
      expect(g.flip(b.id), FlipOutcome.match);
      expect(g.scores, <int>[1, 0]);
      expect(g.turn, 0);
      final MemoryCard c =
          deck.firstWhere((MemoryCard e) => !g.matched.contains(e.id));
      final MemoryCard d = deck.firstWhere(
        (MemoryCard e) => e.pairId != c.pairId && !g.matched.contains(e.id),
      );
      expect(g.flip(c.id), FlipOutcome.first);
      expect(g.flip(d.id), FlipOutcome.mismatch);
      expect(g.awaitingClear, isTrue);
      expect(g.flip(deck.last.id), FlipOutcome.ignored, reason: 'clear first');
      g.clearMismatch();
      expect(g.turn, 1);
      expect(g.awaitingClear, isFalse);
    });

    test('finding every pair finishes the game', () {
      final List<MemoryCard> deck = buildMemoryDeck(names, 6, Random(7));
      final MemoryGame g = MemoryGame(cards: deck, players: 1);
      for (final MemoryCard a in deck) {
        if (g.matched.contains(a.id)) continue;
        final MemoryCard b = deck
            .firstWhere((MemoryCard c) => c.pairId == a.pairId && c.id != a.id);
        g.flip(a.id);
        g.flip(b.id);
      }
      expect(g.finished, isTrue);
      expect(g.pairsFound, 6);
      expect(g.scores, <int>[6]);
    });
  });

  group('game history', () {
    GameResult r(String id, {int ms = 1}) => GameResult(
          id: id,
          gameId: 'qk',
          title: 'Qur’an Knowledge',
          finishedMs: ms,
          correct: 8,
          total: 10,
          difficulty: 'Standard',
        );

    test('a result round-trips through the saved text', () {
      final List<GameResult> back = decodeResults(encodeResults(<GameResult>[
        r('a'),
        const GameResult(
          id: 'b',
          gameId: 'chess',
          title: 'Shatranj (chess)',
          finishedMs: 2,
          outcome: 'Stalemate: a draw',
        ),
      ]));
      expect(back.length, 2);
      expect(back.first.summary, '8 of 10');
      expect(back.first.isIslamic, isTrue);
      expect(back.last.summary, 'Stalemate: a draw');
      expect(back.last.isIslamic, isFalse);
    });

    test('unreadable data is skipped, never thrown', () {
      expect(decodeResults(null), isEmpty);
      expect(decodeResults(''), isEmpty);
      expect(decodeResults('not json'), isEmpty);
      expect(decodeResults('{"a":1}'), isEmpty);
      expect(decodeResults('[{"id":1},{"bad":true}]'), isEmpty);
    });

    test('newest first, capped, and the same id is not listed twice', () {
      List<GameResult> list = <GameResult>[];
      for (int i = 0; i < kHistoryLimit + 10; i++) {
        list = addResult(list, r('g$i', ms: i));
      }
      expect(list.length, kHistoryLimit);
      expect(list.first.id, 'g${kHistoryLimit + 9}');
      list = addResult(list, r('g${kHistoryLimit + 5}', ms: 999));
      expect(list.where((GameResult e) => e.id == 'g${kHistoryLimit + 5}').length, 1);
      expect(list.first.finishedMs, 999);
    });

    test('dates read plainly', () {
      expect(shortDate(DateTime(2026, 10, 26).millisecondsSinceEpoch), '26 Oct 2026');
    });

    test('the history keeps only what a game needs: no names, no contacts', () {
      final String json1 = encodeResults(<GameResult>[r('a')]);
      for (final String banned in <String>['email', 'phone', 'name', 'uid']) {
        expect(json1.contains('"$banned"'), isFalse);
      }
      expect(gameById('qk'), isNotNull);
    });
  });
}
