/// The app's own rooms, findable from the global search ("qibla", "tasbih",
/// "99 names", "hifz"…). Pure Dart — no Flutter, no I/O — so the list and the
/// matching are unit-tested with the plain Dart SDK.
///
/// Every [AppDestination.route] must be a route that exists in
/// `lib/app/router.dart` (a test asserts it). Nothing here is content: a
/// destination only names a screen that already exists and says honestly
/// what is on it.
library;

import 'search_text.dart';

class AppDestination {
  const AppDestination({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.keywords,
  });

  final String id;
  final String title;
  final String subtitle;

  /// A concrete router path (no parameters).
  final String route;

  /// Words and phrases people type to look for this screen.
  final List<String> keywords;

  /// Academy screens disappear with the Academy kill switch.
  bool get isAcademy => route.startsWith('/academy');
}

const List<AppDestination> kAppDestinations = <AppDestination>[
  AppDestination(
    id: 'qibla',
    title: 'Qibla Finder',
    subtitle: 'Find the direction of the Ka‘ba',
    route: '/qibla',
    keywords: <String>['qibla', 'kaaba', 'kabah', 'kaba', 'direction of prayer'],
  ),
  AppDestination(
    id: 'prayer-times',
    title: 'Prayer Times',
    subtitle: 'Today’s five prayers, with alerts',
    route: '/prayer',
    keywords: <String>[
      'prayer times',
      'prayer time',
      'salah times',
      'when to pray',
      'fajr',
      'dhuhr',
      'zuhr',
      'asr',
      'maghrib',
      'isha',
      'adhan',
      'athan',
      'azan',
    ],
  ),
  AppDestination(
    id: 'huda',
    title: 'Huda — Worship Guides',
    subtitle: 'Step-by-step guides: prayer, wudu, fasting, hajj and more',
    route: '/huda',
    keywords: <String>[
      'how to pray',
      'how to pray salah',
      'worship guides',
      'guides',
      'step by step',
      'huda',
    ],
  ),
  AppDestination(
    id: 'tasbih',
    title: 'Dhikr Session · tasbih counter',
    subtitle: 'Count SubhanAllah, Alhamdulillah and Allahu Akbar to 33',
    route: '/academy/dhikr',
    keywords: <String>[
      'tasbih',
      'tasbih counter',
      'dhikr counter',
      'counter',
      'prayer beads',
      'subhanallah',
      'dhikr session',
    ],
  ),
  AppDestination(
    id: 'tasbeeh-counter',
    title: 'Tasbeeh Counter',
    subtitle: 'A plain tap counter with your own target',
    route: '/tasbeeh',
    keywords: <String>[
      'tasbih',
      'tasbeeh',
      'tasbih counter',
      'counter',
      'dhikr counter',
      '33',
    ],
  ),
  AppDestination(
    id: 'adhkar',
    title: 'Dhikr and Du’a',
    subtitle: 'Morning, evening, sleep, worry, travel and more — pick your moment',
    route: '/adhkar',
    keywords: <String>[
      'dhikr',
      'dua',
      'worry',
      'anxiety',
      'before sleep',
      'waking up',
      'supplication',
      'hisn al muslim',
      'morning evening',
      'remembrance',
    ],
  ),
  AppDestination(
    id: 'names99',
    title: 'The 99 Names of Allah',
    subtitle: 'Learn and play with the Beautiful Names',
    route: '/games/names99',
    keywords: <String>[
      '99 names',
      'names of allah',
      'asma ul husna',
      'asmaul husna',
      'asma al husna',
      'al asma ul husna',
      'beautiful names',
    ],
  ),
  AppDestination(
    id: 'calendar',
    title: 'Islamic Calendar',
    subtitle: 'The Hijri date and the months',
    route: '/calendar',
    keywords: <String>[
      'calendar',
      'islamic calendar',
      'hijri',
      'hijri date',
      'islamic date',
      'islamic months',
      'hijri converter',
      'date converter',
      'converter',
    ],
  ),
  AppDestination(
    id: 'masajid',
    title: 'Masajid and Halal Food',
    subtitle: 'Mosques and halal food near you (needs internet)',
    route: '/masajid',
    keywords: <String>[
      'masjid',
      'masjid near me',
      'mosque near me',
      'halal food',
      'halal restaurant',
      'halal restaurants',
    ],
  ),
  AppDestination(
    id: 'family-tree',
    title: 'The Messengers’ Family Tree',
    subtitle: 'The lineage of the Prophets',
    route: '/family-tree',
    keywords: <String>[
      'family tree',
      'lineage',
      'genealogy',
      'tree of the prophets',
      'messengers tree',
    ],
  ),
  AppDestination(
    id: 'letters',
    title: 'Letters School',
    subtitle: 'Learn the Arabic letters, lesson by lesson',
    route: '/academy/letters',
    keywords: <String>[
      'letters',
      'arabic letters',
      'alphabet',
      'arabic alphabet',
      'alif ba ta',
    ],
  ),
  AppDestination(
    id: 'arabic-language',
    title: 'Arabic Language School',
    subtitle: 'Learn Arabic',
    route: '/academy/arabic-language',
    keywords: <String>['learn arabic', 'arabic language', 'arabic'],
  ),
  AppDestination(
    id: 'trivia',
    title: 'Islamic Trivia',
    subtitle: 'A quiz of questions',
    route: '/games/trivia',
    keywords: <String>['trivia', 'quiz', 'quizzes'],
  ),
  AppDestination(
    id: 'games',
    title: 'Games',
    subtitle: 'Shatranj, Ludo, Trivia, the 99 Names and more',
    route: '/games',
    keywords: <String>['games', 'game', 'chess', 'shatranj', 'ludo'],
  ),
  AppDestination(
    id: 'hifz',
    title: 'Hifz Planner',
    subtitle: 'Plan your Qur’an memorisation',
    route: '/academy/hifz',
    keywords: <String>[
      'hifz',
      'memorize',
      'memorise',
      'memorization',
      'memorisation',
      'hafiz',
    ],
  ),
  AppDestination(
    id: 'tajweed',
    title: 'Tajweed Rule Cards',
    subtitle: 'Recitation rules with examples (pending scholar review)',
    route: '/academy/recitation',
    keywords: <String>['tajweed', 'tajwid', 'recitation', 'recitation cards'],
  ),
  AppDestination(
    id: 'zakat',
    title: 'Zakat Calculator',
    subtitle: 'Work out the zakat you owe',
    route: '/zakat',
    keywords: <String>['zakat', 'nisab', 'charity', 'alms'],
  ),
  AppDestination(
    id: 'ramadan',
    title: 'Ramadan',
    subtitle: 'Fasting, suhoor, iftar and the nights of Ramadan',
    route: '/ramadan',
    keywords: <String>['ramadan', 'fasting', 'iftar', 'suhoor', 'sehri'],
  ),
  AppDestination(
    id: 'quran',
    title: 'The Qur’an',
    subtitle: 'All 114 surahs, Arabic and English',
    route: '/quran',
    keywords: <String>['quran', 'read quran', 'surah list', 'mushaf'],
  ),
  AppDestination(
    id: 'quran-bookmarks',
    title: 'Qur’an Bookmarks',
    subtitle: 'Verses you saved',
    route: '/quran/bookmarks',
    keywords: <String>['bookmark', 'bookmarks', 'quran bookmarks'],
  ),
  AppDestination(
    id: 'hadith',
    title: 'The Forty Hadith',
    subtitle: 'an-Nawawi’s collection, Arabic and English',
    route: '/hadith',
    keywords: <String>['hadith', 'forty hadith', '40 hadith', 'nawawi'],
  ),
  AppDestination(
    id: 'stories',
    title: 'Stories',
    subtitle: 'Prophets, companions, khutbahs and daily duas',
    route: '/stories',
    keywords: <String>['stories', 'story', 'khutbah', 'khutbahs'],
  ),
  AppDestination(
    id: 'seerah',
    title: 'Seerah School',
    subtitle: 'The life of the Prophet ﷺ',
    route: '/academy/seerah',
    keywords: <String>[
      'seerah',
      'sirah',
      'life of the prophet',
      'biography of the prophet',
    ],
  ),
  AppDestination(
    id: 'nikah-guide',
    title: 'Marriage — The Nikah',
    subtitle: 'The Huda guide: consent, guardian, witnesses, mahr',
    route: '/huda/guide?id=huda-nikah',
    keywords: <String>[
      'nikah',
      'marriage',
      'getting married',
      'wedding',
      'marry',
    ],
  ),
  AppDestination(
    id: 'night-prayer',
    title: 'Tahajjud — Witr and the night routine',
    subtitle: 'The Huda guide to the night prayer',
    route: '/huda/guide?id=huda-witr',
    keywords: <String>[
      'tahajjud',
      'tahajud',
      'tahajood',
      'night prayer',
      'qiyam al layl',
      'qiyam',
      'witr',
      'late night prayer',
    ],
  ),
  AppDestination(
    id: 'patience',
    title: 'Hardship & Relief',
    subtitle: 'The Huda guide for the tested: the dua of distress and more',
    route: '/huda/guide?id=huda-hardship',
    keywords: <String>[
      'patience',
      'sabr',
      'hardship',
      'trials',
      'difficulty',
      'distress',
    ],
  ),
  AppDestination(
    id: 'jumuah',
    title: 'Jumu’ah — set your mosque’s time',
    subtitle: 'On Prayer Times, with a link to find a masjid',
    route: '/prayer',
    keywords: <String>['jumuah', 'jumah', 'juma', 'friday prayer'],
  ),
  AppDestination(
    id: 'marriage',
    title: 'Family Life School',
    subtitle: 'Marriage and the home (see also the Huda guide on the Nikah)',
    route: '/academy/family-life',
    keywords: <String>['marriage', 'family life', 'husband', 'wife'],
  ),
  AppDestination(
    id: 'hajj',
    title: 'Hajj and Umrah',
    subtitle: 'The pilgrimage, step by step',
    route: '/academy/hajj-umrah-pack',
    keywords: <String>['hajj', 'umrah'],
  ),
  AppDestination(
    id: 'madhhab',
    title: 'What is a madhhab? Ask Hādi',
    subtitle:
        'The four schools of law, explained. Choose yours in Hādi’s ⋮ menu',
    route: '/hadi?q=What+is+a+madhhab%3F',
    keywords: <String>[
      'madhhab',
      'school of law',
      'schools of thought',
      'hanafi',
      'shafii',
      'maliki',
      'hanbali',
    ],
  ),
  AppDestination(
    id: 'ask-hadi',
    title: 'Ask Hādi',
    subtitle: 'Ask a question and get an answer from the sources',
    route: '/hadi',
    keywords: <String>['ask hadi', 'hadi', 'ask a question'],
  ),
  AppDestination(
    id: 'sakina',
    title: 'Sakina',
    subtitle: 'A page of comfort and calm',
    route: '/sakina',
    keywords: <String>['sakina', 'comfort', 'calm', 'anxiety'],
  ),
  AppDestination(
    id: 'feelings',
    title: 'For Your Heart',
    subtitle: 'A guide for what you are feeling',
    route: '/feelings',
    keywords: <String>['feelings', 'emotions', 'for your heart'],
  ),
  AppDestination(
    id: 'new-muslim',
    title: 'New Muslim Path',
    subtitle: 'A first path for someone new to Islam',
    route: '/new-muslim',
    keywords: <String>[
      'new muslim',
      'new to islam',
      'becoming muslim',
      'revert',
      'convert',
      'shahada',
    ],
  ),
  AppDestination(
    id: 'finance',
    title: 'Tayyib Finance',
    subtitle: 'Halal stocks and the paper trading floor',
    route: '/finance',
    keywords: <String>['halal stocks', 'investing', 'invest', 'trading', 'stocks'],
  ),
  AppDestination(
    id: 'verse-cards',
    title: 'Verse Cards',
    subtitle: 'Make a card of a verse to share',
    route: '/share',
    keywords: <String>['verse card', 'verse cards', 'share a verse'],
  ),
  AppDestination(
    id: 'nasheeds',
    title: 'Nasheed Player',
    subtitle: 'Nasheeds and naats',
    route: '/player',
    keywords: <String>['nasheed', 'naat', 'nasheeds'],
  ),
  AppDestination(
    id: 'notes',
    title: 'Notes',
    subtitle: 'Your notes',
    route: '/notes',
    keywords: <String>['notes', 'my notes'],
  ),
  AppDestination(
    id: 'language',
    title: 'Language and Voice',
    subtitle: 'Choose your language',
    route: '/settings/language',
    keywords: <String>['language', 'change language', 'voice'],
  ),
];

