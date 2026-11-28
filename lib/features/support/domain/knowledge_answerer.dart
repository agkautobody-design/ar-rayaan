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

  /// Openers that mean "continue what we were just saying", not a new
  /// subject. A short question that leans on "it", "that" or "this" counts
  /// too.
  static final RegExp _followOpen = RegExp(
      r'^(?:but |ok but |okay but |i get that|i understand|i see|and |so |then |what can i do|what do i do|what should i do|where do i start|where should i start|how do i start|how can i start|how do i begin|what else|tell me more|more |give me an example|for example|like what|such as|can you say more|go on)');
  static final RegExp _followRef = RegExp(r'\b(?:it|that|this|them|those|these)\b');

  /// Whether [question] reads as a follow-up to the answer just given.
  static bool isFollowUp(String question) {
    final String n = CrisisDetector.normalize(question);
    if (n.isEmpty) return false;
    final int words = n.split(' ').where((String w) => w.isNotEmpty).length;
    if (words > 14) return false;
    if (_followOpen.hasMatch(n)) return true;
    return words <= 5 && _followRef.hasMatch(n);
  }

  /// The next answer in the pack of [previous] that the person has not seen
  /// ([isSeen] says whether a snippet id was already given), preferring a how-to and the one that fits
  /// the words of [question] best. Null when the pack has nothing left, so
  /// the normal path goes on. Never used for a support or permission
  /// snippet.
  static KnowledgeAnswer? followUp(
    String question,
    SupportSnippet previous,
    List<SupportPack> packs, {
    bool Function(String id)? isSeen,
    String ageBand = 'adult',
    String lang = 'en',
    bool allowDraft = true,
    DateTime? now,
  }) {
    final DateTime t = now ?? DateTime.now();
    final String n = CrisisDetector.normalize(question);
    final Set<String> words = tokens(question).toSet();
    KnowledgeAnswer? best;
    int bestRel = 0;
    for (final SupportPack p in packs) {
      if (p.kind != 'knowledge' || p.expiredAt(t) || p.name != previous.pack) continue;
      // Tags every snippet of the pack carries say nothing about which
      // answer comes next, so they do not count as a link.
      Set<String>? common;
      for (final SupportSnippet s in p.snippets) {
        common = common == null
            ? s.tags.toSet()
            : common.intersection(s.tags.toSet());
      }
      final Set<String> prevTags = previous.tags
          .where((String x) => !x.startsWith('go-') && !(common?.contains(x) ?? false))
          .toSet();
      for (final SupportSnippet s in p.snippets) {
        if (s.id == previous.id || (isSeen?.call(s.id) ?? false)) continue;
        if (s.askPermission || !s.matchesAge(ageBand) || s.text.isEmpty) continue;
        if (!allowDraft && !s.shippable) continue;
        final int shared = s.tags.where(prevTags.contains).length;
        // A follow-up goes on only to an answer that is linked to the last
        // one (a shared tag) or to the words just asked; otherwise the
        // normal path goes on.
        final int asked = score(s, n, words);
        if (shared == 0 && asked < 4) continue;
        final int rel = shared * 2 + asked;
        final int v = rel + (s.kind == 'howto' ? 1 : 0);
        if (best == null || v > bestRel) {
          bestRel = v;
          best = KnowledgeAnswer(text: s.textIn(lang), snippet: s, score: v);
        }
      }
    }
    return best;
  }

  /// Where an answer sends the person: its first cross-referenced Huda guide
  /// and, from a go- tag, one screen. [isGuide] says whether a guide id may
  /// be opened (the caller passes the nav list); [screens] maps a go- tag to
  /// a route the caller allows. At most two routes.
  static List<String> routesFor(
    SupportSnippet s, {
    required bool Function(String guideId) isGuide,
    required Map<String, String> screens,
  }) {
    final List<String> out = <String>[];
    for (final Map<String, dynamic> x in s.crossRef) {
      final Object? id = x['id'];
      final Object? asset = x['asset'];
      if (id is String &&
          asset is String &&
          asset.endsWith('guides/guides.json') &&
          isGuide(id)) {
        out.add('/huda/guide?id=$id');
        break;
      }
    }
    for (final String tag in s.tags) {
      if (!tag.startsWith('go-')) continue;
      final String? r = screens[tag.substring(3)];
      if (r != null && !out.contains(r)) {
        out.add(r);
        break;
      }
    }
    return out;
  }
}
