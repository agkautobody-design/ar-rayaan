/// The verified-phrase registry: every non-Qur'anic Arabic phrase an Academy
/// v3 lesson may show (the shahada, the takbir, the tashahhud ...).
///
/// A lesson never contains Arabic of its own. It names a phrase here by id.
/// Each phrase records where its Arabic was copied from, whether that copy
/// was checked against the primary-source text (`verified`) or not
/// (`unverified`), and whether a scholar still has to review it
/// (`needsScholarReview`). Files live in `assets/academy/phrases/*.json`, one
/// per author, and are merged at load time so parallel authors never edit the
/// same file. Pure Dart.
library;

import 'dart:convert';

enum PhraseStatus { verified, unverified }

/// One word of a phrase with its transliteration and English gloss.
class WordGloss {
  const WordGloss({required this.tr, required this.en});

  final String tr;
  final String en;
}

class VerifiedPhrase {
  const VerifiedPhrase({
    required this.id,
    required this.translit,
    required this.meaning,
    required this.sources,
    required this.status,
    required this.needsScholarReview,
    this.arabic,
    this.parts = const <String>[],
    this.words,
    this.copiedFrom,
    this.reviewNote = '',
  });

  final String id;

  /// The Arabic, copied from the cited text. Null for a composite phrase.
  final String? arabic;

  /// A composite phrase is the in-order concatenation of these phrase ids and
  /// has no Arabic of its own.
  final List<String> parts;

  final String translit;
  final String meaning;

  /// Optional word-by-word glosses, one per whitespace-separated Arabic word.
  final List<WordGloss>? words;

  /// What the learner is shown as the source ("Muslim 403", ...).
  final List<String> sources;
  final PhraseStatus status;
  final bool needsScholarReview;
  final String? copiedFrom;
  final String reviewNote;

  bool get isComposite => parts.isNotEmpty;
}

class PhraseRegistry {
  PhraseRegistry(this.phrases);

  /// Merges several registry files. A phrase id that appears in two files is
  /// a mistake and is reported by [duplicates].
  factory PhraseRegistry.parseAll(List<String> jsonFiles) {
    final Map<String, VerifiedPhrase> all = <String, VerifiedPhrase>{};
    final List<String> dup = <String>[];
    for (final String raw in jsonFiles) {
      final Map<String, dynamic> doc = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic> ps = doc['phrases'] as Map<String, dynamic>;
      ps.forEach((String id, dynamic v) {
        if (all.containsKey(id)) dup.add(id);
        all[id] = _parsePhrase(id, v as Map<String, dynamic>);
      });
    }
    final PhraseRegistry r = PhraseRegistry(all);
    r.duplicates.addAll(dup);
    return r;
  }

  static VerifiedPhrase _parsePhrase(String id, Map<String, dynamic> m) {
    final List<dynamic>? w = m['words'] as List<dynamic>?;
    return VerifiedPhrase(
      id: id,
      arabic: m['arabic'] as String?,
      parts: <String>[
        for (final dynamic p in (m['parts'] as List<dynamic>? ?? <dynamic>[]))
          p as String,
      ],
      translit: m['translit'] as String? ?? '',
      meaning: m['meaning'] as String? ?? '',
      words: w == null
          ? null
          : <WordGloss>[
              for (final dynamic x in w)
                WordGloss(
                  tr: (x as Map<String, dynamic>)['tr'] as String,
                  en: x['en'] as String,
                ),
            ],
      sources: <String>[
        for (final dynamic s in (m['sources'] as List<dynamic>? ?? <dynamic>[]))
          s as String,
      ],
      status: m['status'] == 'verified'
          ? PhraseStatus.verified
          : PhraseStatus.unverified,
      needsScholarReview: m['needsScholarReview'] as bool? ?? true,
      copiedFrom: m['copiedFrom'] as String?,
      reviewNote: m['reviewNote'] as String? ?? '',
    );
  }

  final Map<String, VerifiedPhrase> phrases;

  /// Ids defined by more than one file.
  final List<String> duplicates = <String>[];

  VerifiedPhrase? operator [](String id) => phrases[id];

  /// The single-line phrases a phrase is made of, in order (the phrase itself
  /// when it is not composite). Null when any part is missing.
  List<VerifiedPhrase>? leaves(String id, [int depth = 0]) {
    final VerifiedPhrase? p = phrases[id];
    if (p == null || depth > 4) return null;
    if (!p.isComposite) return <VerifiedPhrase>[p];
    final List<VerifiedPhrase> out = <VerifiedPhrase>[];
    for (final String part in p.parts) {
      final List<VerifiedPhrase>? sub = leaves(part, depth + 1);
      if (sub == null) return null;
      out.addAll(sub);
    }
    return out;
  }

  /// Problems with the registry itself (empty when it is sound).
  List<String> problems() {
    final List<String> out = <String>[
      for (final String d in duplicates) 'phrase "$d" is defined twice',
    ];
    for (final VerifiedPhrase p in phrases.values) {
      if (p.translit.trim().isEmpty) out.add('${p.id}: no transliteration');
      if (p.meaning.trim().isEmpty) out.add('${p.id}: no meaning');
      if (p.sources.isEmpty) out.add('${p.id}: no source');
      if (p.isComposite) {
        if (p.arabic != null) out.add('${p.id}: composite phrase has its own Arabic');
        if (leaves(p.id) == null) out.add('${p.id}: a part does not exist');
        continue;
      }
      final String? ar = p.arabic;
      if (p.status == PhraseStatus.verified) {
        if (ar == null || ar.trim().isEmpty) {
          out.add('${p.id}: verified but has no Arabic');
        }
        if ((p.copiedFrom ?? '').isEmpty) {
          out.add('${p.id}: verified but says nothing about where it was copied from');
        }
      }
      if (ar != null && ar.trim().isNotEmpty) {
        if (!RegExp(r'[؀-ۿ]').hasMatch(ar)) {
          out.add('${p.id}: Arabic field holds no Arabic letters');
        }
        final List<WordGloss>? w = p.words;
        if (w != null && w.length != ar.trim().split(RegExp(r'\s+')).length) {
          out.add('${p.id}: ${w.length} word glosses for '
              '${ar.trim().split(RegExp(r'\s+')).length} Arabic words');
        }
      }
    }
    return out;
  }
}
