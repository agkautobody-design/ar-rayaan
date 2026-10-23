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
      'I can: answer from the Qur’an and the six books (Sihah Sitta) with '
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
      'That is a good place to begin, and it deserves more than a one-line '
      'answer from me. Two places in this app cover it: the New Muslim path '
      'starts from the very beginning, one short step at a time, and the '
      'Aqeedah school in the Wasia Academy is where what Muslims believe is '
      'taught. For a short list first, ask me about the five pillars of '
      'Islam.\n[GO:/new-muslim]\n[GO:/academy/aqeedah]';

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
        'it, not me. If part of your question is whether something is '
        'permitted, a qualified scholar can speak to that; Our Sources '
        'lists one. $comfort\n[GO:/sources]';
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

  static final RegExp _tahajjud = RegExp(r'\b(?:tahajjud|tahajud|qiyam)\b');
  static final RegExp _howMany = RegExp(
    r'\b(?:how\s+(?:do|to|can|should)|rakah|rakahs|rakat|rakaat|raka|rakas|'
    r'units|steps)\b',
  );

  static bool asksTahajjudHow(String question) {
    final String n = _norm(question);
    return _tahajjud.hasMatch(n) && _howMany.hasMatch(n);
  }

  static const String tahajjudReply =
      'I do not have a verified step-by-step guide or a count of rak’ahs for '
      'tahajjud on my shelf, so I will not give you a number from memory. '
      'For how to pray it and how many rak’ahs, a qualified scholar is the '
      'right person. In the app, the Huda guide on Witr and the night '
      'routine covers the night prayer, and Prayer Times shows tonight’s '
      'window.\n[GO:/huda]\n[GO:/prayer]';

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

  // ── The fixed replies, for the code that must not treat them as shelf ──

  static List<String> get fixedReplies => <String>[
        selfDescriptionReply,
        beginnerReply,
        ramadanPlanReply,
        tahajjudReply,
        hadithNumberDecline,
        clarifyReply,
        closestMatchNote,
        ..._variants,
        ..._rulingVariants,
      ];

  /// True when [answer] is (or contains) one of the fixed replies above, or
  /// the medical hand-off.
  static bool isFixed(String answer) {
    if (answer.contains('is a medical question, and your doctor')) return true;
    return fixedReplies.any(answer.contains);
  }
}
