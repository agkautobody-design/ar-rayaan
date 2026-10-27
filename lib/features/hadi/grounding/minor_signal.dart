/// Hādi's live answers are for adults. When someone says they are under 18,
/// Hādi does not carry on a live conversation: it gives a short, kind, fixed
/// reply and points to a trusted adult and to the children's help lines.
///
/// The age is read from the person's own words only, and is never stored.
abstract final class MinorSignal {
  /// Words that name an age from five to seventeen.
  static const Map<String, int> _spoken = <String, int>{
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
  };

  static const String _spokenAlt =
      'five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|'
      'fifteen|sixteen|seventeen';

  /// The speaker introducing their own age: "I am", "I'm", "im", "i m", "I
  /// turned", "I just turned", "I'll be", "my age is", "my age:".
  static const String _lead =
      r"(?:\bi\s*am|\bi\s*m\b|\bi'm|\bim\b|"
      r"\bi\s+(?:just\s+|have\s+just\s+|'ve\s+just\s+)?turn(?:ed|s)?|"
      r"\bi(?:'ll|\s+will)\s+(?:be|turn)|"
      r"\bmy\s+age\s*(?:is|:|-|=)?)";

  /// Small words that may sit between the lead and the number.
  static const String _filler =
      r"(?:\s+(?:just|only|about|almost|nearly|still|now|currently|"
      r"actually|really|a|an))*";

  /// A number from 1 to 99, or a spelled-out age from five to seventeen.
  static final RegExp _selfAge = RegExp(
    '$_lead$_filler\\s*(?:(\\d{1,2})(?!\\d)|($_spokenAlt)\\b)',
    caseSensitive: false,
  );

  /// What may follow the number when it is NOT an age: a unit, a quantity,
  /// a time of day, a measure. "I'm 17 hours into the fast", "I am 12 weeks
  /// pregnant", "I'm 5 minutes away".
  static final RegExp _notAnAge = RegExp(
    r"^\s*(?:%|percent|per\b|seconds?\b|secs?\b|minutes?\b|mins?\b|"
    r"hours?\b|hrs?\b|days?\b|weeks?\b|wks?\b|months?\b|mos?\b|"
    r"km\b|kms\b|miles?\b|mph\b|kph\b|metres?\b|meters?\b|cm\b|kg\b|"
    r"lbs?\b|pounds?\b|feet\b|foot\b|ft\b|rak\w*|times?\b|o'?clock|"
    r"a\.?m\b|p\.?m\b|people\b|persons?\b|of\s+us\b|ayat\b|ayah\b|"
    r"verses?\b|surahs?\b|pages?\b|juz\b|cups?\b|dates?\b|dollars?\b|"
    r"pounds?\b|euros?\b|rupees?\b|dinars?\b|st\b|nd\b|rd\b|th\b|"
    r"[:./]\d|,\d)",
    caseSensitive: false,
  );

  /// "I'm 15 years into this", "I'm 20 years married": a count of years
  /// that is about something other than the speaker's age.
  static final RegExp _yearsOfSomething = RegExp(
    r"^\s*(?:years?|yrs?)\s+(?:into|since|after|ago|married|in\b|at\b|with\b|"
    r"to\b|before|of\s+(?!age))",
    caseSensitive: false,
  );

  /// "13f", "13M": the usual age-and-gender shorthand.
  static final RegExp _ageGender = RegExp(
    r"(?:^|[.!?,;]\s*|\s)(\d{1,2})[fm]\b(?=\s*(?:$|[.,!?;]|here\b|and\b|"
    r"muslim\b|new\b))",
    caseSensitive: false,
  );

  /// "age 14", "age: 14" at the start of a message or sentence.
  static final RegExp _bareAge = RegExp(
    r"(?:^|[.!?;]\s*)age\s*(?:is|:|-|=)?\s*(\d{1,2})(?!\d)",
    caseSensitive: false,
  );

  static int? _ageOf(RegExpMatch m) {
    final String? digits = m.group(1);
    if (digits != null) return int.tryParse(digits);
    final String? word = m.groupCount >= 2 ? m.group(2) : null;
    return word == null ? null : _spoken[word.toLowerCase()];
  }

