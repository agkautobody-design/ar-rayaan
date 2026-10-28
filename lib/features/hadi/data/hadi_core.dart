/// Hādi's built-in answers: the questions a person actually asks first, each
/// with a real answer, its source printed in the reply, and (for scripture)
/// a card under it from the app's own library.
///
/// This is the first stop for a question (before the older keyword shelf),
/// because it is matched on the topic, not on a fixed phrase: "How do I pray
/// janazah?", "funeral prayer how to" and "salat al janazah steps" all find
/// the funeral prayer, and an ordinary-prayer outline can never be given for
/// it.
///
/// The answers live in `hadi_core_data.dart`, which is GENERATED from
/// `tool/hadi_core/` (every hadith number, grade and Qur'an quotation in it is
/// checked there against the text it cites). Edit the spec, not that file.
///
/// Pure Dart, no Flutter: tested without a widget tree.
library;

import '../../sakina/domain/crisis_detector.dart';
import '../application/hadi_provider.dart';
import 'hadi_core_data.dart';

/// One built-in answer.
class CoreEntry {
  const CoreEntry({
    required this.id,
    required this.patterns,
    required this.answer,
    this.avoid = const <String>[],
    this.topic = '',
    this.beforeGate = false,
    this.why = '',
    this.reviewNote = '',
  });

  /// Stable id, for tests and the battery.
  final String id;

  /// Regular expressions over the canonical question (see [HadiCore.canon]).
  /// The entry answers when ANY of them matches and none of [avoid] does.
  final List<String> patterns;
  final List<String> avoid;

  /// The reply, with its sources printed in the text and `[GO:]` buttons at
  /// the end.
  final String answer;

  /// A topic word a short follow-up ("how much?") can be tied to.
  final String topic;

  /// True when the answer is general and safe to give even though the
  /// question reads like a ruling about one person (for example "Is it okay
  /// to hit my wife?", which must never be met with a hand-off alone).
  final bool beforeGate;

  /// What to say to a bare "why?" right after this answer.
  final String why;

  /// Points a named scholar still has to confirm (kept for the review list).
  final String reviewNote;
}

/// A reply and the entry it came from.
class CoreHit {
  const CoreHit(this.entry, this.text);
  final CoreEntry entry;
  final String text;
}

abstract final class HadiCore {
  // ── Spelling and wording ─────────────────────────────────────────────

