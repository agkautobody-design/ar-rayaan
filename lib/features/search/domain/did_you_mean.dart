/// "Did you mean …" for the global search. Pure Dart — no Flutter, no I/O.
///
/// A query that is one letter away from a surah name or from a word the
/// app's own rooms answer to (but is not itself spelled that way) gets a
/// suggestion. Spellings the search already folds ("Yaseen", "Mulq",
/// "Rehman") are found directly and never produce one.
library;

import '../../quran/domain/quran_models.dart';
import 'app_destinations.dart';
import 'search_text.dart';

String _lettersOnly(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// The one suggestion for [query], or null when the query is spelled
/// correctly, is too short (under 5 letters), or is not near anything.
String? didYouMean(
  List<SurahMeta> metas,
  String query, {
  List<AppDestination> destinations = kAppDestinations,
}) {
  final List<String> words = normalizeSearchQuery(query)
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll('’', '')
      .split(RegExp(r'[^a-z]+'))
      .where((String w) => w.isNotEmpty && w != 'surah' && w != 'sura')
      .toList();
  if (words.isEmpty) return null;
  // A spelling the search already understands ("salat", "sabr") is not a typo.
  if (words.any(isKnownSpelling)) return null;
  final String folded = words.map((String w) => kSpellingFolds[w] ?? w).join();
  final String key = nameKey(folded);
  if (key.length < 5) return null;

  final RegExp article = RegExp(r'^(al|an|ar|as|ash|at|az|ad)');
  // Candidate (key, shown text, stem of the shown word).
  final List<(String, String)> candidates = <(String, String)>[];
  for (final AppDestination d in destinations) {
    for (final String phrase in <String>[...d.keywords, d.title]) {
      for (final String w in phrase
          .toLowerCase()
          .replaceAll("'", '')
          .replaceAll('’', '')
          .split(RegExp(r'[^a-z]+'))) {
        if (w.length >= 5) candidates.add((nameKey(w), w));
      }
    }
  }
  for (final SurahMeta m in metas) {
    final String name = _lettersOnly(m.transliteration);
    candidates.add((nameKey(name), m.transliteration));
    candidates.add((nameKey(name.replaceFirst(article, '')), m.transliteration));
  }

  // Spelled right already: nothing to suggest.
  for (final (String, String) c in candidates) {
    if (c.$1 == key) return null;
  }
  final String queryStem = stemWord(words.join());
  for (final (String, String) c in candidates) {
    if (c.$1.length < 5 || !withinOneEdit(key, c.$1)) continue;
    if (stemWord(_lettersOnly(c.$2)) == queryStem) continue;
    return c.$2;
  }
  return null;
}
