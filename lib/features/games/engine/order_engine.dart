/// The ordering engine: put things in the right order. Used by the Seerah
/// timeline, Prophets in Order, and the Wudu and Salah steps.
///
/// Rules this file keeps (and `test/games/learning_games_test.dart` checks):
///  * every round has a non-empty source and an explanation;
///  * the right order always comes from content already in the app: the
///    order the Seerah School tells its stories in, what the Messengers' tree
///    states, or the steps of a Huda guide exactly as the guide gives them;
///  * no timer, no points; a wrong check costs nothing and can be repeated;
///    a hint is free and there are [kHintsPerOrderGame] of them.
///
/// Pure Dart (no Flutter) so it can be checked with a plain Dart SDK.
library;

import 'dart:math';

/// The most free hints in one ordering game.
const int kHintsPerOrderGame = 3;

/// One thing to place.
class OrderItem {
  const OrderItem({required this.id, required this.label, this.detail});

  final String id;

  /// What the card says.
  final String label;

  /// Shown after the round is solved.
  final String? detail;
}

/// One puzzle: [items] are listed in the RIGHT order.
class OrderRound {
  const OrderRound({
    required this.id,
    required this.prompt,
    required this.items,
    required this.explanation,
    required this.citation,
    this.note,
  });

  final String id;
  final String prompt;
  final List<OrderItem> items;
  final String explanation;

  /// Where the order comes from. Never empty.
  final String citation;

  /// A line about what the order does and does not claim.
  final String? note;
}

/// A game of ordering rounds in progress.
class OrderSession {
  OrderSession(this.rounds, Random rnd, {bool hints = true})
      : _rnd = rnd,
        hintsLeft = hints ? kHintsPerOrderGame : 0 {
    _shuffleCurrent();
  }

  final List<OrderRound> rounds;
  final Random _rnd;
  int index = 0;
  int hintsLeft;

  /// For each position on screen, the index (in the right order) of the item
  /// shown there.
  List<int> arrangement = <int>[];

  /// Positions a hint has fixed.
  final Set<int> locked = <int>{};

  /// Wrong checks in the current round.
  int misses = 0;

  /// True once the current round is in the right order.
  bool solved = false;

  /// Rounds solved with no wrong check.
  int firstTry = 0;

  OrderRound get round => rounds[index];
  int get total => rounds.length;
  bool get isLast => index >= rounds.length - 1;
  List<OrderItem> get shown => <OrderItem>[
        for (final int i in arrangement) round.items[i],
      ];

  void _shuffleCurrent() {
    final int n = rounds[index].items.length;
    List<int> a;
    int guard = 0;
    do {
      a = List<int>.generate(n, (int i) => i)..shuffle(_rnd);
    } while (n > 1 && _inOrder(a) && ++guard < 50);
    if (n > 1 && _inOrder(a)) {
      a = <int>[...a.sublist(1), a.first];
    }
    arrangement = a;
    locked.clear();
    misses = 0;
    solved = false;
  }

  static bool _inOrder(List<int> a) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != i) return false;
    }
    return true;
  }

  bool get canUseHint => hintsLeft > 0 && !solved;

  /// Moves the card at [pos] one place up. False when it cannot move.
  bool moveUp(int pos) => _swap(pos, pos - 1);

  /// Moves the card at [pos] one place down. False when it cannot move.
  bool moveDown(int pos) => _swap(pos, pos + 1);

  bool _swap(int a, int b) {
    if (solved) return false;
    if (a < 0 || b < 0 || a >= arrangement.length || b >= arrangement.length) {
      return false;
    }
    if (locked.contains(a) || locked.contains(b)) return false;
    final int t = arrangement[a];
    arrangement[a] = arrangement[b];
    arrangement[b] = t;
    return true;
  }

  /// How many cards are in their right place.
  int get rightPlaces {
    int n = 0;
    for (int i = 0; i < arrangement.length; i++) {
      if (arrangement[i] == i) n++;
    }
    return n;
  }

  /// Checks the order. Returns true when it is right.
  bool check() {
    if (solved) return true;
    if (rightPlaces == arrangement.length) {
      solved = true;
      if (misses == 0) firstTry += 1;
      return true;
    }
    misses += 1;
    return false;
  }

  /// A free hint: puts the first card that is out of place where it belongs
  /// and fixes it there. Returns the position, or null when none can be used.
  int? useHint() {
    if (!canUseHint) return null;
    for (int p = 0; p < arrangement.length; p++) {
      if (arrangement[p] == p) continue;
      final int q = arrangement.indexOf(p);
      final int t = arrangement[p];
      arrangement[p] = arrangement[q];
      arrangement[q] = t;
      locked.add(p);
      hintsLeft -= 1;
      return p;
    }
    return null;
  }

  /// Moves to the next round. False at the end or before this one is solved.
  bool next() {
    if (!solved || isLast) return false;
    index += 1;
    _shuffleCurrent();
    return true;
  }
}

