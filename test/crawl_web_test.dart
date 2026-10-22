import 'dart:io';
import 'dart:ui' as ui;

import 'package:ar_rayaan/app/core/error_handling.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/core/web_offline.dart';
import 'package:ar_rayaan/app/theme/widgets/ask_hadi_pill.dart';
import 'package:ar_rayaan/app/theme/widgets/needs_internet_view.dart';
import 'package:ar_rayaan/features/adhkar/application/adhkar_providers.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/hadith/application/hadith_providers.dart';
import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/application/quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:ar_rayaan/features/search/presentation/search_screen.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:ar_rayaan/features/stories/data/story_layers_repository.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:ar_rayaan/features/stories/presentation/stories_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'audit/router_source.dart';

/// Crawl audit: web honesty (F-02), global error handling and not-found
/// pages (F-04), the Ask Hadi pill (F-06), Trivia results (F-07) and the
/// per-screen document titles.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // --- F-02: honest offline wording ---------------------------------------

  group('WebOffline wording', () {
    test('the web never claims to work offline', () {
      expect(WebOffline.libraryHeader(web: true), isNot(contains('OFFLINE')));
      expect(WebOffline.libraryNote(web: true), contains('internet'));
      expect(WebOffline.needsInternet('Trivia', web: true),
          'Trivia needs an internet connection on the web. Check your '
          'connection and try again.');
    });

    test('the native apps keep their offline claim', () {
      expect(WebOffline.libraryHeader(web: false), contains('WORKS OFFLINE'));
      expect(WebOffline.libraryNote(web: false), isNull);
      expect(WebOffline.needsInternet('Trivia', web: false),
          'Trivia could not be loaded. Try again.');
    });
  });

  testWidgets('NeedsInternetView says so and offers a retry', (tester) async {
    int retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeedsInternetView(
            what: 'The Qur’an',
            web: true,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.textContaining('needs an internet connection'),
        findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets(
      'a surah that cannot be loaded shows a message and a retry, not a '
      'grey box', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester, height: 1200);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          quranRepositoryProvider.overrideWithValue(_FailingQuran()),
        ],
        child: const MaterialApp(home: SurahReaderScreen(number: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Riverpod 2 rethrows .value on an error: that used to turn this screen
    // into an unhandled exception (the grey box).
    expect(tester.takeException(), isNull);
    expect(find.byType(NeedsInternetView), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Search reports a shelf that failed instead of "no results"', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester, height: 1200);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          quranAllProvider.overrideWith(
            (ref) => Future<List<Surah>>.error(StateError('offline')),
          ),
          storiesProvider.overrideWith((ref) async => <Story>[]),
          hadithCollectionProvider.overrideWith((ref) async => <Hadith>[]),
          adhkarSetsProvider.overrideWith((ref) async => <AdhkarSet>[]),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Some of the library'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('in the shelves that loaded'), findsOneWidget);
    expect(find.textContaining('Nothing on any shelf'), findsNothing);
  });

  testWidgets('Stories says when shelves could not load, with no counter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppHarness.useSurface(tester, height: 1600);
    final StoriesRepository repo = StoriesRepository()
      ..failedPacks.addAll(<String>['khutbahs', 'prophets']);
    final Story story = Story(
      id: 'c1',
      collection: 'companions',
      title: 'A companion',
      kicker: 'K',
      subtitle: 's',
      sourceLabel: 'Established',
      sources: const <String>['Q 1:1'],
      chapters: const <StoryChapter>[
        StoryChapter(heading: 'h', body: 'body text long enough to pass'),
      ],
      familyQuestion: 'q?',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          storiesRepositoryProvider.overrideWithValue(repo),
          storiesProvider.overrideWith((ref) async => <Story>[story]),
          storyIdsWithLayersProvider.overrideWith((ref) async => <String>{}),
        ],
        child: const MaterialApp(home: StoriesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 of ${repo.packCount} shelves could not load'),
        findsOneWidget);
    expect(find.text('TAP TO RETRY'), findsOneWidget);
    expect(find.textContaining('STORIES LOADED'), findsNothing);
  });

  // --- F-04: error handling -------------------------------------------------

  group('AppErrorHandling', () {
    late FlutterExceptionHandler? savedOnError;
    late ErrorWidgetBuilder savedBuilder;
    late ui.PlatformDispatcher dispatcher;
    late ui.ErrorCallback? savedPlatform;

    setUp(() {
      savedOnError = FlutterError.onError;
      savedBuilder = ErrorWidget.builder;
      dispatcher = ui.PlatformDispatcher.instance;
      savedPlatform = dispatcher.onError;
      AppErrorHandling.recent.clear();
    });

    tearDown(() {
      FlutterError.onError = savedOnError;
      ErrorWidget.builder = savedBuilder;
      dispatcher.onError = savedPlatform;
    });

    test('install wires all three nets', () {
      AppErrorHandling.install(replaceErrorWidget: true);
      expect(identical(ErrorWidget.builder, AppErrorFallback.builder), isTrue);
      expect(dispatcher.onError, isNotNull);
      // An uncaught async error is recorded and reported as handled.
      final bool handled = dispatcher.onError!(
        StateError('late failure'),
        StackTrace.current,
      );
      expect(handled, isTrue);
      expect(AppErrorHandling.recent.single, contains('late failure'));
      AppErrorHandling.onZoneError(ArgumentError('zone'), StackTrace.current);
      expect(AppErrorHandling.recent.length, 2);
    });

    test('the record is bounded and keeps only type and message', () {
      for (int i = 0; i < 50; i++) {
        AppErrorHandling.record(StateError('e$i'), null);
      }
      expect(AppErrorHandling.recent.length, AppErrorHandling.maxRecent);
      expect(AppErrorHandling.recent.last, contains('e49'));
    });

    testWidgets('a screen that throws becomes a friendly page with Home', (
      tester,
    ) async {
      final ErrorWidgetBuilder original = ErrorWidget.builder;
      ErrorWidget.builder = AppErrorFallback.builder;
      AppHarness.useSurface(tester, height: 900);
      final GoRouter router = GoRouter(
        initialLocation: '/broken',
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            builder: (BuildContext c, GoRouterState s) =>
                const Scaffold(body: Text('HOME PAGE')),
          ),
          GoRoute(
            path: '/broken',
            builder: (BuildContext c, GoRouterState s) => Scaffold(
              body: Builder(
                builder: (BuildContext context) =>
                    throw StateError('this screen is broken'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      // No grey box, no exception text.
      expect(find.textContaining('broken'), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('HOME PAGE'), findsOneWidget);
      ErrorWidget.builder = original;
    });

    testWidgets('a failed part of a screen shows a small note', (tester) async {
      final ErrorWidgetBuilder original = ErrorWidget.builder;
      ErrorWidget.builder = AppErrorFallback.builder;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                const Text('before'),
                Builder(
                  builder: (BuildContext context) =>
                      throw StateError('one card broke'),
                ),
                const Text('after'),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<StateError>());
      expect(find.text('This part could not be shown.'), findsOneWidget);
      expect(find.text('before'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      ErrorWidget.builder = original;
    });
  });

  group('links with bad ids', () {
    testWidgets('/quran/madinah/abc/x is a not-found page, not a crash', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.text('Faith'), '/quran/madinah/abc/x');
      expect(tester.takeException(), isNull);
      expect(find.text('That page of the Qur’an is not here.'),
          findsOneWidget);
      expect(find.text('Go home'), findsOneWidget);
    });

    testWidgets('out-of-range surah numbers are not found too', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      for (final String bad in <String>[
        '/quran/madinah/0/5',
        '/quran/madinah/115/5',
        '/quran/madinah/2/0',
        '/quran/madinah/2/287',
        '/quran/999',
        '/quran/0',
        '/quran/abc',
      ]) {
        await AppHarness.go(tester, find.text('Faith'), bad);
        expect(tester.takeException(), isNull, reason: bad);
        expect(find.text('Go home'), findsOneWidget, reason: bad);
      }
    });

    testWidgets('an unknown feeling id is a not-found page with Go home', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.text('Faith'), '/feelings/bogus');
      await AppHarness.settle(tester);
      expect(find.text('That guide is not here.'), findsOneWidget);
      expect(find.text('Go home'), findsOneWidget);
    });
  });

  // --- F-06: the Ask Hadi pill ----------------------------------------------

  group('Ask Hadi pill', () {
    tearDown(() => AskHadiPillHost.forceEnabled = null);

    Future<GoRouter> pumpPage(
      WidgetTester tester, {
      bool? enabled = true,
      Widget? body,
    }) async {
      AppHarness.useSurface(tester, height: 800);
      final GoRouter router = GoRouter(
        initialLocation: '/page',
        routes: <RouteBase>[
          GoRoute(
            path: '/page',
            builder: (BuildContext c, GoRouterState s) => AskHadiPillHost(
              enabled: enabled,
              child: body ??
                  Scaffold(
                    body: ListView(
                      children: <Widget>[
                        for (int i = 0; i < 80; i++)
                          SizedBox(height: 60, child: Text('row $i')),
                      ],
                    ),
                  ),
            ),
          ),
          GoRoute(
            path: '/hadi',
            builder: (BuildContext c, GoRouterState s) =>
                const Scaffold(body: Text('HADI PAGE')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('is only as big as the pill, with one small semantics node', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpPage(tester);
      final Size size = tester.getSize(find.byType(AskHadiPill));
      expect(size.width, lessThan(220));
      expect(size.height, lessThan(80));
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Ask Hādi'),
      );
      expect(node.rect.width, lessThan(220));
      expect(node.rect.height, lessThan(80));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('opens Hadi on tap', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ask Hādi'));
      await tester.pumpAndSettle();
      expect(find.text('HADI PAGE'), findsOneWidget);
    });

    testWidgets('is not drawn when switched off', (tester) async {
      await pumpPage(tester, enabled: false);
      expect(find.byType(AskHadiPill), findsNothing);
    });

    testWidgets('hides while scrolling down and returns on scrolling up', (
      tester,
    ) async {
      await pumpPage(tester);
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: find.byType(AskHadiPill),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;
      expect(opacity(), 1);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), 0);
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), 1);
    });

    testWidgets('hides while the keyboard is open', (tester) async {
      await pumpPage(tester);
      expect(find.byType(AskHadiPill), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(find.byType(AskHadiPill), findsNothing);
    });

    testWidgets('sits under a dialog, which keeps every tap', (tester) async {
      await pumpPage(
        tester,
        body: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (BuildContext c) =>
                      const AlertDialog(content: Text('A DIALOG')),
                ),
                child: const Text('open dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      expect(find.text('A DIALOG'), findsOneWidget);
      // The pill is still in its page, but the dialog's barrier is above it.
      await tester.tap(find.text('Ask Hādi'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('HADI PAGE'), findsNothing);
      expect(find.text('A DIALOG'), findsOneWidget);
    });

    testWidgets(
        'shows on /hadith, not on /hadi or the bottom-nav tabs', (
      tester,
    ) async {
      AskHadiPillHost.forceEnabled = true;
      await AppHarness.boot(tester);
      // Home is a tab of the shell: no pill (the Hadi tab is right there).
      expect(find.byType(AskHadiPill), findsNothing);

      // /hadith used to lose the pill to a startsWith('/hadi') check.
      await AppHarness.go(tester, find.text('Faith'), '/hadith');
      expect(find.byType(AskHadiPill), findsOneWidget);

      await AppHarness.go(tester, find.text('Faith'), '/hadi');
      expect(find.byType(AskHadiPill), findsNothing);

      await AppHarness.go(tester, find.text('Faith'), '/prayer');
      expect(find.byType(AskHadiPill), findsOneWidget);

      await AppHarness.go(tester, find.text('Faith'), '/games/ludo');
      expect(find.byType(AskHadiPill), findsNothing); // the board is the page
    });
  });

  // --- F-07: Trivia results -------------------------------------------------

  group('Trivia results', () {
    const TriviaQ question = TriviaQ(
      id: 't1',
      category: 'Prophets',
      question: 'Who built the ark?',
      options: <String>['Nuh', 'Musa'],
      answer: 0,
      why: 'Nuh built the ark by revelation.',
    );

    Future<void> playOneAndFinish(WidgetTester tester) async {
      AppHarness.useSurface(tester, height: 1400);
      final GoRouter router = GoRouter(
        initialLocation: '/games',
        routes: <RouteBase>[
          GoRoute(
            path: '/games',
            builder: (BuildContext c, GoRouterState s) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => c.push('/games/trivia'),
                  child: const Text('GAMES HUB'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/games/trivia',
            builder: (BuildContext c, GoRouterState s) => const TriviaScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (BuildContext c, GoRouterState s) =>
                const Scaffold(body: Text('HOME PAGE')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            triviaProvider.overrideWith((ref) async => <TriviaQ>[question]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('GAMES HUB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Musa')); // the wrong answer
      await tester.pump();
      await tester.tap(find.text('See results'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers Review, Play again, Back to Games and Home', (
      tester,
    ) async {
      await playOneAndFinish(tester);
      expect(find.text('0 / 1'), findsOneWidget);
      for (final String label in <String>[
        'Review answers',
        'Play again',
        'Back to Games',
        'Home',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // A header with a close button too: never a dead end.
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('Review shows what was answered and why', (tester) async {
      await playOneAndFinish(tester);
      await tester.tap(find.text('Review answers'));
      await tester.pumpAndSettle();
      expect(find.text('Who built the ark?'), findsOneWidget);
      expect(find.text('Your answer: Musa'), findsOneWidget);
      expect(find.text('Answer: Nuh'), findsOneWidget);
      expect(find.text('Nuh built the ark by revelation.'), findsOneWidget);
      await tester.tap(find.text('Back to results'));
      await tester.pumpAndSettle();
      expect(find.text('0 / 1'), findsOneWidget);
    });

    testWidgets('Back to Games returns to the hub, Home goes home', (
      tester,
    ) async {
      await playOneAndFinish(tester);
      await tester.tap(find.text('Back to Games'));
      await tester.pumpAndSettle();
      expect(find.text('GAMES HUB'), findsOneWidget);

      await tester.tap(find.text('GAMES HUB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Musa'));
      await tester.pump();
      await tester.tap(find.text('See results'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('HOME PAGE'), findsOneWidget);
    });

    testWidgets('Play again starts a new round', (tester) async {
      await playOneAndFinish(tester);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 1 OF 1 — SCORE 0'), findsOneWidget);
    });

    testWidgets('a trivia pack that cannot load says it needs internet', (
      tester,
    ) async {
      AppHarness.useSurface(tester, height: 900);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            triviaProvider.overrideWith(
              (ref) => Future<List<TriviaQ>>.error(StateError('offline')),
            ),
          ],
          child: const MaterialApp(home: TriviaScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NeedsInternetView), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  // --- document titles ------------------------------------------------------

  group('RouteTitles', () {
    test('known screens get their own title', () {
      expect(RouteTitles.forPath('/prayer'), 'Prayer Times · Ar-Rayaan');
      expect(RouteTitles.forPath('/quran'), 'Qur’an · Ar-Rayaan');
      expect(RouteTitles.forPath('/quran/12'), 'Qur’an · Ar-Rayaan');
      expect(RouteTitles.forPath('/hadith'),
          'Forty Hadith · Ar-Rayaan');
      expect(RouteTitles.forPath('/games/trivia'),
          'Trivia · Ar-Rayaan');
      expect(RouteTitles.forPath('/legal/terms'),
          'Terms of Service · Ar-Rayaan');
      expect(RouteTitles.forPath('/prayer/'), 'Prayer Times · Ar-Rayaan');
    });

    test('Home and unknown paths get the plain app name', () {
      expect(RouteTitles.forPath('/'), 'Ar-Rayaan');
      expect(RouteTitles.forPath('/home'), 'Ar-Rayaan');
      expect(RouteTitles.forPath('/definitely-not-a-page'), 'Ar-Rayaan');
    });

    test('every release route in the router has a title', () {
      final RouterSource router = RouterSource.read();
      final List<String> missing = <String>[];
      for (final String path in router.paths) {
        if (!path.startsWith('/')) continue; // child routes
        if (router.founderOnly.contains(path)) continue;
        if (path == '/' || path == '/home') continue;
        final String concrete = path.replaceAll(RegExp(r':\w+'), '1');
        if (RouteTitles.forPath(concrete) == RouteTitles.appName) {
          missing.add(path);
        }
      }
      expect(missing, isEmpty, reason: 'no title for: $missing');
    });
  });

  test('the web boot page ships no gstatic CanvasKit and has a watchdog', () {
    // F-03 guard: nothing in the page may pull the renderer from a CDN, and
    // the splash must grow a message and a Try again button when the app
    // does not start.
    final String html = _read('web/index.html');
    expect(html.contains('flutter-first-frame'), isTrue);
    expect(html.contains('ar-boot-retry'), isTrue);
    expect(html.contains('20000'), isTrue);
    expect(RegExp(r'<script[^>]+gstatic').hasMatch(html), isFalse);
    for (final String wf in <String>[
      '.github/workflows/build-web.yml',
      '.github/workflows/pr-check.yml',
    ]) {
      expect(_read(wf).contains('--no-web-resources-cdn'), isTrue, reason: wf);
    }
  });
}

String _read(String path) => File(path).readAsStringSync();

class _FailingQuran implements QuranRepository {
  @override
  Future<List<Surah>> all() => Future<List<Surah>>.error(StateError('offline'));

  @override
  Future<List<SurahMeta>> index() =>
      Future<List<SurahMeta>>.error(StateError('offline'));

  @override
  Future<Surah> surah(int number) =>
      Future<Surah>.error(StateError('offline'));
}