  /// Spellings people type, folded to one word. Applied word by word to the
  /// normalised question (apostrophes are already gone: "rak'ah" is
  /// "rakah", "qur'an" is "quran").
  static const Map<String, String> _alias = <String, String>{
    'wudhu': 'wudu', 'wuduu': 'wudu', 'wazu': 'wudu', 'wuzu': 'wudu', 'wudoo': 'wudu', 'wuzoo': 'wudu',
    'wudu': 'wudu', 'ablution': 'wudu', 'ablutions': 'wudu',
    'salat': 'prayer', 'salah': 'prayer', 'salaah': 'prayer',
    'salaat': 'prayer', 'namaz': 'prayer', 'namaaz': 'prayer',
    'rakat': 'rakah', 'rakah': 'rakah', 'rakaat': 'rakah', 'rakats': 'rakah',
    'raka': 'rakah', 'rakas': 'rakah', 'rakahs': 'rakah', 'rakaah': 'rakah',
    'rakaats': 'rakah', 'rakaa': 'rakah', 'rakatain': 'rakah',
    'janaza': 'janazah', 'janazah': 'janazah', 'janaazah': 'janazah',
    'jenazah': 'janazah', 'jinazah': 'janazah', 'janazeh': 'janazah',
    'qiblah': 'qibla', 'kibla': 'qibla', 'qibla': 'qibla', 'kiblah': 'qibla',
    'koran': 'quran', 'quraan': 'quran', 'qoran': 'quran', 'kuran': 'quran',
    'quran': 'quran',
    'hadees': 'hadith', 'hadeeth': 'hadith', 'hadis': 'hadith',
    'hadit': 'hadith', 'hadiths': 'hadith', 'ahadith': 'hadith',
    'ahadeeth': 'hadith',
    'zakah': 'zakat', 'zakaat': 'zakat', 'zakat': 'zakat', 'zakāt': 'zakat',
    'ramadhan': 'ramadan', 'ramazan': 'ramadan', 'ramzan': 'ramadan',
    'iddat': 'iddah', 'idda': 'iddah', 'iddah': 'iddah',
    'tashahud': 'tashahhud', 'tashahhud': 'tashahhud', 'tashahood': 'tashahhud',
    'tahiyyat': 'tashahhud', 'attahiyat': 'tashahhud', 'tashahod': 'tashahhud',
    'sajdah': 'sujud', 'sajda': 'sujud', 'sujood': 'sujud', 'sujud': 'sujud',
    'sajdas': 'sujud', 'sijda': 'sujud',
    'ruku': 'ruku', 'rukoo': 'ruku', 'rukuh': 'ruku', 'rukus': 'ruku',
    'hijaab': 'hijab', 'hijab': 'hijab',
    'haraam': 'haram', 'haram': 'haram', 'halaal': 'halal', 'halal': 'halal',
    'umra': 'umrah', 'umrah': 'umrah', 'haj': 'hajj', 'hadj': 'hajj',
    'hajj': 'hajj',
    'sehri': 'suhoor', 'suhur': 'suhoor', 'suhoor': 'suhoor', 'sehr': 'suhoor',
    'iftaar': 'iftar', 'iftar': 'iftar', 'ifter': 'iftar',
    'shahada': 'shahadah', 'shahadah': 'shahadah', 'shahaadah': 'shahadah',
    'shahadat': 'shahadah', 'kalima': 'shahadah', 'kalimah': 'shahadah',
    'tayamum': 'tayammum', 'tayammum': 'tayammum', 'tayammam': 'tayammum',
    'ghusal': 'ghusl', 'ghusl': 'ghusl', 'ghusul': 'ghusl', 'gusl': 'ghusl',
    'madhab': 'madhhab', 'mazhab': 'madhhab', 'madhhab': 'madhhab',
    'madhahib': 'madhhab', 'madhabs': 'madhhab', 'madhhabs': 'madhhab',
    'mazhabs': 'madhhab', 'mazhaab': 'madhhab',
    'nikkah': 'nikah', 'nikah': 'nikah',
    'mehram': 'mahram', 'mahram': 'mahram', 'mehrem': 'mahram',
    'jumah': 'jumuah', 'jumuah': 'jumuah', 'juma': 'jumuah',
    'jummah': 'jumuah', 'jumma': 'jumuah', 'jumuaa': 'jumuah',
    'taraweeh': 'taraweeh', 'tarawih': 'taraweeh', 'taraweh': 'taraweeh',
    'tarawee': 'taraweeh',
    'vitr': 'witr', 'witr': 'witr', 'witar': 'witr',
    'tahajud': 'tahajjud', 'tahajjud': 'tahajjud',
    'adhaan': 'adhan', 'azan': 'adhan', 'athan': 'adhan', 'adhan': 'adhan',
    'azaan': 'adhan',
    'masjids': 'masjid', 'mosque': 'masjid', 'mosques': 'masjid',
    'sunnat': 'sunnah', 'sunnah': 'sunnah', 'sunna': 'sunnah',
    'najasa': 'najasa', 'najasah': 'najasa', 'najaasa': 'najasa',
    'najis': 'najasa', 'najaasat': 'najasa', 'najasat': 'najasa',
    'bismillah': 'bismillah', 'basmala': 'bismillah', 'basmalah': 'bismillah',
    'bismilah': 'bismillah', 'bismillahi': 'bismillah',
    'miraj': 'miraj', 'meraj': 'miraj', 'mairaj': 'miraj', 'israa': 'isra',
    'isra': 'isra', 'miiraj': 'miraj',
    'kaabah': 'kaaba', 'kabah': 'kaaba', 'kaba': 'kaaba', 'kabba': 'kaaba',
    'kaaba': 'kaaba', 'kabaa': 'kaaba',
    'duaa': 'dua', 'dua': 'dua', 'duas': 'dua', 'duaas': 'dua',
    'sadaqa': 'sadaqah', 'sadaqah': 'sadaqah', 'sadqa': 'sadaqah',
    'fidya': 'fidyah', 'fidyah': 'fidyah',
    'istinja': 'istinja', 'istinjaa': 'istinja',
    'riba': 'riba', 'ribaa': 'riba',
    'mutah': 'mutah',
    'qadha': 'qada', 'qaza': 'qada', 'qada': 'qada', 'qadaa': 'qada',
    'sahabah': 'sahabah', 'sahaba': 'sahabah', 'sahabi': 'sahabah',
    'sahabas': 'sahabah',
    'asalamualaikum': 'salam', 'assalamualaikum': 'salam',
    'assalamoalaikum': 'salam', 'salaam': 'salam',
    'shia': 'shia', 'shiah': 'shia', 'shiite': 'shia', 'shiites': 'shia',
    'shias': 'shia', 'shiism': 'shia',
    'hazrat': 'prophet',
    'mecca': 'makkah', 'makka': 'makkah', 'makkah': 'makkah',
    'medina': 'madinah', 'madina': 'madinah', 'madinah': 'madinah',
    'wifes': 'wife', 'wives': 'wife',
    'rightly': 'rightly',
    'sheikh': 'shaykh', 'shaikh': 'shaykh', 'shaykh': 'shaykh',
    'iman': 'iman', 'eman': 'iman', 'imaan': 'iman',
    'tawheed': 'tawhid', 'tauheed': 'tawhid', 'tawhid': 'tawhid',
    'aqeedah': 'aqidah', 'aqidah': 'aqidah', 'aqeeda': 'aqidah',
    'khutbah': 'khutbah', 'khutba': 'khutbah',
    'fajar': 'fajr', 'fajr': 'fajr', 'zuhr': 'dhuhr', 'zohr': 'dhuhr',
    'duhr': 'dhuhr', 'dhuhr': 'dhuhr', 'dhur': 'dhuhr', 'zuhar': 'dhuhr',
    'magrib': 'maghrib', 'maghrib': 'maghrib', 'esha': 'isha',
    'isha': 'isha', 'ishaa': 'isha', 'asar': 'asr', 'asr': 'asr',
    'chese': 'chess', 'shatranj': 'chess',
  };

