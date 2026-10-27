import '../../sakina/domain/crisis_detector.dart';
import 'hadi_finder.dart';
import 'hadi_routing.dart';

/// Replies Hadi composes ONLY from lines the app already shows elsewhere
/// (the Fasting guide, the Ramadan Nights guide, the New Muslim path, the
/// Wasia Academy, the Nikah guide, "How we handle religious content"), plus
/// buttons to the screens those lines live on. Every quoted line is copied
/// word for word from that screen; test/hadi_round2_test.dart checks the
/// quotes against the app's own files so they cannot drift. Nothing here is
/// a ruling, a hadith or a du'a written for this file.
///
/// Where the app has no verified text (tahajjud steps, how the schools of
/// law differ), the reply says so in plain words in the chat itself and
/// sends the person to the nearest real content; the drafts the owner
/// needs to approve are in docs/content_needed/.
///
/// Pure Dart, no Flutter, so it is tested without a widget tree.
abstract final class HadiExplain {
  static String _norm(String s) => CrisisDetector.normalize(s);

  static const String _lead =
      r'(?:(?:hi|hello|hey|salam|ok|okay|so|please|hadi|can\s+you|could\s+you|'
      r'would\s+you|will\s+you|kindly|just)\s+)*';
  static const String _trail =
      r'(?:\s+(?:please|pls|simply|briefly|in\s+simple\s+words|'
      r'in\s+simple\s+terms|in\s+short|for\s+me|to\s+me|for\s+beginners|'
      r'for\s+a\s+beginner|hadi|in\s+islam))*';

  // ── Why Muslims fast, what Ramadan is ────────────────────────────────

  static final RegExp _fastingWhat = RegExp(
    '^$_lead(?:'
    r'why\s+(?:do|did|should|must|are|have)\s+(?:muslims?|we|people|i|you|they|'
    r'believers)\s+(?:have\s+to\s+|need\s+to\s+|must\s+)?(?:fast|fasting|'
    r'observe\s+ramadan|keep\s+ramadan|keep\s+fasts?)|'
    r'why\s+(?:is|does)\s+(?:fasting|ramadan)\s+(?:so\s+)?(?:important|special|'
    r'obligatory|required|matter|matters)|'
    r'why\s+(?:fast|fasting)(?:\s+in\s+ramadan)?|'
    r'what\s+(?:is|are)\s+(?:the\s+)?(?:point|purpose|reason|reasons|wisdom|'
    r'meaning)\s+(?:of|behind|for)\s+(?:fasting|ramadan)|'
    r'(?:what|whats)\s+(?:is\s+)?(?:ramadan|fasting)(?:\s+and\s+how\s+'
    r'(?:does\s+)?(?:the\s+)?(?:fasting\s+)?(?:work|works))?|'
    r'how\s+(?:does|do)\s+(?:ramadan|fasting)\s+work|'
    r'how\s+do\s+(?:muslims?|people)\s+fast|'
    r'what\s+happens\s+(?:in|during)\s+ramadan|'
    r'(?:tell\s+me|teach\s+me|explain|describe)\s+(?:about\s+|to\s+me\s+)?'
    r'(?:ramadan|fasting)|'
    r'(?:ramadan|fasting)\s+(?:explained|101|basics)|'
    r'(?:the\s+)?basics\s+of\s+(?:ramadan|fasting)'
    ')$_trail\$',
  );

  static final RegExp _funWord = RegExp(
    r'\b(?:interesting|fun|cool|amazing|surprising|neat)\b',
  );
  static final RegExp _ramadanWord = RegExp(r'\b(?:ramadan|ramadhan|fasting)\b');

  static bool asksWhyFast(String question) =>
      _fastingWhat.hasMatch(_norm(question));

  /// "Tell me something interesting about Ramadan".
  static bool asksRamadanInteresting(String question) {
    final String n = _norm(question);
    return _funWord.hasMatch(n) &&
        _ramadanWord.hasMatch(n) &&
        n.split(' ').length <= 10;
  }

