/// How a question about a religious ruling is handled.
///
/// - [none]: not a ruling question.
/// - [general]: "what is the ruling on…": answered, with a footer that it is
///   not a fatwa and that schools differ.
/// - [personal]: "is MY marriage valid", "should I divorce": a ruling about
///   one person's case. Hādi does not answer these at all; it hands the
///   person to a qualified scholar.
enum RulingClass { none, general, personal }

abstract final class RulingGate {
  static final RegExp _topic = RegExp(
    r'\b(divorce|divorced|talaq|talaaq|khula|khul|faskh|custody|inherit\w*|'
    r'will and testament|wasiyyah|abortion|abort|euthanasia|mortgage|'
    r'riba|interest loan|kaffarah|kaffara|fidyah|nikah|mahr|dowry|iddah|'
    r'iddat|zihar|polygam\w*|second wife|temporary marriage|'
    r'mutah|surrogacy|ivf|organ donation|apostasy|murtad|takfir|'
    r'blasphemy|oath|vow|nadhr|loan|sworn|swore|wali|witness\w*|'
    r'married\s+without|marriage\s+without|'
    r'missed\s+(?:my\s+)?(?:\w+\s+)?(?:fasts?|prayers?|salah)|'
    r'(?:fasts?|prayers?|salah)\s+(?:i|we)\s+(?:have\s+|had\s+)?missed|'
    r'(?:make\s+up|catch\s+up|qada)\s+(?:on\s+)?(?:my\s+|the\s+)?'
    r'(?:missed\s+)?(?:fasts?|prayers?|salah)|'
    r'prayers?\s+for\s+years|'
    r'breaking my fast)\b',
    caseSensitive: false,
  );

  /// A state of the speaker's own body or life that a worship ruling turns
  /// on. Not a ruling topic by itself ("what is a period"); it is when it
  /// comes with the speaker and a yes/no question about themselves.
  static final RegExp _bodyState = RegExp(
    r'\b(period|periods|menses|menstru\w*|hayd|nifas|postpartum|pregnan\w*|'
    r'breastfeed\w*|nursing|lactating|nail\s*polish|nailpolish|'
    r'private\s+parts?|vomit\w*|threw\s+up|throw\s+up|nosebleed|'
    r'bleeding|blood|touched|married|engaged|fiance\w*|wife|husband)\b',
    caseSensitive: false,
  );

  /// Acts of worship. A question about "my prayer", "my fast" asking whether
  /// it is valid is about the speaker's own act.
  static final RegExp _worshipNoun = RegExp(
    r'\b(wudu|ghusl|fast|fasts|fasting|prayer|prayers|salah|zakat|hajj|'
    r'umrah|tawaf|sai|ihram)\b',
    caseSensitive: false,
  );

  /// "can I", "should I", "do I need": a yes/no question about the speaker.
  /// A question with how, what, where, when, which, why or who a few words
  /// before it asks for a method or a fact, not a verdict.
  static final RegExp _yesNoMe = RegExp(
    r"\b(?:can|could|may|should|must|do|does|did|am|will|would|have|has|"
    r"is|are)\s+(?:i|we)\b",
    caseSensitive: false,
  );
  static final RegExp _whLead = RegExp(
    r'\b(?:how|what|where|when|which|why|who)(?:\s+\w+){0,3}\s+$',
    caseSensitive: false,
  );

  /// "is it ok", "is it valid", "is my fast broken", "is that allowed",
  /// "permissible for me".
  static final RegExp _verdictAsk = RegExp(
    r"\bis\s+(?:it|this|that|my|our)\s+(?:\w+\s+)?(?:ok|okay|fine|alright|"
    r"valid|invalid|void|broken|accepted|allowed|permissible|permitted|"
    r"haram|halal|sinful|a\s+sin|enough|counted|nullified|ruined)\b|"
    r"\b(?:does|do|did|will)\s+(?:it|this|that|my|our)\s+(?:\w+\s+)?"
    r"(?:count|break|invalidate|nullify|ruin|affect)\b|"
    r"\b(?:what\s+is|whats)\s+(?:my|our)\s+status\b|"
    r"\b(?:permissible|allowed|permitted|halal|haram|lawful|valid|"
    r"obligatory|required|sinful|ok|okay)\s+(?:for|to)\s+(?:me|us)\b|"
    r"\b(?:ruling|fatwa|verdict)\s+(?:for|to)\s+(?:me|us)\b",
    caseSensitive: false,
  );

