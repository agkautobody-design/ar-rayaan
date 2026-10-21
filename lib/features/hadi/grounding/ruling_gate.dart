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
    r'blasphemy|oath|vow|nadhr|'
    r'missed\s+(?:my\s+)?(?:\w+\s+)?(?:fasts?|prayers?|salah)|'
    r'(?:make\s+up|catch\s+up|qada)\s+(?:on\s+)?(?:my\s+)?'
    r'(?:missed\s+)?(?:fasts?|prayers?|salah)|'
    r'prayers?\s+for\s+years|'
    r'breaking my fast)\b',
    caseSensitive: false,
  );

  static final RegExp _personal = RegExp(
    r"\b(my|our)\s+(wife|husband|marriage|nikah|divorce|spouse|case|"
    r"situation|father|mother|parents?|fasts?|wudu|prayers?|salah|"
    r"inheritance|loan|mortgage|oath|vow|child|son|daughter)\b|"
    r"\b(should|can|could|must|may|do|did|am|have|will)\s+(i|we)\b|"
    r"\b(i|we)\s+(am|are|was|were|have|had|did|said|told|took|want\s+to|"
    r"wanna|need\s+to|plan\s+to|swore|promised|missed|skipped|broke|"
    r"forgot|owe)\b|"
    r"\bis\s+(it|my|our)\s+(valid|void|haram|halal|permissible|allowed)\b|"
    r"\bam\s+i\s+(still\s+)?(married|divorced|sinful|a\s+sinner|allowed)\b",
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

  static RulingClass classify(String question) {
    final String q = question.toLowerCase();
    final bool topic = _topic.hasMatch(q) || _topicArabic.hasMatch(q);
    final bool ask = _generalAsk.hasMatch(q) || _askArabic.hasMatch(q);
    if (!topic && !ask) return RulingClass.none;
    final bool personal = _personal.hasMatch(q) || _personalArabic.hasMatch(q);
    if (personal && topic) return RulingClass.personal;
    // "Is my divorce valid" has a topic word; "should I do X" with only a
    // ruling-word is general unless it is clearly about "me".
    if (personal &&
        RegExp(
          r"\b(my|our)\b.*\b(valid|void|haram|halal|permissible|allowed)\b|"
          r"\b(am\s+i|should\s+i|can\s+i|do\s+i\s+have)\b",
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
    r"\b(you\s+(must|have\s+to|need\s+to|are\s+required\s+to|should\s+"
    r"(divorce|leave|separate|abort|stop\s+praying))|"
    r"your\s+(marriage|nikah|divorce|fast|wudu|prayer|oath|vow)\s+"
    r"(is|was|has\s+been|remains)\s+(valid|invalid|void|broken|annulled|"
    r"complete|accepted|not\s+valid)|it\s+is\s+(haram|forbidden|"
    r"obligatory)\s+for\s+you|you\s+are\s+(still\s+|not\s+)?(married|"
    r"divorced|sinful|a\s+sinner|guilty))\b",
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
