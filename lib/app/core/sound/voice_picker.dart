/// Picks an on-device text-to-speech voice for each guide: a man's voice for
/// Hādi, a gentle woman's voice for Wasia. Pure Dart, so it is unit-tested.
///
/// The device decides which voices exist; this only chooses well among them
/// and, when no matching voice exists, falls back to pitch and rate so the two
/// still sound different. Phones rarely state a gender field, so gender is read
/// from the name: an explicit "male" or "female", the Google voice codes that
/// Android uses (en-us-x-iom-local), or a first name.
library;

enum VoiceProfile { neutral, hadi, wasia }

enum VoiceGender { male, female, unknown }

class VoiceChoice {
  const VoiceChoice({this.name, this.locale, required this.pitch, required this.rate});

  /// Null when no suitable voice was found: the device default is used.
  final String? name;
  final String? locale;
  final double pitch;
  final double rate;
}

/// One voice the person can pick, with a label a person can read.
class VoiceOption {
  const VoiceOption({
    required this.name,
    required this.locale,
    required this.gender,
    required this.label,
    required this.arabic,
    required this.natural,
  });

  final String name;
  final String locale;
  final VoiceGender gender;
  final String label;
  final bool arabic;

  /// The name says it is a higher-quality (neural, enhanced, premium) voice.
  final bool natural;
}

