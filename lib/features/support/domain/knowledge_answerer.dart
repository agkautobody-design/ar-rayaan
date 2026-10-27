import '../../sakina/domain/crisis_detector.dart';
import 'support_pack.dart';

/// An answer taken from a built-in knowledge pack.
class KnowledgeAnswer {
  const KnowledgeAnswer({required this.text, required this.snippet, required this.score});

  final String text;
  final SupportSnippet snippet;
  final int score;
}

/// Answers from the broad knowledge packs (app help, Islam basics, how-tos,
/// new-Muslim, family) with no model call: the cost policy is to answer
/// offline first and use an online model only where it is allowed and needed.
///
/// Retrieval is plain words, as docs/support/pack_format.md section 8 says:
/// a trigger phrase found in the question, tag words, and the words of the
/// snippet text. A snippet answers only above a threshold and clearly ahead
/// of the next best; otherwise nothing is returned and the normal path (the
/// ruling gate, the library, the online model if allowed) goes on.
abstract final class KnowledgeAnswerer {
  static const int threshold = 5;
  static const int margin = 2;

  static const Set<String> _stop = <String>{
    'the', 'a', 'an', 'is', 'are', 'am', 'do', 'does', 'did', 'how', 'what',
    'why', 'when', 'where', 'who', 'can', 'could', 'should', 'would', 'i', 'my',
    'me', 'you', 'your', 'to', 'of', 'in', 'on', 'for', 'and', 'or', 'it', 'this',
    'that', 'with', 'about', 'be', 'there', 'any', 'have', 'has', 'if', 'so',
    'please', 'tell', 'explain', 'want', 'know', 'need',
  };

  static List<String> tokens(String text) => <String>[
        for (final String w in CrisisDetector.normalize(text).split(' '))
          if (w.length > 2 && !_stop.contains(w)) w,
      ];

  static int score(SupportSnippet s, String normalized, Set<String> words) {
    int v = 0;
    for (final String t in s.triggers) {
      final String nt = CrisisDetector.normalize(t);
      if (nt.isEmpty) continue;
      final List<String> tt = tokens(t);
      if (' $normalized '.contains(' $nt ') ||
          (tt.isNotEmpty && tt.every(words.contains))) {
        v += 4;
      }
    }
    for (final String tag in s.tags) {
      for (final String w in tokens(tag)) {
        if (words.contains(w)) v += 2;
      }
    }
    final Set<String> body = tokens(s.textIn('en')).toSet();
    int overlap = 0;
    for (final String w in words) {
      if (body.contains(w)) overlap++;
    }
    return v + (overlap > 3 ? 3 : overlap);
  }

  /// The best answer for [question] among the knowledge [packs], or null.
  /// [ageBand] is `adult` for Hadi. Snippets that need permission or are
  /// support wording are never used here.
  static KnowledgeAnswer? answer(
    String question,
    List<SupportPack> packs, {
    String ageBand = 'adult',
    String lang = 'en',
    bool allowDraft = true,
    DateTime? now,
  }) {
    final DateTime t = now ?? DateTime.now();
    final String n = CrisisDetector.normalize(question);
    final Set<String> words = tokens(question).toSet();
    if (words.isEmpty) return null;
    KnowledgeAnswer? best;
    int second = 0;
    for (final SupportPack p in packs) {
      if (p.kind != 'knowledge' || p.expiredAt(t)) continue;
      for (final SupportSnippet s in p.snippets) {
        if (s.askPermission || !s.matchesAge(ageBand) || s.text.isEmpty) continue;
        if (!allowDraft && !s.shippable) continue;
        final int v = score(s, n, words);
        if (best == null || v > best.score) {
          if (best != null) second = best.score;
          best = KnowledgeAnswer(text: s.textIn(lang), snippet: s, score: v);
        } else if (v > second) {
          second = v;
        }
      }
    }
    final KnowledgeAnswer? b = best;
    if (b == null || b.score < threshold || b.score - second < margin) return null;
    return b;
  }
}
