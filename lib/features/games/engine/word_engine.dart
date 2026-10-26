/// Word Search and Word Scramble: the grid, the shuffle and the checks.
///
/// Rules this file keeps (and `test/games/learning_games_test.dart` checks):
///  * the words come from the Huda glossary in the app, each with its own
///    plain gloss as the clue, and nothing else;
///  * a word is never a Name of Allah: puzzles that jumble or hide the Names
///    are not made;
///  * no timer, no points; hints are free and fixed in number.
///
/// Pure Dart (no Flutter) so it can be checked with a plain Dart SDK.
library;

import 'dart:math';

/// The most free hints in one word game.
const int kHintsPerWordGame = 3;

/// A word and its clue.
class WordClue {
  const WordClue({required this.word, required this.clue, required this.term});

  /// Lower-case letters a to z only, used in the grid.
  final String word;

  /// The gloss the app gives for the term.
  final String clue;

  /// The term as the glossary prints it.
  final String term;
}

/// Turns glossary entries into puzzle words: letters a to z only, between
/// [minLen] and [maxLen] long, no repeats.
List<WordClue> wordsFromGlossary(
  List<({String term, String gloss})> entries, {
  int minLen = 4,
  int maxLen = 10,
}) {
  final List<WordClue> out = <WordClue>[];
  final Set<String> seen = <String>{};
  for (final ({String term, String gloss}) e in entries) {
    final String w = e.term
        .toLowerCase()
        .replaceAll('’', '')
        .replaceAll("'", '');
    if (w.length < minLen || w.length > maxLen) continue;
    if (!RegExp(r'^[a-z]+$').hasMatch(w)) continue;
    if (e.gloss.trim().isEmpty || !seen.add(w)) continue;
    out.add(WordClue(word: w, clue: e.gloss.trim(), term: e.term));
  }
  return out;
}

/// A cell position.
typedef Cell = ({int r, int c});

/// A word placed in the grid.
class PlacedWord {
  const PlacedWord(this.clue, this.start, this.dr, this.dc);

  final WordClue clue;
  final Cell start;
  final int dr;
  final int dc;

  Cell cellAt(int i) => (r: start.r + dr * i, c: start.c + dc * i);

  Cell get end => cellAt(clue.word.length - 1);

  List<Cell> get cells => <Cell>[
        for (int i = 0; i < clue.word.length; i++) cellAt(i),
      ];
}

/// A word-search grid.
class WordGrid {
  WordGrid(this.size, this.letters, this.placed);

  final int size;

  /// `letters[r][c]`, one lower-case letter each.
  final List<List<String>> letters;
  final List<PlacedWord> placed;

  String at(Cell x) => letters[x.r][x.c];

  /// The placed word that runs from [a] to [b] in either direction, or null.
  PlacedWord? match(Cell a, Cell b) {
    for (final PlacedWord p in placed) {
      if ((p.start == a && p.end == b) || (p.start == b && p.end == a)) {
        return p;
      }
    }
    return null;
  }

  /// True when [a] to [b] is a straight line (row, column or diagonal).
  static bool isLine(Cell a, Cell b) {
    final int dr = (b.r - a.r).abs();
    final int dc = (b.c - a.c).abs();
    return dr == 0 || dc == 0 || dr == dc;
  }
}

/// The directions words run in: right, down, and down-right.
const List<({int dr, int dc})> _dirs = <({int dr, int dc})>[
  (dr: 0, dc: 1),
  (dr: 1, dc: 0),
  (dr: 1, dc: 1),
];

/// Makes a [size] x [size] grid with up to [count] words hidden in it.
/// Returns null when fewer than 3 words fit.
WordGrid? buildWordGrid(
  List<WordClue> pool,
  Random rnd, {
  int size = 10,
  int count = 7,
}) {
  final List<WordClue> usable = <WordClue>[
    for (final WordClue w in pool)
      if (w.word.length <= size) w,
  ];
  if (usable.length < 3) return null;
  for (int attempt = 0; attempt < 40; attempt++) {
    final List<WordClue> picked = (List<WordClue>.of(usable)..shuffle(rnd))
        .take(count)
        .toList()
      ..sort((WordClue a, WordClue b) => b.word.length - a.word.length);
    final List<List<String?>> g = <List<String?>>[
      for (int r = 0; r < size; r++) List<String?>.filled(size, null),
    ];
    final List<PlacedWord> placed = <PlacedWord>[];
    for (final WordClue w in picked) {
      PlacedWord? at;
      for (int t = 0; t < 120 && at == null; t++) {
        final ({int dr, int dc}) d = _dirs[rnd.nextInt(_dirs.length)];
        final int maxR = size - 1 - d.dr * (w.word.length - 1);
        final int maxC = size - 1 - d.dc * (w.word.length - 1);
        if (maxR < 0 || maxC < 0) continue;
        final Cell s = (r: rnd.nextInt(maxR + 1), c: rnd.nextInt(maxC + 1));
        bool fits = true;
        for (int i = 0; i < w.word.length && fits; i++) {
          final String? cur = g[s.r + d.dr * i][s.c + d.dc * i];
          if (cur != null && cur != w.word[i]) fits = false;
        }
        if (fits) at = PlacedWord(w, s, d.dr, d.dc);
      }
      if (at == null) continue;
      for (int i = 0; i < w.word.length; i++) {
        final Cell c = at.cellAt(i);
        g[c.r][c.c] = w.word[i];
      }
      placed.add(at);
    }
    if (placed.length < 3) continue;
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
    final List<List<String>> letters = <List<String>>[
      for (int r = 0; r < size; r++)
        <String>[
          for (int c = 0; c < size; c++)
            g[r][c] ?? alphabet[rnd.nextInt(alphabet.length)],
        ],
    ];
    return WordGrid(size, letters, placed);
  }
  return null;
}

