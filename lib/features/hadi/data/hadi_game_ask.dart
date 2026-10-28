/// "Ask Hadi about this" in the games.
///
/// The button used to send a loose sentence ("I just answered this quiz
/// question ...") that matched no topic on the shelf, so Hadi answered with a
/// list of games or a blurb about the Huda guides. Now the game sends a
/// question in a fixed shape, and this file reads it back and answers from the
/// game's own verified fields (the question, the right answer, the
/// explanation and the source it cites). Nothing is added from memory: the
/// reply says so, and points to the Qur'an or Hadith screen when the source is
/// one of those.
///
/// Both sides live here ([quiz], [order], [words] build the question; [answer]
/// reads it) so they cannot drift apart. Pure Dart, no Flutter.
library;

abstract final class HadiGameAsk {
  static const String quizOpen =
      'I just answered a quiz question in the game and want to understand it.';
  static const String orderOpen =
      'I just played an ordering game and want to understand it.';
  static const String wordsOpen =
      'I just met words in a glossary game and want to understand them.';

  /// Every reply starts with this, so the rest of the app can tell it is a
  /// fixed reply built from the game's own text.
  static const String replyOpen = 'Here is what the game itself holds';

  /// True when [question] was built by one of the games.
  static bool isGameAsk(String question) {
    final String q = question.trimLeft();
    return q.startsWith(quizOpen) ||
        q.startsWith(orderOpen) ||
        q.startsWith(wordsOpen);
  }

  /// True when [reply] is one of the replies built here.
  static bool isReply(String reply) => reply.startsWith(replyOpen);

  static String _clean(String s, int max) {
    final String t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= max) return t;
    final int cut = t.lastIndexOf(' ', max);
    return '${t.substring(0, cut > max ~/ 2 ? cut : max)} …';
  }

  // ── The questions the games send ────────────────────────────────────

  static String quiz({
    required String prompt,
    required String answer,
    required String explanation,
    required String citation,
  }) =>
      '$quizOpen\n'
      'Question: ${_clean(prompt, 240)}\n'
      'Right answer: ${_clean(answer, 160)}\n'
      'What the game says: ${_clean(explanation, 400)}\n'
      'Source: ${_clean(citation, 160)}';

  static String order({
    required List<String> items,
    required String explanation,
    required String citation,
  }) =>
      '$orderOpen\n'
      'The right order: ${_clean(items.join(', then '), 300)}\n'
      'What the game says: ${_clean(explanation, 400)}\n'
      'Source: ${_clean(citation, 160)}';

  static String words({
    required List<({String term, String meaning})> entries,
    required String source,
  }) =>
      '$wordsOpen\n'
      '${<String>[
        for (final ({String term, String meaning}) e in entries.take(12))
          'Word: ${_clean(e.term, 40)} = ${_clean(e.meaning, 160)}',
      ].join('\n')}\n'
      'Source: ${_clean(source, 200)}';

  // ── The replies ─────────────────────────────────────────────────────

  static String _field(List<String> lines, String label) {
    for (final String l in lines) {
      if (l.startsWith('$label: ')) return l.substring(label.length + 2).trim();
    }
    return '';
  }

  static final RegExp _quranRef = RegExp(
    r'(?:Qur.an|Quran|Surah|Sura)\b|\b\d{1,3}:\d{1,3}\b',
    caseSensitive: false,
  );
  static final RegExp _hadithRef = RegExp(
    r'\b(?:Bukhari|Muslim|Tirmidhi|Abu Dawud|Nasa.i|Ibn Majah|hadith|Nawawi)\b',
    caseSensitive: false,
  );

  static String _buttons(String source) {
    final StringBuffer b = StringBuffer();
    if (_quranRef.hasMatch(source)) b.write('\n[GO:/quran]');
    if (_hadithRef.hasMatch(source)) b.write('\n[GO:/hadith]');
    if (b.isEmpty) b.write('\n[GO:/search]');
    return b.toString();
  }

  static const String _honest =
      'This is the game’s own text and its source; I am not adding '
      'anything from memory. ';

  /// The reply to a question built by one of the games, or null when
  /// [question] is not one.
  static String? answer(String question) {
    final String q = question.trim();
    final List<String> lines = q.split('\n');
    if (q.startsWith(quizOpen)) {
      final String qs = _field(lines, 'Question');
      final String a = _field(lines, 'Right answer');
      final String why = _field(lines, 'What the game says');
      final String src = _field(lines, 'Source');
      if (qs.isEmpty || a.isEmpty) return null;
      return '$replyOpen about that question, with the source it cites. '
          '$_honest\n\n'
          'Question: $qs\n'
          'Right answer: $a\n'
          '${why.isEmpty ? '' : 'What the game says: $why\n'}'
          '${src.isEmpty ? '' : 'Source: $src\n'}\n'
          'To go deeper, open the source below, or ask me about the topic in '
          'a few words (the name of the surah, the prophet or the person).'
          '${_buttons(src)}';
    }
    if (q.startsWith(orderOpen)) {
      final String order = _field(lines, 'The right order');
      final String why = _field(lines, 'What the game says');
      final String src = _field(lines, 'Source');
      if (order.isEmpty) return null;
      return '$replyOpen about that order, with the source it cites. '
          '$_honest\n\n'
          'The right order: $order\n'
          '${why.isEmpty ? '' : 'What the game says: $why\n'}'
          '${src.isEmpty ? '' : 'Source: $src\n'}\n'
          'If one step is unclear, ask me about it by name, for example '
          '“how do I make wudu”, and I will answer it on its own.'
          '${_buttons(src)}';
    }
    if (q.startsWith(wordsOpen)) {
      final List<String> words = <String>[
        for (final String l in lines)
          if (l.startsWith('Word: ')) l.substring('Word: '.length).trim(),
      ];
      final String src = _field(lines, 'Source');
      if (words.isEmpty) return null;
      return '$replyOpen about ${words.length == 1 ? 'that word' : 'those words'}'
          ', with where it comes from. $_honest\n\n'
          '${words.map((String w) => '- $w').join('\n')}\n'
          '${src.isEmpty ? '' : '\nSource: $src\n'}\n'
          'The guides in Huda use these words in their steps. Ask me about '
          'the act itself, for example “how do I make wudu”, for the '
          'full answer with its sources.\n[GO:/huda]';
    }
    return null;
  }
}
