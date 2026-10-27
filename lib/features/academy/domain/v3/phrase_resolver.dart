/// Turns a lesson's phrase reference into the lines the screen shows.
///
/// A reference is either an id from the verified-phrase registry
/// (`shahada.full`) or a Qur'an reference (`q:1:2`, `q:112:1-4`). A word
/// reference picks one Arabic word of a single-line reference:
/// `q:1:2#0`, `shahada.tawhid#3`. Pure Dart.
library;

import 'phrase_registry.dart';
import 'quran_verses.dart';

class ResolvedWord {
  const ResolvedWord({required this.arabic, this.tr, this.en});

  final String arabic;
  final String? tr;
  final String? en;
}

/// One line of Arabic with what goes with it.
class ResolvedLine {
  const ResolvedLine({
    required this.arabic,
    this.translit,
    this.meaning,
    this.words,
    this.surah,
    this.ayah,
    this.meaningCredit,
  });

  final String arabic;
  final String? translit;
  final String? meaning;
  final List<ResolvedWord>? words;

  /// Set for an ayah: the app has real recitation audio for it.
  final int? surah;
  final int? ayah;

  /// Who the meaning is from, when it is not the app author's own wording.
  final String? meaningCredit;

  bool get isAyah => surah != null && ayah != null;
}

class ResolvedPhrase {
  const ResolvedPhrase({
    required this.ref,
    required this.lines,
    required this.verified,
    required this.needsScholarReview,
    required this.sources,
    this.wholeMeaning,
  });

  final String ref;
  final List<ResolvedLine> lines;

  /// False if any part is `unverified`.
  final bool verified;
  final bool needsScholarReview;
  final List<String> sources;

  /// The meaning of a multi-line phrase as one sentence (null for one line).
  final String? wholeMeaning;

  /// True only when every line is an ayah: the one case with real audio.
  bool get hasAudio => lines.isNotEmpty && lines.every((ResolvedLine l) => l.isAyah);

  String get arabicJoined => lines.map((ResolvedLine l) => l.arabic).join(' ');
}

const String kSaheehCredit = 'Saheeh International';

class PhraseResolver {
  PhraseResolver(this.registry, this.quran);

  final PhraseRegistry registry;
  final QuranVerses quran;

  /// Resolves [ref]. [words] are word glosses a lesson supplies for an ayah
  /// (the registry carries its own for phrases). Null when it cannot be
  /// resolved, or when a phrase is not verified and carries no Arabic.
  ResolvedPhrase? resolve(String ref, {List<WordGloss>? words}) {
    if (QuranRef.looksLikeOne(ref)) return _resolveQuran(ref, words);
    final List<VerifiedPhrase>? leaves = registry.leaves(ref);
    final VerifiedPhrase? top = registry[ref];
    if (leaves == null || top == null) return null;
    final List<ResolvedLine> lines = <ResolvedLine>[];
    bool verified = true;
    bool review = false;
    final List<String> sources = <String>[];
    for (final VerifiedPhrase p in leaves) {
      final String? ar = p.arabic;
      if (ar == null || ar.trim().isEmpty) return null;
      if (p.status != PhraseStatus.verified) verified = false;
      if (p.needsScholarReview) review = true;
      for (final String s in p.sources) {
        if (!sources.contains(s)) sources.add(s);
      }
      lines.add(ResolvedLine(
        arabic: ar,
        translit: p.translit,
        meaning: p.meaning,
        words: _zip(ar, p.words),
      ));
    }
    if (top.isComposite) {
      for (final String s in top.sources) {
        if (!sources.contains(s)) sources.add(s);
      }
    }
    return ResolvedPhrase(
      ref: ref,
      lines: lines,
      verified: verified && top.status == PhraseStatus.verified,
      needsScholarReview: review || top.needsScholarReview,
      sources: sources,
      wholeMeaning: top.isComposite ? top.meaning : null,
    );
  }

  ResolvedPhrase? _resolveQuran(String ref, List<WordGloss>? words) {
    final QuranRef? q = QuranRef.tryParse(ref);
    if (q == null || !quran.has(q)) return null;
    final List<ResolvedLine> lines = <ResolvedLine>[];
    for (int a = q.from; a <= q.to; a++) {
      final Verse v = quran.verse(q.surah, a)!;
      lines.add(ResolvedLine(
        arabic: v.arabic,
        translit: quran.transliteration(q.surah, a),
        meaning: v.english,
        meaningCredit: kSaheehCredit,
        words: q.isRange ? null : _zip(v.arabic, words),
        surah: q.surah,
        ayah: a,
      ));
    }
    return ResolvedPhrase(
      ref: ref,
      lines: lines,
      verified: true,
      needsScholarReview: false,
      sources: <String>["Qur'an $q"],
    );
  }

  static List<ResolvedWord>? _zip(String arabic, List<WordGloss>? glosses) {
    final List<String> toks = tokens(arabic);
    if (glosses == null || glosses.length != toks.length) return null;
    return <ResolvedWord>[
      for (int i = 0; i < toks.length; i++)
        ResolvedWord(arabic: toks[i], tr: glosses[i].tr, en: glosses[i].en),
    ];
  }

  /// The whitespace-separated words of [arabic].
  static List<String> tokens(String arabic) =>
      arabic.trim().split(RegExp(r'\s+')).where((String t) => t.isNotEmpty).toList();

  /// The Arabic words of a single-line reference, or null.
  List<String>? wordsOf(String ref) {
    final ResolvedPhrase? p = resolve(ref);
    if (p == null || p.lines.length != 1) return null;
    return tokens(p.lines.first.arabic);
  }

  /// The Arabic of a word reference such as `q:1:2#0`, or null.
  String? wordArabic(String wordRef) {
    final int hash = wordRef.lastIndexOf('#');
    if (hash < 0) return null;
    final int? i = int.tryParse(wordRef.substring(hash + 1));
    final List<String>? toks = wordsOf(wordRef.substring(0, hash));
    if (i == null || toks == null || i < 0 || i >= toks.length) return null;
    return toks[i];
  }
}