  static const String fastingReply =
      'Fasting in Ramadan is the fourth pillar of Islam. The app’s Fasting '
      'guide describes it as “From dawn to sunset, and what breaks the '
      'fast”.\n\n'
      'Why: the Qur’an gives the reason in its first words on it: “O you '
      'who have believed, decreed upon you is fasting as it was decreed '
      'upon those before you that you may become righteous” '
      '(Qur’an 2:183).\n\n'
      'How it works, in the guide’s words: “Take suhoor, for in the suhoor '
      'there is blessing” (Sahih al-Bukhari 1923), so suhoor is that '
      'pre-dawn meal. What breaks the fast is eating, drinking, and '
      'marital relations (Qur’an 2:187). Illness and travel are excused, '
      'with an equal number of days made up later (Qur’an 2:184). Ramadan '
      'begins by sighting the moon: “start fasting on seeing the crescent of '
      'Ramadan and stop on seeing the crescent of Shawwal” (Sahih '
      'al-Bukhari 1909).\n\n'
      'For your own case (health, travel, pregnancy), please ask a '
      'qualified scholar. The whole guide is below.'
      '\n[GO:/huda/guide?id=huda-fasting]\n[GO:/ramadan]';

  static const String ramadanInterestingReply =
      'Some things from the Ramadan Nights guide in this app, in its own '
      'words:\n\n'
      '“Jibril met the Prophet ﷺ every night of Ramadan and they reviewed '
      'the Qur’an” (Sahih al-Bukhari 6).\n\n'
      'And of how he was in that month, the guide says “he was at his most '
      'generous then” (Sahih al-Bukhari 6): the hadith likens his generosity '
      'to a free wind, the strong unrestrained wind.\n\n'
      'And Laylat al-Qadr is “better than a thousand months” (Qur’an 97:3), '
      'in the odd nights of the last ten.\n\n'
      'If you want the plain basics of why and how Muslims fast, ask me '
      '“Why do Muslims fast?”'
      '\n[GO:/huda/guide?id=huda-taraweeh]\n[GO:/huda/guide?id=huda-fasting]';

  // ── Tahajjud ─────────────────────────────────────────────────────────

  static const String tahajjudReply =
      'The app has a Tahajjud guide: what the Qur’an says about the night '
      'prayer, the hadith on the last third of the night, praying in pairs, '
      'beginning with two short rak’ahs, and Aisha’s report of the '
      'Prophet’s ﷺ own night prayer. Every reference in it was checked '
      'against the Qur’an text in the app and sunnah.com, but it is marked '
      'scholar review needed. One line from it: “the most excellent prayer '
      'after what is prescribed is prayer during the night” '
      '(Sahih Muslim 1163).\n\n'
      'I will not give you a rak’ah count or a method from memory: the '
      'guide reports what the sources say and leaves the schools’ views to '
      'a qualified teacher. The Witr and night guide has the witr and the '
      'qunut, and Prayer Times shows tonight’s tahajjud '
      'window.\n[GO:/huda/guide?id=huda-tahajjud]\n[GO:/prayer]';

  // ── The schools of law ───────────────────────────────────────────────

  static final RegExp _schoolName = RegExp(
    r'\b(?:madhhabs?|madhabs?|mazhabs?|schools?\s+of\s+(?:law|fiqh|thought)|'
    r'fiqh\s+schools?|four\s+schools|hanafi|hanafis|shafii|shafiis|maliki|'
    r'malikis|hanbali|hanbalis)\b',
  );
  static final RegExp _schoolAsk = RegExp(
    r'\b(?:differ\w*|difference\w*|compar\w*|versus|vs|between|disagree\w*|'
    r'what\s+(?:is|are)|whats|name|list|which|explain|tell\s+me|who\s+are)\b',
  );

