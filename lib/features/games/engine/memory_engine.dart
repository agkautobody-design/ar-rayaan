/// The memory-pairs game: an Arabic Name on one card, its spelling on the
/// other. Pure Dart; the screen only draws what this says.
///
/// No timer and no score beyond "pairs found". With more than one player the
/// turn passes after a miss and stays after a match.
library;

import 'dart:math';

/// One of the 99 Names, as the game needs it.
typedef MemoryName = ({
  int n,
  String name,
  String meaning,
  String ref,
  String? arabic,
});

/// One card. Two cards with the same [pairId] are a pair.
class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.face,
    required this.isArabic,
  });

  final int id;
  final int pairId;
  final String face;
  final bool isArabic;
}

/// What a flip did.
enum FlipOutcome { ignored, first, match, mismatch }

/// The Names that have Arabic and can go on a card.
List<MemoryName> memoryCandidates(List<MemoryName> all) => <MemoryName>[
      for (final MemoryName n in all)
        if ((n.arabic ?? '').trim().isNotEmpty && n.name.trim().isNotEmpty) n,
    ];

/// The pair counts a setup screen may offer for [available] Names.
List<int> memoryPairChoices(int available) => <int>[
      for (final int n in const <int>[6, 8, 10])
        if (n <= available) n,
    ];

/// A shuffled deck of [pairs] pairs, two cards each.
List<MemoryCard> buildMemoryDeck(
  List<MemoryName> all,
  int pairs,
  Random rnd,
) {
  final List<MemoryName> pool = memoryCandidates(all)..shuffle(rnd);
  final List<MemoryName> chosen = pool.take(pairs).toList();
  final List<MemoryCard> raw = <MemoryCard>[];
  for (int i = 0; i < chosen.length; i++) {
    raw.add(MemoryCard(
      id: 0,
      pairId: chosen[i].n,
      face: chosen[i].arabic!.trim(),
      isArabic: true,
    ));
    raw.add(MemoryCard(
      id: 0,
      pairId: chosen[i].n,
      face: chosen[i].name,
      isArabic: false,
    ));
  }
  raw.shuffle(rnd);
  return <MemoryCard>[
    for (int i = 0; i < raw.length; i++)
      MemoryCard(
        id: i,
        pairId: raw[i].pairId,
        face: raw[i].face,
        isArabic: raw[i].isArabic,
      ),
  ];
}

/// A game in progress.
class MemoryGame {
  MemoryGame({required this.cards, required this.players})
      : scores = List<int>.filled(players, 0);

  final List<MemoryCard> cards;
  final int players;

  /// Pairs found by each player.
  final List<int> scores;

  /// Card ids already matched.
  final Set<int> matched = <int>{};

  /// The first card turned in the current try, and the second if it missed.
  int? first;
  int? second;

  /// 0-based player to move.
  int turn = 0;

  /// Tries made (two cards turned = one try).
  int tries = 0;

  bool get finished => matched.length == cards.length;

  /// True while a missed pair is showing and waits to be turned back.
  bool get awaitingClear => second != null;

  int get pairsFound => matched.length ~/ 2;

  /// True when card [i] is face up.
  bool isUp(int i) => matched.contains(i) || i == first || i == second;

  /// Turns card [i]. After a miss, call [clearMismatch] before the next flip.
  FlipOutcome flip(int i) {
    if (i < 0 || i >= cards.length) return FlipOutcome.ignored;
    if (second != null || matched.contains(i) || i == first) {
      return FlipOutcome.ignored;
    }
    if (first == null) {
      first = i;
      return FlipOutcome.first;
    }
    tries += 1;
    if (cards[first!].pairId == cards[i].pairId) {
      matched
        ..add(first!)
        ..add(i);
      scores[turn] += 1;
      first = null;
      return FlipOutcome.match;
    }
    second = i;
    return FlipOutcome.mismatch;
  }

  /// Turns a missed pair back and passes the turn.
  void clearMismatch() {
    if (second == null) return;
    first = null;
    second = null;
    turn = (turn + 1) % players;
  }
}
