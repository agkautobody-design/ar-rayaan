/// The browser tab title for each screen (web only: it is what the tab, the
/// history list and a screen reader's "page" announcement show).
///
/// Pure and testable; `app.dart` applies it when the route changes. A path
/// that is not listed gets the plain app name, never a wrong title.
abstract final class RouteTitles {
  static const String appName = 'Ar-Rayaan';

  /// Exact paths.
  static const Map<String, String> _exact = <String, String>{
    '/': appName,
    '/home': appName,
    '/onboarding': 'Welcome',
    '/search': 'Find Anything',
    '/ramadan': 'Ramadan',
    '/finance': 'Tayyib Finance',
    '/finance/floor': 'Trading Floor',
    '/finance/rayaan': 'Rayaan Stocks',
    '/settings': 'Settings',
    '/settings/language': 'Language',
    '/masajid': 'Masajid and Halal Food',
    '/home/elder': 'Elder Home',
    '/elder-care': 'Elder Care',
    '/home/quick': 'Quick Access',
    '/kids': 'For Children',
    '/noor/reflections': 'My Reflections',
    '/games': 'Games',
    '/games/ludo': 'Ludo',
    '/games/shatranj': 'Shatranj',
    '/games/lineage': 'Lineage Challenge',
    '/games/ayah': 'Ayah Completion',
    '/games/hijrah': 'The Hijrah Journey',
    '/games/trivia': 'Trivia',
    '/games/names99': 'The 99 Names',
    '/player': 'Nasheed Player',
    '/player/my-additions': 'My Additions',
    '/player/playlists': 'My Playlists',
    '/player/request': 'Request a Nasheed',
    '/majlis': 'Majlis',
    '/majlis/new': 'New Thread',
    '/notes': 'Notes',
    '/downloads': 'Downloads',
    '/feelings': 'Feelings',
    '/huda': 'Huda Guides',
    '/huda/guide': 'Huda Guide',
    '/family-tree': 'Family Tree of the Prophets',
    '/stories': 'Stories',
    '/stories/read': 'Story',
    '/new-muslim': 'New Muslim Path',
    '/auth/login': 'Sign in',
    '/auth/signup': 'Create account',
    '/auth/reset': 'Reset password',
    '/auth/verify': 'Verify email',
    '/prayer': 'Prayer Times',
    '/quran': 'Qur’an',
    '/quran/bookmarks': 'Qur’an Bookmarks',
    '/hadith': 'Forty Hadith',
    '/adhkar': 'Dhikr and Du’a',
    '/qibla': 'Qibla',
    '/calendar': 'Islamic Calendar',
    '/zakat': 'Zakat',
    '/share': 'Share',
    '/sources': 'Sources',
    '/sources/policy': 'Content Policy',
    '/sakina': 'Sakina',
    '/sakina/steady': 'Steady Yourself',
    '/sakina/mood': 'How Are You Today',
    '/sakina/safety': 'My Safety Plan',
    '/menu': 'Menu',
    '/noor': 'Today’s NOOR',
    '/journey': 'My Journey',
    '/explore': 'Explore',
    '/family': 'Family Wing',
    '/community': 'Community',
    '/hadi': 'Hādi',
    '/profile': 'You',
    '/academy': 'Wasia Academy',
    '/academy/gate': 'Wasia Academy',
    '/academy/hifz': 'Hifz Planner',
    '/academy/arabic-language': 'Arabic Language School',
    '/academy/aqeedah': 'Aqeedah School',
    '/academy/hadith': 'Hadith School',
    '/academy/seerah': 'Seerah School',
    '/academy/history': 'History School',
    '/academy/stories': 'Stories School',
    '/academy/character': 'Character School',
    '/academy/family-life': 'Family Life School',
    '/academy/youth': 'Youth School',
    '/academy/womens': 'Women’s School',
    '/academy/transactions': 'Transactions School',
    '/academy/end-of-life': 'End of Life School',
    '/academy/dawah': 'Dawah School',
    '/academy/health': 'Health School',
    '/academy/hisn': 'Hisn al-Muslim',
    '/academy/hajj-umrah-pack': 'Hajj and Umrah',
    '/academy/ramadan-mode': 'Ramadan Mode',
    '/academy/qa': 'Questions and Answers',
    '/academy/dua': 'Du’a School',
    '/academy/audio-packs': 'Audio Packs',
    '/academy/dhikr': 'Dhikr Session',
    '/academy/review': 'Review',
    '/academy/letters': 'Letters School',
    '/academy/family': 'Family Wing',
    '/academy/recitation': 'Recitation Cards',
    '/academy/quranic-arabic': 'Quranic Arabic Words',
    '/academy/understanding': 'Understanding School',
    '/legal/terms': 'Terms of Service',
    '/legal/privacy': 'Privacy Policy',
    '/legal/delete-account': 'Delete Account',
  };

  /// Paths with an id: matched by prefix, most specific first.
  static const List<(String, String)> _prefixes = <(String, String)>[
    ('/quran/madinah/', 'Qur’an Page View'),
    ('/quran/', 'Qur’an'),
    ('/finance/rayaan/', 'Rayaan Lesson'),
    ('/majlis/thread/', 'Majlis Thread'),
    ('/feelings/', 'Feelings'),
    ('/academy/letters/lesson/', 'Letters Lesson'),
    ('/academy/exam/', 'Exam'),
    ('/academy/course/', 'Course'),
    ('/academy/lesson/', 'Lesson'),
  ];

  /// The document title for [path].
  static String forPath(String path) {
    final String p = path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final String? exact = _exact[p];
    if (exact != null) return _wrap(exact);
    for (final (String prefix, String name) in _prefixes) {
      if (p.startsWith(prefix)) return _wrap(name);
    }
    return appName;
  }

  static String _wrap(String name) =>
      name == appName ? appName : '$name \u00b7 $appName';
}
