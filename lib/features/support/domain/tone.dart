/// Chooses how Hadi sounds: warm, brief or formal.
///
/// Inputs are only what is already on the device: the person's setting (if
/// any) and the pace of the current conversation (how long their messages
/// are). No profile is built; nothing is stored beyond the setting itself.
enum SupportTone { warm, brief, formal, playful, calm }

abstract final class ToneChooser {
  /// [setting] is the person's choice ('warm', 'brief', 'formal' or 'auto').
  /// [recentLengths] are the word counts of their last few messages. [distress]
  /// forces the calm, plain register and never allows play.
  static List<String> order({
    String setting = 'auto',
    List<int> recentLengths = const <int>[],
    bool distress = false,
  }) {
    if (distress) return const <String>['calm', 'warm', 'brief'];
    switch (setting) {
      case 'brief':
        return const <String>['brief', 'warm', 'calm'];
      case 'formal':
        return const <String>['formal', 'warm', 'calm'];
      case 'warm':
        return const <String>['warm', 'calm', 'brief'];
    }
    // Auto: follow the person's pace. Short messages get short replies; long
    // ones get warmth; nothing else is inferred.
    if (recentLengths.isNotEmpty) {
      final List<int> last = recentLengths.length > 3
          ? recentLengths.sublist(recentLengths.length - 3)
          : recentLengths;
      final double avg = last.reduce((int a, int b) => a + b) / last.length;
      if (avg <= 4) return const <String>['brief', 'warm', 'calm'];
    }
    return const <String>['warm', 'calm', 'brief'];
  }
}
