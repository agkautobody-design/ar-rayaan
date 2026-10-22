import 'corpus.dart';
import 'passage.dart';
import 'verifier_patterns.dart';

/// What the verifier hands back for a live model's reply.
class VerifiedAnswer {
  const VerifiedAnswer({
    required this.text,
    required this.sourceIds,
    this.droppedIds = 0,
    this.removedReferences = 0,
    this.removedQuotes = 0,
    this.removedArabic = false,
    this.unsupportedGrade = false,
  });

  /// The reply with every `[[src:…]]` token removed and every reference or
  /// quotation Hādi could not stand behind taken out.
  final String text;

  /// The passages to print under the reply, in order of appearance.
  final List<String> sourceIds;

  /// `[[src:…]]` tokens that did not resolve to a real passage.
  final int droppedIds;

  /// Free-typed hadith or Qur'an references that did not resolve.
  final int removedReferences;

  /// Long quotations that were not found in a passage Hādi is showing.
  final int removedQuotes;

  /// A run of Arabic script (the model must not type scripture) was removed.
  final bool removedArabic;

  /// The reply called something sahih/hasan/da'if/fabricated without a hadith
  /// from the library to stand on.
  final bool unsupportedGrade;

  bool get changed =>
      droppedIds > 0 ||
      removedReferences > 0 ||
      removedQuotes > 0 ||
      removedArabic ||
      unsupportedGrade;
}

/// Deterministic checks on a live model's reply. Scripture reaches the
/// screen only through the corpus: the model points at IDs, the app prints
/// the text, and anything the model typed on its own that looks like a
/// citation, a long quotation or Arabic scripture is removed.
abstract final class AnswerVerifier {
  static final RegExp _token = RegExp(
    r'\[\[\s*src\s*:\s*([a-zA-Z]:[A-Za-z0-9:\-]+)\s*\]\]',
  );
  static final RegExp _strayBrackets = RegExp(r'\[\[[^\]\n]*\]\]');

  static final RegExp _hadithRef = RegExp(
    r"(?:Sahih\s+|Sunan\s+|Jami[ʿ'’`]?\s*(?:at-|al-)?\s*)?(?:al-|an-|at-)?"
    r"(Bukhari|Muslim|Abu\s+Dawu?d|Abu\s+Dawood|Tirmidhi|Nasa['’]?i|Ibn\s+Majah)"
    r"\s*(?:,|:|#|no\.?|number|hadith)?\s*\(?(\d{1,5})\)?",
    caseSensitive: false,
  );

  static final RegExp _quranRefWord = RegExp(
    r"(?:Qur['’]?an|Quran|Surah|Surat|Sura|Ayah|Ayat|Verses?)\b"
    r"[^\n\d()]{0,32}?(\d{1,3})\s*:\s*(\d{1,4})(?:\s*[-–]\s*(\d{1,4}))?",
    caseSensitive: false,
  );
  static final RegExp _quranRefParen = RegExp(
    r'\((\d{1,3}):(\d{1,4})(?:\s*[-–]\s*(\d{1,4}))?\)',
  );

  static const String _arabicChars =
      r'\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF';
  static final RegExp _arabicRun = RegExp('[$_arabicChars][$_arabicChars\\s]*');

  /// Arabic-script text inside quotation marks or Qur'anic brackets.
  static final RegExp _quotedArabic = RegExp(
    '(?:“[^”\\n]*”|"[^"\\n]*"|«[^»\\n]*»|﴿[^﴾\\n]*﴾|﴾[^﴿\\n]*﴿)',
  );

  /// Tashkeel and Qur'anic annotation marks, which ordinary Arabic or Urdu
  /// prose does not carry in bulk but typed scripture does.
  static final RegExp _tashkeel = RegExp(
    '[\u064B-\u0652\u0670\u06D6-\u06ED]',
  );

  static int _arabicLetters(String s) =>
      _arabicRun.allMatches(s).fold<int>(
        0,
        (int a, Match m) => a + m.group(0)!.replaceAll(RegExp(r'\s'), '').length,
      );

  static final RegExp _gradeClaim = RegExp(
    r"\b(?:graded|rated|classed|classified|considered|deemed|judged|is|was|are)"
    r"\s+(?:as\s+)?(?:a\s+)?(?:sahih|hasan|da['’]?if|weak|fabricated|mawdu['’]?)\b",
    caseSensitive: false,
  );