  /// Polite openings that say nothing about the topic.
  static final RegExp _lead = RegExp(
    r'^(?:(?:hi|hello|hey|salam|hadi|please|pls|plz|ok|okay|so|and|well|um|'
    r'sorry|brother|sister|bro|sis|dear|can\s+you|could\s+you|would\s+you|'
    r'will\s+you|kindly|just|quick\s+question|a\s+question|question|'
    r'i\s+have\s+a\s+question|i\s+wanted\s+to\s+ask|i\s+want\s+to\s+ask|'
    r'i\s+was\s+wondering|i\s+am\s+wondering|im\s+wondering|'
    r'i\s+would\s+like\s+to\s+know|i\s+want\s+to\s+know|i\s+wanna\s+know|'
    r'i\s+need\s+to\s+know|id\s+like\s+to\s+know|do\s+you\s+know|'
    r'tell\s+me|let\s+me\s+know|explain\s+to\s+me|explain)\s+)+',
  );

  static final RegExp _trail = RegExp(
    r'(?:\s+(?:please|pls|plz|thanks|thank\s+you|jazakallah|jazakallahu\s+khayran|'
    r'hadi|brother|sister|in\s+islam|islamically|according\s+to\s+islam|'
    r'in\s+simple\s+words|briefly|in\s+short))+$',
  );

  /// The question as the patterns see it: lower case, no punctuation, no
  /// apostrophes, one spelling per word, no polite opening or ending.
  static String canon(String question) {
    final String n = CrisisDetector.normalize(question);
    if (n.isEmpty) return '';
    final List<String> words = <String>[
      for (final String w in n.split(' '))
        if (w.isNotEmpty) _alias[w] ?? w,
    ];
    String s = words.join(' ');
    for (int i = 0; i < 3; i++) {
      final String t = s.replaceFirst(_lead, '').replaceFirst(_trail, '');
      if (t == s || t.isEmpty) break;
      s = t;
    }
    return s;
  }

  // ── The entries ──────────────────────────────────────────────────────

  static final List<_Compiled> _compiled = <_Compiled>[
    for (final CoreEntry e in kHadiCoreEntries)
      _Compiled(
        e,
        <RegExp>[for (final String p in e.patterns) RegExp(p)],
        <RegExp>[for (final String p in e.avoid) RegExp(p)],
      ),
  ];

  static final Set<String> _answerBodies = <String>{
    for (final CoreEntry e in kHadiCoreEntries) _body(e.answer),
  };

