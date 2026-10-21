/// Wasia inside a lesson: answers grounded in THAT lesson's own text, and a
/// check on every reply that comes from a live AI service.
///
/// Two parts, both pure Dart:
///  * [LessonAnswerer] answers from the lesson text alone, with no AI and no
///    network: it finds the sentences of the lesson that share the question's
///    words and says them back. When nothing in the lesson matches it says so
///    and sends the learner to Hādi or a teacher. This is the offline path
///    and the path a child is on while the parent's AI switch is off.
///  * [WasiaAnswerVerifier] is the counterpart of Hādi's answer verifier for
///    a live reply: anything that looks like scripture, a reference, a
///    quotation, Arabic or a hadith grade must already be in the lesson text,
///    or it is taken out before the learner sees it.
library;

/// The lesson Wasia is answering about. [text] is the lesson's own words.
class LessonGrounding {
  const LessonGrounding({
    required this.id,
    required this.title,
    required this.text,
  });

  final String id;
  final String title;
  final String text;
}

/// What the learner is told when the lesson has no answer.
const String kWasiaNotInLesson =
    'I can only answer from this lesson, and I cannot find that in it. Try '
    'asking in other words, or ask Hādi or a teacher you trust.';

/// What the learner is told for a question that asks for a ruling. Wasia
/// teaches; she does not rule.
const String kWasiaNoRulings =
    'That is a question about a ruling, and I do not give rulings. Hādi '
    'names his sources, and a local scholar can answer for your own '
    'situation.';

abstract final class LessonAnswerer {
  static const Set<String> _stop = <String>{
    'the', 'and', 'for', 'are', 'was', 'were', 'what', 'when', 'where',
    'which', 'who', 'whom', 'why', 'how', 'does', 'did', 'has', 'have', 'had',
    'this', 'that', 'these', 'those', 'with', 'from', 'about', 'into', 'than',
    'then', 'there', 'their', 'they', 'them', 'you', 'your', 'can', 'could',
    'would', 'should', 'will', 'not', 'but', 'any', 'all', 'its', 'our',
    'tell', 'explain', 'mean', 'means', 'meaning', 'lesson', 'wasia', 'please',
    'more', 'some', 'one', 'also', 'just', 'say', 'said', 'ask',
  };

  static List<String> _words(String s) => RegExp(r'[a-z\u00C0-\u024F]+')
      .allMatches(s.toLowerCase())
      .map((Match m) => m.group(0)!)
      .toList();

  /// Words of [question] worth matching (no filler words, at least 3 letters).
  static Set<String> keywords(String question) => <String>{
        for (final String w in _words(question))
          if (w.length >= 3 && !_stop.contains(w)) w,
      };

  static bool _same(String a, String b) {
    if (a == b) return true;
    if (a.length < 5 || b.length < 5) return false;
    // A shared stem of five letters: "pray" / "prayers" do not count, but
    // "purifies" / "purified" and "charity" / "charitable" do.
    return a.substring(0, 5) == b.substring(0, 5);
  }

  /// Sentences of [text], in order.
  static List<String> sentences(String text) => text
      .split(RegExp(r'(?<=[.!?])\s+|\n+'))
      .map((String s) => s.trim())
      .where((String s) => s.length > 3)
      .toList();

