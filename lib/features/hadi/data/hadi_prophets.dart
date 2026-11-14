import 'dart:convert';

import '../../../app/core/content/content_sync.dart';
import '../../sakina/domain/crisis_detector.dart';

/// "Tell me the story of Prophet Yunus", "who was Hud?", "what happened to
/// the people of Lut?": answered from the app's own prophet stories
/// (assets/stories/prophets.json), quoted and never rewritten, with a button
/// to the full story.
///
/// Before this, Hādi knew only a handful of prophets by hand. A question about
/// any other one either fell to "not on my shelf" (Hud) or, worse, matched the
/// words "prophet" and "story" to the life of the Prophet Muhammad ﷺ (Yunus).
abstract final class HadiProphets {
  /// Every reply starts with this, so the controller treats it as a fixed
  /// answer and never swaps it for a looser library match.
  static const String opener = 'as the app tells it';

  static bool isReply(String answer) => answer.contains(opener);

  /// Story id → the names people use for that prophet. A name marked with a
  /// leading `!` is also an everyday English word ("lot", "job"), so it only
  /// counts next to "prophet" or "nabi".
  static const Map<String, List<String>> names = <String, List<String>>{
    'prophet-adam': <String>['adam'],
    'prophet-idris': <String>['idris', 'enoch'],
    'prophet-nuh': <String>['nuh', 'nooh', 'noah'],
    'prophet-hud': <String>['hud', '!hood', 'aad'],
    'prophet-salih': <String>['salih', 'saleh', 'thamud', 'the she camel'],
    'prophet-ibrahim': <String>['ibrahim', 'ebrahim', 'abraham'],
    'prophet-lut': <String>['lut', 'loot', '!lot'],
    'prophet-ismail': <String>['ismail', 'ismael', 'ishmael'],
    'prophet-ishaq': <String>['ishaq', 'isaac'],
    'prophet-yaqub': <String>['yaqub', 'yaqoob', 'yakub', 'jacob'],
    'prophet-yusuf': <String>['yusuf', 'yousuf', 'yusef', 'joseph'],
    'prophet-ayyub': <String>['ayyub', 'ayub', 'ayoub', '!job'],
    'prophet-shuayb': <String>['shuayb', 'shuaib', 'shoaib', 'madyan', 'midian'],
    'prophet-musa': <String>['musa', 'moosa', 'moses'],
    'prophet-harun': <String>['harun', 'haroon', 'aaron'],
    'prophet-dhul-kifl': <String>['dhul kifl', 'dhulkifl', 'zulkifl', 'zul kifl'],
    'prophet-dawud': <String>['dawud', 'dawood', 'daud', '!david'],
    'prophet-sulayman': <String>['sulayman', 'sulaiman', 'suleiman', 'solomon'],
    'prophet-ilyas': <String>['ilyas', 'elias', 'elijah'],
    'prophet-alyasa': <String>['alyasa', 'al yasa', 'elisha'],
    'prophet-yunus': <String>['yunus', 'younus', 'yunis', 'jonah', 'dhun nun', 'man of the fish'],
    'prophet-zakariya': <String>['zakariya', 'zakariyya', 'zakaria', 'zechariah', 'zachariah', 'yahya', '!john the baptist'],
    'prophet-isa': <String>['isa', 'eesa', 'jesus'],
  };

  static final RegExp _listAsk = RegExp(
    r'\b(?:(?:list|name|names|all|every|order\s+of|how\s+many)\s+(?:of\s+)?(?:the\s+)?(?:25\s+|twenty\s*five\s+)?prophets|'
    r'prophets\s+(?:in\s+order|mentioned|named)|25\s+prophets|twenty\s*five\s+prophets)\b',
  );

  /// "List all the prophets in order", "how many prophets are named".
  static bool asksList(String question) =>
      _listAsk.hasMatch(CrisisDetector.normalize(question));

  /// All twenty-five named prophets, with a way into their stories. Carries
  /// [opener] so the controller keeps it as written.
  static const String listReply =
      'The Qur\'an names twenty-five prophets, $opener from Adam, the first, '
      'to Muhammad, the last. The Qur\'an does not give one fixed order for '
      'all of them; this is the order the app\'s stories follow where they '
      'can: Adam, Idris, Nuh, Hud, Salih, Ibrahim, Lut, Ismail, Ishaq, '
      'Yaqub, Yusuf, Ayyub, Shuayb, Musa, Harun, Dhul-Kifl, Dawud, Sulayman, '
      'Ilyas, Al-Yasa, Yunus, Zakariya, Yahya, Isa and Muhammad, peace be '
      'upon them all. Ask me for any one of them, for example "tell me the '
      'story of Yusuf", or open the stories shelf.\n[GO:/stories]';

  static final RegExp _storyCue = RegExp(
    r'\b(?:story|stories|believe\w*\s+(?:about|of)|say\w*\s+about|teach\w*\s+about|tell me about|tell me of|teach me about|who was|who is|'
    r'who were|life of|history of|what happened to|learn about|know about|'
    r'about (?:the )?prophet|about nabi|narrate|qissa|qisas)\b',
  );
  static final RegExp _prophetWord =
      RegExp(r'\b(?:prophet|prophets|nabi|messenger|rasul|peace be upon him|pbuh)\b');

  /// The story id a question asks for, or null. The question must name a
  /// prophet and ask for a story ("story", "tell me about", "who was", "what
  /// happened to"), or name him as a prophet. Isa is matched only on a story
  /// cue, so "why is Jesus not God?" keeps its own answer.
  /// A question about a ruling, a name for a child or a du'a mentions a
  /// prophet without asking for his story.
  static final RegExp _notAStory = RegExp(
    r'\b(?:halal|haram|allowed|permissible|permitted|ruling|fatwa|can i|'
    r'is it ok|name my|baby name|dua of|duaa of|supplication of)\b',
  );

