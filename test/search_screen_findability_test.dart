import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_ask_bar.dart';
import 'package:ar_rayaan/features/hadith/application/hadith_providers.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/hadith/presentation/hadith_screen.dart';
import 'package:ar_rayaan/features/huda/presentation/huda_screens.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/presentation/search_screen.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

Surah _surah(int n, String translit, String meaning, List<String> english) {
  return Surah(
    meta: SurahMeta(
      number: n,
      arabicName: translit,
      transliteration: translit,
      englishMeaning: meaning,
      revelationType: 'meccan',
      ayahCount: english.length,
    ),
    ayahs: <Ayah>[
      for (int i = 0; i < english.length; i++)
        Ayah(number: i + 1, arabic: 'بسم', english: english[i]),
    ],
  );
}

const Hadith _h1 = Hadith(
  number: 1,
  arabic: 'إنما الأعمال',
  english: 'Actions are (judged) by motives (niyyah), so each man will have '
      'what he intended.',
);

const Hadith _h2 = Hadith(
  number: 2,
  arabic: 'الصلاة',
  english: 'The prayer is a light and patience is illumination.',
);

const Guide _prayGuide = Guide(
  id: 'huda-prayer',
  category: 'Worship',
  title: 'How to Pray — The Essentials',
  subtitle: 'The prayer, step by step',
  steps: <String>['Stand'],
  sources: <String>['Test'],
);

