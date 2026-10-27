import '../../sakina/domain/crisis_detector.dart';
import '../application/hadi_provider.dart';

/// What a short "yes" refers to: either a question to answer in its place or
/// a finished reply.
class HadiFollowUp {
  const HadiFollowUp.asking(this.question) : reply = null;
  const HadiFollowUp.answering(this.reply) : question = null;

  final String? question;
  final String? reply;
}

/// Replies that point at content the app already has, instead of answering
/// from a shelf that does not hold the answer. Nothing here is scripture or a
/// ruling: every reply either says what Hādi can and cannot do, or sends the
/// person to a screen that exists (every [GO:] route is on the whitelist in
/// hadi_controller.dart; test/hadi_nav_test.dart checks this file too).
///
/// Pure Dart, no Flutter, so it is tested without a widget tree.
abstract final class HadiRouting {
  static String _norm(String s) => CrisisDetector.normalize(s);

  // ── What Hādi can and cannot do ──────────────────────────────────────

  static final RegExp _selfDescription = RegExp(
    r'\b(?:'
    r'(?:what|which)\s+(?:things\s+)?(?:will|would|do|can|cant|cannot|wont|'
    r'are\s+you\s+not\s+able\s+to|are\s+you\s+not\s+allowed\s+to)\s+'
    r'you\s+(?:refuse|decline|not\s+answer|not\s+do|never\s+answer|'
    r'never\s+do|not\s+help)|'
    r'what\s+(?:cant|cannot|wont)\s+you\s+(?:do|answer|help|say|tell)|'
    r'what\s+are\s+(?:your|hadis)\s+(?:limits|limitations|rules|boundaries)|'
    r'what\s+(?:are|is)\s+(?:you|hadi)\s+(?:not\s+)?'
    r'(?:able|allowed|unable)\s+to|'
    r'what\s+do\s+you\s+refuse|'
    r'what\s+questions\s+(?:will|do|can|cant|wont)\s+you\s+(?:not\s+)?'
    r'(?:answer|refuse|decline)|'
    r'what\s+are\s+you\s+(?:not\s+)?(?:able|allowed)'
    r')\b',
  );

  static bool describesSelf(String question) =>
      _selfDescription.hasMatch(_norm(question));

  static const String selfDescriptionReply =
      'Here is what I do, and what I will not do.\n\n'
      'I can: answer from the Qur’an and the authentic hadith books with '
      'the source printed under the answer; show you where things are in '
      'this app and take you there; point you to a guide, a story or a '
      'du’a that fits; and stay with you when something is heavy.\n\n'
      'I will not: give a fatwa or rule on your own situation (marriage, '
      'divorce, inheritance, whether your own worship is valid), because '
      'that belongs to a qualified scholar who knows your case; invent a '
      'verse, a hadith, a du’a or a hadith number; give medical advice; or '
      'answer what has nothing to do with Islam or this app.\n\n'
      'When I have no verified answer I say so, and I point you to a guide, '
      'to Search, or to a qualified scholar. Our Sources shows where '
      'everything comes from.\n[GO:/sources]';

  // ── Someone new to Islam ─────────────────────────────────────────────

  static const String _lead =
      r'(?:(?:hi|hello|hey|salam|ok|okay|so|please|hadi|can\s+you|could\s+you|'
      r'would\s+you|will\s+you|kindly)\s+)*';
  static const String _trail =
      r'(?:\s+(?:please|pls|simply|briefly|in\s+simple\s+words|'
      r'in\s+simple\s+terms|in\s+short|for\s+me|to\s+me|for\s+beginners|'
      r'for\s+a\s+beginner|hadi))*';

  static final RegExp _beginner = RegExp(
    '^$_lead(?:'
    r'(?:what|whats)\s+(?:is|are)\s+(?:exactly\s+|actually\s+)?'
    r'(?:islam|the\s+islamic\s+faith|the\s+muslim\s+faith|'
    r'the\s+islamic\s+religion|the\s+muslim\s+religion|islamic\s+faith)|'
    r'(?:what|whats)\s+(?:do|does)\s+(?:muslims?|islam)\s+(?:actually\s+)?'
    r'(?:believe(?:\s+in)?|teach|stand\s+for)|'
    r'(?:what\s+(?:is|are)\s+)?(?:the\s+)?(?:basic|basics|core|main|key|'
    r'fundamental)\s+(?:beliefs?|teachings?|principles?)\s+(?:of|in)\s+'
    r'(?:islam|muslims?)|'
    r'(?:tell\s+me|teach\s+me|explain|describe)\s+(?:about\s+|to\s+me\s+)?'
    r'islam|'
    r'(?:an\s+)?(?:introduction|intro|beginners?\s+guide|guide)\s+to\s+islam|'
    r'islam\s+(?:101|basics|explained|for\s+beginners|in\s+a\s+nutshell)|'
    r'(?:the\s+)?basics\s+of\s+islam|'
    r'(?:what\s+do\s+i\s+need\s+to\s+know|where\s+do\s+i\s+start|'
    r'how\s+do\s+i\s+start|where\s+to\s+start)\s+(?:about|with|learning)\s+'
    r'(?:about\s+)?islam|'
    r'(?:i\s+)?(?:know\s+nothing\s+about\s+islam|am\s+new\s+to\s+islam|'
    r'im\s+new\s+to\s+islam|new\s+to\s+islam|want\s+to\s+learn\s+'
    r'(?:about\s+)?islam)|'
    r'(?:what\s+(?:is|are)\s+)?(?:the\s+)?(?:six\s+|6\s+)?articles\s+of\s+'
    r'(?:faith|iman)|'
    r'(?:what\s+is\s+)?(?:the\s+)?(?:meaning|definition)\s+of\s+'
    r'(?:the\s+word\s+)?islam|'
    r'what\s+does\s+(?:the\s+word\s+)?islam\s+mean|'
    r'who\s+are\s+(?:the\s+)?muslims|'
    r'what\s+is\s+it\s+to\s+be\s+a\s+muslim|'
    r'(?:how\s+(?:do|can)\s+i|how\s+to)\s+(?:become|be)\s+a\s+muslim|'
    r'(?:how\s+(?:do|can)\s+i|how\s+to)\s+convert\s+to\s+islam'
    ')$_trail\$',
  );

