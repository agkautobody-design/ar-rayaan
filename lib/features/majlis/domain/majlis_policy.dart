/// Client-side rules for the Courtyard. The authoritative limits live in
/// `firestore.rules`; this mirrors them so people get a clear message
/// instead of a silent permission error.
class MajlisPolicy {
  const MajlisPolicy._();

  static const int nameMin = 2;
  static const int nameMax = 30; // rules allow up to 40
  static const int titleMin = 4;
  static const int titleMax = 140;
  static const int bodyMax = 2000;

  /// Minimum gap between two writes by one person (rules enforce 20 s).
  static const Duration minGap = Duration(seconds: 25);

  /// At most this many writes per rolling hour.
  static const int maxPerHour = 12;

  /// Words nobody may use as (or inside) a display name: the app, its
  /// assistants, staff roles, and scholarly titles that would let someone
  /// pass opinions off as authority.
  static const Set<String> reservedWords = <String>{
    'hadi',
    'sakina',
    'noor',
    'wasia',
    'admin',
    'administrator',
    'moderator',
    'mod',
    'staff',
    'team',
    'official',
    'support',
    'founder',
    'shaykh',
    'sheikh',
    'sheik',
    'shaikh',
    'imam',
    'mufti',
    'scholar',
    'ustadh',
    'ustaz',
    'allama',
    'hafiz',
  };

  /// Reserved when found anywhere in the name with separators removed.
  static const Set<String> reservedFragments = <String>{
    'arrayaan',
    'arrayyan',
    'rayaanapp',
    'arrayaanteam',
  };

  static const Map<String, String> _fold = <String, String>{
    'ā': 'a',
    'ī': 'i',
    'ū': 'u',
    'ḥ': 'h',
    'á': 'a',
    'à': 'a',
    'é': 'e',
    'è': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '@': 'a',
    '\$': 's',
  };

  /// Lower-cases, folds look-alike characters and digits, and returns the
  /// name as a list of plain-letter words.
  static List<String> nameWords(String name) {
    final b = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      b.write(_fold[ch] ?? ch);
    }
    return b
        .toString()
        .split(RegExp(r'[^a-z؀-ۿ]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Null when [name] may be used, otherwise a message for the person.
  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < nameMin) {
      return 'Please choose a display name of at least $nameMin characters.';
    }
    if (trimmed.length > nameMax) {
      return 'Display names can be at most $nameMax characters.';
    }
    final words = nameWords(trimmed);
    for (final w in words) {
      if (reservedWords.contains(w)) {
        return 'That name is reserved. Please choose another display name.';
      }
    }
    final collapsed = words.join();
    for (final f in reservedFragments) {
      if (collapsed.contains(f)) {
        return 'That name is reserved. Please choose another display name.';
      }
    }
    return null;
  }

  static String? validateTitle(String title) {
    final t = title.trim();
    if (t.length < titleMin) return 'Give the thread a title of a few words.';
    if (t.length > titleMax) return 'Titles can be at most $titleMax characters.';
    return null;
  }

  static String? validateBody(String body) {
    final t = body.trim();
    if (t.isEmpty) return 'Write something first.';
    if (t.length > bodyMax) return 'Posts can be at most $bodyMax characters.';
    return null;
  }

  /// Decides whether another write is allowed given the times of the
  /// person's recent writes (most recent last). Returns null if allowed,
  /// otherwise how long to wait.
  static Duration? waitBeforeNextPost(List<DateTime> recent, DateTime now) {
    if (recent.isNotEmpty) {
      final sinceLast = now.difference(recent.last);
      if (sinceLast < minGap) return minGap - sinceLast;
    }
    final hourAgo = now.subtract(const Duration(hours: 1));
    final inHour = recent.where((t) => t.isAfter(hourAgo)).toList()..sort();
    if (inHour.length >= maxPerHour) {
      return inHour.first.add(const Duration(hours: 1)).difference(now);
    }
    return null;
  }

  static const List<String> reportReasons = <String>[
    'harassment',
    'hate',
    'unsafe',
    'misinformation',
    'spam',
    'other',
  ];

  static const Map<String, String> reportLabels = <String, String>{
    'harassment': 'Harassment or bullying',
    'hate': 'Hateful or abusive',
    'unsafe': 'Self-harm, abuse or danger to someone',
    'misinformation': 'Presents a ruling or hadith wrongly',
    'spam': 'Spam or advertising',
    'other': 'Something else',
  };
}
