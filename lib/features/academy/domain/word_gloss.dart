/// Word glosses for the Qur'anic Arabic deck.
///
/// `assets/academy/word_pack.json` is pinned by a checksum and carries no
/// verified meanings, so the meanings live in their own file,
/// `assets/academy/word_glosses.json`, and are merged onto the cards when
/// they load. Each entry is keyed by the card key (`surah:ayah:form`).
library;

import 'dart:convert';

import 'word_deck.dart';

/// The named source shown as the provenance of every merged meaning. A card
/// without a named source never shows its meaning (see [WordCard.hasMeaning]).
const String kWordGlossSource =
    'Ar-Rayaan word glosses v1 (written for this app, not yet scholar-reviewed)';

/// One meaning (and, for content words, the root) for a deck card.
class WordGloss {
  const WordGloss({required this.key, required this.gloss, this.root});

  final String key;
  final String gloss;
  final String? root;
}

/// Parses `word_glosses.json`. Entries with an empty key or gloss are
/// dropped: a blank meaning is never merged.
Map<String, WordGloss> parseWordGlosses(String raw) {
  final Map<String, dynamic> doc = jsonDecode(raw) as Map<String, dynamic>;
  final Map<String, WordGloss> out = <String, WordGloss>{};
  for (final Object? e in (doc['glosses'] as List<dynamic>? ?? <dynamic>[])) {
    final Map<String, dynamic> j = e as Map<String, dynamic>;
    final String key = (j['key'] as String? ?? '').trim();
    final String gloss = (j['gloss'] as String? ?? '').trim();
    if (key.isEmpty || gloss.isEmpty) continue;
    out[key] = WordGloss(
      key: key,
      gloss: gloss,
      root: (j['root'] as String?)?.trim().isEmpty ?? true
          ? null
          : (j['root'] as String).trim(),
    );
  }
  return out;
}

/// Returns [card] with the meaning from [glosses] when the card has no
/// meaning of its own. A card the learner added from the reader with its own
/// named source is left alone; learner progress ([WordCard.review]) is never
/// touched.
WordCard withGloss(WordCard card, Map<String, WordGloss> glosses) {
  final WordGloss? g = glosses[card.key];
  if (g == null || card.hasMeaning) return card;
  return card.copyWith(
    gloss: g.gloss,
    root: g.root ?? card.root,
    glossSource: kWordGlossSource,
  );
}