  static bool asksBeginner(String question) =>
      _beginner.hasMatch(_norm(question));

  static const String beginnerReply =
      'That is a good place to begin. These are the app’s own words, from '
      'the New Muslim path and the Wasia Academy, not mine.\n\n'
      'Day 1 of the New Muslim path: “The testimony that none deserves '
      'worship but Allah, and that Muhammad is His Messenger, is the door '
      'into Islam.” It adds the Qur’an’s words: “Indeed, the religion in '
      'the sight of Allah is Islam” (Qur’an 3:19).\n\n'
      'Day 2: “Islam stands on five: the testimony, the prayer, the alms, '
      'the fast of Ramadan, and the pilgrimage for those able.”\n\n'
      'On what a Muslim believes, the Wasia Academy lesson on the six '
      'articles of faith says: “The Prophet ﷺ defined faith in the hadith '
      'of Jibreel (Muslim 8): belief in Allah, His angels, His books, His '
      'messengers, the Last Day, and the divine decree.”\n\n'
      'The What Is Islam guide sets the word, the verses and the hadith in '
      'order, with their sources (not yet scholar-reviewed). The New Muslim '
      'path goes on one short step a day, and the Aqeedah school teaches '
      'what Muslims believe. For a short list first, ask me about the five '
      'pillars of Islam.\n[GO:/huda/guide?id=huda-what-is-islam]\n[GO:/new-muslim]';

  // ── "These may help" must never promise buttons that are not there ──