  static final RegExp _yo = RegExp(
    r"\b(\d{1,2})\s*(?:y/?o|yo|years?\s+old|yrs?\s+old)\b",
    caseSensitive: false,
  );
  static final RegExp _words = RegExp(
    r"\b(?:i\s*am|i'm|im|i\s*m)\s+(?:still\s+)?(?:a\s+)?(?:kid|child|minor|"
    r"teen|teenager|schoolboy|schoolgirl|under\s*18|underage|not\s+18)\b|"
    r"\b(?:i\s*am|i'm|im|i\s*m)\s+in\s+(?:grade|year|class)\s+(?:[1-9]|1[0-2])\b|"
    r"\b(?:i\s*am|i'm|im|i\s*m)\s+in\s+(?:middle|primary|elementary|high)\s+school\b|"
    r"\bmy\s+parents\s+(?:don'?t|do\s+not)\s+let\s+me\b",
    caseSensitive: false,
  );

  /// A school year the speaker is in: "8th grade", "seventh grade", "year
  /// 9", "class 6".
  static const String _gradeNumber =
      r"(?:[1-9]|1[0-2]|one|two|three|four|five|six|seven|eight|nine|ten|"
      r"eleven|twelve)";
  static const String _gradeOrdinal =
      r"(?:[1-9](?:st|nd|rd|th)|1[0-2]th|first|second|third|fourth|fifth|"
      r"sixth|seventh|eighth|ninth|tenth|eleventh|twelfth)";
  static const String _gradeRef =
      '(?:$_gradeOrdinal[\\s-]+(?:grade|class|year|form|std)\\b|'
      '(?:grade|year|class|form|std|standard)\\s+$_gradeNumber\\b)';

  /// "I'm in 8th grade", "I'm a student in year 9", "I am in seventh
  /// grade": first person, in a school year. A parent's "my son is in 8th
  /// grade" has no first-person subject right before it, so it is not caught.
  static final RegExp _inGrade = RegExp(
    r"(?:\bi\s*am|\bi\s*m\b|\bi'm|\bim\b)\s+(?:[a-z]+\s+){0,3}?"
    '(?:in|entering|starting|doing|finishing)\\s+(?:the\\s+)?$_gradeRef',
    caseSensitive: false,
  );

  /// "my teacher in class 6 told me": a child describing their own class.
  static final RegExp _myClassTeacher = RegExp(
    r"\bmy\s+(?:class\s+)?(?:teacher|classmates?)\s+(?:in|of|from|at)\s+"
    '(?:the\\s+)?$_gradeRef',
    caseSensitive: false,
  );

  /// "I go to primary school", "I'm still in school".
  static final RegExp _inSchool = RegExp(
    r"\bi\s+(?:go|goes|attend|am\s+going|'m\s+going)\s+to\s+(?:a\s+)?"
    r"(?:primary|elementary|middle|junior|secondary)\s+school\b|"
    r"(?:\bi\s*am|\bi\s*m\b|\bi'm|\bim\b)\s+still\s+in\s+"
    r"(?:high\s+|middle\s+|primary\s+|secondary\s+|elementary\s+)?school\b",
    caseSensitive: false,
  );

  /// "my 5 year old", "my son is 8 years old": a possessive up to a few
  /// words before the number, with a copula allowed. Anchored to the end of
  /// the text before the number, so it only sees what is right in front.
  static final RegExp _possessiveBefore = RegExp(
    r"\b(?:my|our|his|her|their|your)\s+(?:[a-z'’,-]+\s+){0,3}"
    r"(?:(?:is|was|turned|turns|just\s+turned)\s+)?$",
    caseSensitive: false,
  );

  /// First-person words: if the possessive stretch also names the speaker
  /// ("my friend and I are 15"), the age is theirs.
  static final RegExp _firstPerson = RegExp(
    r"\b(?:i|me|we|us|im|i'm|i’m|myself)\b",
    caseSensitive: false,
  );

  /// "me and my sister are 15": the speaker is part of the pair.
  static final RegExp _andMe = RegExp(
    r"\b(?:me|i|we|us)\s+(?:and|&)\s+$",
    caseSensitive: false,
  );

