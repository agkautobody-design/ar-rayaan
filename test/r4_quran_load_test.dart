import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/online_status.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/content_loading_view.dart';
import 'package:ar_rayaan/app/theme/widgets/needs_internet_view.dart';
import 'package:ar_rayaan/features/academy/domain/hifz_progress.dart';
import 'package:ar_rayaan/features/adhkar/domain/adhkar_models.dart';
import 'package:ar_rayaan/features/adhkar/presentation/adhkar_screen.dart';
import 'package:ar_rayaan/features/academy/presentation/hifz_planner_screen.dart';
import 'package:ar_rayaan/features/quran/application/quran_offline.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/application/quran_repository.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_index.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// A repository whose text never arrives (a very slow connection) but whose
/// surah names are bundled, like the real one.
class _SlowTextQuran implements QuranRepository {
  final Completer<List<Surah>> text = Completer<List<Surah>>();
  int allCalls = 0;

  @override
  Future<List<SurahMeta>> index() async => kSurahIndex;

  @override
  Future<List<Surah>> all() {
    allCalls++;
    return text.future;
  }

  @override
  Future<Surah> surah(int number) async => (await text.future)[number - 1];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled surah index', () {
    test('matches quran.json in every field', () {
      final List<dynamic> q =
          jsonDecode(File('assets/quran/quran.json').readAsStringSync())
              as List<dynamic>;
      expect(kSurahIndex.length, 114);
      expect(q.length, 114);
      for (int i = 0; i < 114; i++) {
        final Map<String, dynamic> s = q[i] as Map<String, dynamic>;
        final SurahMeta m = kSurahIndex[i];
        expect(m.number, s['n'], reason: 'surah ${i + 1}');
        expect(m.arabicName, s['ar'], reason: 'surah ${i + 1}');
        expect(m.transliteration, s['tl'], reason: 'surah ${i + 1}');
        expect(m.englishMeaning, s['en'], reason: 'surah ${i + 1}');
        expect(m.revelationType, s['ty'], reason: 'surah ${i + 1}');
        expect(m.ayahCount, s['c'], reason: 'surah ${i + 1}');
      }
    });