  /// [text] with the "These may help in the meantime:" line removed when
  /// there is no button to follow it, and moved to the very end (right above
  /// the buttons, after any footer) when there is.
  static String guardLeadIn(String text, List<String> routes) {
    if (!text.contains(refusalLeadIn)) return text;
    final String stripped = text
        .replaceAll(refusalLeadIn, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return routes.isEmpty ? stripped : '$stripped\n\n$refusalLeadIn';
  }

// ── Questions for a doctor ───────────────────────────────────────────

  /// Stemmed words (see the offline provider) that mark a medical question.
  static const Set<String> medicalWords = <String>{
    'medication',
    'medicine',
    'med',
    'pill',
    'tablet',
    'antidepressant',
    'prescription',
    'prescribed',
    'dosage',
    'dose',
    'psychiatrist',
    'therapist',
    'therapy',
    'ssri',
  };

  static final RegExp _anxious = RegExp(
    r'\b(?:anxiety|anxious|worry|worried|worries|stress|stressed|panic)\b',
  );

  static String medicalReply(String question) {
    final bool anxious = _anxious.hasMatch(_norm(question));
    final String comfort = anxious
        ? 'Separately, if it would comfort you, ask me for “A du’a for '
            'anxiety” and I will share it from my shelf.'
        : 'Separately, if you would like a du’a for what you are going '
            'through, tell me and I will share one from my shelf.';
    return 'Whether to take a medicine, which one, or how much is a medical '
        'question, and your doctor or pharmacist is the right person for '
        'it, not me. If a doctor has prescribed it, please keep following '
        'your doctor’s advice, and do not stop or change a medicine on your '
        'own. The Illness and Patience guide in this app says: “Allah has '
        'made a remedy for every illness He created, so seek treatment”. '
        'If part of your question is whether something is permitted, a '
        'qualified scholar can speak to that; Our Sources lists one. '
        '$comfort\n[GO:/huda/guide?id=huda-illness]\n[GO:/sources]';
  }

  // ── Ramadan planning ─────────────────────────────────────────────────

  static final RegExp _planWords = RegExp(
    r'\b(?:plan|planner|planning|schedule|timetable|checklist|routine|'
    r'tracker|track|timings|suhoor\s+times?|iftar\s+times?|sehri\s+times?)\b',
  );

  static bool asksRamadanPlan(String question) {
    final String n = _norm(question);
    return n.contains('ramadan') && _planWords.hasMatch(n);
  }

  static const String ramadanPlanReply =
      'A plan is easier to keep in the Ramadan screen than in a chat. It has '
      'a fasting log, a Qur’an completion tracker by juz, live suhoor and '
      'iftar countdowns from your prayer times, and a sadaqah tracker. '
      'Ramadan Mode in the Wasia Academy covers the rhythm of the month. I '
      'will not make up a schedule or times for you here.'
      '\n[GO:/ramadan]\n[GO:/academy/ramadan-mode]';

  // ── Tahajjud: how, and how many ──────────────────────────────────────

  static final RegExp _tahajjud = RegExp(
    r'\b(?:tahajjud|tahajud|tahajjod|tahajood|qiyam|night\s+prayer|'
    r'prayer\s+(?:in|at|during)\s+the\s+night)\b',
  );
  static final RegExp _howMany = RegExp(
    r'\b(?:how\s+(?:do|to|can|should|many|much)|rakah|rakahs|rakat|rakaat|raka|'
    r'rakas|units|steps|teach|learn|method|guide)\b',
  );

  static bool asksTahajjudHow(String question) {
    final String n = _norm(question);
    return _tahajjud.hasMatch(n) && _howMany.hasMatch(n);
  }

  // ── A hadith number that cannot be confirmed ─────────────────────────

  static final RegExp _numberAsk = RegExp(
    r'\b(?:hadith\s+(?:number|no|num|reference|ref)|'
    r'number\s+of\s+(?:the\s+|this\s+|that\s+)?hadith|hadith\s+\d{1,5}|'
    r'(?:source|reference)\s+(?:for|of)\s+(?:this|that|the)\s+'
    r'(?:hadith|saying)|'
    r'where\s+(?:is|can\s+i\s+find)\s+(?:this|that|the)\s+(?:hadith|saying)|'
    r'(?:bukhari|muslim|tirmidhi|ibn\s+majah|abu\s+dawud|nasai|nasa\s*i)\s+'
    r'(?:number\s+|no\s+)?\d{1,5})\b',
  );

  static bool asksHadithNumber(String question) =>
      _numberAsk.hasMatch(_norm(question));

  static const String closestMatchNote =
      'I cannot confirm a hadith number for the exact wording you gave. The '
      'closest match on my shelf is below, and it may not be the same '
      'wording, so please do not treat its number as the answer to your '
      'question.';

  /// [answer] for a question that asks for a hadith number. When the person
  /// typed a number and the answer does not contain it, nothing on the shelf
  /// is that hadith, and the plain "cannot confirm" reply is given instead of
  /// a different hadith. When no number was typed (they asked for one), the
  /// closest match is shown and labelled as such.
  static String forNumberAsk(String question, String answer) {
    final List<String> typed = <String>[
      for (final RegExpMatch m in RegExp(r'\d{1,5}').allMatches(question))
        m.group(0)!,
    ];
    if (typed.isEmpty) return '$closestMatchNote\n\n$answer';
    if (typed.every(answer.contains)) return answer;
    return hadithNumberDecline;
  }

  static const String hadithNumberDecline =
      'I cannot confirm a hadith number for that wording, and I will not '
      'give one from memory. Find Anything searches the Forty Hadith and '
      'the rest of the app, and every hadith this app prints shows its '
      'collection, number and grade. To check whether a saying is '
      'authentic, a qualified scholar, or the collection itself, is the '
      'place to confirm it.\n[GO:/search]\n[GO:/hadith]';

  // ── "Yes please" ─────────────────────────────────────────────────────

  static final RegExp _affirm = RegExp(
    r'^(?:oh\s+)?(?:yes|yeah|yea|yep|yup|ya|ok|okay|sure|alright|please|'
    r'go\s+ahead|do\s+it|of\s+course|that\s+would\s+be\s+'
    r'(?:great|nice|good|helpful)|i\s+would\s+like\s+that|id\s+like\s+that)'
    r'\b',
  );

  static final RegExp _offer = RegExp(
    r'(?:would you like|if you(?:\s+would)?\s+(?:like|want)|shall i|'
    r'should i|do you want|want me to|i can|i could|i will)\s+'
    r'(?:me\s+to\s+)?(?:share|give|offer|show|open|send|read|recite|find|'
    r'tell)?\s*(?:you\s+)?(?:with\s+)?(.{3,70}?)'
    r'(?:\s+if\s+you[^.?!]*)?(?:[.?!;,]|$)',
    caseSensitive: false,
  );

  static const Set<String> _offerCues = <String>{
    'dua',
    'supplication',
    'hadith',
    'verse',
    'ayah',
    'story',
    'stories',
    'guide',
    'page',
    'steps',
    'reminder',
    'dhikr',
    'adhkar',
    'khutbah',
    'surah',
    'prayer',
    'example',
  };

  static const Set<String> _fillers = <String>{
    'a', 'an', 'the', 'of', 'for', 'to', 'my', 'me', 'i', 'you', 'your', //
    'it', 'that', 'this', 'please', 'yes', 'yeah', 'yep', 'ok', 'okay', //
    'sure', 'and', 'in', 'on', 'with', 'about', 'some', 'do', 'go', //
    'ahead', 'would', 'like', 'id', 'oh', 'ya', 'yea', 'yup', 'alright', //
    'course', 'is', 'be', 'great', 'nice', 'good', 'helpful', 'dua', //
  };

  static Set<String> _content(String s) => <String>{
        for (final String w in _norm(s).split(' '))
          if (w.length > 2 && !_fillers.contains(w)) w,
      };

  /// The thing Hādi last offered, as a short phrase, or null.
  static String? _lastOffer(String text) {
    String? found;
    for (final RegExpMatch m in _offer.allMatches(text)) {
      final String g = (m.group(1) ?? '').trim();
      if (g.isEmpty || g.toLowerCase().startsWith('to ')) continue;
      final List<String> words = _norm(g).split(' ');
      if (words.length > 9) continue;
      if (words.any(_offerCues.contains)) found = g;
    }
    return found;
  }

  /// What a short affirmative ("Yes please, the dua for my mother") means,
  /// given the conversation so far. Null when [question] is not a short
  /// affirmative, so it is answered as an ordinary question.
  static HadiFollowUp? followUp(String question, List<HadiMessage> history) {
    final String n = _norm(question);
    if (n.isEmpty || !_affirm.hasMatch(n)) return null;
    final List<String> words = n.split(' ');
    if (words.length > 10) return null;
    final String rest = n.replaceFirst(_affirm, '').trim();
    final Set<String> restContent = _content(rest);

    HadiMessage? last;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].fromHadi) {
        last = history[i];
        break;
      }
    }
    if (last != null) {
      final String? offered = _lastOffer(last.text);
      if (offered != null) {
        final bool agrees = restContent.isEmpty ||
            rest.contains('dua') ||
            restContent.any(_content(offered).contains);
        if (agrees && words.length <= 9) {
          return HadiFollowUp.asking(offered);
        }
      }
      if (last.routes.isNotEmpty && restContent.isEmpty) {
        return HadiFollowUp.answering(
          'Here you are. Tap below to open it.\n[GO:${last.routes.first}]',
        );
      }
    }
    if (restContent.isEmpty && words.length <= 3) {
      return const HadiFollowUp.answering(clarifyReply);
    }
    return null;
  }

  static const String clarifyReply =
      'Yes to what, exactly? I do not want to guess which of my suggestions '
      'you mean. Tell me in a few words what you would like, for example '
      '“A du’a for anxiety” or “How do I make wudu?”, and I will bring it.';

  // ── A refusal that does not leave the person stranded ────────────────

  /// Each starts with words no other reply uses, so a later question can see
  /// that the last reply was a refusal (see [isRefusal]).
  static const List<String> _variants = <String>[
    'Still no verified answer for that on my shelf, and I will not guess. '
        'The buttons below go to the closest place in the app, and Search '
        'looks across every story, guide and du’a. For a ruling, or a '
        'case of your own, a qualified scholar is the right person; Our '
        'Sources lists one.',
    'I cannot answer that from verified texts. It may help to put it in '
        'other words, since a single topic word such as “fasting” or '
        '“wudu” often works best. The buttons below go to the closest place '
        'in the app, and Search finds a word anywhere in it.',
    'That one is beyond my shelf, so rather than repeat myself: the '
        'closest place in the app is the first button below, Search can '
        'find a word anywhere in the app, and your local masjid or a '
        'qualified scholar can answer what I cannot.',
  ];

  static const List<String> _rulingVariants = <String>[
    'Still no verified answer on whether that is permitted, and I will not '
        'guess: it depends on the details and on your school. Our Sources '
        'lists a qualified scholar, and the buttons below go to the closest '
        'place in the app.',
    'I cannot answer that ruling from verified texts. A qualified scholar '
        'who knows the details is the right person; Our Sources lists one, '
        'and your local masjid can help too. Search is below if you want to '
        'look for the topic itself.',
    'That one is beyond my shelf, and a ruling is not mine to guess. Please '
        'take it to a qualified scholar. Our Sources is the first button '
        'below, and the second goes to the closest place in the app.',
  ];

  static const List<String> _markers = <String>[
    'rather not guess',
    'That is outside what I do',
    'Still no verified answer',
    'I cannot answer that from verified texts',
    'I cannot answer that ruling from verified texts',
    'That one is beyond my shelf',
  ];

  /// True when [text] is one of Hādi's refusals.
  static bool isRefusal(String text) => _markers.any(text.contains);

  /// How many refusals in a row end [history] (counting only Hādi's replies).
  static int refusalsInARow(List<HadiMessage> history) {
    int n = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      final HadiMessage m = history[i];
      if (!m.fromHadi) continue;
      if (!isRefusal(m.text)) break;
      n++;
    }
    return n;
  }

  /// The refusal for a later try: different wording each time, with the
  /// buttons that go with it. Null for the first refusal (the caller then
  /// uses its fixed text and [refusalRoutes]).
  static String? variantFor(
    String question,
    List<HadiMessage> history, {
    required bool ruling,
  }) {
    final int again = refusalsInARow(history);
    if (again == 0) return null;
    final List<String> pool = ruling ? _rulingVariants : _variants;
    final String text = pool[(again - 1) % pool.length];
    final List<String> routes = refusalRoutes(question, ruling: ruling);
    return '$text\n${<String>[for (final String r in routes) '[GO:$r]'].join('\n')}';
  }

  static final List<(RegExp, String)> _topics = <(RegExp, String)>[
    (
      RegExp(r'\b(?:arabic|alphabet|letters?|grammar|vocabulary|word\s+by\s+'
          r'word|wordbyword|words?\s+of)\b'),
      '/academy/quranic-arabic',
    ),
    (
      RegExp(r'\b(?:aqeedah|aqidah|belief|beliefs|believe|faith|iman|tawhid|'
          r'angels?|jinn|afterlife|judgment|judgement|paradise|jannah|hell|'
          r'qadr|fate|creed)\b'),
      '/academy/aqeedah',
    ),
    (
      RegExp(r'\b(?:quran|surah|surahs|ayah|ayat|verses?|tafsir|recite|'
          r'recitation|tajweed)\b'),
      '/quran',
    ),
    (
      RegExp(r'\b(?:dua|duas|supplication|supplications|dhikr|adhkar|zikr)\b'),
      '/academy/hisn',
    ),
    (
      RegExp(r'\b(?:ramadan|suhoor|sehri|iftar|eid|taraweeh)\b'),
      '/ramadan',
    ),
    (
      RegExp(r'\b(?:dating|boyfriend|girlfriend|courtship|spouse)\b'),
      '/academy/family-life',
    ),
    (
      RegExp(r'\b(?:prayer|prayers|salah|salat|namaz|wudu|ghusl|tayammum|fast|'
          r'fasting|hajj|umrah|zakat|janazah|funeral|nikah|marriage|divorce|'
          r'inheritance|halal|haram)\b'),
      '/huda',
    ),
    (
      RegExp(r'\b(?:story|stories|prophet|prophets|seerah|sunnah|companions?|'
          r'khutbah|khutbahs)\b'),
      '/stories',
    ),
    (
      RegExp(r'\b(?:feel|feeling|heart|sad|anxious|anxiety|worry|lonely|'
          r'grief|depressed)\b'),
      '/feelings',
    ),
    (
      RegExp(r'\b(?:child|children|kids?|teach|homeschool|learn|learning)\b'),
      '/academy',
    ),
  ];

  /// True when the question names a topic the app has a place for.
  static bool hasTopic(String question) {
    final String n = _norm(question);
    return _topics.any(((RegExp, String) t) => t.$1.hasMatch(n));
  }

  /// The closest place in the app for what was asked. Always whitelisted.
  static String topicRoute(String question) {
    final String n = _norm(question);
    for (final (RegExp re, String route) in _topics) {
      if (re.hasMatch(n)) return route;
    }
    return '/academy/qa';
  }

  /// The two buttons that go under a refusal. A ruling question gets Our
  /// Sources first (where the scholar is named); anything else gets the
  /// closest place in the app and Search.
  static List<String> refusalRoutes(String question, {required bool ruling}) {
    final String topic = topicRoute(question);
    return ruling
        ? <String>['/sources', topic == '/sources' ? '/search' : topic]
        : <String>[topic, '/search'];
  }

  /// Words put in front of the buttons under a first refusal.
  static const String refusalLeadIn = 'These may help in the meantime:';

  // ── Questions the app holds no verified answer for ───────────────────
  //
  // Round 3 (first-time-user study). Each reply below says plainly that
  // Hadi has no verified answer, and sends the person to a screen that
  // exists. None of them states a ruling, a hadith or a du'a; every quoted
  // line is copied from the guide it names (test/hadi_round3_test.dart
  // checks the quotes against the app's own files).

  // Combining or shortening prayers on a journey.
  static final RegExp _combineWord = RegExp(
    r'\b(?:combin\w*|jam|jama|jamaa|jamaah|merg\w*|clubb\w*)\b',
  );
  static final RegExp _salahWord = RegExp(
    r'\b(?:dhuhr|zuhr|duhr|zohr|dhur|asr|maghrib|magrib|isha|esha|ishaa|'
    r'prayers?|salah|salat|namaz)\b',
  );
  static final RegExp _travelWord = RegExp(
    r'\b(?:travel\w*|trip|journey|flight|flying|airport|safar|musafir|'
    r'abroad|road\s+trip)\b',
  );
  static final RegExp _twoPrayers = RegExp(
    r'\b(?:dhuhr|zuhr|duhr|zohr|dhur)\b.*\b(?:asr)\b|'
    r'\b(?:asr)\b.*\b(?:dhuhr|zuhr|duhr|zohr|dhur)\b|'
    r'\b(?:maghrib|magrib)\b.*\b(?:isha|esha|ishaa)\b|'
    r'\b(?:isha|esha|ishaa)\b.*\b(?:maghrib|magrib)\b',
  );

  /// "Can I combine Dhuhr and Asr when travelling?"
  static bool asksCombinePrayers(String question) {
    final String n = _norm(question);
    if (n.split(' ').length > 24) return false;
    if (!_combineWord.hasMatch(n) || !_salahWord.hasMatch(n)) return false;
    return _travelWord.hasMatch(n) || _twoPrayers.hasMatch(n);
  }

  static const String travelPrayerReply =
      'I do not have a verified answer on combining prayers on a journey, '
      'and I will not answer a different question in its place. It depends on the details of the journey and on your school, '
      'so please ask a qualified scholar; Our Sources lists one.\n\n'
      'The nearest thing in the app is the Travel guide. On the shortened '
      'prayer it points to Qur’an 4:101, and its school note says: “follow '
      'your school’s fiqh for your journey”.'
      '\n[GO:/huda/guide?id=huda-travel]\n[GO:/sources]';

  // Someone Hadi has no source on.
  static final RegExp _whoIs = RegExp(
    r'^(?:(?:hi|hello|salam|please|hadi|ok|okay|so)\s+)*'
    r'(who\s+(?:is|was|are|were)|whos|tell\s+me\s+(?:more\s+)?about|'
    r'what\s+do\s+you\s+know\s+about|do\s+you\s+know|'
    r'(?:biography|bio|credentials|qualifications|background)\s+of|'
    r'what\s+are\s+the\s+(?:credentials|qualifications)\s+of)\s+(.+)$',
  );
  static const Set<String> _honorifics = <String>{
    'shaykh', 'sheikh', 'shaikh', 'sheik', 'imam', 'dr', 'mufti', 'maulana',
    'mawlana', 'moulana', 'ustadh', 'ustaz', 'ustad', 'hafiz', 'qari', //
    'professor', 'prof', 'mr', 'mrs', 'ms', 'brother', 'sister', 'sidi', //
  };
  static const Set<String> _nameParticles = <String>{
    'ibn', 'bin', 'bint', 'abu', 'abi', 'umm', 'al', 'an', 'ar', 'as', //
    'ash', 'ad', 'az', 'el', 'the', //
  };
  // A subject that starts with one of these is not a person's name.
  static const Set<String> _notAName = <String>{
    'the', 'a', 'an', 'my', 'your', 'our', 'this', 'that', 'these', 'those', //
    'best', 'most', 'first', 'last', 'all', 'any', 'some', 'you', 'yourself', //
    'hadi', 'wasia', 'islam', 'muslim', 'muslims', 'allah', 'prophet', //
    'prophets', 'quran', 'it', 'there', 'he', 'she', 'they', 'we', 'i', //
  };
  static final RegExp _subjectEnd =
      RegExp(r'\s(?:and|what|his|her|their|who|how|is|was|please)\s.*$');

  /// The name words of a "who is X?" question, with whether X carries a
  /// title (Shaykh, Imam, Dr, …); null when the question is not about a
  /// person. Words are normalised but not stemmed.
  static ({List<String> words, bool titled, bool who})? personSubject(
    String question,
  ) {
    final String n = _norm(question);
    final RegExpMatch? m = _whoIs.firstMatch(n);
    if (m == null) return null;
    final String subject = (m.group(2) ?? '').replaceFirst(_subjectEnd, '');
    final bool who = (m.group(1) ?? '').startsWith('who');
    final List<String> words =
        subject.split(' ').where((String w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 6) return null;
    if (_notAName.contains(words.first)) return null;
    final bool titled = _honorifics.contains(words.first);
    return (
      words: <String>[
        for (final String w in words)
          if (!_honorifics.contains(w) && !_nameParticles.contains(w)) w,
      ],
      titled: titled,
      who: who,
    );
  }

  /// True when [question] asks who a person is and Hadi has no source on
  /// them. [known] says whether a word is one the shelf knows (the offline
  /// provider passes its own index). A titled person needs one unknown name
  /// word, an untitled one two, so "who is Umar" still reaches the shelf.
  static bool asksUnknownPerson(
    String question, {
    required bool Function(String word) known,
  }) {
    final ({List<String> words, bool titled, bool who})? p =
        personSubject(question);
    if (p == null) return false;
    final int unknown =
        p.words.where((String w) => w.length >= 4 && !known(w)).length;
    // "Tell me about quantum entanglement" is a topic, not a person: only
    // "who is …" or a title makes two unknown words a person.
    if (p.titled) return unknown >= 1;
    return p.who && unknown >= 2;
  }

  /// True when the person asked about is the shaykh Our Sources names.
  static bool asksAboutSourceShaykh(String question) {
    final ({List<String> words, bool titled, bool who})? p =
        personSubject(question);
    return p != null &&
        p.words.any((String w) => w == 'saqib' || w == 'iqbal');
  }

  static const String unknownPersonReply =
      'I cannot speak about individuals I have no source on, and I have none '
      'on the person you named. I will not describe someone from memory or '
      'guess at who they are or what they have studied. Our Sources lists '
      'every text, translation and teacher the app is built on, and Find '
      'Anything searches the whole app.\n[GO:/sources]\n[GO:/search]';

  static const String sourceShaykhReply =
      'I cannot speak about individuals I have no source on, and I hold no '
      'biography or credentials for Shaykh Muhammad Saqib Iqbal. All I can '
      'tell you is how Our Sources describes his channel: lectures on '
      'creed, fiqh, seerah and purification of the heart, on his official '
      'YouTube channel. How we handle religious content says no named '
      'scholar has reviewed this app yet. For who he is and what he has '
      'studied, please look at his channel itself.'
      '\n[GO:/sources]\n[GO:/sources/policy]';

  // Relationships before marriage.
  static final RegExp _relationship = RegExp(
    r'\b(?:dating|boyfriends?|girlfriends?|courtship|courting|'
    r'(?:go|going|went)\s+out\s+with|premarital|pre\s+marital|'
    r'talk(?:ing)?\s+to\s+(?:a\s+)?(?:girls?|boys?|guys?)|'
    r'relationships?\s+before\s+marriage|haram\s+relationship)\b',
  );

  static bool asksRelationship(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 16 && _relationship.hasMatch(n);
  }

  static const String relationshipReply =
      'Many people ask this, and I am not assuming anything about you. I do '
      'not have a verified answer on what is and is not allowed between a '
      'man and a woman before marriage: it depends on the details and on '
      'your school, so a qualified scholar is the right person; Our '
      'Sources lists one.\n\n'
      'What the app does hold is its guide to marriage itself, Marriage — '
      'The Nikah: consent, the guardian and witnesses, the mahr, and the '
      'spirit of the home. Family Life School covers mercy between '
      'spouses. And if something is weighing on you, tell me and I will '
      'listen.'
      '\n[GO:/huda/guide?id=huda-nikah]\n[GO:/academy/family-life]';

  // Rights of husband and wife.
  static final RegExp _rightsWord = RegExp(
    r'\b(?:rights?|dut(?:y|ies)|responsibilit\w*|obligations?|roles?)\b',
  );

  static bool asksSpouseRights(String question) {
    final String n = _norm(question);
    if (n.split(' ').length > 22) return false;
    if (RegExp(r'\b(?:my|our)\s+(?:husband|wife|spouse)\b').hasMatch(n)) {
      return false;
    }
    // Both spouses named: "rights of husband and wife". A question about one
    // of them has its own answer on the shelf.
    final bool both = RegExp(r'\b(?:husbands?)\b').hasMatch(n) &&
            RegExp(r'\b(?:wife|wives)\b').hasMatch(n) ||
        RegExp(r'\bspouses?\b').hasMatch(n);
    return _rightsWord.hasMatch(n) && both;
  }

  static const String spouseRightsReply =
      'I do not have a verified, balanced answer on the rights and duties of '
      'each spouse, and I will not quote one side only. Marriage — The '
      'Nikah is the app’s own guide: it covers consent, the guardian and '
      'witnesses, the mahr, and the spirit of the home, with the line '
      '“the best of you is the best of you to their wives” (Tirmidhi '
      '3895, sahih per Darussalam). Family Life School covers mercy '
      'between spouses and the trust of children.\n\n'
      'For your own situation, a qualified scholar is the right person; Our '
      'Sources lists one.'
      '\n[GO:/huda/guide?id=huda-nikah]\n[GO:/academy/family-life]';

  // Groups within Islam.
  static final RegExp _groupWord = RegExp(
    r'\b(?:sunnis?|shias?|shiah|shiites?|ahmadis?|ahmadiyya|qadianis?|'
    r'sufis?|sufism|salafis?|wahhabis?|barelvis?|deobandis?|ibadis?)\b',
  );
  static final RegExp _groupAsk = RegExp(
    r'\b(?:differ\w*|difference\w*|versus|vs|between|compar\w*|split|'
    r'divid\w*|real|true|wrong|right|correct|misguided|kafirs?|'
    r'not\s+muslims?)\b',
  );

  static bool asksGroupDifference(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 20 &&
        _groupWord.hasMatch(n) &&
        _groupAsk.hasMatch(n);
  }

  static const String groupDifferenceReply =
      'I do not have a verified account of how these groups differ, and I '
      'will not describe one group in another’s words, from memory, or say '
      'which is right. A wrong or one-sided answer here would do harm. A '
      'qualified scholar can explain it fairly; Our Sources lists one.\n\n'
      'How we handle religious content, linked below, says what I can and '
      'cannot be relied on for. The Huda guides each carry a school note '
      'where the schools of law differ.'
      '\n[GO:/sources/policy]\n[GO:/huda]';

  // Memorising the Qur'an.
  static final RegExp _memoriseWord = RegExp(
    r'\b(?:memori[sz]\w*|hifz|by\s+heart)\b',
  );
  // Tracking or planning, or a named surah: the Hifz planner fits. A plain
  // "memorization tips" keeps the shelf's own answer.
  static final RegExp _memoriseAsk = RegExp(
    r'\b(?:track\w*|plan\w*|schedul\w*|progress|surah|sura|chapter|juz|'
    r'mulk|baqarah|yasin|kahf|rahman|fatiha|naba)\b',
  );

  static bool asksMemoriseHow(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 22 &&
        _memoriseWord.hasMatch(n) &&
        _memoriseAsk.hasMatch(n);
  }

  static const String memoriseReply =
      'Memorizing has its own screen in this app: the Hifz planner in the '
      'Wasia Academy. You pick a surah, set how many ayat a day you can '
      'manage, see roughly when you would finish, get a daily revision '
      'lane, and mark the ayat you have memorised. Your list stays on this '
      'device, and the screen says a teacher or checker confirms it.\n\n'
      'To work on a surah itself, the Qur’an reader has repeat controls for '
      'looping an ayah or a range.\n[GO:/academy/hifz]\n[GO:/quran]';

  // Someone new to Islam, said in their own words.
  static final RegExp _newcomerLoose = RegExp(
    r'\b(?:new\s+to\s+(?:islam|the\s+(?:faith|religion|deen))|'
    r'(?:just|recently)\s+(?:converted|reverted|became\s+(?:a\s+)?muslim|'
    r'embraced\s+islam|took\s+(?:my\s+)?shahada)|'
    r'(?:new|recent)\s+(?:muslim|convert|revert)|'
    r'i\s+(?:am|m)\s+a\s+(?:convert|revert))\b',
  );

  static bool asksNewcomerLoose(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 18 && _newcomerLoose.hasMatch(n);
  }

  // ── Sensitive questions the shelf cannot answer ──────────────────────

  static final RegExp _hitWord = RegExp(
    r'\b(?:hit|hits|hitting|beat|beats|beating|strike|strikes|striking|'
    r'slap\w*|spank\w*|smack\w*)\b',
  );
  static final RegExp _spouseWord = RegExp(
    r'\b(?:wife|wives|husband|husbands|spouse|spouses)\b',
  );
  static final RegExp _firstPersonWord =
      RegExp(r'\b(?:i|im|ive|me|my|mine|myself|we|our|us)\b');

  /// "Does the Qur'an allow a husband to hit his wife?" asked as a question
  /// about the text, not by someone it is happening to (that is the abuse
  /// support path, which runs first).
  static bool asksHittingSpouse(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 30 &&
        _hitWord.hasMatch(n) &&
        _spouseWord.hasMatch(n) &&
        !_firstPersonWord.hasMatch(n);
  }

  static const String hittingSpouseReply =
      'I do not have a verified answer on this, and I will not give a '
      'verdict or explain the verse from memory. A wrong or one-sided '
      'answer here could do real harm. Scholars treat Qur’an 4:34 in detail, '
      'with its context and with differing explanations, so please put it '
      'to a qualified scholar; Our Sources lists one.\n\n'
      'The Qur’an reader shows the verse itself, in the translation the app '
      'carries (An-Nisa’, ayah 34), so you can read exactly what it says.\n\n'
      'If someone is hurting you or frightens you at home, tell me, and the '
      'heart button at the top of this chat lists help lines for your '
      'country.\n[GO:/sources]\n[GO:/quran]';

  static final RegExp _whoRuns = RegExp(
    r'\b(?:who\s+(?:runs?|owns?|owned|made|makes|built|builds|created|'
    r'creates|develops?|developed|funds?|funded|finances?|operates?|'
    r'maintains?|started|founded|is\s+behind|are\s+behind|pays\s+for)\s+'
    r'(?:this|the|your)\s+(?:app|application|company|project|website)|'
    r'who\s+(?:is|are)\s+(?:the\s+)?(?:owner|owners|founder|founders|'
    r'developer|developers|creator|creators|publisher)(?:\s+of\s+'
    r'(?:this|the)\s+(?:app|application)|\s*$)|'
    r'who\s+(?:is|are)\s+behind\s+(?:this|it|ar\s*rayaan)|'
    r'who\s+funds?\s+(?:this|it))\b',
  );

  /// "Who runs this app and who funds it?"
  static bool asksWhoRunsApp(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 20 && _whoRuns.hasMatch(n);
  }

  static const String whoRunsReply =
      'The app does not name an owner, a company or a funder on the '
      'screens I can read from, so I have none to give you, and I will not '
      'guess one.\n\n'
      'What it does say: the Terms of Service (in Settings) describe Ar-Rayaan as a '
      'study and reflection companion, not a religious authority. Our '
      'Sources lists every text, translation and reciter it uses, and '
      'links Shaykh Muhammad Saqib Iqbal’s channel for guidance. How we '
      'handle religious content says no named scholar has reviewed the app '
      'yet. On cost: everything in this app, including me, is free today, '
      'nothing asks for a card, and a paid plan for extra live answers is '
      'planned but not open.\n[GO:/sources]\n[GO:/settings]';

  // ── The same answer twice ────────────────────────────────────────────

  static final RegExp _tokenRe = RegExp(r'\s*\[GO:[^\]]*\]');

  static String _core(String s) =>
      s.replaceAll(_tokenRe, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static const List<String> _repeatOpeners = <String>[
    'That is the same answer I gave a moment ago, and I have no more '
        'verified detail to add.',
    'I would only be saying the same thing again, and I have nothing '
        'further on my shelf for this.',
    'Repeating it would not help you: that is all I have verified on this.',
  ];

  static const String _repeatTail =
      ' If it did not answer what you meant, put it in other words. Asking '
      'me “How do you work?” shows what I can and cannot answer, and the '
      'buttons below go to how the app handles religious content and to '
      'the closest place for your topic.';

  static const String _repeatSchools =
      ' The Huda guides show each guide’s school note, and “Your school of '
      'law” in the More options menu lets me name your school when I hand '
      'you to a scholar.';

  static final RegExp _schoolTalk = RegExp(
    r'\b(?:madhhabs?|madhabs?|schools?|scholars?|disagree\w*|differ\w*|'
    r'hanafi|shafii|maliki|hanbali)\b',
  );

  /// The words that open a reply to a request for more than there is.
  static const String _moreOpener =
      'That is everything I have verified on this, and I have no further '
      'fact to give you without making one up.';

  static final RegExp _moreAsk = RegExp(
    r'\b(?:another|one\s+more|something\s+else|anything\s+else|'
    r'tell\s+me\s+more|next\s+one|a\s+different\s+one|'
    r'more\s+(?:facts?|things?|info\w*|details?|examples?))\b',
  );

  /// True for a short request for something new ("tell me another
  /// interesting thing about Ramadan").
  static bool asksForMore(String question) {
    final String n = _norm(question);
    return n.split(' ').length <= 14 && _moreAsk.hasMatch(n);
  }

  /// True when [question] is the same question the person asked last time,
  /// typed again. Only then is a second identical answer a loop: a first
  /// ask, a suggestion chip or a hand-off from Search is never one.
  static bool sameQuestionAgain(String question, List<HadiMessage> history) {
    final String now = _norm(question);
    if (now.isEmpty) return false;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].fromHadi) continue;
      return _norm(history[i].text) == now;
    }
    return false;
  }

  /// True when [reply] (a finished answer) is already in what Hadi said
  /// before. Short replies, hand-offs to a button, and refusals (which have
  /// their own variants) never count.
  static bool repeatsEarlier(String reply, List<HadiMessage> history) {
    final String c = _core(reply);
    if (c.length < 60 || c.startsWith('Here you are.') || isRefusal(c)) {
      return false;
    }
    for (final HadiMessage m in history) {
      if (m.fromHadi && _core(m.text).contains(c)) return true;
    }
    return false;
  }

  /// True when Hadi has already said [reply] in this conversation.
  static bool saidBefore(String reply, List<HadiMessage> history) {
    final String c = _core(reply);
    return history
        .any((HadiMessage m) => m.fromHadi && _core(m.text).contains(c));
  }

  /// The reply to use in place of [answer], or null to give [answer] as it
  /// is. [answer] is replaced only when it was already said AND either the
  /// person typed the very same question twice in a row, or asked for
  /// "another" and there is none.
  static String? replacementForRepeat(
    String question,
    String answer,
    List<HadiMessage> history,
  ) {
    if (!repeatsEarlier(answer, history)) return null;
    if (asksForMore(question)) return noMoreReply(question);
    if (sameQuestionAgain(question, history)) {
      return repeatReply(question, history);
    }
    return null;
  }

  /// Said when someone asks for another fact and the shelf has no more.
  static String noMoreReply(String question) {
    final String topic = topicRoute(question);
    final String second = topic == '/academy/qa' ? '/search' : topic;
    return '$_moreOpener Ask me about a different part of the topic, or '
        'open the closest place in the app below.\n[GO:$second]';
  }

  /// What to say in place of an answer that would repeat itself. Wording
  /// changes each time it is needed; the buttons go to the policy page and
  /// the closest place for [question].
  static String repeatReply(String question, List<HadiMessage> history) {
    final int before = history
        .where((HadiMessage m) =>
            m.fromHadi && _repeatOpeners.any((String o) => m.text.contains(o)))
        .length;
    final String opener = _repeatOpeners[before % _repeatOpeners.length];
    final bool schools = _schoolTalk.hasMatch(_norm(question));
    final String topic = schools ? '/huda' : topicRoute(question);
    final String second = topic == '/academy/qa' ? '/search' : topic;
    return '$opener$_repeatTail${schools ? _repeatSchools : ''}'
        '\n[GO:/sources/policy]\n[GO:$second]';
  }

  // ── The fixed replies, for the code that must not treat them as shelf ──

  static List<String> get fixedReplies => <String>[
        selfDescriptionReply,
        beginnerReply,
        ramadanPlanReply,
        hadithNumberDecline,
        clarifyReply,
        closestMatchNote,
        travelPrayerReply,
        unknownPersonReply,
        sourceShaykhReply,
        relationshipReply,
        spouseRightsReply,
        groupDifferenceReply,
        memoriseReply,
        hittingSpouseReply,
        whoRunsReply,
        ..._variants,
        ..._rulingVariants,
      ];

  /// True when [answer] is (or contains) one of the fixed replies above, or
  /// the medical hand-off.
  static bool isFixed(String answer) {
    if (answer.contains('is a medical question, and your doctor')) return true;
    if (_repeatOpeners.any(answer.contains)) return true;
    if (answer.contains(_moreOpener)) return true;
    return fixedReplies.any(answer.contains);
  }
}