  static bool asksSchools(String question) {
    final String n = _norm(question);
    if (!_schoolName.hasMatch(n) || !_schoolAsk.hasMatch(n)) return false;
    // A question about one practice ("is it fard in the hanafi school") is
    // still a school question; a ruling about the person's own case never
    // reaches here (the ruling gate answers it first).
    return n.split(' ').length <= 14;
  }

  static const String schoolsReply =
      'There are four major schools of fiqh: Hanafi, Maliki, Shafi’i, and '
      'Hanbali. The four schools are valid paths to the same truth. '
      'Differences between qualified scholars on questions open to ijtihad '
      'are recognised as legitimate, and Muslims are asked to be gentle '
      'with each other about them. A layperson should follow one school '
      'consistently under a qualified teacher.\n\n'
      'The app has a short guide, The Four Schools: How They Differ, with '
      'one worked example (the hands in prayer) and the sources it comes '
      'from. It is marked scholar review needed.\n\n'
      'What I cannot do: tell you how the schools differ on any other '
      'point. My shelf holds no verified text for any single school, and I '
      'will not state a school’s position from memory. Please ask a '
      'qualified scholar of your school, or your local masjid; Our Sources '
      'lists one. In the More options menu at the top of this chat, “Your '
      'school of law” lets me name your school when I hand you to a '
      'scholar.\n[GO:/huda/guide?id=huda-madhhab-overview]\n[GO:/sources]';

  // ── How Hadi works, who reviewed it ──────────────────────────────────

  static final RegExp _reviewers = RegExp(
    r'\b(?:who|scholars?|imams?|muftis?|sheikhs?|shaykhs?|experts?|anyone|'
    r'anybody|someone|somebody|ulema|ulama)\b',
  );
  static final RegExp _reviewVerb = RegExp(
    r'\b(?:review\w*|check\w*|verif\w*|approv\w*|vet\w*|audit\w*|proofread|'
    r'endors\w*|certif\w*|authenticat\w*|validat\w*|vouch\w*|wrote|written|'
    r'authored|looked\s+at)\b',
  );
  static final RegExp _reviewTarget = RegExp(
    r'\b(?:app|answers?|content|you|hadi|your|ar\s+rayaan|rayaan|'
    r'application|information|replies|responses)\b',
  );

  static final RegExp _howItWorks = RegExp(
    r'\b(?:'
    r'how\s+(?:do|does|did)\s+(?:you|hadi)\s+(?:work|answer|know|find|get|'
    r'decide|come\s+up)|'
    r'where\s+(?:do|does)\s+(?:your|hadis?)\s+(?:answers?|information|'
    r'knowledge|content)\s+come\s+from|'
    r'how\s+(?:are|were)\s+(?:your|the)\s+answers\s+(?:made|written|'
    r'produced|generated|checked|sourced)|'
    r'(?:can|should|could)\s+i\s+trust\s+(?:you|hadi|this\s+app|your\s+'
    r'answers|the\s+answers)|'
    r'are\s+(?:your|the)\s+answers\s+(?:reliable|accurate|correct|authentic|'
    r'trustworthy|verified|checked|reviewed|sourced|real|true)|'
    r'(?:are|is)\s+(?:you|hadi)\s+(?:an?\s+)?(?:ai|bot|robot|chatbot|'
    r'machine|real\s+person|human|scholar|mufti|imam|sheikh|shaykh)|'
    r'do\s+you\s+(?:make\s+things\s+up|make\s+up\s+(?:answers|things)|'
    r'invent\s+(?:answers|things|sources)|hallucinate|lie)|'
    r'what\s+are\s+your\s+sources|'
    r'is\s+this\s+app\s+(?:reliable|trustworthy|authentic|accurate)'
    r')\b',
  );

  static bool asksHowIWork(String question) {
    final String n = _norm(question);
    if (_howItWorks.hasMatch(n)) return true;
    return n.split(' ').length <= 22 &&
        _reviewers.hasMatch(n) &&
        _reviewVerb.hasMatch(n) &&
        _reviewTarget.hasMatch(n);
  }

