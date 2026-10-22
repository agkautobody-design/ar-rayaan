/// Patterns shared by the two live-answer verifiers (Hādi's and Wasia's), so
/// a hole closed in one is closed in the other. Pure Dart.
library;

abstract final class VerifierPatterns {
  /// A hadith reference in a book the app cannot check by number: Musnad
  /// Ahmad, Riyad as-Salihin, Bulugh al-Maram, Mishkat, Hisn al-Muslim,
  /// Muwatta, Darimi, al-Adab al-Mufrad. It is removed, never kept.
  static final RegExp unverifiableRef = RegExp(
    r"\b(?:Musnad\s+(?:al-?\s*)?Ahmad|Ahmad(?:\s+ibn\s+Hanbal)?|"
    r"Riy[aā]d(?:\s+(?:as|us|al)[- ]?\s*[SṢ]?[aā]li[hḥ][iī]n)?|"
    r"Bul[uū]gh(?:\s+al-?\s*Mar[aā]m)?|"
    r"Mishk[aā]t(?:\s+al-?\s*Mas[aā]b[iī][hḥ])?|"
    r"Hisn(?:\s+al-?\s*Muslim)?|Muwatt?a['’]?(?:\s+Malik)?|"
    r"(?:Sunan\s+)?(?:ad-?\s*)?D[aā]rim[iī]|"
    r"(?:al-?\s*)?Adab\s+al-?\s*Mufrad|Sahih\s+Ibn\s+Hibb[aā]n|"
    r"Mustadrak(?:\s+al-?\s*H[aā]kim)?|Silsilah?)"
    r"(?:\s*[,:#(]?\s*(?:vol(?:ume)?\.?\s*\d{1,3}\s*[,:]?\s*)?"
    r"(?:p(?:age)?\.?\s*\d{1,4}|no\.?\s*\d{1,5}|number\s*\d{1,5}|"
    r"hadith\s*(?:no\.?|number|#)?\s*\d{1,5}|\d{1,5}(?:\s*/\s*\d{1,5})?))\)?",
    caseSensitive: false,
  );

  /// "Bukhari, Book 3, Hadith 12" and "Hadith 1234": book and chapter
  /// numbering the app does not use, so it cannot be checked.
  static final RegExp bookNumbering = RegExp(
    r"\b(?:(?:Sahih\s+|Sunan\s+|Jami['’]?\s*)?(?:al-|an-|at-)?"
    r"(?:Bukhari|Muslim|Abu\s+Dawu?d|Tirmidhi|Nasa['’]?i|Ibn\s+Majah)"
    r"[\s,:(]+)?(?:Book|Volume|Vol\.?|Chapter|Kitab)\s*(?:of\s+\w+\s*)?"
    r"\d{1,4}\s*[,:)]?\s*(?:Hadith|Ḥadīth|No\.?|Number|#)\s*\d{1,5}\)?|"
    r"\bHadith\s*(?:no\.?|number|#)\s*\d{1,5}\b",
    caseSensitive: false,
  );

  /// "Surah Al-Baqarah verse 255", "Surah 2, ayah 255", "Surat Yusuf ayat 4-5".
  static final RegExp surahVerse = RegExp(
    r"\b(?:Surah|Surat|Sura)\s+(?:No\.?\s*)?"
    r"((?:[A-Za-z'’\-]+\s+)?[A-Za-z'’\-]+|\d{1,3})\s*[,(]?\s*"
    r"(?:verses?|ayah|ayat|ayahs|aya|v\.?)\s*(?:no\.?\s*)?"
    r"(\d{1,4})(?:\s*[-–]\s*(\d{1,4}))?\)?",
    caseSensitive: false,
  );

  /// Words that attribute what follows to Allah, the Prophet or a book.
  /// In Arabic and Urdu only a verb of saying that is followed closely by
  /// Allah or the Prophet counts, because "said" alone is ordinary prose.
  static final RegExp attribution = RegExp(
    r"(?:says?|said|states?|stated|narrated|reported|reports?|taught|"
    r"revealed|verse|ayah|hadith|qur['\u2019]?an|prophet|messenger)|"
    r"(?:\u0642\u0627\u0644|\u0642\u0627\u0644\u062A|\u064A\u0642\u0648\u0644|"
    r"\u0641\u0631\u0645\u0627\u06CC\u0627|\u0641\u0631\u0645\u0627\u062A\u0627|"
    r"\u0641\u0631\u0645\u0627\u062A\u06D2|\u06A9\u06C1\u0627)"
    r"[^\n]{0,20}?(?:\u0627\u0644\u0644\u0647|\u0627\u0644\u0644\u06C1|"
    r"\u0627\u0644\u0646\u0628\u064A|\u0646\u0628\u06CC|\u0631\u0633\u0648\u0644|"
    r"\u0627\u0644\u0631\u0633\u0648\u0644|\uFDFA)",
    caseSensitive: false,
  );