    test('the real repository answers index() without loading the text', () async {
      // The same list object every time: nothing is read or parsed.
      final List<SurahMeta> index = await BundledQuranRepository().index();
      expect(identical(index, kSurahIndex), isTrue);
    });
  });

  group('Qur’an screen on a very slow connection', () {
    testWidgets('the surah list shows at once while the text is pending', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      AppHarness.useSurface(tester, height: 1600);
      final _SlowTextQuran repo = _SlowTextQuran();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            quranRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(theme: AppTheme.dark(), home: const QuranScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ContentLoadingView), findsNothing);
      expect(find.text('Al-Fatihah'), findsOneWidget);
      expect(find.text('Al-Baqarah'), findsOneWidget);
      // The text download started in the background, exactly once.
      expect(repo.allCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the loading note is plain words', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuranTextLoadingNote())),
      );
      expect(find.byKey(const Key('quran-text-loading-note')), findsOneWidget);
      expect(find.textContaining('about 2 MB'), findsOneWidget);
      expect(find.textContaining('look through the list now'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('loading view counts the wait', () {
    test('stalled message shows seconds so far', () {
      final String m = loadingMessageFor(
        LoadingPhase.stalled,
        'the Qur’an',
        web: true,
        elapsed: const Duration(seconds: 47),
      );
      expect(m, contains('47 seconds so far'));
      expect(m, contains('keeps going'));
    });

    testWidgets('Try again does not restart the Qur’an download', (
      tester,
    ) async {
      // The retry in QuranScreen / the reader only refreshes providers; the
      // repository (which owns the download) is never replaced.
      final String screen = File(
        'lib/features/quran/presentation/quran_screen.dart',
      ).readAsStringSync();
      final String reader = File(
        'lib/features/quran/presentation/surah_reader_screen.dart',
      ).readAsStringSync();
      final int loadingAt = screen.indexOf('loading: () => ContentLoadingView');
      final int errorAt = screen.indexOf('error: (Object e, _)');
      expect(
        screen.substring(loadingAt, errorAt),
        isNot(contains('invalidate(quranRepositoryProvider)')),
      );
      final int rLoading = reader.indexOf('loading: () => ContentLoadingView');
      final int rError = reader.indexOf('error: (Object e, _)');
      expect(
        reader.substring(rLoading, rError),
        isNot(contains('invalidate(quranRepositoryProvider)')),
      );
    });
  });

  group('offline', () {
    testWidgets('the dead end says how to have the Qur’an offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeedsInternetView(
              what: 'This surah',
              web: true,
              hint: kQuranOfflineHint,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('needs-internet-hint')), findsOneWidget);
      expect(
        find.textContaining('Open the Qur’an once while online'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Settings > Save Qur’an for offline'),
        findsOneWidget,
      );
      expect(find.textContaining('work without internet'), findsOneWidget);
    });

    testWidgets('the hint is not shown on the phone app', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeedsInternetView(
              what: 'This surah',
              web: false,
              hint: kQuranOfflineHint,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('needs-internet-hint')), findsNothing);
    });

    test('saving while offline says so plainly and fetches nothing', () async {
      final bool? Function() before = deviceOnlineProbe;
      deviceOnlineProbe = () => false;
      addTearDown(() => deviceOnlineProbe = before);
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(quranOfflineSaveProvider.notifier).save();
      expect(c.read(quranOfflineSaveProvider).phase, QuranSavePhase.offline);
      expect(
        quranOfflineMessage(
          QuranSavePhase.offline,
          web: true,
          alreadyStored: false,
        ),
        'You are offline. Connect once to save it.',
      );
    });

    test('the failed message says a connection is needed once', () {
      final String m = quranOfflineMessage(
        QuranSavePhase.failed,
        web: true,
        alreadyStored: false,
      );
      expect(m, contains('Could not save'));
      expect(m, contains('connection once'));
    });
  });

  group('Hifz planner surah picker', () {
    testWidgets('pick a surah by name instead of tapping plus 49 times', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      AppHarness.useSurface(tester, height: 2400);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const HifzPlannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The default is the Juz Amma plan, starting at An-Nas; the picker shows
      // a name, not a bare number.
      expect(find.text('114 · An-Nas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('hifz-surah-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hifz-surah-search')), 'mulk');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hifz-surah-67')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hifz-surah-67')));
      await tester.pumpAndSettle();

      expect(find.text('67 · Al-Mulk'), findsOneWidget);
      expect(
        HifzState.decode(prefs.getString(kHifzPref)).targetSurah,
        67,
      );
      expect(find.textContaining('Surah 67 (Al-Mulk) has 30 ayat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a number works in the picker too', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      AppHarness.useSurface(tester, height: 2400);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const HifzPlannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hifz-surah-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('hifz-surah-search')), '36');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hifz-surah-36')));
      await tester.pumpAndSettle();
      expect(find.text('36 · Ya-Sin'), findsOneWidget);
    });
  });

  group('findability', () {
    testWidgets('Explore (Faith) lists the Hifz planner and opens it', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await tester.tap(find.text('Faith'));
      await AppHarness.settle(tester);
      final Finder entry = find.text(
        'Memorise the Qur’an · Hifz planner',
      );
      expect(entry, findsOneWidget);
      await tester.tap(entry);
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/academy/hifz',
      );
    });

    testWidgets('Dhikr starts with a Tasbih counter that opens the counter',
        (tester) async {
      String? opened;
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext c, GoRouterState s) => const Scaffold(
              body: AdhkarChooser(sets: <AdhkarSet>[], onOpenSet: null),
            ),
          ),
          GoRoute(
            path: '/academy/dhikr',
            builder: (BuildContext c, GoRouterState s) {
              opened = s.uri.path;
              return const Scaffold(body: Text('counter page'));
            },
          ),
        ],
      );
      AppHarness.useSurface(tester, height: 1800);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      // First thing under the intro line, above the single duas.
      final Finder row = find.text('Tasbih counter');
      expect(row, findsOneWidget);
      expect(
        tester.getTopLeft(row).dy,
        lessThan(tester.getTopLeft(find.text('A SINGLE DUA')).dy),
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(opened, '/academy/dhikr');
    });
  });
}
