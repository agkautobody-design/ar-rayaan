/// Crisis detection — the one shared safety net for every place a person can
/// type their pain into the app (Hādi today; anything else later).
///
/// It runs BEFORE any answer provider — the offline shelf and every live AI
/// alike — and when it fires the provider is never called at all: the person
/// gets a fixed, compassionate reply with real help lines for their country,
/// and what they wrote stays on the device.
///
/// Design rules (locked):
/// - Whole-word / whole-phrase matching on normalised text. Never substring:
///   "breakfast" contains "fast", "business" contains "sin" — those must not
///   fire anything.
/// - When in doubt about a self-harm phrase, fire. A gentle card shown
///   needlessly costs a second; a missed crisis costs far more.
/// - Idioms and religious phrasing that are clearly not about self-harm
///   ("I want to die upon Islam", "Suicide Squad", "it hit me that…") are
///   excluded explicitly, and each exclusion is pinned by a test.
/// - No number is ever invented. Lines come only from [HelpResources].
library;

import 'sakina_content.dart';

/// What kind of moment the message is.
enum CrisisKind {
  /// The person may be thinking of ending their life or hurting themselves
  /// (or is writing about someone who is).
  selfHarm,

  /// A question about suicide itself ("is suicide haram?", "will he be
  /// forgiven?") with no sign the person is describing their own plan. The
  /// answer is compassion first, honesty second, help lines always.
  suicideQuestion,

  /// Someone is hurting, threatening or forcing the person (domestic
  /// violence, child abuse, sexual assault).
  abuse,
}

/// One phrase to look for, with optional guards against known false alarms.
class _Pat {
  const _Pat(
    this.phrase, {
    this.notAfter = const <String>[],
    this.notFollowedBy = const <String>[],
    this.needsPrevious = false,
    this.mustEnd = false,
  });

  /// Normalised, space-separated words.
  final String phrase;

  /// The word just before the phrase must not be one of these.
  final List<String> notAfter;

  /// The words just after the phrase must not start with any of these
  /// phrases.
  final List<String> notFollowedBy;

  /// The phrase must have at least one word before it (stops "beats me!"
  /// as a lone idiom from reading as an accusation).
  final bool needsPrevious;

  /// The phrase must be the last words of the message ("I can't go on."
  /// fires; "I can't go on Friday" does not).
  final bool mustEnd;
}

abstract final class CrisisDetector {
  /// Lowercases, drops apostrophes ("don't" -> "dont"), turns every other
  /// punctuation mark into a space, folds a few Arabic/Persian letter forms
  /// and diacritics, and squeezes letters repeated three or more times
  /// ("diiiie" -> "die"). Words are joined by single spaces.
  static String normalize(String input) {
    final StringBuffer out = StringBuffer();
    bool lastWasSpace = true;
    for (final int original in input.toLowerCase().runes) {
      int c = original;
      // Apostrophes and quote-like marks inside words vanish.
      if (c == 0x27 || c == 0x2018 || c == 0x2019 || c == 0x60 || c == 0xB4) {
        continue;
      }
      // Arabic harakat, tatweel and dagger alef vanish.
      if ((c >= 0x064B && c <= 0x065F) || c == 0x0640 || c == 0x0670) {
        continue;
      }
      // Fold letter variants so typing style does not matter.
      if (c == 0x0623 || c == 0x0625 || c == 0x0622) c = 0x0627; // alef forms
      if (c == 0x0649 || c == 0x06CC) c = 0x064A; // alef maqsura / farsi yeh
      if (c == 0x06A9) c = 0x0643; // keheh -> kaf
      if (c == 0x06C1 || c == 0x06BE) c = 0x0647; // urdu heh -> heh
      final bool ascii = (c >= 0x61 && c <= 0x7A) || (c >= 0x30 && c <= 0x39);
      final bool separatorSymbol = (c >= 0x80 && c <= 0xBF) ||
          (c >= 0x2000 && c <= 0x206F) ||
          (c >= 0x3000 && c <= 0x303F) ||
          (c >= 0xFF00 && c <= 0xFF0F) ||
          c == 0x060C ||
          c == 0x061B ||
          c == 0x061F ||
          c == 0x06D4 ||
          c == 0xD7;
      final bool keep = ascii || (c > 0x7F && !separatorSymbol);
      if (keep) {
        out.writeCharCode(c);
        lastWasSpace = false;
      } else {
        if (!lastWasSpace) {
          out.write(' ');
          lastWasSpace = true;
        }
      }
    }
    return _squeeze(out.toString().trim());
  }