  /// Letters and digits only, lower case: for comparing a quotation with a
  /// passage without caring about punctuation or brackets.
  static String condense(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// The passages [text] cites by reference, in order of appearance, at
  /// most [limit]: a Qur'an reference that exists in the bundled Qur'an
  /// (`Qur'an 2:183-185`, `(94:5)`) and a hadith that is in the corpus
  /// (`Sahih Muslim 2749`). Nothing else resolves, so a reference that is not
  /// in Hādi's library never gets a card. Used for the built-in shelf, whose
  /// answers are written by hand: the app prints the Arabic, translation and
  /// grade from its own library under them, as it does for live answers.
  static List<String> citedIds(
    String text,
    HadiCorpus corpus, {
    int limit = 5,
  }) {
    final List<({int at, String id})> found = <({int at, String id})>[];
    for (final RegExpMatch m in _hadithRef.allMatches(text)) {
      final Passage? p = corpus.hadithByRef(m.group(1)!, m.group(2)!);
      if (p != null) found.add((at: m.start, id: p.id));
    }
    void quran(RegExpMatch m) {
      final int surah = int.parse(m.group(1)!);
      final int from = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? from : int.parse(toRaw);
      final Passage? p = corpus.quranRange(surah, from, to);
      if (p != null) found.add((at: m.start, id: p.id));
    }

    _quranRefWord.allMatches(text).forEach(quran);
    _quranRefParen.allMatches(text).forEach(quran);
    found.sort(
      (({int at, String id}) a, ({int at, String id}) b) =>
          a.at.compareTo(b.at),
    );
    final List<String> out = <String>[];
    for (final ({int at, String id}) f in found) {
      if (!out.contains(f.id)) out.add(f.id);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Verifies [raw] against [corpus].
  ///
  /// When [keepUserScript] is true the user wrote in Arabic or Urdu script, so
  /// ordinary prose in that script is kept. Quoted Arabic and any run that
  /// looks like vowelled scripture is still removed.
  static VerifiedAnswer verify(
    String raw,
    HadiCorpus corpus, {
    bool keepUserScript = false,
  }) {
    final Set<String> sources = <String>{};
    int dropped = 0;
    int removedRefs = 0;
    int removedQuotes = 0;
    bool removedArabic = false;

    // 1. Pointers the model was asked to write.
    String text = raw.replaceAllMapped(_token, (Match m) {
      final Passage? p = corpus.resolve(m.group(1)!);
      if (p == null) {
        dropped++;
      } else {
        sources.add(p.id);
      }
      return '';
    });
    text = text.replaceAll(_strayBrackets, '');

    // 2. Hadith references typed by hand: kept only when they are in the
    //    library, and then the library's passage is shown too.
    text = text.replaceAllMapped(VerifierPatterns.bookNumbering, (Match m) {
      removedRefs++;
      return '';
    });
    text = text.replaceAllMapped(VerifierPatterns.unverifiableRef, (Match m) {
      removedRefs++;
      return '';
    });
    text = text.replaceAllMapped(_hadithRef, (Match m) {
      final Passage? p = corpus.hadithByRef(m.group(1)!, m.group(2)!);
      if (p != null) {
        sources.add(p.id);
        return m.group(0)!;
      }
      removedRefs++;
      return '';
    });

    // 3. Qur'an references typed by hand: a real ayah is kept and its text
    //    is printed from the bundled Qur'an; an impossible one is removed.
    String quranRef(Match m) {
      final int surah = int.parse(m.group(1)!);
      final int from = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? from : int.parse(toRaw);
      final Passage? p = corpus.quranRange(surah, from, to);
      if (p != null) {
        sources.add(p.id);
        return m.group(0)!;
      }
      removedRefs++;
      return '';
    }

    // "Surah Al-Baqarah verse 255": the name is looked up in the bundled
    // Qur'an; an unknown surah or ayah is removed like any other reference.
    text = text.replaceAllMapped(VerifierPatterns.surahVerse, (Match m) {
      final int? surah = corpus.surahNumber(m.group(1)!);
      if (surah == null) {
        removedRefs++;
        return '';
      }
      final int from = int.parse(m.group(2)!);
      final String? toRaw = m.group(3);
      final int to = toRaw == null ? from : int.parse(toRaw);
      final Passage? p = corpus.quranRange(surah, from, to);
      if (p == null) {
        removedRefs++;
        return '';
      }
      sources.add(p.id);
      return m.group(0)!;
    });
    text = text.replaceAllMapped(_quranRefWord, quranRef);
    text = text.replaceAllMapped(_quranRefParen, quranRef);

    // 4. The model must not type scripture in Arabic.
    if (keepUserScript) {
      text = text.replaceAllMapped(_quotedArabic, (Match m) {
        if (_arabicLetters(m.group(0)!) >= 12) {
          removedArabic = true;
          return '';
        }
        return m.group(0)!;
      });
    }
    text = text.replaceAllMapped(_arabicRun, (Match m) {
      final String run = m.group(0)!;
      final int letters = run.replaceAll(RegExp(r'\s'), '').length;
      if (letters >= 12) {
        // Prose in the user's own script is kept, but not an "Allah says:"
        // line in it: that is scripture typed by the model.
        if (keepUserScript &&
            _tashkeel.allMatches(run).length < 2 &&
            !VerifierPatterns.attributedAround(m.input, m.start, m.end)) {
          return run;
        }
        removedArabic = true;
        return '';
      }
      return run;
    });

    // 5. Long quotations must be inside a passage Hādi is showing.
    final List<String> shown = <String>[
      for (final String id in sources)
        if (corpus.resolve(id) != null) condense(corpus.resolve(id)!.english),
    ];
    text = VerifierPatterns.filterQuotes(
      text,
      allowed: (String inner) {
        final String q = condense(inner);
        if (q.isEmpty) return true;
        for (final String s in shown) {
          if (s.contains(q)) return true;
        }
        return false;
      },
      onRemoved: () => removedQuotes++,
    );

    // 6. A grade claim needs a hadith from the library to stand on.
    bool unsupportedGrade = false;
    final bool hasHadith = sources.any((String id) => id.startsWith('h:'));
    if (!hasHadith) {
      int graded = 0;
      text = VerifierPatterns.dropGradeSentences(text, () => graded++);
      if (graded > 0 || _gradeClaim.hasMatch(text)) unsupportedGrade = true;
    }

    // Tidy the gaps the removals leave behind. Nothing is written into the
    // reply to mark a removal: the screen shows a collapsed note under it.
    text = text
        .replaceAll(RegExp(r'\(\s*\)|“\s*”|"\s*"'), '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAllMapped(RegExp(r' +([,.;:!?])'), (Match m) => m.group(1)!)
        .replaceAll(RegExp(r'\s*[:;,]\s*(?=[.!?](?:\s|$))'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return VerifiedAnswer(
      text: text,
      sourceIds: sources.take(5).toList(),
      droppedIds: dropped,
      removedReferences: removedRefs,
      removedQuotes: removedQuotes,
      removedArabic: removedArabic,
      unsupportedGrade: unsupportedGrade,
    );
  }
}