  static const String howIWorkReply =
      'Here is how I work, from what the app itself says about it. I am '
      'Hādi, a study aid inside the app, not a scholar or a mufti.\n\n'
      'Who has reviewed this: no one yet. How we handle religious content '
      'says: “Scholar review needed. No named scholar has reviewed this '
      'app yet. We check every citation we can, we say so when we cannot, '
      'and we will name a reviewer here only once one has agreed to be '
      'named.”\n\n'
      'How I answer: from a shelf of answers written by hand and from the '
      'Qur’an and hadith library in the app. The Arabic and the translation '
      'under an answer come from that library, because “Qur’an is never '
      'quoted from memory, and never produced by an AI.” When I have no '
      'verified answer I say so instead of making one up. If you add your '
      'own AI account (optional), a model writes the reply and the app '
      'removes any verse, hadith or quotation it cannot check against the '
      'library.\n\n'
      'Rulings: “The app does not issue fatwas, and an AI answer is never a '
      'fatwa.” For a ruling, I send you to a qualified scholar. I do not '
      'give a hadith or its number from memory; ask about a hadith on its '
      'own and I will say whether my shelf holds it.\n\n'
      'Cost: everything in this app, including me, is free today. Nothing '
      'asks for a card.\n\n'
      'Our Sources lists every text, translation and reciter.'
      '\n[GO:/sources]';

  // ── A legal penalty asked about as a fact ────────────────────────────

  static const String legalReply =
      'That is a question about a legal ruling, and I do not have a '
      'verified answer for it on my shelf. I will not give a verdict from '
      'memory: scholars treat it in detail, with conditions and with '
      'differing views, and a one-line answer from me could mislead. A '
      'qualified scholar is the right person, and Our Sources lists one. If '
      'you are asking because of something that is happening to you, tell '
      'me, and I will listen.\n[GO:/sources]\n[GO:/academy/qa]';

  // ── Stories ──────────────────────────────────────────────────────────

  static final RegExp _storyAsk = RegExp(
    '^$_lead(?:'
    r'(?:tell|read|give|share|narrate|say)\s+(?:me|us)\s+(?:a|an|any|one|'
    r'another|some|the)?\s*(?:short\s+|kids?\s+|good\s+|islamic\s+|nice\s+|'
    r'bedtime\s+|simple\s+|new\s+|different\s+|fun\s+)*(?:story|stories)|'
    r'(?:i\s+want|i\s+would\s+like|id\s+like|we\s+want|can\s+i\s+have|'
    r'can\s+i\s+get)\s+(?:to\s+hear\s+|to\s+read\s+)?(?:a|an|some|one)\s+'
    r'(?:short\s+|kids?\s+|good\s+|islamic\s+|nice\s+|bedtime\s+|simple\s+)*'
    r'(?:story|stories)|'
    r'(?:a\s+)?(?:short\s+|kids?\s+|bedtime\s+|islamic\s+)*(?:story|stories)'
    r'|story\s+time'
    ')(?:\\s+for\\s+(?:kids|children|my\\s+(?:kid|kids|child|children|son|'
    'daughter)))?$_trail\$',
  );

  static bool asksForStory(String question) =>
      _storyAsk.hasMatch(_norm(question));

  static const String storyReply =
      'I do not tell stories from memory, because I only share what is in '
      'the app’s sources. The Stories section has them: Stories of the '
      'Prophets, Women of Islam, The Companions, Tales of the Ummah and '
      'more. Tap Stories and pick one to read. Stories School turns the '
      'same stories into lessons with a family question.'
      '\n[GO:/stories]\n[GO:/academy/stories]';

  // ── Marriage ─────────────────────────────────────────────────────────