  static String? storyIdFor(String question) {
    final String n = ' ${CrisisDetector.normalize(question)} ';
    if (_notAStory.hasMatch(n)) return null;
    final bool cue = _storyCue.hasMatch(n);
    final bool prophetWord = _prophetWord.hasMatch(n);
    if (!cue && !prophetWord) return null;
    // The prophet named first in the question wins ("Musa and Harun" is
    // Musa's story).
    String? found;
    int foundAt = 1 << 30;
    for (final MapEntry<String, List<String>> e in names.entries) {
      if (e.key == 'prophet-isa' && !cue) continue;
      for (final String raw in e.value) {
        final bool common = raw.startsWith('!');
        final String name = common ? raw.substring(1) : raw;
        final RegExp re = common
            ? RegExp('\\b(?:(?:prophet|nabi)|(?:story|life|history) of) $name\\b')
            : RegExp('\\b$name\\b');
        final RegExpMatch? m = re.firstMatch(n);
        if (m == null) continue;
        if (m.start < foundAt) {
          found = e.key;
          foundAt = m.start;
        }
      }
    }
    return found;
  }

  static List<dynamic>? _stories;

  /// Test hook: the stories to answer from instead of the bundled pack.
  static void debugSetStories(List<dynamic>? stories) => _stories = stories;

  static Future<List<dynamic>?> _load() async {
    if (_stories != null) return _stories;
    try {
      _stories = await ContentSync.loadParsed<List<dynamic>>(
        'stories/prophets.json',
        (String raw) => json.decode(raw) as List<dynamic>,
      );
    } catch (_) {
      return null;
    }
    return _stories;
  }

  /// The reply for [question], or null when it does not ask for a prophet's
  /// story or the story cannot be read.
  static Future<String?> reply(String question) async {
    if (asksList(question)) return listReply;
    final String? id = storyIdFor(question);
    if (id == null) return null;
    final List<dynamic>? stories = await _load();
    if (stories == null) return null;
    Map<dynamic, dynamic>? story;
    for (final dynamic s in stories) {
      if (s is Map && s['id'] == id) {
        story = s;
        break;
      }
    }
    if (story == null) return null;
    return compose(story, askedYahya: _asksYahya(question));
  }

  static bool _asksYahya(String q) =>
      RegExp(r'\b(?:yahya|john the baptist)\b')
          .hasMatch(CrisisDetector.normalize(q));

  /// Builds the reply from one story entry: its title and subtitle, the first
  /// chapter (cut at a sentence end, verbatim), the other chapter headings,
  /// the sources, and a button to the full story.
  static String compose(Map<dynamic, dynamic> story, {bool askedYahya = false}) {
    final String id = story['id'] as String;
    final String title = (story['title'] as String? ?? '').trim();
    final String subtitle = (story['subtitle'] as String? ?? '').trim();
    final List<Map<dynamic, dynamic>> chapters = <Map<dynamic, dynamic>>[
      for (final dynamic c in (story['chapters'] as List<dynamic>? ?? const <dynamic>[]))
        if (c is Map && c['body'] is String) c,
    ];
    if (chapters.isEmpty) return '';
    // For Yahya, open at the good news of his birth (Zakariya's story holds it).
    int start = 0;
    if (askedYahya) {
      for (int i = 0; i < chapters.length; i++) {
        final String b = chapters[i]['body'] as String;
        if (b.contains('John') || b.contains('Yahya')) {
          start = i;
          break;
        }
      }
    }
    final Map<dynamic, dynamic> first = chapters[start];
    final StringBuffer b = StringBuffer();
    if (askedYahya) {
      b.write('Yahya (John) is born in the story of his father Zakariya, '
          '$opener');
    } else {
      b.write('Here is the story of $title, $opener');
    }
    b.write(subtitle.isEmpty ? '.' : ': ${_lower(subtitle)}.');
    b.write('\n\n');
    final String heading = (first['heading'] as String? ?? '').trim();
    if (heading.isNotEmpty) b.write('$heading\n');
    b.write(excerpt(first['body'] as String));
    final List<String> rest = <String>[
      for (int i = 0; i < chapters.length; i++)
        if (i != start && (chapters[i]['heading'] as String? ?? '').trim().isNotEmpty)
          (chapters[i]['heading'] as String).trim(),
    ];
    if (rest.isNotEmpty) {
      b.write('\n\nThe full story goes on: ${rest.join(' · ')}.');
    }
    final List<String> sources = <String>[
      for (final dynamic s in (story['sources'] as List<dynamic>? ?? const <dynamic>[]))
        if (s is String) s,
    ];
    if (sources.isNotEmpty) {
      b.write('\nSources: ${sources.take(3).join('; ')}'
          '${sources.length > 3 ? '; and more in the story' : ''}.');
    }
    b.write('\n[GO:/stories/read?id=$id]');
    return b.toString();
  }

  static String _lower(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// The first ~900 characters of [text], cut at a sentence end. A verbatim
  /// cut, never a rewrite.
  static String excerpt(String text, {int max = 900}) {
    final String s = text.trim();
    if (s.length <= max) return s;
    final String cut = s.substring(0, max);
    int end = -1;
    for (final String m in <String>['. ', '! ', '? ', ".' ", '.’ ', ').']) {
      final int i = cut.lastIndexOf(m);
      if (i > end) end = i + m.trimRight().length - 1;
    }
    return end > 250 ? cut.substring(0, end + 1).trimRight() : cut.trimRight();
  }
}
