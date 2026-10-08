/// Word Deck — the Quranic Arabic school's core loop.
///
/// A [WordCard] is one vocabulary target: a word as it appears in the
/// Quran, its root, a short gloss, the ayah that carries it, and the
/// Al-Husary audio reference. Cards come from the verified corpus
/// (corpus.quran.com cross-checked against the Tanzil text — a word
/// that fails checksum review never ships) OR from the reader's
/// tap-a-word loop (the moat).
library;

import 'mushaf_layout.dart' show AyahLocation;
import 'recitation_audio.dart' show AyahRef;
import 'spaced_repetition.dart';

/// One vocabulary target.
class WordCard {
  const WordCard({
    required this.key,

    /// The word exactly as it appears in the Uthmani text.
    required this.arabic,
    required this.gloss,

    /// Three-letter (or topic) root in Arabic, e.g. ك ت ب.
    this.root,
    this.occurrences = 1,
    this.frequencyRank,
    this.sourceAyah,
    this.audioRef,
    required this.review,
  });

  /// Stable identity: 's:a:wordform' (surah:ayah:form) — dedupe key.
  final String key;
  final String arabic;
  final String gloss;
  final String? root;
  final int occurrences;
  final int? frequencyRank;
  final AyahRef? sourceAyah;

  /// Audio for THIS occurrence (Al-Husary per-ayah file).
  final AyahLocation? audioRef;

  final ReviewCard review;

  WordCard copyWith({ReviewCard? review}) => WordCard(
        key: key,
        arabic: arabic,
        gloss: gloss,
        root: root,
        occurrences: occurrences,
        frequencyRank: frequencyRank,
        sourceAyah: sourceAyah,
        audioRef: audioRef,
        review: review ?? this.review,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'arabic': arabic,
        'gloss': gloss,
        if (root != null) 'root': root,
        'occurrences': occurrences,
        if (frequencyRank != null) 'frequencyRank': frequencyRank,
        if (sourceAyah != null)
          'sourceAyah': <int>[sourceAyah!.surah, sourceAyah!.ayah],
        'review': review.toJson(),
      };

  factory WordCard.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? sa = json['sourceAyah'] as List<dynamic>?;
    final ReviewCard r = ReviewCard.fromJson(
      (json['review'] as Map<String, dynamic>?) ?? <String, dynamic>{
        'wordKey': json['key'],
        'dueDate': DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      },
    );
    return WordCard(
      key: json['key'] as String,
      arabic: json['arabic'] as String,
      gloss: json['gloss'] as String,
      root: json['root'] as String?,
      occurrences: (json['occurrences'] as num?)?.toInt() ?? 1,
      frequencyRank: json['frequencyRank'] as int?,
      sourceAyah: sa == null ? null : AyahRef(sa[0] as int, sa[1] as int),
      review: r.wordKey.isEmpty
          ? ReviewCard(
              wordKey: json['key'] as String,
              easiness: r.easiness,
              intervalDays: r.intervalDays,
              repetitions: r.repetitions,
              dueDate: r.dueDate,
            )
          : r,
    );
  }
}

abstract final class WordDeckEngine {
  /// Add [card] to [deck] unless its key already exists (never duplicate
  /// a word the learner has met).
  static Map<String, WordCard> addCard(
    Map<String, WordCard> deck,
    WordCard card,
  ) {
    if (deck.containsKey(card.key)) return deck;
    return <String, WordCard>{...deck, card.key: card};
  }

  /// Build today's session: due reviews first (oldest first), then fresh
  /// introductions, capped at [sessionCap] (Simplicity: small daily
  /// sessions beat marathon cramming).
  static List<WordCard> buildSession({
    required Map<String, WordCard> deck,
    required DateTime now,
    int sessionCap = 15,
  }) {
    // Fresh cards (never reviewed) enter via the fresh lane only — a
    // new word is an introduction, not a failed review.
    final List<WordCard> due = Sm2Engine.dueQueue(
      deck.values
          .where((WordCard c) => c.review.repetitions > 0)
          .map((WordCard c) => c.review)
          .toList(),
      now,
    ).map((ReviewCard r) => deck[r.wordKey]!).toList();
    final List<WordCard> fresh = Sm2Engine.freshCards(
      deck.values.map((WordCard c) => c.review).toList(),
    ).map((ReviewCard r) => deck[r.wordKey]!).toList();
    final List<WordCard> session = <WordCard>[...due, ...fresh];
    return session.length > sessionCap
        ? session.sublist(0, sessionCap)
        : session;
  }

  /// Apply a grade to the card in [deck]; returns the updated deck.
  static Map<String, WordCard> grade({
    required Map<String, WordCard> deck,
    required String key,
    required ReviewGrade grade,
    required DateTime now,
  }) {
    final WordCard? card = deck[key];
    if (card == null) return deck;
    final ReviewCard updated = Sm2Engine.schedule(card.review, grade, now);
    return <String, WordCard>{...deck, key: card.copyWith(review: updated)};
  }
}
