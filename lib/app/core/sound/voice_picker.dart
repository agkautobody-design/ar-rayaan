/// Picks an on-device text-to-speech voice for each guide: a man's voice for
/// Hādi, a gentle woman's voice for Wasia. Pure Dart, so it is unit-tested.
///
/// The device decides which voices exist; this only chooses well among them
/// by name (voices rarely state a gender field) and, when no matching voice
/// exists, falls back to pitch and rate so the two still sound different.
library;

enum VoiceProfile { neutral, hadi, wasia }

class VoiceChoice {
  const VoiceChoice({this.name, this.locale, required this.pitch, required this.rate});

  /// Null when no suitable voice was found: the device default is used.
  final String? name;
  final String? locale;
  final double pitch;
  final double rate;
}

abstract final class VoicePicker {
  static const List<String> _male = <String>[
    'daniel', 'alex', 'aaron', 'arthur', 'oliver', 'tom', 'rishi', 'lee',
    'guy', 'ryan', 'davis', 'christopher', 'eric', 'roger', 'brian',
    'andrew', 'steffan', 'mark', 'james', 'male', 'david', 'george',
  ];
  static const List<String> _female = <String>[
    'samantha', 'karen', 'moira', 'tessa', 'serena', 'kate', 'ava',
    'allison', 'susan', 'aria', 'jenny', 'sonia', 'libby', 'zira', 'emma',
    'female', 'victoria', 'fiona', 'joanna', 'salli', 'hazel', 'catherine',
  ];
  static const List<String> _novelty = <String>[
    'fred', 'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles',
    'cellos', 'good news', 'jester', 'organ', 'ralph', 'superstar',
    'trinoids', 'whisper', 'wobble', 'zarvox', 'junior', 'kathy', 'princess',
    'espeak', 'compact',
  ];
  static const List<String> _quality = <String>[
    'premium', 'enhanced', 'neural', 'natural', 'online', 'siri',
  ];

  static int _score(String name, String locale, List<String> want,
      List<String> avoid) {
    final String n = name.toLowerCase();
    for (final String x in _novelty) {
      if (n.contains(x)) return -1;
    }
    for (final String x in avoid) {
      if (RegExp('\\b$x\\b').hasMatch(n)) return -1;
    }
    int s = 0;
    for (final String x in want) {
      if (n.contains(x)) {
        s += 10;
        break;
      }
    }
    for (final String x in _quality) {
      if (n.contains(x)) s += 4;
    }
    if (locale.toLowerCase().startsWith('en-us') ||
        locale.toLowerCase().startsWith('en_us')) {
      s += 1;
    }
    return s;
  }

  /// [voices] are the device's voices as flutter_tts reports them: maps with
  /// at least `name` and `locale`. Only English voices are considered.
  static VoiceChoice choose(List<Map<dynamic, dynamic>> voices,
      VoiceProfile profile) {
    final double pitch = switch (profile) {
      VoiceProfile.hadi => 0.82,
      VoiceProfile.wasia => 1.08,
      VoiceProfile.neutral => 1.0,
    };
    final double rate = switch (profile) {
      VoiceProfile.hadi => 0.46,
      VoiceProfile.wasia => 0.42,
      VoiceProfile.neutral => 0.48,
    };
    if (profile == VoiceProfile.neutral) {
      return VoiceChoice(pitch: pitch, rate: rate);
    }
    final List<String> want =
        profile == VoiceProfile.hadi ? _male : _female;
    final List<String> avoid =
        profile == VoiceProfile.hadi ? _female : _male;
    Map<dynamic, dynamic>? best;
    int bestScore = 9; // a voice must match a gendered name (10+) to win
    for (final Map<dynamic, dynamic> v in voices) {
      final String name = (v['name'] ?? '').toString();
      final String locale = (v['locale'] ?? '').toString();
      if (!locale.toLowerCase().startsWith('en')) continue;
      final int s = _score(name, locale, want, avoid);
      if (s > bestScore) {
        bestScore = s;
        best = v;
      }
    }
    if (best == null) {
      return VoiceChoice(pitch: pitch, rate: rate);
    }
    // A real matching voice needs little pitch bending.
    return VoiceChoice(
      name: best['name'].toString(),
      locale: best['locale'].toString(),
      pitch: profile == VoiceProfile.hadi ? 0.92 : 1.02,
      rate: rate,
    );
  }
}
