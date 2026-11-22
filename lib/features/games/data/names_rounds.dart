import 'dart:math';

/// One question of the Names quiz: "which Name means …?".
class NamesRound {
  const NamesRound({
    required this.meaning,
    required this.options,
    required this.answer,
    required this.arabic,
    required this.ref,
  });

  /// The meaning shown as the question.
  final String meaning;

  /// Four Names in English letters; [answer] indexes the right one.
  final List<String> options;
  final int answer;

  /// The right Name in Arabic script (shown after answering), if known.
  final String? arabic;

  /// Where the Name is rooted, as written in the deck.
  final String ref;
}

/// One entry of the deck, kept free of any screen so it can be tested.
class NamesCard {
  const NamesCard(this.name, this.meaning, this.ref, [this.arabic]);
  final String name;
  final String meaning;
  final String ref;
  final String? arabic;
}

/// [count] questions from [cards]. The same [rnd] seed gives the same
/// questions in the same order with the same choices, which is how two
/// players in a race get one game. Each card is asked at most once, and the
/// three wrong choices are other cards with a different name.
List<NamesRound> buildNamesRounds(
  List<NamesCard> cards,
  Random rnd, {
  int count = 10,
}) {
  final List<NamesCard> pool = List<NamesCard>.of(cards);
  if (pool.length < 4) return const <NamesRound>[];
  pool.shuffle(rnd);
  final int n = count < pool.length ? count : pool.length;
  final List<NamesRound> out = <NamesRound>[];
  for (int i = 0; i < n; i++) {
    final NamesCard right = pool[i];
    final List<NamesCard> others = pool
        .where((NamesCard c) => c.name != right.name)
        .toList()
      ..shuffle(rnd);
    final List<NamesCard> four = <NamesCard>[right, ...others.take(3)]
      ..shuffle(rnd);
    out.add(NamesRound(
      meaning: right.meaning,
      options: <String>[for (final NamesCard c in four) c.name],
      answer: four.indexOf(right),
      arabic: right.arabic,
      ref: right.ref,
    ));
  }
  return out;
}