  /// Collapses any letter repeated three or more times to one
  /// ("diiiie" -> "die", "pleeease" -> "pleease" stays harmless).
  static String _squeeze(String s) {
    final List<int> runes = s.runes.toList();
    final StringBuffer b = StringBuffer();
    int i = 0;
    while (i < runes.length) {
      int j = i;
      while (j < runes.length && runes[j] == runes[i]) {
        j++;
      }
      final int count = j - i;
      final int copies = count >= 3 ? 1 : count;
      for (int k = 0; k < copies; k++) {
        b.writeCharCode(runes[i]);
      }
      i = j;
    }
    return b.toString();
  }

  // ── Self-harm: explicit phrases ──────────────────────────────────────

  static const List<String> _religiousDeathContinuations = <String>[
    'as a martyr',
    'as a shaheed',
    'as shaheed',
    'as a muslim',
    'as a good muslim',
    'as a believer',
    'as muslim',
    'upon',
    'with iman',
    'with la ilaha',
    'on iman',
    'on islam',
    'on the deen',
    'on the straight path',
    'in madinah',
    'in medina',
    'in makkah',
    'in mecca',
    'in the path',
    'for the sake',
    'for allah',
    'laughing',
  ];

  /// "tired of living in a flat" is about a place, not about life.
  static const List<String> _placeContinuations = <String>[
    'in',
    'on',
    'at',
    'with',
    'under',
    'near',
    'far',
    'abroad',
    'here',
    'there',
  ];

