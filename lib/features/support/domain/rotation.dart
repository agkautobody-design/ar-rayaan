import 'dart:math';

import 'support_pack.dart';

/// Picks a snippet so that the same wording is never repeated within a gap.
///
/// The owner is very sensitive to canned or repeated replies, so this is the
/// rule (docs/support/pack_format.md section 5):
///  * seeded per session (a [Random] with a seed), so the order differs
///    between sessions and is repeatable in tests;
///  * a history of the ids shown, per variant group, by turn number;
///  * candidates = the given snippets minus any shown within the group's
///    `minGapTurns`; when none are left, widen to the least recently shown;
///  * the identical text is never shown twice in a row, in any case.
class SnippetRotator {
  SnippetRotator({int seed = 0, this.defaultMinGap = 6}) : _rng = Random(seed);

  final Random _rng;
  final int defaultMinGap;

  /// id -> the turn it was last shown.
  final Map<String, int> _lastTurn = <String, int>{};
  String? _lastText;
  int _turn = 0;

  int get turn => _turn;

  /// Call once for every message the person sends.
  void nextTurn() => _turn++;

  /// The ids shown so far, most recent first (for the on-device context
  /// summary and for tests).
  List<String> get shownIds {
    final List<MapEntry<String, int>> e = _lastTurn.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    return <String>[for (final MapEntry<String, int> x in e) x.key];
  }

  bool wasShownWithin(SupportSnippet s, int gap) {
    final int? t = _lastTurn[s.id];
    return t != null && _turn - t < gap;
  }

  /// Chooses one of [options]. [toneOrder] lists the tones by preference
  /// (the first is the best). [text] gives the final text of an option (after
  /// slots are filled) so the same sentence is never repeated. Returns null
  /// when [options] is empty.
  SupportSnippet? pick(
    List<SupportSnippet> options, {
    List<String> toneOrder = const <String>[],
    String Function(SupportSnippet)? text,
  }) {
    if (options.isEmpty) return null;
    String textOf(SupportSnippet s) => text != null ? text(s) : s.textIn('en');
    bool notSameAsLast(SupportSnippet s) => textOf(s) != _lastText;

    List<SupportSnippet> fresh(List<SupportSnippet> l) => <SupportSnippet>[
          for (final SupportSnippet s in l)
            if (!wasShownWithin(s, s.minGapTurns ?? defaultMinGap) && notSameAsLast(s)) s,
        ];

    List<SupportSnippet> pool = <SupportSnippet>[];
    // Preferred tones first, widening one tone at a time.
    final List<String?> order = <String?>[...toneOrder, null];
    for (final String? tone in order) {
      final List<SupportSnippet> inTone = tone == null
          ? options
          : <SupportSnippet>[
              for (final SupportSnippet s in options)
                if (s.tone == tone) s,
            ];
      pool = fresh(inTone);
      if (pool.isNotEmpty) break;
    }
    if (pool.isEmpty) {
      // Everything was used lately: take the least recently shown, still
      // never the line we just said.
      final List<SupportSnippet> sorted = options.where(notSameAsLast).toList();
      if (sorted.isEmpty) return null;
      sorted.sort((SupportSnippet a, SupportSnippet b) =>
          (_lastTurn[a.id] ?? -1).compareTo(_lastTurn[b.id] ?? -1));
      final int oldest = _lastTurn[sorted.first.id] ?? -1;
      pool = <SupportSnippet>[
        for (final SupportSnippet s in sorted)
          if ((_lastTurn[s.id] ?? -1) == oldest) s,
      ];
    }
    final SupportSnippet chosen = pool[_rng.nextInt(pool.length)];
    _lastTurn[chosen.id] = _turn;
    _lastText = textOf(chosen);
    return chosen;
  }
}
