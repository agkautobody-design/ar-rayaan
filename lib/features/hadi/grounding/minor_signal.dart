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

  static bool isMinor(String text) {
    for (final RegExpMatch m in _age.allMatches(text)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n != null && n >= 5 && n < 18) return true;
    }
    for (final RegExpMatch m in _yo.allMatches(text)) {
      final int? n = int.tryParse(m.group(1)!);
      if (n != null && n >= 5 && n < 18) return true;
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