  static final List<_Pat> _selfHarm = <_Pat>[
    // Wanting to be dead
    const _Pat('want to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wants to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wanted to die', notFollowedBy: _religiousDeathContinuations),
    const _Pat('wanna die'),
    const _Pat('want to be dead'),
    const _Pat('wish i was dead'),
    const _Pat('wish i were dead'),
    const _Pat('wish i could die'),
    const _Pat('wish i would die'),
    const _Pat('wish i was never born'),
    const _Pat('wish i were never born'),
    const _Pat('wish i had never been born'),
    const _Pat('wish i never existed'),
    const _Pat('wish i didnt exist'),
    const _Pat('wish i could disappear'),
    const _Pat('wish i could just disappear'),
    const _Pat('wish i would not wake up'),
    const _Pat('wish i wouldnt wake up'),
    const _Pat('dont want to wake up'),
    const _Pat('dont want to be alive'),
    const _Pat('dont want to be here anymore'),
    const _Pat('dont want to live'),
    const _Pat('dont wanna live'),
    const _Pat('dont want to exist'),
    const _Pat('do not want to live'),
    const _Pat('do not want to be alive'),
    const _Pat('do not want to exist'),
    const _Pat('no longer want to live'),
    const _Pat('no longer want to be alive'),
    const _Pat('better off dead'),
    const _Pat('better off without me'),
    const _Pat('better off if i was gone'),
    const _Pat('better off if i were gone'),
    const _Pat('better off if i were dead'),
    const _Pat('better off if i died'),
    const _Pat('rather be dead'),
    const _Pat('rather die'),
    // Life not worth living
    const _Pat('not worth living'),
    const _Pat('isnt worth living'),
    const _Pat('wasnt worth living'),
    const _Pat('nobody would miss me'),
    const _Pat('no one would miss me'),
    const _Pat('nobody would care if i died'),
    const _Pat('no one would care if i died'),
    const _Pat('if i were dead'),
    const _Pat('if i was dead'),
    const _Pat('no reason to live'),
    const _Pat('no reason to go on'),
    const _Pat('no reason to be alive'),
    const _Pat('nothing to live for'),
    const _Pat('no point in living'),
    const _Pat('no point living'),
    const _Pat('no point in life'),
    const _Pat('no point in going on'),
    const _Pat('whats the point of living'),
    const _Pat('whats the point of life'),
    const _Pat('what is the point of living'),
    const _Pat('tired of living', notFollowedBy: _placeContinuations),
    const _Pat('tired of life'),
    const _Pat('tired of being alive'),
    const _Pat('sick of living', notFollowedBy: _placeContinuations),
    const _Pat('sick of life'),
    const _Pat('sick of being alive'),
    const _Pat('done with life'),
    const _Pat('done with living', notFollowedBy: _placeContinuations),
    const _Pat('give up on life'),
    const _Pat('giving up on life'),
    const _Pat('cant go on', mustEnd: true),
    const _Pat('cant go on living'),
    const _Pat('cant go on like this'),
    const _Pat('cant go on anymore'),
    const _Pat('cant go on any longer'),
    const _Pat('cant go on any more'),
    const _Pat('cant go on much longer'),
    const _Pat('cant live like this'),
    const _Pat('no will to live'),
    // Ending it
    const _Pat('end it all'),
    const _Pat('ending it all'),
    const _Pat('end my life'),
    const _Pat('end my own life'),
    const _Pat('ending my life'),
    const _Pat('end his life'),
    const _Pat('end her life'),
    const _Pat('end their lives'),
    const _Pat('take my life'),
    const _Pat('take my own life'),
    const _Pat('taking my own life'),
    const _Pat('take his own life'),
    const _Pat('take her own life'),
    const _Pat('take their own lives'),
    const _Pat('taking his own life'),
    const _Pat('taking her own life'),
    // Killing / hurting oneself
    const _Pat('kill myself'),
    const _Pat('killing myself'),
    const _Pat('killed myself'),
    const _Pat('kill my self'),
    const _Pat('kill himself'),
    const _Pat('kill herself'),
    const _Pat('kill themselves'),
    const _Pat('killing himself'),
    const _Pat('killing herself'),
    const _Pat('hurt myself'),
    const _Pat('hurting myself'),
    const _Pat('hurt my self'),
    const _Pat('harm myself'),
    const _Pat('harming myself'),
    const _Pat('harm my self'),
    const _Pat('hurt himself'),
    const _Pat('hurt herself'),
    const _Pat('harm himself'),
    const _Pat('harm herself'),
    const _Pat('hurting himself'),
    const _Pat('hurting herself'),
    const _Pat('self harm'),
    const _Pat('selfharm'),
    const _Pat('self harming'),
    const _Pat('self harmed'),
    const _Pat('cut myself'),
    const _Pat('cutting myself'),
    const _Pat('cut himself'),
    const _Pat('cut herself'),
    const _Pat('cut my wrists'),
    const _Pat('cut my wrist'),
    const _Pat('slit my wrists'),
    const _Pat('slit my wrist'),
    const _Pat('slit my throat'),
    const _Pat('hang myself'),
    const _Pat('hanging myself'),
    const _Pat('shoot myself'),
    const _Pat('poison myself'),
    const _Pat('drown myself'),
    const _Pat('throw myself off'),
    const _Pat('throw myself in front'),
    const _Pat('jump off a bridge'),
    const _Pat('jump off a building'),
    const _Pat('jump off a roof'),
    const _Pat('jump from a building'),
    const _Pat('jump in front of a train'),
    const _Pat('overdose on'),
    const _Pat('overdose myself'),
    const _Pat('overdosed'),
    const _Pat('overdosing'),
    const _Pat('take an overdose'),
    const _Pat('took an overdose'),
    const _Pat('take too many pills'),
    const _Pat('took too many pills'),
    const _Pat('swallow all my pills'),
    const _Pat('swallow all the pills'),
    const _Pat('take all my pills'),
    const _Pat('take all the pills'),
    // Suicidal, suicide attempts
    const _Pat('suicidal'),
    const _Pat('attempt suicide'),
    const _Pat('attempted suicide'),
    const _Pat('attempting suicide'),
    const _Pat('suicide attempt'),
    const _Pat('suicide note'),
    const _Pat('sucide'),
    const _Pat('suicde'),
    const _Pat('suiside'),
    // Arabic
    const _Pat('اريد ان اموت'),
    const _Pat('ابغي اموت'),
    const _Pat('ابي اموت'),
    const _Pat('اريد الموت'),
    const _Pat('اتمني الموت'),
    const _Pat('اتمني ان اموت'),
    const _Pat('اقتل نفسي'),
    const _Pat('سانتحر'),
    const _Pat('اريد الانتحار'),
    const _Pat('افكر في الانتحار'),
    const _Pat('انهي حياتي'),
    const _Pat('اريد ان انهي حياتي'),
    const _Pat('تعبت من الحياه'),
    const _Pat('لا اريد ان اعيش'),
    const _Pat('لا اريد العيش'),
    // Urdu (script and Roman)
    const _Pat('مرنا چاهتا هوں'),
    const _Pat('مرنا چاهتي هوں'),
    const _Pat('مرنا چاهتا هون'),
    const _Pat('مرنا چاهتي هون'),
    const _Pat('marna chahta hoon'),
    const _Pat('marna chahti hoon'),
    const _Pat('marna chahta hun'),
    const _Pat('marna chahti hun'),
    const _Pat('jaan de dunga'),
    const _Pat('jaan de dungi'),
    const _Pat('zindagi khatam karna'),
    // Malay / Indonesian
    const _Pat('mau mati'),
    const _Pat('nak mati'),
    const _Pat('mahu mati'),
    const _Pat('ingin mati'),
    const _Pat('pengen mati'),
    // Turkish, Spanish
    const _Pat('ölmek istiyorum'),
    const _Pat('quiero morir'),
    const _Pat('quiero morirme'),
  ];