// ---------------------------------------------------------------------------
// Seerah timeline
// ---------------------------------------------------------------------------

String _short(String s) {
  final String t = s.trim();
  if (t.length <= 140) return t;
  final int cut = t.lastIndexOf(' ', 140);
  return '${t.substring(0, cut > 70 ? cut : 140)} …';
}

/// A story of the Seerah School as the timeline needs it.
typedef TimelineStory = ({String title, String firstSource, int number});

/// One event of the timeline bank, in the order the Seerah School tells them.
typedef TimelineEvent = ({
  String id,
  String story,
  String label,
  String fact,
});

/// Builds [rounds] rounds of [size] events each. The events are asked in the
/// order the Seerah School tells its stories, which is what the bank is
/// checked against.
List<OrderRound> buildSeerahOrder(
  List<TimelineEvent> events,
  Map<String, TimelineStory> stories,
  Random rnd, {
  int rounds = 5,
  int size = 4,
}) {
  final List<TimelineEvent> ok = <TimelineEvent>[
    for (final TimelineEvent e in events)
      if (stories.containsKey(e.story)) e,
  ];
  if (ok.length < size) return <OrderRound>[];
  final List<OrderRound> out = <OrderRound>[];
  final Set<String> seen = <String>{};
  int guard = 0;
  while (out.length < rounds && guard++ < rounds * 30) {
    final List<int> picks = List<int>.generate(ok.length, (int i) => i)
      ..shuffle(rnd);
    final List<int> chosen = picks.take(size).toList()..sort();
    final String key = chosen.join(',');
    if (!seen.add(key)) continue;
    final List<TimelineEvent> es = <TimelineEvent>[
      for (final int i in chosen) ok[i],
    ];
    out.add(OrderRound(
      id: 'seerah-order-$key',
      prompt: 'Put these events of the Seerah in the order they happened, '
          'earliest first.',
      items: <OrderItem>[
        for (final TimelineEvent e in es)
          OrderItem(id: e.id, label: e.label, detail: e.fact),
      ],
      explanation: <String>[
        for (int i = 0; i < es.length; i++)
          '${i + 1}. ${es[i].label}: “${es[i].fact}”',
      ].join('\n'),
      citation: <String>[
        for (final TimelineEvent e in es)
          'Seerah School, “${stories[e.story]!.title}” '
              '(story ${stories[e.story]!.number} of 30): '
              '${_short(stories[e.story]!.firstSource)}',
      ].join('\n'),
      note: 'The order is the one the Seerah School tells its stories in. '
          'Each event is shown with the words of its own story.',
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Prophets in order
// ---------------------------------------------------------------------------

/// True when [ancestor] is an Established ancestor of [person] in the
/// Messengers' tree: every person on the way up is Established too.
bool isEstablishedAncestor(
  Map<String, Map<String, dynamic>> nodes,
  String ancestor,
  String person,
) {
  final Set<String> seen = <String>{};
  bool walk(String id) {
    if (!seen.add(id)) return false;
    final Map<String, dynamic>? n = nodes[id];
    if (n == null || n['sourceLabel'] != 'Established') return false;
    for (final dynamic p in (n['parents'] as List<dynamic>? ?? <dynamic>[])) {
      final String pid = p as String;
      final Map<String, dynamic>? pn = nodes[pid];
      if (pn == null || pn['sourceLabel'] != 'Established') continue;
      if (pid == ancestor) return true;
      if (walk(pid)) return true;
    }
    return false;
  }

  return walk(person);
}

/// Why [a] comes before [b], in words the tree itself supports, or null when
/// the tree does not order them.
String? prophetOrderReason(
  Map<String, Map<String, dynamic>> nodes,
  String a,
  String b,
) {
  final String an = (nodes[a]?['name'] as String?) ?? a;
  final String bn = (nodes[b]?['name'] as String?) ?? b;
  if (a == 'adam') {
    return 'Adam was the first man and the first prophet, so $bn comes '
        'after him.';
  }
  if (b == 'muhammad') {
    return '$an is before Muhammad ﷺ, the Seal of the Prophets.';
  }
  if (isEstablishedAncestor(nodes, a, b)) {
    return '$an is an ancestor of $bn in the Messengers’ tree.';
  }
  return null;
}

/// Builds the rounds from the bank's lists of person ids (each in the right
/// order). A round whose order the tree does not support is dropped.
List<OrderRound> buildProphetOrder(
  List<List<String>> bank,
  Map<String, Map<String, dynamic>> nodes,
  Random rnd, {
  int rounds = 5,
}) {
  final List<OrderRound> pool = <OrderRound>[];
  for (int r = 0; r < bank.length; r++) {
    final List<String> ids = bank[r];
    if (ids.length < 3) continue;
    bool ok = true;
    final List<String> lines = <String>[];
    for (int i = 0; i < ids.length - 1 && ok; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        if (prophetOrderReason(nodes, ids[i], ids[j]) == null) {
          ok = false;
          break;
        }
      }
      final String? why = prophetOrderReason(nodes, ids[i], ids[i + 1]);
      if (why != null) lines.add(why);
    }
    if (!ok) continue;
    final List<String> cites = <String>[];
    for (final String id in ids) {
      final Map<String, dynamic>? n = nodes[id];
      if (n == null) {
        ok = false;
        break;
      }
      final List<String> src = ((n['sources'] as List<dynamic>?) ?? <dynamic>[])
          .cast<String>();
      if (src.isEmpty) {
        ok = false;
        break;
      }
      cites.add('${n['name']}: ${src.first}');
    }
    if (!ok) continue;
    pool.add(OrderRound(
      id: 'prophets-order-$r',
      prompt: 'Put these prophets in order, earliest first.',
      items: <OrderItem>[
        for (final String id in ids)
          OrderItem(id: id, label: nodes[id]!['name'] as String),
      ],
      explanation: lines.join('\n'),
      citation: 'The Messengers’ tree (Family section). ${cites.join(' · ')}',
      note: 'Only prophets whose order the tree states are asked: Adam first, '
          'Muhammad ﷺ last, and fathers before their sons. No dates are '
          'given.',
    ));
  }
  pool.shuffle(rnd);
  return pool.take(rounds).toList();
}

// ---------------------------------------------------------------------------
// Wudu and Salah steps
// ---------------------------------------------------------------------------

/// A Huda guide as the steps game needs it.
typedef GuideSteps = ({
  String id,
  String title,
  List<String> steps,
  List<String> sources,
  String? madhhabNote,
});

const Map<String, String> _fullLabels = <String, String>{
  'Recite the opening supplication':
      'Recite the opening supplication, then Surah al-Fatihah',
  'Sujud — prostrate on seven limbs':
      'Sujud — prostrate on seven limbs: forehead (with nose), two hands, '
          'two knees, two feet',
  'In the final sitting: the tashahhud':
      'Final sitting: the tashahhud, blessings on the Prophet ﷺ, then the '
          'salaam to the right and left',
};

/// A short card label for a guide step: the words before the first dash,
/// semicolon or bracket, cut at a word if it is still long.
String stepLabel(String step) {
  String s = step.trim();
  // Steps whose words before the first dash or bracket would drop part of
  // the act (Fatihah, the seven limbs, the salaam) keep a fuller label.
  for (final MapEntry<String, String> e in _fullLabels.entries) {
    if (s.startsWith(e.key)) return e.value;
  }
  for (final String sep in <String>[' — ', ' – ', '; ', ' (']) {
    final int at = s.indexOf(sep);
    if (at > 12) s = s.substring(0, at);
  }
  s = s.trim();
  while (s.endsWith('.') || s.endsWith(',') || s.endsWith(':')) {
    s = s.substring(0, s.length - 1).trimRight();
  }
  if (s.length > 90) {
    final int cut = s.lastIndexOf(' ', 90);
    s = '${s.substring(0, cut > 40 ? cut : 90)} …';
  }
  return s;
}

/// Builds the step rounds for one guide: the first half, the second half, and
/// all the steps together. The right order is the guide's own order.
List<OrderRound> buildStepOrder(GuideSteps g) {
  final List<String> steps = <String>[
    for (final String s in g.steps)
      if (s.trim().isNotEmpty) s.trim(),
  ];
  if (steps.length < 4 || g.sources.isEmpty) return <OrderRound>[];
  final List<OrderItem> items = <OrderItem>[
    for (int i = 0; i < steps.length; i++)
      OrderItem(
        id: '${g.id}-${i + 1}',
        label: stepLabel(steps[i]),
        detail: steps[i],
      ),
  ];
  final int half = steps.length ~/ 2;
  final String note = 'These steps are the guide “${g.title}” in the app, in '
      'the guide’s own order. The app does not give them as one school’s '
      'way. ${g.madhhabNote ?? 'Schools of law differ on some details, so '
          'ask a teacher you trust.'}';
  OrderRound round(String id, String prompt, List<OrderItem> its) =>
      OrderRound(
        id: id,
        prompt: prompt,
        items: its,
        explanation: <String>[
          for (int i = 0; i < its.length; i++) '${i + 1}. ${its[i].detail}',
        ].join('\n'),
        citation: 'Huda guide “${g.title}”. Sources: ${g.sources.join('; ')}',
        note: note,
      );
  return <OrderRound>[
    round(
      '${g.id}-a',
      'Put the first $half steps in order.',
      items.sublist(0, half),
    ),
    round(
      '${g.id}-b',
      'Put the last ${steps.length - half} steps in order.',
      items.sublist(half),
    ),
    round(
      '${g.id}-all',
      'Now put all ${steps.length} steps in order.',
      items,
    ),
  ];
}