  /// "is my fast valid": the act is the speaker's own.
  static final RegExp _myActAsk = RegExp(
    r"\b(?:is|was|does|did|will)\s+(?:my|our)\s+(?:\w+\s+)?"
    r"(?:valid|invalid|void|broken|accepted|counted|count|break|nullified|"
    r"ruined|correct|ok|okay|complete|fine)\b|"
    r"\bdid\s+(?:i|we)\s+(?:break|invalidate|nullify|ruin)\b",
    caseSensitive: false,
  );

  static bool _askedYesNoAboutMe(String q) {
    for (final RegExpMatch m in _yesNoMe.allMatches(q)) {
      if (!_whLead.hasMatch(q.substring(0, m.start))) return true;
    }
    return _verdictAsk.hasMatch(q);
  }

  /// The speaker is in the sentence: "I", "we", "my", "me", "our".
  static final RegExp _speaker = RegExp(
    r"\b(?:i|we|my|our|me|us|myself)\b",
    caseSensitive: false,
  );

  /// Short forms written out ("im" -> "i am") so one pattern sees them all.
  static String _expand(String q) {
    return q
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAllMapped(
          RegExp(r"\b(i|we)'?(m|ve|d|ll|re)\b", caseSensitive: false),
          (Match m) {
            final String who = m.group(1)!;
            switch (m.group(2)!.toLowerCase()) {
              case 'm':
              case 're':
                return '$who am';
              case 've':
                return '$who have';
              case 'd':
                return '$who had';
              default:
                return '$who will';
            }
          },
        );
  }

  static final RegExp _personal = RegExp(
    r"\b(my|our)\s+(wife|husband|marriage|nikah|divorce|talaq|khula|faskh|"
    r"status|spouse|case|situation|father|mother|parents?|fasts?|wudu|"
    r"prayers?|salah|inheritance|loan|mortgage|oath|vow|child|son|"
    r"daughter)\b|"
    r"\b(should|can|could|must|may|do|did|am|have|will)\s+(i|we)\b|"
    r"\b(i|we)\s+(am|are|was|were|have|had|did|said|told|took|want\s+to|"
    r"wanna|need\s+to|plan\s+to|swore|promised|missed|skipped|broke|"
    r"forgot|owe|got|get|married|divorced|separated|left|touched|vomited|"
    r"ate|drank|slept|started|stopped|lost|found|borrowed|lent|paid)\b|"
    r"\bis\s+(it|my|our)\s+(valid|void|haram|halal|permissible|allowed)\b|"
    r"\bam\s+i\s+(still\s+)?(married|divorced|sinful|a\s+sinner|allowed)\b|"
    r"\b(?:permissible|allowed|permitted|halal|haram|lawful|valid|ok|okay)\s+"
    r"(?:for|to)\s+(?:me|us)\b",
    caseSensitive: false,
  );

  static final RegExp _generalAsk = RegExp(
    r"\b(ruling|rulings|fatwa|haram|halal|permissible|allowed|forbidden|"
    r"makruh|mustahabb|wajib|fard|sunnah or|is it a sin|is it sinful)\b",
    caseSensitive: false,
  );

  // Arabic and Urdu. A regex word boundary does not see Arabic letters as word
  // characters, so these use a look-behind for "not preceded by an Arabic
  // letter" instead.
  static const String _noArabicBefore = r'(?<![\u0600-\u06FF\u0750-\u077F])';

  /// Ruling topics: divorce, inheritance, vows, expiation, abortion, interest,
  /// making up missed prayers and fasts.
  static final RegExp _topicArabic = RegExp(
    '$_noArabicBefore'
    r'(?:طلاق|طلقت|ميراث|إرث|ارث|وراثت|نذر|كفارة|كفارہ|إجهاض|اجهاض|'
    r'ربا|قضاء\s+الصلاة|قضاء\s+الصوم|قضا\s+نماز|نماز\s+قضا|'
    r'فاتتني|فاتني)',
  );

  /// "Is my divorce valid": the speaker's own case, in Arabic or Urdu.
  static final RegExp _personalArabic = RegExp(
    '$_noArabicBefore'
    r'(?:طلاقي|زواجي|نذري|يميني|صلاتي|صيامي|زوجتي|زوجي|ابني|ابنتي|'
    r'يجوز\s+لي|فاتتني|فاتني|طلقت|میری|میرا|میرے|مجھے|میں)',
  );

  /// "What is the ruling on…" in Arabic or Urdu.
  static final RegExp _askArabic = RegExp(
    '$_noArabicBefore'
    r'(?:حكم|حكمه|فتوى|حلال|حرام|يجوز|جائز|ناجائز|حکم|فتویٰ|فتوی)',
  );