  /// Words that, alone, mean the subject of suicide has come up. Whether
  /// that is a person in danger or a person asking a religious question is
  /// decided afterwards.
  static final List<_Pat> _suicideConcept = <_Pat>[
    const _Pat(
      'suicide',
      notFollowedBy: <String>[
        'squad',
        'bomber',
        'bombers',
        'bombing',
        'bombings',
        'attack',
        'attacks',
        'mission',
        'missions',
        'vest',
        'vests',
        'terrorist',
        'terrorists',
        'door',
        'doors',
        'jockey',
      ],
    ),
    const _Pat('suicides'),
    const _Pat('commit suicide'),
    const _Pat('committed suicide'),
    const _Pat('committing suicide'),
    const _Pat('commits suicide'),
    const _Pat('kill yourself'),
    const _Pat('killing yourself'),
    const _Pat('harm yourself'),
    const _Pat('take your own life'),
    const _Pat('end your life'),
    const _Pat('انتحار'),
    const _Pat('الانتحار'),
    const _Pat('انتحر'),
    const _Pat('خودکشی'),
    const _Pat('خود کشی'),
    const _Pat('khudkushi'),
    const _Pat('khud kushi'),
    const _Pat('bunuh diri'),
    const _Pat('intihar'),
    const _Pat('आत्महत्या'),
    const _Pat('suicidio'),
    const _Pat('suicidarme'),
  ];

  /// Words that make a suicide mention a question about the topic rather
  /// than a disclosure.
  static const List<String> _questionMarkers = <String>[
    'haram',
    'halal',
    'sin',
    'sinful',
    'allowed',
    'permissible',
    'forgive',
    'forgiven',
    'forgives',
    'hell',
    'jannah',
    'paradise',
    'punishment',
    'punished',
    'kafir',
    'janazah',
    'janaza',
    'funeral',
    'buried',
    'ruling',
    'islam',
    'islamic',
    'quran',
    'hadith',
    'scholars',
    'does allah',
    'will allah',
    'what happens',
    'is it',
    'can i pray',
    'pray for',
    'حرام',
    'حلال',
    'هل',
    'ما حكم',
    'جائز',
  ];

  /// Words that say the person is speaking about themselves, even inside a
  /// question. These override the "just a question" reading.
  static const List<String> _personalMarkers = <String>[
    'i want',
    'i wanna',
    'i am thinking',
    'im thinking',
    'i have been thinking',
    'ive been thinking',
    'i keep thinking',
    'i think about',
    'thinking about suicide',
    'thinking of suicide',
    'thoughts of suicide',
    'suicidal thoughts',
    'i feel like',
    'i might',
    'i am going to',
    'im going to',
    'i will',
    'i plan',
    'i planned',
    'i tried',
    'i have tried',
    'ive tried',
    'i cant',
    'i am so',
    'im so',
  ];

  // ── Abuse ────────────────────────────────────────────────────────────

  static const List<String> _idiomPrevious = <String>[
    'it',
    'that',
    'this',
    'which',
    'what',
    'reality',
    'thought',
    'idea',
    'realization',
    'then',
    'suddenly',
  ];

