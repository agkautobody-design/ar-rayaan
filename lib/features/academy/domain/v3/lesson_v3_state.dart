/// The gating rules of Academy v3 lessons, as plain Dart objects the screen
/// drives and the tests exercise.
///
/// The rules (owner's standard):
///  * a check, an arrange or a match must be PASSED before the lesson goes on;
///  * a wrong answer re-teaches (the option's own text) and names the step
///    that taught it, so the learner can go back to it;
///  * the learner is never trapped: after [GatedRun.maxMisses] misses on the
///    same item the answer is shown with its explanation, the item counts as
///    settled, and it comes back once more at the end of the lesson;
///  * nothing here counts points, scores or streaks. A miss only changes what
///    is shown next.
library;

import 'dart:math';

import 'lesson_v3_model.dart';

/// A seed that is the same on every run and platform (String.hashCode is not
/// promised to be).
int stableSeed(String s) {
  int h = 17;
  for (final int c in s.codeUnits) {
    h = (h * 31 + c) & 0x3fffffff;
  }
  return h;
}

class ItemRecord {
  int misses = 0;
  bool correct = false;
  bool revealed = false;
}

class AnswerResult {
  const AnswerResult({
    required this.correct,
    required this.revealed,
    required this.misses,
  });

  final bool correct;

  /// True when the answer is now shown to the learner (two misses).
  final bool revealed;
  final int misses;

  bool get settled => correct || revealed;
}

/// Everything the learner has answered in one run through a lesson.
class GatedRun {
  static const int maxMisses = 2;

  final Map<String, ItemRecord> _records = <String, ItemRecord>{};

  ItemRecord _rec(String key) => _records.putIfAbsent(key, ItemRecord.new);

  bool isSettled(String key) {
    final ItemRecord? r = _records[key];
    return r != null && (r.correct || r.revealed);
  }

  bool wasRevealed(String key) => _records[key]?.revealed ?? false;

  int missesOf(String key) => _records[key]?.misses ?? 0;

  /// Keys of every item the learner had to be shown the answer to.
  List<String> get revealedKeys => <String>[
        for (final MapEntry<String, ItemRecord> e in _records.entries)
          if (e.value.revealed) e.key,
      ];

  /// Record one answer to [key]. Answering a settled item changes nothing.
  AnswerResult record(String key, {required bool correct}) {
    final ItemRecord r = _rec(key);
    if (!(r.correct || r.revealed)) {
      if (correct) {
        r.correct = true;
      } else {
        r.misses++;
        if (r.misses >= maxMisses) r.revealed = true;
      }
    }
    return AnswerResult(correct: r.correct, revealed: r.revealed, misses: r.misses);
  }
}

// ---------------------------------------------------------------------------
// Check step: one item at a time.
// ---------------------------------------------------------------------------

class PickResult {
  const PickResult({
    required this.correct,
    required this.revealed,
    this.reteach,
    this.back,
  });

  final bool correct;
  final bool revealed;
  final String? reteach;
  final String? back;
}

class CheckStepState {
  CheckStepState(this.step, this.run);

  final CheckStep step;
  final GatedRun run;

  int current = 0;

  /// Options already tried on the current item (all wrong).
  final Set<int> tried = <int>{};

  /// The re-teach for the last wrong pick (cleared on the next pick).
  String? reteach;
  String? back;

  CheckItem get item => step.items[current];

  String keyOf(int index) => '${step.id}/${step.items[index].id}';

  bool get itemSettled => run.isSettled(keyOf(current));
  bool get itemRevealed => run.wasRevealed(keyOf(current));
  bool get isLastItem => current == step.items.length - 1;

  /// The step is passed when every item is answered right or shown.
  bool get allSettled {
    for (int i = 0; i < step.items.length; i++) {
      if (!run.isSettled(keyOf(i))) return false;
    }
    return true;
  }

  /// Choose option [option] for the current item.
  PickResult pick(int option) {
    if (itemSettled || option < 0 || option >= item.options.length) {
      return PickResult(correct: itemSettled && !itemRevealed, revealed: itemRevealed);
    }
    final bool right = option == item.answer;
    final AnswerResult r = run.record(keyOf(current), correct: right);
    if (right) {
      reteach = null;
      back = null;
      return const PickResult(correct: true, revealed: false);
    }
    tried.add(option);
    final CheckOption o = item.options[option];
    reteach = o.reteach;
    back = o.back;
    return PickResult(
      correct: false,
      revealed: r.revealed,
      reteach: o.reteach,
      back: o.back,
    );
  }

  /// Move to the next item once the current one is settled.
  bool advance() {
    if (!itemSettled || isLastItem) return false;
    current++;
    tried.clear();
    reteach = null;
    back = null;
    return true;
  }
}

// ---------------------------------------------------------------------------
// Arrange step.
// ---------------------------------------------------------------------------

class ArrangeFeedback {
  const ArrangeFeedback({
    required this.correct,
    required this.revealed,
    this.reteach,
    this.back,
    this.firstWrong,
  });

  final bool correct;
  final bool revealed;
  final String? reteach;
  final String? back;
  final int? firstWrong;
}