  /// The answer from the lesson, or null when no sentence of it shares a
  /// word with [question]. At most two sentences, in the order the lesson
  /// has them, so the reply is the lesson's own words and nothing else.
  static String? answer(String question, String lessonText) {
    final Set<String> keys = keywords(question);
    if (keys.isEmpty) return null;
    final List<String> sents = sentences(lessonText);
    final List<(int, int)> scored = <(int, int)>[];
    for (int i = 0; i < sents.length; i++) {
      final List<String> words = _words(sents[i]);
      int score = 0;
      for (final String k in keys) {
        if (words.any((String w) => _same(w, k))) score++;
      }
      if (score > 0) scored.add((i, score));
    }
    if (scored.isEmpty) return null;
    // A question with several keywords needs a sentence that matches more
    // than one of them; a single shared word is too weak to answer with.
    final int best = scored.map(((int, int) e) => e.$2).reduce(
          (int a, int b) => a > b ? a : b,
        );
    if (keys.length >= 3 && best < 2) return null;
    scored.sort(((int, int) a, (int, int) b) {
      final int byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    final List<int> pick = scored.take(2).map(((int, int) e) => e.$1).toList()
      ..sort();
    final String body = pick
        .map((int i) => sents[i].length > 320
            ? '${sents[i].substring(0, 317)}...'
            : sents[i])
        .join(' ');
    return 'From this lesson: $body';
  }
}

/// A live reply after [WasiaAnswerVerifier.verify].
class VerifiedWasiaAnswer {
  const VerifiedWasiaAnswer({
    required this.text,
    this.removedReferences = 0,
    this.removedQuotes = 0,
    this.removedArabic = false,
    this.removedGrades = 0,
  });

  final String text;
  final int removedReferences;
  final int removedQuotes;
  final bool removedArabic;
  final int removedGrades;

  bool get changed =>
      removedReferences > 0 ||
      removedQuotes > 0 ||
      removedArabic ||
      removedGrades > 0;
}

/// What the learner is told when something was removed.
const String kWasiaRemovedNote =
    'Wasia removed something she could not check against this lesson.';

abstract final class WasiaAnswerVerifier {
  static final RegExp _hadithRef = RegExp(
    r"(?:Sahih\s+|Sunan\s+|Jami[\u02bf'\u2019`]?\s*(?:at-|al-)?\s*)?"
    r'(?:al-|an-|at-)?'
    r"(Bukhari|Muslim|Abu\s+Dawu?d|Abu\s+Dawood|Tirmidhi|Nasa['\u2019]?i|"
    r'Ibn\s+Majah|Ahmad)'
    r'\s*(?:,|:|#|no\.?|number|hadith)?\s*\(?(\d{1,5})\)?',
    caseSensitive: false,
  );

  static final RegExp _quranRef = RegExp(
    r'(\d{1,3})\s*:\s*(\d{1,4})(?:\s*[-\u2013]\s*(\d{1,4}))?',
  );

  /// How a reply writes a verse: after a word that names the Qur'an, or in
  /// brackets. A bare "10:30" (a time) is not a verse reference.
  static final RegExp _quranRefWord = RegExp(
    r"(?:Qur['\u2019]?an|Quran|Surah|Surat|Sura|Ayah|Ayat|Verses?)\b"
    r'[^\n\d()]{0,32}?(\d{1,3})\s*:\s*(\d{1,4})(?:\s*[-\u2013]\s*(\d{1,4}))?',
    caseSensitive: false,
  );
  static final RegExp _quranRefParen = RegExp(
    r'\((\d{1,3}):(\d{1,4})(?:\s*[-\u2013]\s*(\d{1,4}))?\)',
  );

  static const String _arabicChars =
      r'\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF';
  static final RegExp _arabicRun = RegExp('[$_arabicChars][$_arabicChars\\s]*');
  static final RegExp _marks = RegExp('[\u064B-\u0652\u0670\u06D6-\u06ED]');

  static final RegExp _quoted =
      RegExp('[\u201C"]([^\u201D"\u201C\\n]{40,600})[\u201D"]');

  static final RegExp _gradeClaim = RegExp(
    r"\b(?:graded|rated|classed|classified|considered|deemed|judged|is|was|are)"
    r"\s+(?:as\s+)?(?:a\s+)?(sahih|hasan|da['\u2019]?if|weak|fabricated|"
    r"mawdu['\u2019]?)\b",
    caseSensitive: false,
  );

  static String _condense(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static String _collection(String raw) => raw
      .toLowerCase()
      .replaceAll(RegExp('[^a-z]'), '')
      .replaceAll('abudawood', 'abudawud');

  static String _bareArabic(String s) =>
      s.replaceAll(_marks, '').replaceAll(RegExp(r'\s'), '');

  /// Every `surah:ayah` the lesson text names, ranges expanded.
  static Set<String> _lessonAyat(String lesson) {
    final Set<String> out = <String>{};
    for (final Match m in _quranRef.allMatches(lesson)) {
      final int s = int.parse(m.group(1)!);
      final int a = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? a : int.parse(toRaw);
      if (to < a || to - a > 300) {
        out.add('$s:$a');
        continue;
      }
      for (int i = a; i <= to; i++) {
        out.add('$s:$i');
      }
    }
    return out;
  }

  static Set<String> _lessonHadith(String lesson) => <String>{
        for (final Match m in _hadithRef.allMatches(lesson))
          '${_collection(m.group(1)!)}:${m.group(2)}',
      };

  /// Checks [raw] against [lessonText]. Text the lesson does not carry is
  /// removed: a reference, a long quotation, a run of Arabic, a hadith grade.
  static VerifiedWasiaAnswer verify(String raw, String lessonText) {
    int refs = 0;
    int quotes = 0;
    int grades = 0;
    bool arabic = false;

    String text = raw
        .replaceAll(RegExp(r'\[\[[^\]\n]*\]\]'), '')
        .replaceAll(RegExp(r'\[GO:[^\]]+\]'), '');

    // 1. Hadith references: only those the lesson itself gives.
    final Set<String> lessonHadith = _lessonHadith(lessonText);
    text = text.replaceAllMapped(_hadithRef, (Match m) {
      final String key = '${_collection(m.group(1)!)}:${m.group(2)}';
      if (lessonHadith.contains(key)) return m.group(0)!;
      refs++;
      return '(reference removed)';
    });

    // 2. Qur'an references: only ayat the lesson itself names.
    final Set<String> lessonAyat = _lessonAyat(lessonText);
    String quranRef(Match m) {
      final int s = int.parse(m.group(1)!);
      final int a = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? a : int.parse(toRaw);
      bool ok = to >= a && to - a <= 300;
      for (int i = a; ok && i <= to; i++) {
        if (!lessonAyat.contains('$s:$i')) ok = false;
      }
      if (ok) return m.group(0)!;
      refs++;
      return '(verse reference removed)';
    }

    text = text.replaceAllMapped(_quranRefWord, quranRef);
    text = text.replaceAllMapped(_quranRefParen, quranRef);

    // 3. Arabic: a long run is kept only if the lesson has it.
    final String lessonArabic = _bareArabic(lessonText);
    text = text.replaceAllMapped(_arabicRun, (Match m) {
      final String run = m.group(0)!;
      final String bare = _bareArabic(run);
      if (bare.length < 10) return run;
      if (lessonArabic.contains(bare)) return run;
      arabic = true;
      return '';
    });

    // 4. Long quotations must come from the lesson.
    final String lessonCondensed = _condense(lessonText);
    text = text.replaceAllMapped(_quoted, (Match m) {
      final String q = _condense(m.group(1)!);
      if (q.isNotEmpty && lessonCondensed.contains(q)) return m.group(0)!;
      quotes++;
      return '(a quotation Wasia could not check was removed)';
    });

    // 5. A hadith grade the lesson does not give is dropped with its
    //    sentence.
    final String lessonLower = lessonText.toLowerCase();
    final List<String> kept = <String>[];
    for (final String s in text.split(RegExp(r'(?<=[.!?])\s+'))) {
      final Match? g = _gradeClaim.firstMatch(s);
      if (g != null) {
        final String grade =
            g.group(1)!.toLowerCase().replaceAll('\u2019', "'");
        if (!lessonLower.contains(grade.replaceAll("'", ''))) {
          grades++;
          continue;
        }
      }
      kept.add(s);
    }
    text = kept.join(' ');

    text = text
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r' +([,.;:!?])'), r'$1')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return VerifiedWasiaAnswer(
      text: text,
      removedReferences: refs,
      removedQuotes: quotes,
      removedArabic: arabic,
      removedGrades: grades,
    );
  }
}
