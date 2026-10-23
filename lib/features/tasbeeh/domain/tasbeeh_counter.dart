/// A plain counter: no wording, no claims, just a number going up. Pure Dart
/// (no Flutter, no I/O) so it is unit-tested with the plain Dart SDK.
///
/// The count runs 0..target-1 inside a round. Reaching the target starts the
/// next round at 0 and adds one to [TasbeehState.rounds].
library;

/// Largest target the user may type.
const int kTasbeehMaxTarget = 100000;

/// Hard stop for the round counter so the screen can never overflow.
const int kTasbeehMaxRounds = 999999;

/// Longest optional label the user may type.
const int kTasbeehMaxLabel = 40;

/// The one-tap targets.
const List<int> kTasbeehPresets = <int>[33, 99, 100];

const int kTasbeehDefaultTarget = 33;

class TasbeehState {
  const TasbeehState({
    this.count = 0,
    this.rounds = 0,
    this.target = kTasbeehDefaultTarget,
    this.label = '',
  });

  /// Position in the current round, 0..target-1.
  final int count;

  /// Completed rounds.
  final int rounds;

  /// Round length, 1..[kTasbeehMaxTarget].
  final int target;

  /// Optional note the user typed.
  final String label;

  /// Everything counted so far, across rounds.
  int get total => rounds * target + count;

  TasbeehState copyWith({
    int? count,
    int? rounds,
    int? target,
    String? label,
  }) {
    return TasbeehState(
      count: count ?? this.count,
      rounds: rounds ?? this.rounds,
      target: target ?? this.target,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TasbeehState &&
      other.count == count &&
      other.rounds == rounds &&
      other.target == target &&
      other.label == label;

  @override
  int get hashCode => Object.hash(count, rounds, target, label);

  @override
  String toString() =>
      'TasbeehState(count: $count, rounds: $rounds, target: $target)';
}

/// What one +1 did.
class TasbeehStep {
  const TasbeehStep(this.state, {required this.reachedTarget});

  final TasbeehState state;

  /// True when this step completed a round.
  final bool reachedTarget;
}

abstract final class TasbeehLogic {
  /// Pulls any state into its legal range (used when loading from storage).
  static TasbeehState sanitize(TasbeehState s) {
    final int target = _clampInt(s.target, 1, kTasbeehMaxTarget);
    final int rounds = _clampInt(s.rounds, 0, kTasbeehMaxRounds);
    final int count = _clampInt(s.count, 0, target - 1);
    final String label = s.label.length > kTasbeehMaxLabel
        ? s.label.substring(0, kTasbeehMaxLabel)
        : s.label;
    return TasbeehState(
      count: count,
      rounds: rounds,
      target: target,
      label: label,
    );
  }

  /// Reads a typed target. Null when it is not a whole number in
  /// 1..[kTasbeehMaxTarget].
  static int? parseTarget(String text) {
    final String t = text.trim();
    if (t.isEmpty || t.length > 7) return null;
    for (final int u in t.codeUnits) {
      if (u < 0x30 || u > 0x39) return null;
    }
    final int? v = int.tryParse(t);
    if (v == null || v < 1 || v > kTasbeehMaxTarget) return null;
    return v;
  }

  /// +1. At the target the round closes and the next one starts at 0.
  static TasbeehStep increment(TasbeehState s) {
    final int next = s.count + 1;
    if (next >= s.target) {
      if (s.rounds >= kTasbeehMaxRounds) {
        return TasbeehStep(s, reachedTarget: false);
      }
      return TasbeehStep(
        s.copyWith(count: 0, rounds: s.rounds + 1),
        reachedTarget: true,
      );
    }
    return TasbeehStep(s.copyWith(count: next), reachedTarget: false);
  }

  /// -1 (undo). Steps back across a round boundary; never below zero.
  static TasbeehState undo(TasbeehState s) {
    if (s.count > 0) return s.copyWith(count: s.count - 1);
    if (s.rounds > 0) {
      return s.copyWith(count: s.target - 1, rounds: s.rounds - 1);
    }
    return s;
  }

  /// Applies a net number of presses (positive = +1 each, negative = undo).
  /// Used to fold in presses made while the screen was off.
  static TasbeehState applyDelta(TasbeehState s, int delta) {
    TasbeehState cur = s;
    if (delta >= 0) {
      for (int i = 0; i < delta; i++) {
        cur = increment(cur).state;
      }
    } else {
      for (int i = 0; i < -delta; i++) {
        cur = undo(cur);
      }
    }
    return cur;
  }

  /// A new target restarts the position inside the round and keeps rounds.
  static TasbeehState setTarget(TasbeehState s, int target) {
    final int t = _clampInt(target, 1, kTasbeehMaxTarget);
    return s.copyWith(target: t, count: s.count % t);
  }

  /// Back to zero. Target and label stay.
  static TasbeehState reset(TasbeehState s) => s.copyWith(count: 0, rounds: 0);

  static TasbeehState setLabel(TasbeehState s, String label) {
    return s.copyWith(
      label: label.length > kTasbeehMaxLabel
          ? label.substring(0, kTasbeehMaxLabel)
          : label,
    );
  }

  static int _clampInt(int v, int lo, int hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  }
}