class ArrangeState {
  ArrangeState(this.step, this.run, {Random? random}) {
    final List<int> idx = List<int>.generate(step.items.length, (int i) => i);
    final Random rng = random ?? Random(stableSeed(step.id));
    // Never present the answer already in order.
    for (int tries = 0; tries < 20; tries++) {
      idx.shuffle(rng);
      if (!_isIdentity(idx)) break;
    }
    if (_isIdentity(idx) && idx.length > 1) {
      final int t = idx[0];
      idx[0] = idx[1];
      idx[1] = t;
    }
    pool = idx;
  }

  final ArrangeStep step;
  final GatedRun run;

  /// Items not yet placed, in the order they are offered.
  late final List<int> pool;

  /// Item indices the learner has put in order, first to last.
  final List<int> placed = <int>[];

  ArrangeFeedback? feedback;

  static bool _isIdentity(List<int> l) {
    for (int i = 0; i < l.length; i++) {
      if (l[i] != i) return false;
    }
    return true;
  }

  String get key => step.id;

  bool get settled => run.isSettled(key);
  bool get revealed => run.wasRevealed(key);
  bool get complete => placed.length == step.items.length;

  List<int> get remaining => <int>[
        for (final int i in pool)
          if (!placed.contains(i)) i,
      ];

  void place(int item) {
    if (settled || placed.contains(item)) return;
    placed.add(item);
    feedback = null;
  }

  /// Take back the item at [position] and everything after it.
  void takeBackFrom(int position) {
    if (settled || position < 0 || position >= placed.length) return;
    placed.removeRange(position, placed.length);
    feedback = null;
  }

  /// Check the order. Needs every item placed.
  ArrangeFeedback check() {
    if (settled) {
      return feedback ?? ArrangeFeedback(correct: !revealed, revealed: revealed);
    }
    if (!complete) {
      return feedback = const ArrangeFeedback(
        correct: false,
        revealed: false,
        reteach: 'Put every step in place first, then check.',
      );
    }
    int? wrongAt;
    for (int i = 0; i < placed.length; i++) {
      if (placed[i] != i) {
        wrongAt = i;
        break;
      }
    }
    final bool right = wrongAt == null && complete;
    final AnswerResult r = run.record(key, correct: right);
    if (right) {
      return feedback = const ArrangeFeedback(correct: true, revealed: false);
    }
    if (r.revealed) {
      placed
        ..clear()
        ..addAll(List<int>.generate(step.items.length, (int i) => i));
      return feedback = ArrangeFeedback(
        correct: false,
        revealed: true,
        reteach: step.explain,
      );
    }
    final int at = wrongAt ?? 0;
    final ArrangeItem should = step.items[at];
    // Keep what was right, hand the rest back.
    placed.removeRange(at, placed.length);
    return feedback = ArrangeFeedback(
      correct: false,
      revealed: false,
      reteach: 'Place ${at + 1} should be: ${should.text}. ${should.why}',
      back: should.back,
      firstWrong: at,
    );
  }
}

// ---------------------------------------------------------------------------
// Match step.
// ---------------------------------------------------------------------------

class MatchFeedback {
  const MatchFeedback({
    required this.correct,
    required this.revealed,
    this.reteach,
    this.back,
  });

  final bool correct;
  final bool revealed;
  final String? reteach;
  final String? back;
}

class MatchState {
  MatchState(this.step, this.run, {Random? random}) {
    final List<int> idx = List<int>.generate(step.pairs.length, (int i) => i);
    final Random rng = random ?? Random(stableSeed('${step.id}#match'));
    for (int tries = 0; tries < 20; tries++) {
      idx.shuffle(rng);
      if (!_same(idx)) break;
    }
    rightOrder = idx;
  }

  final MatchStep step;
  final GatedRun run;

  /// The order the right-hand faces are offered in (pair indices).
  late final List<int> rightOrder;

  /// The left face currently chosen.
  int? selectedLeft;

  /// Pairs already joined (right or shown).
  final Set<int> done = <int>{};

  static bool _same(List<int> l) {
    for (int i = 0; i < l.length; i++) {
      if (l[i] != i) return false;
    }
    return l.length > 1;
  }

  String keyOf(int pair) => '${step.id}/p$pair';

  bool get allSettled {
    for (int i = 0; i < step.pairs.length; i++) {
      if (!run.isSettled(keyOf(i))) return false;
    }
    return true;
  }

  void selectLeft(int pair) {
    if (done.contains(pair)) return;
    selectedLeft = pair;
  }

  /// The learner taps the right-hand face of pair [rightPair]. Null when no
  /// left face is chosen.
  MatchFeedback? tapRight(int rightPair) {
    final int? left = selectedLeft;
    if (left == null || done.contains(rightPair)) return null;
    final bool right = left == rightPair;
    final AnswerResult r = run.record(keyOf(left), correct: right);
    if (right) {
      done.add(left);
      selectedLeft = null;
      return const MatchFeedback(correct: true, revealed: false);
    }
    final MatchPair p = step.pairs[left];
    if (r.revealed) {
      done.add(left);
      selectedLeft = null;
      return MatchFeedback(
        correct: false,
        revealed: true,
        reteach: 'That one goes with the other: ${p.why}',
        back: p.back,
      );
    }
    return MatchFeedback(
      correct: false,
      revealed: false,
      reteach: 'Not that one. ${p.why}',
      back: p.back,
    );
  }
}