  static final List<_Pat> _abuse = <_Pat>[
    const _Pat('beats me', needsPrevious: true, notAfter: _idiomPrevious),
    const _Pat('beating me'),
    const _Pat('beat me'),
    const _Pat('beaten me'),
    const _Pat('beaten by my'),
    const _Pat('beaten by him'),
    const _Pat('beaten by her'),
    const _Pat('beaten up by my'),
    const _Pat('hit by my husband'),
    const _Pat('hit by my father'),
    const _Pat('hit by my dad'),
    const _Pat('hit by my mother'),
    const _Pat('hit by my brother'),
    const _Pat('beats me up'),
    const _Pat('beat me up'),
    const _Pat('hits me', notAfter: _idiomPrevious, notFollowedBy: <String>['up']),
    const _Pat('hitting me'),
    const _Pat('hit me', notAfter: _idiomPrevious, notFollowedBy: <String>['up', 'with the']),
    const _Pat('slaps me'),
    const _Pat('slapped me'),
    const _Pat('slapping me'),
    const _Pat('punches me'),
    const _Pat('punched me'),
    const _Pat('kicks me'),
    const _Pat('kicked me'),
    const _Pat('chokes me'),
    const _Pat('choked me'),
    const _Pat('strangled me'),
    const _Pat('strangles me'),
    const _Pat('husband beats', notFollowedBy: <String>['his wife']),
    const _Pat('husband hits', notFollowedBy: <String>['his wife']),
    const _Pat('husband beat', notFollowedBy: <String>['his wife']),
    const _Pat('husband hit', notFollowedBy: <String>['his wife']),
    const _Pat('wife beats', notFollowedBy: <String>['her husband']),
    const _Pat('father beats'),
    const _Pat('father hits'),
    const _Pat('dad beats'),
    const _Pat('dad hits'),
    const _Pat('mother beats'),
    const _Pat('mother hits'),
    const _Pat('mom beats'),
    const _Pat('mom hits'),
    const _Pat('mum beats'),
    const _Pat('mum hits'),
    const _Pat('brother beats'),
    const _Pat('brother hits'),
    const _Pat('parents beat'),
    const _Pat('parents hit'),
    const _Pat('abuses me'),
    const _Pat('abused me'),
    const _Pat('abusing me'),
    const _Pat('being abused'),
    const _Pat('i am abused'),
    const _Pat('i was abused'),
    const _Pat('abused as a child'),
    const _Pat('abusive husband'),
    const _Pat('abusive wife'),
    const _Pat('abusive father'),
    const _Pat('abusive mother'),
    const _Pat('abusive parents'),
    const _Pat('abusive marriage'),
    const _Pat('abusive relationship'),
    const _Pat('abusive home'),
    const _Pat('abusive boyfriend'),
    const _Pat('abusive family'),
    const _Pat('child abuse'),
    const _Pat('domestic violence'),
    const _Pat('domestic abuse'),
    const _Pat('family violence'),
    const _Pat('physically abused'),
    const _Pat('emotionally abused'),
    const _Pat('emotional abuse'),
    const _Pat('sexually abused'),
    const _Pat('sexual abuse'),
    const _Pat('sexually assaulted'),
    const _Pat('sexual assault'),
    const _Pat('raped'),
    const _Pat('raped me'),
    const _Pat('rapes me'),
    const _Pat('molested'),
    const _Pat('touched me inappropriately'),
    const _Pat('touches me inappropriately'),
    const _Pat('forced me to have sex'),
    const _Pat('forces me to have sex'),
    const _Pat('forced himself on me'),
    const _Pat('forces himself on me'),
    const _Pat('forced me to sleep with'),
    const _Pat('forces me to sleep with'),
    const _Pat('afraid of my husband'),
    const _Pat('scared of my husband'),
    const _Pat('afraid of my father'),
    const _Pat('scared of my father'),
    const _Pat('afraid of my dad'),
    const _Pat('scared of my dad'),
    const _Pat('afraid of my brother'),
    const _Pat('scared of my brother'),
    const _Pat('afraid of my mother'),
    const _Pat('scared of my mother'),
    const _Pat('afraid to go home'),
    const _Pat('scared to go home'),
    const _Pat('afraid for my life'),
    const _Pat('scared for my life'),
    const _Pat('fear for my life'),
    const _Pat('fear for my safety'),
    const _Pat('not safe at home'),
    const _Pat('unsafe at home'),
    const _Pat('dont feel safe at home'),
    const _Pat('dont feel safe with him'),
    const _Pat('threatened to kill me'),
    const _Pat('threatens to kill me'),
    const _Pat('threatening to kill me'),
    const _Pat('tried to kill me'),
    const _Pat('trying to kill me'),
    const _Pat('wants to kill me'),
    const _Pat('locked me in'),
    const _Pat('locks me in'),
    const _Pat('زوجي يضربني'),
    const _Pat('يضربني'),
    const _Pat('ابي يضربني'),
    const _Pat('العنف الاسري'),
  ];