  /// A legal penalty asked about as a fact, about nobody in particular:
  /// "is the punishment for leaving Islam death?", "what is the penalty for
  /// apostasy". Never fires when the speaker is in the sentence (I, my, we),
  /// because a person afraid for themself is not asking a legal question.
  static final RegExp _legalPenalty = RegExp(
    r'\b(?:(?:punishment|punishments|punishable|penalty|penalties|sentence|execution|'
    r'executed|death\s+penalty|capital\s+punishment|hudud|hadd|stoned|'
    r'stoning|flogging|lashes|put\s+to\s+death|killed|killing)\b.{0,50}'
    r'\b(?:leaving\s+(?:islam|the\s+(?:religion|faith|deen))|leave\s+islam|'
    r'leaves\s+islam|left\s+islam|'
    r'apostasy|apostate|apostates|murtad|blasphemy|adultery|zina|theft|'
    r'stealing|homosexual\w*|disbelief|renounc\w*)|'
    r'(?:leaving\s+(?:islam|the\s+(?:religion|faith|deen))|leave\s+islam|'
    r'leaves\s+islam|apostasy|apostate|'
    r'apostates|murtad|blasphemy)\b.{0,50}\b(?:punishment|punishments|'
    r'penalty|penalties|punishable|death|executed|killed|sentence|hudud))',
    caseSensitive: false,
  );

  /// True for a third-person question about a legal penalty (see above).
  static bool isLegalPenaltyQuestion(String question) {
    final String q = _expand(question.toLowerCase());
    return _legalPenalty.hasMatch(q) && !_speakerIn(q);
  }

  /// "Give me the source" asks for a reference; it does not put the
  /// speaker's own case in the sentence.
  static final RegExp _askingForMe = RegExp(
    r'\b(?:give|show|tell|send|let|help|teach|get)\s+(?:me|us)\b',
  );

  static bool _speakerIn(String q) =>
      _speaker.hasMatch(q.replaceAll(_askingForMe, ' '));

  static RulingClass classify(String question) {
    final String q = _expand(question.toLowerCase());
    if (_legalPenalty.hasMatch(q) && !_speakerIn(q)) {
      return RulingClass.general;
    }
    final bool topic = _topic.hasMatch(q) || _topicArabic.hasMatch(q);
    final bool ask = _generalAsk.hasMatch(q) || _askArabic.hasMatch(q);
    // A worship state of the speaker's own ("I'm on my period, can I touch
    // the Qur'an?", "I am pregnant, can I fast?") with a yes/no question
    // about themselves is a ruling on one person's case, whatever the words.
    final bool ownState = _speaker.hasMatch(q) &&
        ((_bodyState.hasMatch(q) && _askedYesNoAboutMe(q)) ||
            (_worshipNoun.hasMatch(q) && _myActAsk.hasMatch(q)));
    // "I'm married and my wife left, what is my status".
    final bool maritalStatus =
        RegExp(r'\b(?:married|wife|husband|spouse|marriage)\b').hasMatch(q) &&
            RegExp(r'\b(?:my|our)\s+status\b').hasMatch(q);
    // "Can I pray during my period?" has a plain answer in the verified
    // texts on the shelf (the woman leaves the prayer in those days), so it
    // is answered; anything with details (touching the Qur'an, making up
    // what was missed) still goes to a scholar.
    final bool settledPeriod = RegExp(
          r'^(?:can|may|should|do)\s+i\s+(?:pray|fast|perform\s+salah)\b'
          r'[^,;.?]*\b(?:period|periods|menses|menstruation)\b[^,;.?]*\??$',
        ).hasMatch(q.trim()) &&
        !RegExp(r'\b(?:make\s+up|qada|missed|touch|read|recite)\b').hasMatch(q);
    if ((ownState && !settledPeriod) || maritalStatus) {
      return RulingClass.personal;
    }
    if (!topic && !ask) return RulingClass.none;
    final bool personal = _personal.hasMatch(q) || _personalArabic.hasMatch(q);
    if (personal && topic) return RulingClass.personal;
    // "Is my divorce valid" has a topic word; "should I do X" with only a
    // ruling-word is general unless it is clearly about "me".
    if (personal &&
        RegExp(
          r"\b(my|our)\b.*\b(valid|void|haram|halal|permissible|allowed)\b|"
          r"\b(am\s+i|should\s+i|can\s+i|do\s+i\s+have)\b|"
          r"\b(?:permissible|allowed|permitted|halal|haram|lawful|valid|ok|"
          r"okay)\s+(?:for|to)\s+(?:me|us)\b",
        ).hasMatch(q)) {
      return RulingClass.personal;
    }
    return RulingClass.general;
  }