  static final RegExp _marriageAsk = RegExp(
    '^$_lead(?:'
    r'(?:what|whats)\s+(?:should|do|does|can|must)\s+(?:i|we|you|one|a\s+'
    r'person)?\s*(?:need\s+to\s+)?know\s+(?:about|on)\s+(?:islamic\s+)?'
    r'(?:marriage|nikah|nikkah)|'
    r'(?:tell|teach)\s+me\s+(?:about\s+)?(?:islamic\s+)?(?:marriage|nikah|'
    r'nikkah)|'
    r'explain\s+(?:islamic\s+)?(?:marriage|nikah|nikkah)|'
    r'(?:marriage|nikah|nikkah)\s+in\s+islam|'
    r'islamic\s+(?:marriage|nikah|wedding)|'
    r'(?:how\s+(?:does|do)\s+)?(?:islamic\s+)?(?:marriage|nikah|nikkah)'
    r'(?:\s+work|\s+basics)?|'
    r'(?:the\s+)?(?:basics|guide|rules|requirements|conditions|pillars)\s+'
    r'(?:of|for)\s+(?:a\s+)?(?:valid\s+)?(?:islamic\s+)?(?:marriage|nikah|'
    r'nikkah)|'
    r'(?:what|whats)\s+(?:is|are)\s+(?:the\s+)?(?:conditions|requirements|'
    r'rules|pillars)\s+(?:of|for)\s+(?:a\s+)?(?:valid\s+)?(?:marriage|'
    r'nikah|nikkah)|'
    r'(?:what|whats)\s+(?:is\s+)?(?:a\s+)?(?:marriage|nikah|nikkah)\s+'
    r'(?:in\s+islam)?|'
    r'marriage\s+advice|'
    r'(?:i\s+)?(?:want|plan|hope|wish)\s+to\s+(?:get\s+married|marry)'
    r'(?:\s+(?:soon|someday|one\s+day|this\s+year|next\s+year))?'
    r'(?:\s+(?:what|how)\s+(?:should|do|can)\s+(?:i|we)\s+(?:need\s+to\s+)?'
    r'(?:know|do|learn|start))?'
    ')$_trail\$',
  );

  static bool asksAboutMarriage(String question) =>
      _marriageAsk.hasMatch(_norm(question));

  static const String marriageReply =
      'Marriage has its own guide in this app, Marriage — The Nikah. It '
      'covers the command to marry, consent as the core condition, the '
      'sermon, the guardian and witnesses, the mahr, and the spirit of the '
      'home. Family Life School covers marriage and the home day to day: '
      'mercy between spouses and the trust of children.\n\n'
      'For your own situation (a proposal, a contract, a dispute), a '
      'qualified scholar is the right person; Our Sources lists one.'
      '\n[GO:/huda/guide?id=huda-nikah]\n[GO:/academy/family-life]';

  // ── The nearest masjid ───────────────────────────────────────────────

  static final RegExp _masjidWord = RegExp(
    r'\b(?:masjid|masjids|masajid|mosque|mosques|musalla|jamaat|'
    r'prayer\s+(?:place|places|space|spaces|room|rooms|hall|halls))\b',
  );
  static final RegExp _halalWord = RegExp(r'\bhalal\b');
  static final RegExp _nearAsk = RegExp(
    r'\b(?:nearest|nearby|closest|near\s+me|near\s+here|near\s+us|'
    r'close\s+to\s+me|close\s+by|around\s+me|around\s+here|in\s+my\s+'
    r'(?:area|city|town|neighbou?rhood)|local|find|locate|'
    r'where\s+(?:is|are|can)|directions?)\b',
  );
  static final RegExp _jumuahWord =
      RegExp(r'\b(?:jumuah|jummah|jumah|jumua|jumaa|jumma|juma)\b');
  static final RegExp _fridayPrayer =
      RegExp(r'\bfriday\s+(?:prayers?|salah|salat|namaz|khutbah|sermon)\b');
  static final RegExp _timeAsk =
      RegExp(r'\b(?:times?|timings?|schedule|when)\b');
  static final RegExp _nearOnly = RegExp(
    r'\b(?:nearest|nearby|closest|near\s+me|near\s+here|near\s+us|'
    r'close\s+to\s+me|close\s+by|around\s+me|around\s+here|in\s+my\s+'
    r'(?:area|city|town|neighbou?rhood))\b',
  );
  static const List<String> _jumuahSpellings = <String>[
    'jumuah',
    'jummah',
    'jumah',
    'jumua',
    'jumaa',
    'jumma',
    'juma',
  ];