abstract final class VoicePicker {
  static const List<String> _male = <String>[
    'daniel', 'alex', 'aaron', 'arthur', 'oliver', 'tom', 'rishi', 'lee',
    'guy', 'ryan', 'davis', 'christopher', 'eric', 'roger', 'brian',
    'andrew', 'steffan', 'mark', 'james', 'david', 'george', 'liam',
    'thomas', 'neerja', 'ravi', 'hamed', 'naayf', 'maged', 'tarik',
  ];
  static const List<String> _female = <String>[
    'samantha', 'karen', 'moira', 'tessa', 'serena', 'kate', 'ava',
    'allison', 'susan', 'aria', 'jenny', 'sonia', 'libby', 'zira', 'emma',
    'victoria', 'fiona', 'joanna', 'salli', 'hazel', 'catherine', 'laila',
    'zariyah', 'amelie', 'michelle', 'nicole', 'ivy',
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

  // Google's Android voices carry a three-letter code after "-x-". These are
  // the English ones whose gender is known.
  static const Set<String> _codeMale = <String>{
    'iol', 'iom', 'tpd', // en-US
    'rjs', 'gbb', 'gbd', // en-GB
    'aub', 'aud', // en-AU
  };
  static const Set<String> _codeFemale = <String>{
    'sfg', 'iob', 'iog', 'tpc', 'tpf', // en-US
    'gba', 'gbc', 'gbg', // en-GB
    'aua', 'auc', // en-AU
  };

  /// The voice's gender as far as its name says; unknown when it does not.
  static VoiceGender genderOf(String name) {
    final String n = name.toLowerCase();
    if (n.contains('female')) return VoiceGender.female;
    if (RegExp(r'(^|[^a-z])male([^a-z]|$)').hasMatch(n)) return VoiceGender.male;
    final RegExpMatch? m = RegExp(r'^(en-(?:us|gb|au))-x-([a-z]{3})').firstMatch(n);
    if (m != null) {
      final String code = m.group(2)!;
      if (_codeMale.contains(code)) return VoiceGender.male;
      if (_codeFemale.contains(code)) return VoiceGender.female;
    }
    if (n == 'google us english') return VoiceGender.female;
    for (final String x in _male) {
      if (RegExp('\\b$x\\b').hasMatch(n)) return VoiceGender.male;
    }
    for (final String x in _female) {
      if (RegExp('\\b$x\\b').hasMatch(n)) return VoiceGender.female;
    }
    return VoiceGender.unknown;
  }

  static bool _isNovelty(String n) {
    for (final String x in _novelty) {
      if (n.contains(x)) return true;
    }
    return false;
  }

  static bool _isNatural(String n) {
    for (final String x in _quality) {
      if (n.contains(x)) return true;
    }
    return false;
  }

  static String _norm(String locale) => locale.replaceAll('_', '-');

  static bool _isEnglish(String locale) => locale.toLowerCase().startsWith('en');

  static bool _isArabic(String locale) => locale.toLowerCase().startsWith('ar');

  static int _score(String name, String locale, VoiceGender want) {
    final String n = name.toLowerCase();
    if (_isNovelty(n)) return -1;
    final VoiceGender g = genderOf(name);
    if (g != VoiceGender.unknown && g != want) return -1;
    int s = 0;
    if (g == want) s += 10;
    if (_isNatural(n)) s += 4;
    final String l = _norm(locale).toLowerCase();
    if (l.startsWith('en-us')) s += 1;
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
    final double rate = baseRate(profile);
    if (profile == VoiceProfile.neutral) {
      return VoiceChoice(pitch: pitch, rate: rate);
    }
    final VoiceGender want =
        profile == VoiceProfile.hadi ? VoiceGender.male : VoiceGender.female;
    Map<dynamic, dynamic>? best;
    int bestScore = 9; // a voice must match the gender (10+) to win
    for (final Map<dynamic, dynamic> v in voices) {
      final String name = (v['name'] ?? '').toString();
      final String locale = (v['locale'] ?? '').toString();
      if (!_isEnglish(locale)) continue;
      final int s = _score(name, locale, want);
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

  /// The speaking pace each guide starts from (before the person's speed).
  static double baseRate(VoiceProfile profile) => switch (profile) {
        VoiceProfile.hadi => 0.46,
        VoiceProfile.wasia => 0.42,
        VoiceProfile.neutral => 0.48,
      };

  /// An Arabic voice, preferring the guide's gender. A name of null means the
  /// device has no Arabic voice installed.
  static VoiceChoice chooseArabic(List<Map<dynamic, dynamic>> voices,
      VoiceProfile profile) {
    final VoiceGender want = switch (profile) {
      VoiceProfile.hadi => VoiceGender.male,
      VoiceProfile.wasia => VoiceGender.female,
      VoiceProfile.neutral => VoiceGender.unknown,
    };
    Map<dynamic, dynamic>? best;
    int bestScore = -1;
    for (final Map<dynamic, dynamic> v in voices) {
      final String name = (v['name'] ?? '').toString();
      final String locale = (v['locale'] ?? '').toString();
      if (!_isArabic(locale) || _isNovelty(name.toLowerCase())) continue;
      int s = 1;
      final VoiceGender g = genderOf(name);
      if (want != VoiceGender.unknown) {
        if (g == want) s += 10;
        if (g != VoiceGender.unknown && g != want) s -= 1;
      }
      if (_isNatural(name.toLowerCase())) s += 4;
      if (s > bestScore) {
        bestScore = s;
        best = v;
      }
    }
    if (best == null) {
      return VoiceChoice(pitch: 1.0, rate: baseRate(profile));
    }
    return VoiceChoice(
      name: best['name'].toString(),
      locale: best['locale'].toString(),
      pitch: 1.0,
      rate: baseRate(profile),
    );
  }

  static const Map<String, String> _langNames = <String, String>{
    'en-us': 'English (US)',
    'en-gb': 'English (UK)',
    'en-au': 'English (Australia)',
    'en-in': 'English (India)',
    'en-ca': 'English (Canada)',
    'en-za': 'English (South Africa)',
    'en-ie': 'English (Ireland)',
    'en-ng': 'English (Nigeria)',
    'en-ph': 'English (Philippines)',
    'en-sg': 'English (Singapore)',
    'ar': 'Arabic',
    'ar-sa': 'Arabic (Saudi Arabia)',
    'ar-ae': 'Arabic (UAE)',
    'ar-eg': 'Arabic (Egypt)',
    'ar-xa': 'Arabic',
  };

  static String _langName(String locale) {
    final String l = _norm(locale).toLowerCase();
    return _langNames[l] ?? _langNames[l.split('-').first] ?? locale;
  }

  /// Every English and Arabic voice on the device, labelled so a person can
  /// tell them apart: "English (US) · man · Voice 2". Novelty voices are left
  /// out. Order: English before Arabic, men before women, then by name.
  static List<VoiceOption> options(List<Map<dynamic, dynamic>> voices) {
    final List<VoiceOption> out = <VoiceOption>[];
    final Map<String, int> counter = <String, int>{};
    final List<Map<dynamic, dynamic>> usable = voices.where((v) {
      final String name = (v['name'] ?? '').toString();
      final String locale = (v['locale'] ?? '').toString();
      return name.isNotEmpty &&
          (_isEnglish(locale) || _isArabic(locale)) &&
          !_isNovelty(name.toLowerCase());
    }).toList()
      ..sort((a, b) {
        final String an = (a['name'] ?? '').toString();
        final String bn = (b['name'] ?? '').toString();
        final String al = (a['locale'] ?? '').toString();
        final String bl = (b['locale'] ?? '').toString();
        final int ar = _isArabic(al) ? 1 : 0;
        final int br = _isArabic(bl) ? 1 : 0;
        if (ar != br) return ar - br;
        final int ag = genderOf(an).index;
        final int bg = genderOf(bn).index;
        if (ag != bg) return ag - bg;
        final int c = _norm(al).compareTo(_norm(bl));
        return c != 0 ? c : an.compareTo(bn);
      });
    for (final Map<dynamic, dynamic> v in usable) {
      final String name = v['name'].toString();
      final String locale = (v['locale'] ?? '').toString();
      final VoiceGender g = genderOf(name);
      final String who = switch (g) {
        VoiceGender.male => 'man',
        VoiceGender.female => 'woman',
        VoiceGender.unknown => 'voice',
      };
      final String key = '${_norm(locale)}|$who';
      final int n = (counter[key] ?? 0) + 1;
      counter[key] = n;
      // iPhone and Mac voices have real names; Android ones are codes.
      final bool coded = name.contains('-x-') || name.contains('#');
      final String tail = coded ? 'Voice $n' : name;
      final bool natural = _isNatural(name.toLowerCase());
      out.add(VoiceOption(
        name: name,
        locale: locale,
        gender: g,
        arabic: _isArabic(locale),
        natural: natural,
        label: '${_langName(locale)} · $who · $tail'
            '${natural ? ' · natural' : ''}',
      ));
    }
    return out;
  }
}