  /// The footer added to a general answer.
  static const String generalFooter =
      'This is general information, not a fatwa. Schools of law differ, and '
      'a qualified scholar can apply it to a real situation.';

  /// The whole reply to a personal ruling question. No model is called.
  static String personalReply({String? schoolLabel}) {
    final String school = schoolLabel == null
        ? ''
        : ' Tell them you follow the $schoolLabel school so they can answer '
            'within it.';
    return 'This is a question about your own situation, and a ruling on a '
        'real case needs a qualified scholar who can ask you questions and '
        'hear the details. I will not guess at it, because a wrong answer '
        'here could affect your marriage, your family or your worship.$school\n\n'
        'Please ask a scholar you trust, your local imam, or a '
        'dar al-ifta service in your country. What I can do is explain the '
        'general rules and bring you the Qur’an and hadith that speak to '
        'the topic.';
  }

  static final RegExp _verdict = RegExp(
    r"\b(you\s+(must|have\s+to|need\s+to|are\s+required\s+to|owe|"
    r"should\s+(divorce|leave|separate|abort|stop\s+praying|repeat|redo|"
    r"make\s+up|pay|offer|perform|fast|stop|break))|"
    r"you\s+(?:do\s+not|don'?t)\s+(?:have\s+to|need\s+to|owe)|"
    r"you\s+(?:are|were)\s+(?:not\s+)?(?:allowed|permitted|obliged|"
    r"obligated|exempt|excused|required)|"
    r"your\s+(marriage|nikah|divorce|talaq|fast|wudu|prayer|oath|vow)\s+"
    r"(is|was|has\s+been|remains|does|did)\s+(not\s+)?(valid|invalid|void|"
    r"broken|annulled|complete|accepted|not\s+valid|count|counted|"
    r"took\s+place|stands|ruined|nullified)|"
    r"(?:that|this|it)\s+means\s+(?:that\s+)?(?:the\s+|your\s+)?"
    r"(?:divorce|talaq|marriage|nikah|fast|prayer|wudu|oath|vow)\s+"
    r"(?:has\s+|had\s+)?(?:took|taken|occurred|happened|stands|counts|"
    r"is\s+valid|is\s+invalid|is\s+void|is\s+broken)|"
    r"(?:it|this|that)\s+(?:was|is|has\s+been)\s+(?:invalid|void|broken|"
    r"nullified|annulled|ruined)|"
    r"it\s+is\s+(haram|forbidden|obligatory|mandatory)\s+for\s+you|"
    r"you\s+are\s+(still\s+|not\s+)?(married|divorced|sinful|a\s+sinner|"
    r"guilty|excused)|"
    r"(?:as\s+a\s+(?:mufti|scholar|sheikh|shaykh|imam),?\s+)?i\s+"
    r"(?:hereby\s+)?(?:issue|give|declare|rule)\b[^.]{0,40}\b(?:fatwa|"
    r"ruling|verdict)|"
    r"(?:stop|quit|skip|avoid)\s+(?:taking\s+)?(?:your\s+)?(?:medication|"
    r"medicine|meds|treatment|insulin|pills)|"
    r"(?:shias?|sunnis?|ahmadis?|qadianis?|barelvis?|deobandis?|salafis?|"
    r"wahhabis?|sufis?|ibadis?)\s+(?:are|is)\s+(?:not\s+(?:real\s+|true\s+)?"
    r"muslims?|kafirs?|disbelievers|misguided|deviants?|heretics?|"
    r"mushriks?|going\s+to\s+hell))\b",
    caseSensitive: false,
  );

  /// Replaces any sentence in a live reply that gives a verdict on the
  /// person's own case. Returns the cleaned text and whether it changed.
  static ({String text, bool changed}) filterLive(String text) {
    final List<String> parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    bool changed = false;
    final List<String> kept = <String>[];
    for (final String s in parts) {
      if (_verdict.hasMatch(s)) {
        changed = true;
        continue;
      }
      kept.add(s);
    }
    if (!changed) return (text: text, changed: false);
    final String body = kept.join(' ').trim();
    return (
      text: '$body\n\nFor a ruling on your own situation, please ask a '
          'qualified scholar.'.trim(),
      changed: true,
    );
  }
}
