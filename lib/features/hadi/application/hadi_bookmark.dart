import '../../stories/domain/story.dart';

/// "Bookmark Yusuf": reads a request to save a story and finds the story it
/// names. Pure Dart, so it is tested without a controller. The controller
/// does the saving itself and only says "saved" after the story is really in
/// the saved set; a request that names no story is left to the normal flow.
abstract final class HadiBookmark {
  static List<String> _words(String s) {
    final String lower = s.toLowerCase().replaceAll(RegExp(r'[’‘`]'), '');
    return <String>[
      for (final String w in lower.replaceAll("'", '').split(RegExp(r'[^a-z0-9]+')))
        if (w.isNotEmpty) w,
    ];
  }

  static final RegExp _request = RegExp(
    r'^(?:(?:please|pls|can you|could you|would you|will you|kindly|hadi|hey|'
    r'ok|okay)\s+)*(?:bookmark|save|add)\s+(.+)$',
  );

  /// Words that do not name a story.
  static const Set<String> _filler = <String>{
    'the', 'this', 'that', 'story', 'stories', 'of', 'a', 'an', 'about', //
    'to', 'my', 'bookmarks', 'bookmark', 'saved', 'favourites', //
    'favorites', 'favourite', 'favorite', 'journey', 'later', 'please', //
    'pls', 'in', 'into', 'for', 'on', 'list', 'it', 'me', 'now', //
  };

  /// The words that name the story in [question], or null when the question
  /// is not a request to save something that could be a story.
  static List<String>? titleWords(String question) {
    final String n = _words(question).join(' ');
    final RegExpMatch? m = _request.firstMatch(n);
    if (m == null) return null;
    final List<String> words = <String>[
      for (final String w in m.group(1)!.split(' '))
        if (!_filler.contains(w)) w,
    ];
    if (words.isEmpty || words.length > 6) return null;
    return words;
  }

  /// The stories whose title contains every one of [words]. When one title
  /// is exactly the words, only that one.
  static List<Story> match(List<String> words, List<Story> stories) {
    final Set<String> want = words.toSet();
    final List<Story> hits = <Story>[
      for (final Story s in stories)
        if (s.duplicateOf == null && _words(s.title).toSet().containsAll(want))
          s,
    ];
    final List<Story> exact = <Story>[
      for (final Story s in hits)
        if (_words(s.title.split('(').first).toSet().difference(want).isEmpty &&
            _words(s.title.split('(').first).isNotEmpty)
          s,
    ];
    final List<Story> chosen = exact.isNotEmpty ? exact : hits;
    // The same title listed twice is one story to the person.
    final Set<String> seen = <String>{};
    return <Story>[
      for (final Story s in chosen)
        if (seen.add(s.title)) s,
    ];
  }
}