Future<void> _pumpSearch(
  WidgetTester tester, {
  List<Surah>? quran,
  List<Hadith> hadiths = const <Hadith>[_h1, _h2],
  List<Guide> guides = const <Guide>[_prayGuide],
  bool academyOn = true,
  GoRouter? router,
  List<AdhkarSet> adhkar = const <AdhkarSet>[],
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  AppHarness.useSurface(tester, height: 3000);
  final List<Surah> surahs = quran ??
      <Surah>[
        _surah(67, 'Al-Mulk', 'The Sovereignty', <String>[
          'Blessed is He in whose hand is dominion',
          'Who created death and life',
        ]),
        _surah(2, 'Al-Baqarah', 'The Cow', <String>[
          'Establish prayer and give zakah',
        ]),
      ];
  final List<Override> overrides = <Override>[
    sharedPreferencesProvider.overrideWithValue(prefs),
    quranAllProvider.overrideWith((ref) async => surahs),
    storiesProvider.overrideWith((ref) async => <Story>[]),
    hadithCollectionProvider.overrideWith((ref) async => hadiths),
    adhkarSetsProvider.overrideWith((ref) async => adhkar),
    guidesProvider.overrideWith((ref) async => guides),
    academyFlagProvider.overrideWith((ref) async => academyOn),
  ];
  if (router != null) {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  } else {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _type(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField), q);
  await tester.pump(const Duration(milliseconds: 300));
}

double _top(WidgetTester tester, Finder f) => tester.getTopLeft(f.first).dy;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a surah is found by its name', (WidgetTester tester) async {
    await _pumpSearch(tester);
    await _type(tester, 'mulk');
    expect(find.text('SURAH 67'), findsOneWidget);
    expect(find.textContaining('Al-Mulk'), findsWidgets);
    expect(find.textContaining('Nothing on any shelf'), findsNothing);
  });

  testWidgets('an app room is found and listed first', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await _type(tester, 'qibla');
    expect(find.text('IN THE APP'), findsWidgets);
    expect(find.text('Qibla Finder'), findsOneWidget);
    await _type(tester, 'tasbih');
    expect(find.textContaining('tasbih counter'), findsOneWidget);
  });

  testWidgets('Academy rooms are hidden when the Academy is switched off', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester, academyOn: false);
    await tester.pump(const Duration(milliseconds: 50));
    await _type(tester, 'tasbih');
    expect(find.textContaining('tasbih counter'), findsNothing);
  });

  testWidgets(
      'order: app rooms, guides, hadith, then the Qur’an verses', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await _type(tester, 'prayer');
    final Finder room = find.text('IN THE APP');
    final Finder guide = find.text('GUIDE');
    final Finder hadith = find.text('HADITH');
    final Finder verse = find.textContaining('QUR\'AN 2:1');
    expect(room, findsWidgets);
    expect(guide, findsOneWidget);
    expect(hadith, findsOneWidget);
    expect(verse, findsOneWidget);
    expect(_top(tester, room) < _top(tester, guide), isTrue);
    expect(_top(tester, guide) < _top(tester, hadith), isTrue);
    expect(_top(tester, hadith) < _top(tester, verse), isTrue);
  });

  testWidgets('"intentions" finds the hadith that says "motives"', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await _type(tester, 'actions are judged by intentions');
    expect(find.text('HADITH'), findsOneWidget);
    expect(find.textContaining('Hadith 1'), findsOneWidget);
    await _type(tester, 'intentions');
    expect(find.textContaining('Hadith 1'), findsOneWidget);
  });

  testWidgets('a hadith result opens the Forty Hadith at its number', (
    WidgetTester tester,
  ) async {
    String? opened;
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) => const SearchScreen(),
        ),
        GoRoute(
          path: '/hadith',
          builder: (BuildContext c, GoRouterState s) {
            opened = s.uri.toString();
            return const Scaffold(body: Text('hadith page'));
          },
        ),
      ],
    );
    await _pumpSearch(tester, router: router);
    await _type(tester, 'intentions');
    await tester.tap(find.textContaining('Hadith 1'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, '/hadith?n=1');
  });

  testWidgets('the counts line says what is shown and what more there is', (
    WidgetTester tester,
  ) async {
    final List<String> verses = <String>[
      for (int i = 0; i < 45; i++) 'He is the Most Merciful, verse $i',
    ];
    await _pumpSearch(
      tester,
      quran: <Surah>[_surah(1, 'Al-Fatihah', 'The Opening', verses)],
    );
    await _type(tester, 'merciful');
    expect(find.textContaining('30 SHOWN'), findsOneWidget);
    expect(find.textContaining('45 IN THE QUR\'AN'), findsOneWidget);
  });

  testWidgets('a pasted 5000-character wall is cut to a short query', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    final String wall = List<String>.filled(700, 'mercy').join(' ');
    final Stopwatch w = Stopwatch()..start();
    await tester.enterText(find.byType(TextField), wall);
    await tester.pump(const Duration(milliseconds: 400));
    w.stop();
    final EditableText field =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text.length, lessThanOrEqualTo(80));
    expect(tester.takeException(), isNull);
    expect(w.elapsedMilliseconds, lessThan(5000));
  });

  testWidgets('typing waits for a pause: a burst is searched once', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'qib');
    await tester.pump(const Duration(milliseconds: 30));
    await tester.enterText(find.byType(TextField), 'qibla');
    // Not yet: the pause has not passed.
    expect(find.text('Qibla Finder'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Qibla Finder'), findsOneWidget);
  });

  testWidgets('"privacy" and "difference of opinion" find a room', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await _type(tester, 'privacy');
    expect(find.text('Privacy Policy'), findsOneWidget);
    await _type(tester, 'difference of opinion');
    expect(find.textContaining('The Four Schools'), findsOneWidget);
  });

  testWidgets('a story named for the word comes before one that mentions it', (
    WidgetTester tester,
  ) async {
    Story story(String id, String title, String body) => Story(
          id: id,
          collection: 'companions',
          title: title,
          kicker: 'K',
          subtitle: 's',
          sourceLabel: 'Established',
          sources: const <String>['Q 1:1'],
          chapters: <StoryChapter>[StoryChapter(heading: 'h', body: body)],
          familyQuestion: 'q?',
        );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester, height: 3000);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          quranAllProvider.overrideWith((ref) async => <Surah>[]),
          storiesProvider.overrideWith(
            (ref) async => <Story>[
              story('a', 'A Quiet Evening', 'He spoke about patience at length.'),
              story('b', 'The Story of Patience', 'A man waited.'),
            ],
          ),
          hadithCollectionProvider.overrideWith((ref) async => <Hadith>[]),
          adhkarSetsProvider.overrideWith((ref) async => <AdhkarSet>[]),
          guidesProvider.overrideWith((ref) async => <Guide>[]),
          academyFlagProvider.overrideWith((ref) async => true),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _type(tester, 'patience');
    final Finder named = find.text('The Story of Patience');
    final Finder mentioned = find.text('A Quiet Evening');
    expect(named, findsOneWidget);
    expect(mentioned, findsOneWidget);
    expect(find.text('STORY · MENTIONED'), findsOneWidget);
    expect(_top(tester, named) < _top(tester, mentioned), isTrue);
  });

  testWidgets('no result says so and offers to ask Hādi', (
    WidgetTester tester,
  ) async {
    String? opened;
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) => const SearchScreen(),
        ),
        GoRoute(
          path: '/hadi',
          builder: (BuildContext c, GoRouterState s) {
            opened = s.uri.toString();
            return const Scaffold(body: Text('hadi page'));
          },
        ),
      ],
    );
    await _pumpSearch(tester, router: router);
    await _type(tester, 'Zzzq Wxy');
    expect(find.textContaining('Nothing on any shelf matches "Zzzq Wxy"'),
        findsOneWidget);
    await tester.tap(find.textContaining('Ask Hādi'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, '/hadi?q=Zzzq+Wxy');
  });

  testWidgets('the field is focused once the page has settled, and clears', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final EditableText field =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    await _type(tester, 'mulk');
    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(find.byTooltip('Clear'), findsNothing);
    expect(find.text('mulk'), findsNothing);
  });

  testWidgets('spelling variants find the surah', (WidgetTester tester) async {
    await _pumpSearch(tester);
    await _type(tester, 'Mulq');
    expect(find.text('SURAH 67'), findsOneWidget);
    await _type(tester, 'Baqara');
    expect(find.text('SURAH 2'), findsOneWidget);
  });

  testWidgets('a one-letter slip gets "Did you mean" and a tap searches it', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await _type(tester, 'baqrah');
    expect(find.byKey(const Key('did-you-mean')), findsOneWidget);
    expect(find.text('Did you mean "Al-Baqarah"?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('did-you-mean')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SURAH 2'), findsOneWidget);
    expect(find.byKey(const Key('did-you-mean')), findsNothing);
    final EditableText field =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Al-Baqarah');
  });

  testWidgets('a correct word gets no suggestion', (WidgetTester tester) async {
    await _pumpSearch(tester);
    await _type(tester, 'baqarah');
    expect(find.byKey(const Key('did-you-mean')), findsNothing);
  });

  testWidgets('type, clear, type again: the box keeps working', (
    WidgetTester tester,
  ) async {
    await _pumpSearch(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await _type(tester, 'qibla');
    expect(find.text('Qibla Finder'), findsOneWidget);

    final State<StatefulWidget> before =
        tester.state(find.byType(EditableText));
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // On the web the tap on Clear leaves the old text input dead, so Clear
    // rebuilds the box from scratch, as reopening the page does.
    expect(
      identical(before, tester.state(find.byType(EditableText))),
      isFalse,
      reason: 'Clear gives a fresh text input',
    );
    EditableText field =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, isEmpty);
    expect(field.focusNode.hasFocus, isTrue, reason: 'focus kept after Clear');

    await _type(tester, 'tasbih');
    field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'tasbih');
    expect(find.textContaining('tasbih counter'), findsOneWidget);

    // Again, after a result list: tap the box and type something else.
    await tester.tap(find.byKey(const Key('search-field')));
    await tester.pump();
    await _type(tester, 'mulk');
    expect(find.text('SURAH 67'), findsOneWidget);
  });

  testWidgets('the box stays on screen while the results scroll', (
    WidgetTester tester,
  ) async {
    final List<String> verses = <String>[
      for (int i = 0; i < 45; i++) 'He is the Most Merciful, verse $i',
    ];
    await _pumpSearch(
      tester,
      quran: <Surah>[_surah(1, 'Al-Fatihah', 'The Opening', verses)],
    );
    await _type(tester, 'merciful');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pump();
    expect(find.byKey(const Key('search-field')), findsOneWidget);
    final EditableText field =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'merciful');
  });

  testWidgets('a dhikr result opens its own set', (WidgetTester tester) async {
    String? opened;
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) => const SearchScreen(),
        ),
        GoRoute(
          path: '/adhkar',
          builder: (BuildContext c, GoRouterState s) {
            opened = s.uri.toString();
            return const Scaffold(body: Text('adhkar page'));
          },
        ),
      ],
    );
    await _pumpSearch(
      tester,
      router: router,
      adhkar: const <AdhkarSet>[
        AdhkarSet(
          id: 'evening',
          titleEn: 'Evening Adhkar',
          titleAr: 'x',
          items: <Dhikr>[
            Dhikr(
              number: 1,
              arabic: 'x',
              count: 1,
              translation: 'I seek refuge in the perfect words of Allah',
            ),
          ],
        ),
      ],
    );
    await _type(tester, 'perfect words');
    await tester.tap(find.text('Evening Adhkar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, '/adhkar?set=evening');
  });

  group('Home "Ask Hādi anything" bar', () {
    testWidgets('carries the typed question to the chat', (
      WidgetTester tester,
    ) async {
      String? opened;
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext c, GoRouterState s) =>
                const Scaffold(body: Center(child: HadiAskBar())),
          ),
          GoRoute(
            path: '/hadi',
            builder: (BuildContext c, GoRouterState s) {
              opened = s.uri.toString();
              return const Scaffold(body: Text('hadi page'));
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.enterText(find.byType(TextField), 'Is music haram?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, '/hadi?q=Is+music+haram%3F');
    });

    testWidgets('empty, it still opens the chat', (WidgetTester tester) async {
      String? opened;
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext c, GoRouterState s) =>
                const Scaffold(body: Center(child: HadiAskBar())),
          ),
          GoRoute(
            path: '/hadi',
            builder: (BuildContext c, GoRouterState s) {
              opened = s.uri.toString();
              return const Scaffold(body: Text('hadi page'));
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.byTooltip('Send to Hādi'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(opened, '/hadi');
    });
  });

  testWidgets('Hādi sends a question handed over in the address', (
    WidgetTester tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(
      tester,
      find.byType(Scaffold).first,
      '/hadi?q=Assalamu+alaikum',
    );
    // The question is on screen as the person's own message.
    expect(find.text('Assalamu alaikum'), findsWidgets);
  });

  testWidgets('the Forty Hadith scrolls to the number it is opened at', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester, height: 900);
    final List<Hadith> forty = <Hadith>[
      for (int n = 1; n <= 40; n++)
        Hadith(
          number: n,
          arabic: '\u0628\u0633\u0645',
          english: 'Text of hadith number $n. ' * 12,
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadithCollectionProvider.overrideWith((ref) async => forty),
        ],
        child: const MaterialApp(home: HadithScreen(initialNumber: 30)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    final Finder label = find.text('HADITH 30');
    expect(label, findsOneWidget);
    final double y = tester.getTopLeft(label).dy;
    expect(y > 0 && y < 900, isTrue, reason: 'hadith 30 is on screen, y=$y');
  });
}