  /// "I have a 6 year old", "teach a 10 year old": an article after a verb
  /// that talks about another child. "as a 13 year old" and "I'm just a 14
  /// year old" are NOT in this list on purpose: those are the speaker.
  static final RegExp _articleAfterVerb = RegExp(
    r"\b(?:teach|teaching|taught|tell|telling|told|met|know|knew|have|has|"
    r"had|saw|see|seen|adopt|adopted|raising|raise|babysit|babysitting)"
    r"\s+(?:a|an|the)\s+$",
    caseSensitive: false,
  );

  /// A sentence that starts "A 10 year old girl asked me ...": about someone
  /// else only when a third-person verb follows within a few words.
  static final RegExp _sentenceStartArticle = RegExp(
    r"(?:^|[.!?]\s+)(?:a|an|the)\s+$",
    caseSensitive: false,
  );
  static final RegExp _thirdPersonVerb = RegExp(
    r"^(?:\s+\w+){0,3}\s+(?:asked|told|came|said|wants?|doesn'?t|does\s+not|"
    r"refuses?|won'?t|keeps?|is\s+asking)\b",
    caseSensitive: false,
  );

  /// True when the "N years old" at [m] is said about someone else.
  static bool _aboutSomeoneElse(String text, RegExpMatch m) {
    final String before = text.substring(0, m.start);
    final RegExpMatch? poss = _possessiveBefore.firstMatch(before);
    if (poss != null &&
        !_firstPerson.hasMatch(poss.group(0)!) &&
        !_andMe.hasMatch(before.substring(0, poss.start))) {
      return true;
    }
    if (_articleAfterVerb.hasMatch(before)) return true;
    if (_sentenceStartArticle.hasMatch(before) &&
        _thirdPersonVerb.hasMatch(text.substring(m.end))) {
      return true;
    }
    return false;
  }

  static bool isMinor(String text) {
    final String t = text.replaceAll('’', "'").replaceAll('‘', "'");
    for (final RegExpMatch m in _selfAge.allMatches(t)) {
      final int? n = _ageOf(m);
      if (n == null || n < 5 || n >= 18) continue;
      final String after = t.substring(m.end);
      if (_notAnAge.hasMatch(after) || _yearsOfSomething.hasMatch(after)) {
        continue;
      }
      return true;
    }
    for (final RegExpMatch m in _ageGender.allMatches(t)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n != null && n >= 5 && n < 18) return true;
    }
    for (final RegExpMatch m in _bareAge.allMatches(t)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n != null && n >= 5 && n < 18) return true;
    }
    for (final RegExpMatch m in _yo.allMatches(t)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n == null || n < 5 || n >= 18) continue;
      if (_aboutSomeoneElse(t, m)) continue;
      return true;
    }
    return _words.hasMatch(t) ||
        _inGrade.hasMatch(t) ||
        _myClassTeacher.hasMatch(t) ||
        _inSchool.hasMatch(t);
  }

  static const String firstReply =
      'As-salamu alaikum, and thank you for telling me. My live answers are '
      'for adults, so the best thing is to ask a parent, a teacher or an '
      'imam you trust. For children, Wasia in the Academy teaches '
      'step by step, and she is made for you.\n\n'
      'If anything is worrying you, or someone is making you feel unsafe, '
      'please tell a trusted adult today (a parent if it feels safe, a '
      'teacher, a school counsellor, or a child helpline). You choose who. '
      'The help lines below are for young people.';

  static const List<String> followUps = <String>[
    'I am glad you are here. A parent or teacher is the best person to '
        'ask about this. Wasia in the Academy is there for your learning, '
        'and the lines below are free if you ever need to talk.',
    'That is a good thing to ask someone you trust, like a parent or your '
        'teacher at the masjid. If you feel unsafe or upset, tell a trusted adult '
        'today (you choose who). The lines below are for young people.',
  ];

  static String replyFor(int priorMinorReplies) => priorMinorReplies <= 0
      ? firstReply
      : followUps[(priorMinorReplies - 1) % followUps.length];
}