  /// True when an attribution word sits within [window] characters before
  /// [start] in [text].
  static bool attributedBefore(String text, int start, {int window = 60}) {
    final int from = start - window < 0 ? 0 : start - window;
    return attribution.hasMatch(text.substring(from, start));
  }

  /// True when an attribution word sits shortly before [start], or opens the
  /// span itself ([start] to [end]): "قال الله تعالى ..." begins with it.
  static bool attributedAround(String text, int start, int end,
      {int window = 40, int lead = 14}) {
    if (attributedBefore(text, start, window: window)) return true;
    final int to = start + lead < end ? start + lead : end;
    return attribution.hasMatch(text.substring(start, to));
  }

  static final List<RegExp> _quotePatterns = <RegExp>[
    RegExp('“([^”\\n]{20,2000})”'),
    RegExp(r'"([^"\n]{20,2000})"'),
    RegExp('«([^»\\n]{20,2000})»'),
    RegExp('„([^“”\\n]{20,2000})[“”]'),
    RegExp('‹([^›\\n]{20,2000})›'),
    // Curly single quotes: the closing mark must not be an apostrophe.
    RegExp(
      '‘((?:[^’\\n]|’(?=[A-Za-z])){20,2000}?)’(?![A-Za-z0-9])',
    ),
    // Straight single quotes, not an apostrophe inside a word.
    RegExp(
      r"(?<![A-Za-z0-9])'((?:[^'\n]|'(?=[A-Za-z])){20,2000}?)'(?![A-Za-z0-9])",
    ),
  ];

  /// Every quotation in [text], in whatever marks it is written. A quotation
  /// of 40 characters or more, or of 20 or more that follows an attribution
  /// ("Allah says ..."), is passed to [allowed]; when that returns false the
  /// quotation is replaced by [replacement] and [onRemoved] is called.
  static String filterQuotes(
    String text, {
    required bool Function(String inner) allowed,
    required void Function() onRemoved,
    String replacement = '',
  }) {
    String out = text;
    for (final RegExp p in _quotePatterns) {
      final String snapshot = out;
      out = snapshot.replaceAllMapped(p, (Match m) {
        final String inner = m.group(1)!;
        final bool long = inner.length >= 40;
        if (!long && !attributedBefore(snapshot, m.start)) return m.group(0)!;
        if (allowed(inner)) return m.group(0)!;
        onRemoved();
        return replacement;
      });
    }
    return out;
  }

  /// A sentence that grades a hadith or narration.
  static final RegExp gradeSentence = RegExp(
    r"\b(?:graded|rated|classed|classified|considered|deemed|judged|is|was|"
    r"are|were|as)\s+(?:as\s+|to\s+be\s+)?(?:a\s+|an\s+)?(?:very\s+)?"
    r"(?:sahih|hasan|da['’]?[iy]f|weak|fabricated|mawdu['’]?|"
    r"munkar|batil|forged|spurious|authentic|sound|reliable|rejected)\b|"
    r"\b(?:sahih|hasan|da['’]?[iy]f|weak|fabricated|mawdu['’]?|"
    r"munkar|forged|spurious)\s+(?:hadith|narration|report|chain|isnad)\b|"
    r"\b(?:hadith|narration|report|isnad)\b[^.!?\n]{0,50}"
    r"\b(?:sahih|hasan|da['’]?[iy]f|weak|fabricated|mawdu['’]?|"
    r"authentic|munkar|forged|spurious)\b",
    caseSensitive: false,
  );

  /// Sentences of [text] without those that grade a narration. [removed]
  /// is called once per sentence dropped. Line breaks are kept.
  static String dropGradeSentences(String text, void Function() removed) {
    final List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final List<String> kept = <String>[];
      for (final String s in lines[i].split(RegExp(r'(?<=[.!?])\s+'))) {
        if (gradeSentence.hasMatch(s)) {
          removed();
          continue;
        }
        kept.add(s);
      }
      lines[i] = kept.join(' ');
    }
    return lines.join('\n');
  }
}
