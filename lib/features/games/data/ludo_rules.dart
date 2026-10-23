/// Pure Ludo rules that need no widgets, so they can be unit tested.
///
/// Token state: -1 in the base, 0..51 on the track (relative to the player's
/// own start), 52..57 in the home column, 58 finished.
abstract final class LudoRules {
  static const int inBase = -1;
  static const int lastTrackCell = 51;
  static const int finished = 58;

  /// The tokens of [player] that can move with [roll]. A token in the base
  /// needs a 6; a finished token never moves; a token in the home column
  /// needs an exact roll to reach the heart of the board.
  static List<int> validMoves(List<List<int>> tok, int player, int roll) {
    final List<int> out = <int>[];
    for (int t = 0; t < tok[player].length; t++) {
      final int p = tok[player][t];
      if (p == finished) continue;
      if (p == inBase) {
        if (roll == 6) out.add(t);
        continue;
      }
      if (p <= lastTrackCell) {
        out.add(t);
        continue;
      }
      final int h = p - 52 + roll;
      if (h <= 6) out.add(t);
    }
    return out;
  }

  /// True when every token of [player] is still in the base, so only a 6 can
  /// help. Used to tell a new player WHY a roll passed.
  static bool onlyBaseTokens(List<List<int>> tok, int player) =>
      tok[player].every((int p) => p == inBase);

  /// What the dice face shows: the roll in play, else the last roll, so the
  /// number does not vanish back to "?" the moment a turn passes. 0 = none yet.
  static int faceValue({required int dice, required int lastRoll}) =>
      dice != 0 ? dice : lastRoll;
}