  static final RegExp _tokenRe = RegExp(r'\s*\[GO:[^\]]*\]');

  static String _body(String s) =>
      s.replaceAll(_tokenRe, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Every built-in answer (for the tests that check them all).
  static List<CoreEntry> get entries => kHadiCoreEntries;

  /// The entry for an already-canonical question, or null.
  static CoreEntry? _find(String canonical) {
    if (canonical.isEmpty) return null;
    for (final _Compiled c in _compiled) {
      if (c.avoid.any((RegExp r) => r.hasMatch(canonical))) continue;
      if (c.patterns.any((RegExp r) => r.hasMatch(canonical))) return c.entry;
    }
    return null;
  }

  /// The entry that answers [question], or null.
  static CoreEntry? match(String question) {
    final String c = canon(question);
    if (c.split(' ').length > 40) return null;
    return _find(c);
  }

  /// True when the built-in answers take [question] before the ruling gate
  /// (see [CoreEntry.beforeGate]).
  static bool claims(String question) {
    final CoreEntry? e = match(question);
    return e != null && e.beforeGate;
  }

  /// True when [reply] (a provider reply, buttons and all) is one of the
  /// built-in answers, word for word.
  static bool isCoreAnswer(String reply) {
    final String b = _body(reply);
    if (_answerBodies.contains(b)) return true;
    // A note added under the answer (the general-ruling footer) does not make
    // it a different answer.
    return _answerBodies.any(b.startsWith);
  }

  // ── Short follow-ups ("how much?", "what breaks it?") ────────────────

  /// Topic words a follow-up can be tied to: the first match in a recent
  /// question names the topic. Each is the canonical noun placed in the
  /// follow-up in place of "it".
  static final List<(RegExp, String)> _topics = <(RegExp, String)>[
    (RegExp(r'\bzakat\b'), 'zakat'),
    (RegExp(r'\bwudu\b'), 'wudu'),
    (RegExp(r'\bghusl\b'), 'ghusl'),
    (RegExp(r'\btayammum\b'), 'tayammum'),
    (RegExp(r'\bjanazah\b|\bfuneral\b'), 'janazah'),
    (RegExp(r'\bramadan\b|\bfasting\b|\bfast\b'), 'fasting'),
    (RegExp(r'\bhajj\b'), 'hajj'),
    (RegExp(r'\bumrah\b'), 'umrah'),
    (RegExp(r'\beid\b'), 'eid'),
    (RegExp(r'\bnikah\b|\bmarriage\b'), 'nikah'),
    (RegExp(r'\b99\b.*\bnames?\b|\bnames of allah\b'), '99 names game'),
    (RegExp(r'\bchess\b'), 'chess'),
    (RegExp(r'\bludo\b'), 'ludo'),
    (RegExp(r'\btrivia\b'), 'trivia game'),
    (RegExp(r'\bmemory match\b|\bnames memory\b'), 'names memory game'),
    (RegExp(r'\bstreaks?\b|\bmy log\b'), 'my log'),
    (RegExp(r'\bquran\b'), 'quran'),
    (RegExp(r'\bhadith\b'), 'hadith'),
    (RegExp(r'\btaraweeh\b'), 'taraweeh'),
    (RegExp(r'\bwitr\b'), 'witr'),
    (RegExp(r'\btahajjud\b'), 'tahajjud'),
    (RegExp(r'\bqibla\b'), 'qibla'),
    (RegExp(r'\bdownloads?\b'), 'downloads'),
    (RegExp(r'\bacademy\b'), 'academy'),
    (RegExp(r'\bjumuah\b'), 'jumuah'),
    (RegExp(r'\bprayer\b|\bpray\b|\brakah\b'), 'prayer'),
  ];

  static final RegExp _elliptical = RegExp(
    r'^(?:and\s+|what\s+about\s+|how\s+about\s+)?'
    r'(?:how|what|who|when|where|why|which|is|are|can|do|does|did|should|'
    r'must|may)\b',
  );
  static final RegExp _pronoun = RegExp(r'\b(?:it|its|that|this|them|those|these)\b');

  /// If [question] is a short follow-up that names no topic of its own,
  /// the question rewritten with the topic of the conversation so far
  /// ("how much?" after "What is zakat?" becomes "how much zakat"). Null
  /// when it is not such a follow-up, or no recent question names a topic.
  static String? expandFollowUp(String question, List<HadiMessage> history) {
    final String c = canon(question);
    final List<String> words = c.split(' ');
    if (c.isEmpty || words.length > 7) return null;
    if (!_elliptical.hasMatch(c)) return null;
    // A question with a topic of its own is not a follow-up.
    for (final (RegExp re, String _) in _topics) {
      if (re.hasMatch(c)) return null;
    }
    final bool pronoun = _pronoun.hasMatch(c);
    // "what if I have debts", "what about my loan": a short "what if / what
    // about" is a follow-up even when it has a few more words.
    final bool whatIf =
        RegExp(r'^(?:and\s+)?(?:what\s+if|what\s+about|how\s+about)\b').hasMatch(c);
    if (!pronoun && words.length > (whatIf ? 7 : 4)) return null;
    String? topic;
    int seen = 0;
    for (int i = history.length - 1; i >= 0 && seen < 6; i--) {
      final HadiMessage m = history[i];
      if (m.fromHadi) continue;
      seen++;
      final String past = canon(m.text);
      for (final (RegExp re, String t) in _topics) {
        if (re.hasMatch(past)) {
          topic = t;
          break;
        }
      }
      if (topic != null) break;
    }
    if (topic == null) return null;
    if (pronoun) return c.replaceAll(_pronoun, topic);
    return '$c $topic';
  }

  static final RegExp _wantsMore = RegExp(
    r'^(?:(?:tell me|give me|show me) )?(?:(?:another|one more|more|something else|'
    r'anything else|other)\b.*\b(?:about|on|of|regarding) (?:it|that|this)|'
    r'(?:tell me )?more(?: about (?:it|that|this))?|go on|and then|continue)$',
  );

  /// The reply to "tell me more" / "another thing about it" when nothing
  /// further is on the shelf, or null when [question] is not that request.
  static String? moreReply(String question, List<HadiMessage> history) {
    if (history.isEmpty || !_wantsMore.hasMatch(canon(question))) return null;
    return 'That is everything I have checked on this, and I will not add '
        'anything I cannot source. Ask about one part of it, for example its '
        'conditions, what breaks it, or who it applies to, and I will answer '
        'that. Search also finds stories, guides and du\u2019as on it.'
        '\n[GO:/search]';
  }

  /// The entry whose answer Hādi gave last, if it was a built-in one.
  static CoreEntry? _lastEntry(List<HadiMessage> history) {
    for (int i = history.length - 1; i >= 0; i--) {
      final HadiMessage m = history[i];
      if (!m.fromHadi) continue;
      final String b = _body(m.text);
      for (final _Compiled e in _compiled) {
        if (b.startsWith(_body(e.entry.answer))) return e.entry;
      }
      return null;
    }
    return null;
  }

  static String? _sourceLine(String answer) {
    for (final String l in answer.split('\n')) {
      if (l.startsWith('Source:')) return l;
    }
    return null;
  }

  /// The answer to [question] given the conversation so far, or null when
  /// no built-in answer fits. A bare "why?" gets the entry's own reason.
  static CoreHit? answer(String question, List<HadiMessage> history) {
    final String c = canon(question);
    if (c.isEmpty) return null;
    if (c == 'why' || c == 'why is that' || c == 'why so') {
      final CoreEntry? last = _lastEntry(history);
      if (last == null) return null;
      if (last.why.isNotEmpty) return CoreHit(last, last.why);
      final String? src = _sourceLine(last.answer);
      return CoreHit(
        last,
        src == null
            ? 'The reasons are in the answer above. Tell me which part is '
                'unclear and I will say it another way.'
            : 'The reasons are in the answer above, and they rest on these '
                'texts: ${src.replaceFirst(RegExp(r'^Source:\s*'), '')}\n'
                'Tell me which part is unclear and I will say it another way.',
      );
    }
    final CoreEntry? e = _find(c);
    if (e != null) return CoreHit(e, e.answer);
    final String? expanded = expandFollowUp(question, history);
    if (expanded != null) {
      final CoreEntry? f = _find(expanded);
      if (f != null) return CoreHit(f, f.answer);
    }
    return null;
  }
}

class _Compiled {
  const _Compiled(this.entry, this.patterns, this.avoid);
  final CoreEntry entry;
  final List<RegExp> patterns;
  final List<RegExp> avoid;
}