/// Destinations that answer [query], best first (an exact keyword beats a
/// keyword contained in the query, which beats a partial one), then list
/// order. Needs 3+ characters. [academyOn] false hides Academy screens.
List<AppDestination> matchDestinations(
  String query, {
  bool academyOn = true,
  int limit = 6,
  List<AppDestination> destinations = kAppDestinations,
}) {
  final String q = query.trim();
  if (q.length < 3) return const <AppDestination>[];
  final List<String> qt = searchTokens(q, dropStopwords: true);
  if (qt.isEmpty) return const <AppDestination>[];
  final Set<String> qSet = qt.toSet();

  final List<(int, int, AppDestination)> scored = <(int, int, AppDestination)>[];
  for (int i = 0; i < destinations.length; i++) {
    final AppDestination d = destinations[i];
    if (!academyOn && d.isAcademy) continue;
    int best = 0;
    for (final String phrase in <String>[...d.keywords, d.title]) {
      final List<String> kt = searchTokens(phrase, dropStopwords: true);
      if (kt.isEmpty) continue;
      int score = 0;
      if (kt.every(qSet.contains)) {
        // The whole keyword is in the query; exact when nothing else is.
        score = kt.length == qSet.length && qSet.every(kt.contains) ? 3 : 2;
      } else if (queryTokensCovered(qt, searchTokens(phrase))) {
        score = 1;
      }
      if (score > best) best = score;
    }
    if (best > 0) scored.add((best, i, d));
  }
  scored.sort(((int, int, AppDestination) a, (int, int, AppDestination) b) {
    final int byScore = b.$1.compareTo(a.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return <AppDestination>[
    for (final (int, int, AppDestination) s in scored.take(limit)) s.$3,
  ];
}
