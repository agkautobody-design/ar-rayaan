/// Hādi's live answers are for adults. When someone says they are under 18,
/// Hādi does not carry on a live conversation: it gives a short, kind, fixed
/// reply and points to a trusted adult and to the children's help lines.
///
/// The age is read from the person's own words only, and is never stored.
abstract final class MinorSignal {
  static final RegExp _age = RegExp(
    r"\b(?:i\s*am|i'm|im|i\s+turned|my\s+age\s+is)\s+(?:an?\s+)?(\d{1,2})"
    r"(?:\s*(?:years?|yrs?|y\.?\s?o\.?|yo)\b|[\s-]*year[\s-]*old|\s*[.,!?;]|\s*$|"
    r"\s+and\b|\s+(?:girl|boy|male|female|muslim|but|so)\b)",
    caseSensitive: false,
  );
  static final RegExp _yo = RegExp(
    r"\b(\d{1,2})\s*(?:y/?o|yo|years?\s+old|yrs?\s+old)\b",
    caseSensitive: false,
  );
  static final RegExp _words = RegExp(
    r"\b(?:i\s*am|i'm|im)\s+(?:still\s+)?(?:a\s+)?(?:kid|child|minor|"
    r"teen|teenager|schoolboy|schoolgirl|under\s*18|underage|not\s+18)\b|"
    r"\b(?:i\s*am|i'm|im)\s+in\s+(?:grade|year|class)\s+(?:[1-9]|1[0-2])\b|"
    r"\b(?:i\s*am|i'm|im)\s+in\s+(?:middle|primary|elementary|high)\s+school\b|"
    r"\bmy\s+parents\s+(?:don'?t|do\s+not)\s+let\s+me\b",
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
    for (final RegExpMatch m in _age.allMatches(text)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n != null && n >= 5 && n < 18) return true;
    }
    for (final RegExpMatch m in _yo.allMatches(text)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n == null || n < 5 || n >= 18) continue;
      if (_aboutSomeoneElse(text, m)) continue;
      return true;
    }
    return _words.hasMatch(text);
  }

  static const String firstReply =
      'As-salamu alaikum, and thank you for telling me. My live answers are '
      'for adults, so the best thing is to ask a parent, a teacher or an '
      'imam you trust. For children, Wasia in the Academy teaches '
      'step by step, and she is made for you.\n\n'
      'If anything is worrying you, or someone is making you feel unsafe, '
      'please tell a grown-up you trust today. The help lines below are for '
      'young people.';

  static const List<String> followUps = <String>[
    'I am glad you are here. A parent or teacher is the best person to '
        'ask about this. Wasia in the Academy is there for your learning, '
        'and the lines below are free if you ever need to talk.',
    'That is a good thing to ask someone you trust, like a parent or your '
        'teacher at the masjid. If you feel unsafe or upset, tell a grown-up '
        'today. The lines below are for young people.',
  ];

  static String replyFor(int priorMinorReplies) => priorMinorReplies <= 0
      ? firstReply
      : followUps[(priorMinorReplies - 1) % followUps.length];
}