  /// True when the question names Friday prayer, even badly spelled by
  /// voice or thumb ("jump near me"): a one-letter slip is believed only
  /// when the question also says "near me" or "nearby".
  static bool _namesFriday(String n) {
    if (_jumuahWord.hasMatch(n) || _fridayPrayer.hasMatch(n)) return true;
    if (!_nearOnly.hasMatch(n)) return false;
    for (final String w in n.split(' ')) {
      for (final String v in _jumuahSpellings) {
        if (HadiFinder.near(w, v)) return true;
      }
    }
    return false;
  }

  static bool asksNearestMasjid(String question) {
    final String n = _norm(question);
    if (n.split(' ').length > 16) return false;
    final bool near = _nearAsk.hasMatch(n);
    if (_masjidWord.hasMatch(n) && near) return true;
    if (_namesFriday(n) && (near || _timeAsk.hasMatch(n))) return true;
    // "halal food near me", "halal restaurant nearby".
    return _halalWord.hasMatch(n) && _nearOnly.hasMatch(n);
  }

  static String masjidReply(String question) {
    final String n = _norm(question);
    final bool friday = _namesFriday(n);
    final bool food = _halalWord.hasMatch(n) && !_masjidWord.hasMatch(n);
    final String jumuah = friday
        ? ' The time of Friday prayer is set by your own masjid, so please '
            'ask them; Prayer Times has a Friday row where you can set '
            'your masjid’s time.'
        : '';
    return 'I cannot see where you are, so I cannot name the nearest '
        'masjid${food ? ' or halal restaurant' : ''}. The Masajid screen '
        'searches for mosques and halal food near you, and it needs an '
        'internet connection.$jumuah'
        '\n[GO:/masajid]${friday ? '\n[GO:/prayer]' : ''}';
  }

  // ── The set of replies, for the code that must not treat them as shelf

  static List<String> get fixedReplies => <String>[
        fastingReply,
        ramadanInterestingReply,
        tahajjudReply,
        schoolsReply,
        howIWorkReply,
        legalReply,
        storyReply,
        marriageReply,
      ];

  /// True when [answer] is (or contains) one of the composed replies, or the
  /// start of the masjid reply.
  static bool isFixed(String answer) {
    if (answer.contains('I cannot see where you are, so I cannot name the '
        'nearest masjid')) {
      return true;
    }
    return fixedReplies.any(answer.contains);
  }

  static final RegExp _tokens = RegExp(r'\s*\[GO:[^\]]*\]');

  /// True when [clean], a reply with its [GO:] tokens already removed, is one
  /// of the composed replies (or the beginner reply), so the controller can
  /// limit the cards printed under it.
  static bool isComposed(String clean) {
    String strip(String s) => s.replaceAll(_tokens, '').trim();
    final String c = strip(clean);
    return <String>[...fixedReplies, HadiRouting.beginnerReply]
        .any((String r) => c.contains(strip(r)));
  }

  /// The reply for [question], or null when none of the above applies. Run
  /// after the person-specific checks (crisis, grief, ruling gate) and
  /// before the shelf is searched.
  static String? replyFor(String question) {
    if (asksHowIWork(question)) return howIWorkReply;
    if (asksSchools(question)) return schoolsReply;
    if (asksRamadanInteresting(question)) return ramadanInterestingReply;
    if (asksWhyFast(question)) return fastingReply;
    if (asksAboutMarriage(question)) return marriageReply;
    if (asksForStory(question)) return storyReply;
    if (asksNearestMasjid(question)) return masjidReply(question);
    return null;
  }
}