/// A Word Search game in progress.
class SearchSession {
  SearchSession(this.grid, {bool hints = true})
      : hintsLeft = hints ? kHintsPerWordGame : 0;

  final WordGrid grid;
  final Set<String> found = <String>{};

  /// Words whose first letter a hint has shown.
  final Set<String> hinted = <String>{};
  int hintsLeft;

  bool get finished => found.length == grid.placed.length;

  /// Tries the line from [a] to [b]. Returns the word found, or null.
  PlacedWord? tryLine(Cell a, Cell b) {
    final PlacedWord? p = grid.match(a, b);
    if (p == null || found.contains(p.clue.word)) return null;
    found.add(p.clue.word);
    return p;
  }

  /// A free hint: shows where an unfound word starts.
  PlacedWord? useHint() {
    if (hintsLeft <= 0) return null;
    for (final PlacedWord p in grid.placed) {
      if (found.contains(p.clue.word) || hinted.contains(p.clue.word)) {
        continue;
      }
      hinted.add(p.clue.word);
      hintsLeft -= 1;
      return p;
    }
    return null;
  }
}

/// [word] with its letters in a different order. Words with one letter
/// repeated all through cannot differ and are returned as they are.
List<String> scrambleLetters(String word, Random rnd) {
  final List<String> original = word.split('');
  if (original.toSet().length < 2) return original;
  List<String> a = List<String>.of(original);
  for (int i = 0; i < 60; i++) {
    a = List<String>.of(original)..shuffle(rnd);
    if (a.join() != word) return a;
  }
  return <String>[...original.sublist(1), original.first];
}

/// A Word Scramble game in progress.
class ScrambleSession {
  ScrambleSession(this.words, Random rnd, {bool hints = true})
      : _rnd = rnd,
        hintsLeft = hints ? kHintsPerWordGame : 0 {
    _start();
  }

  final List<WordClue> words;
  final Random _rnd;
  int index = 0;
  int hintsLeft;

  /// Rounds solved with no wrong check.
  int firstTry = 0;
  int misses = 0;
  bool solved = false;

  /// Tile letters, and which are used, for the current word.
  List<String> tiles = <String>[];

  /// Tile indexes in the order the player tapped them.
  final List<int> built = <int>[];

  WordClue get current => words[index];
  int get total => words.length;
  bool get isLast => index >= words.length - 1;
  String get attempt => built.map((int i) => tiles[i]).join();

  void _start() {
    tiles = scrambleLetters(words[index].word, _rnd);
    built.clear();
    misses = 0;
    solved = false;
  }

  bool isUsed(int tile) => built.contains(tile);

  void tapTile(int tile) {
    if (solved || tile < 0 || tile >= tiles.length || isUsed(tile)) return;
    built.add(tile);
  }

  /// Takes back the tile at [slot] and everything after it.
  void removeFrom(int slot) {
    if (solved || slot < 0 || slot >= built.length) return;
    built.removeRange(slot, built.length);
  }

  void clear() {
    if (!solved) built.clear();
  }

  /// Checks the word. Returns true when right.
  bool check() {
    if (solved) return true;
    if (attempt == current.word) {
      solved = true;
      if (misses == 0) firstTry += 1;
      return true;
    }
    misses += 1;
    return false;
  }

  /// A free hint: clears the attempt and puts the next right letter down.
  bool useHint() {
    if (hintsLeft <= 0 || solved) return false;
    final String w = current.word;
    // Keep the correct beginning of the attempt, drop the rest.
    int ok = 0;
    while (ok < built.length && ok < w.length && tiles[built[ok]] == w[ok]) {
      ok++;
    }
    built.removeRange(ok, built.length);
    if (ok >= w.length) return false;
    for (int i = 0; i < tiles.length; i++) {
      if (!isUsed(i) && tiles[i] == w[ok]) {
        built.add(i);
        hintsLeft -= 1;
        return true;
      }
    }
    return false;
  }

  bool next() {
    if (!solved || isLast) return false;
    index += 1;
    _start();
    return true;
  }
}