  static final List<_Pat> _selfHarmNormalized = _normalizeAll(_selfHarm);
  static final List<_Pat> _conceptNormalized = _normalizeAll(_suicideConcept);
  static final List<_Pat> _abuseNormalized = _normalizeAll(_abuse);
  static final List<String> _questionNormalized = <String>[
    for (final String m in _questionMarkers) normalize(m),
  ];
  static final List<String> _personalNormalized = <String>[
    for (final String m in _personalMarkers) normalize(m),
  ];

  static List<_Pat> _normalizeAll(List<_Pat> pats) => <_Pat>[
        for (final _Pat p in pats)
          _Pat(
            normalize(p.phrase),
            notAfter: <String>[for (final String w in p.notAfter) normalize(w)],
            notFollowedBy: <String>[
              for (final String w in p.notFollowedBy) normalize(w),
            ],
            needsPrevious: p.needsPrevious,
            mustEnd: p.mustEnd,
          ),
      ];

  static bool _matches(List<String> tokens, _Pat p) {
    final List<String> pt = p.phrase.split(' ');
    if (pt.isEmpty || p.phrase.isEmpty) return false;
    for (int i = 0; i + pt.length <= tokens.length; i++) {
      bool same = true;
      for (int j = 0; j < pt.length; j++) {
        if (tokens[i + j] != pt[j]) {
          same = false;
          break;
        }
      }
      if (!same) continue;
      if (p.needsPrevious && i == 0) continue;
      if (p.mustEnd && i + pt.length != tokens.length) continue;
      if (i > 0 && p.notAfter.contains(tokens[i - 1])) continue;
      if (p.notFollowedBy.isNotEmpty) {
        final String rest = '${tokens.sublist(i + pt.length).join(' ')} ';
        bool excluded = false;
        for (final String f in p.notFollowedBy) {
          if (rest.startsWith('$f ')) {
            excluded = true;
            break;
          }
        }
        if (excluded) continue;
      }
      return true;
    }
    return false;
  }

  static bool _anyMatch(List<String> tokens, List<_Pat> pats) {
    for (final _Pat p in pats) {
      if (_matches(tokens, p)) return true;
    }
    return false;
  }

  static bool _containsPhrase(String padded, String phrase) =>
      padded.contains(' $phrase ');

  /// Returns the kind of crisis in [text], or null when there is none.
  static CrisisKind? detect(String text) {
    final String norm = normalize(text);
    if (norm.isEmpty) return null;
    final List<String> tokens = norm.split(' ');
    final String padded = ' $norm ';

    if (_anyMatch(tokens, _selfHarmNormalized)) return CrisisKind.selfHarm;

    if (_anyMatch(tokens, _conceptNormalized)) {
      bool personal = false;
      for (final String m in _personalNormalized) {
        if (_containsPhrase(padded, m)) {
          personal = true;
          break;
        }
      }
      if (personal) return CrisisKind.selfHarm;
      bool question = false;
      for (final String m in _questionNormalized) {
        if (_containsPhrase(padded, m)) {
          question = true;
          break;
        }
      }
      return question ? CrisisKind.suicideQuestion : CrisisKind.selfHarm;
    }

    if (_anyMatch(tokens, _abuseNormalized)) return CrisisKind.abuse;
    return null;
  }
}

/// The fixed replies. Compassion first; real help second; never a lecture;
/// never a pointer to a feature that does not exist.
abstract final class CrisisResponses {
  static const String _quran3953 =
      'Allah says: “Say, O My servants who have transgressed against '
      'themselves [by sinning], do not despair of the mercy of Allah. '
      'Indeed, Allah forgives all sins. Indeed, it is He who is the '
      'Forgiving, the Merciful.” (Qur’an 39:53)';

  /// Which help rows serve each kind of moment.
  static Set<HelpKind> kindsFor(CrisisKind kind) {
    switch (kind) {
      case CrisisKind.selfHarm:
      case CrisisKind.suicideQuestion:
        return const <HelpKind>{
          HelpKind.suicide,
          HelpKind.emergency,
          HelpKind.muslim,
        };
      case CrisisKind.abuse:
        return const <HelpKind>{HelpKind.abuse, HelpKind.emergency};
    }
  }

  /// The tappable rows for [kind] in [countryCode] (null = unknown).
  static List<HelpResource> resourcesFor(
    CrisisKind kind,
    String? countryCode,
  ) {
    return HelpResources.forCountry(countryCode, kinds: kindsFor(kind));
  }

  static String _lines(List<HelpResource> rows, {int max = 5}) {
    final StringBuffer b = StringBuffer();
    int n = 0;
    for (final HelpResource r in rows) {
      if (n >= max) break;
      if (r.dial == null && r.url == null) continue;
      b.writeln('• ${r.name} (${r.region}): ${r.contact}');
      n++;
    }
    return b.toString().trimRight();
  }

  /// The full reply text for [kind]. Includes the help lines as plain text
  /// so that it still works when read aloud, copied, or shown without the
  /// tappable panel.
  static String textFor(CrisisKind kind, {String? countryCode}) {
    final String lines = _lines(resourcesFor(kind, countryCode));
    switch (kind) {
      case CrisisKind.selfHarm:
        return 'I am really glad you told me. What you are carrying sounds '
            'very heavy, and I will not answer it with a lecture.\n\n'
            'Please reach a real person right now. If you might act on '
            'these thoughts, or you have already hurt yourself, call your '
            'local emergency number now, move away from anything you could '
            'use to hurt yourself, and go to someone you trust.\n\n'
            '$lines\n\n'
            'If you are worried about someone else, stay with them, and '
            'call the emergency number if they are in danger.\n\n'
            '$_quran3953\n\n'
            'You are not a burden, and this pain does not get the last '
            'word. I am an app, not a person, so the people behind these '
            'lines matter more than anything I can say. I am still here.';
      case CrisisKind.suicideQuestion:
        return 'I hear the weight behind that question, and I will answer '
            'it honestly, but first: if you are asking because you are in '
            'pain yourself, or because you lost someone this way, you are '
            'not being judged here.\n\n'
            'Most scholars teach that life is a trust from Allah that we '
            'are not to end: “And do not kill yourselves [or one another]. '
            'Indeed, Allah is to you ever Merciful.” (Qur’an 4:29). But '
            'that is never the first thing a hurting person needs to hear, '
            'and it is not the whole of what Islam says about you. '
            'Judgement of any person belongs to Allah alone, and His mercy '
            'is vaster than our fear. For a ruling about someone you lost, '
            'please ask a qualified scholar in person.\n\n'
            '$_quran3953\n\n'
            'If any part of this is about you, please talk to a real '
            'person now:\n\n'
            '$lines\n\n'
            'If you might act on these thoughts, call your local emergency '
            'number now.';
      case CrisisKind.abuse:
        return 'I am sorry. What you describe is not okay, and it is not '
            'your fault. Nothing, not marriage, not family, not honour, '
            'makes it acceptable for someone to hurt, threaten or force '
            'you. Your safety comes first, and you do not have to decide '
            'anything tonight.\n\n'
            'If you are in danger right now, call your local emergency '
            'number. If you can leave safely, go to someone you trust. '
            'These lines are confidential:\n\n'
            '$lines\n\n'
            'If you are asking for someone else, the same lines can advise '
            'you. A trusted imam or scholar can help too, and a good one '
            'will put your safety first. If you want to talk it through '
            'here, I am listening.';
    }
  }

  /// A short reminder appended to a normal answer when a crisis card was
  /// already shown a moment ago (so a follow-up question is not blocked,
  /// but help stays in view).
  static String reminderFor(CrisisKind kind) {
    if (kind == CrisisKind.abuse) {
      return 'If you are in danger, please call your local emergency '
          'number. The confidential help lines above are still there for '
          'you.';
    }
    return 'If any part of this is about you, the help lines above are '
        'still there, and your local emergency number is always an '
        'option.';
  }
}
