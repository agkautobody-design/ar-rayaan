import 'dart:typed_data';

import 'package:ar_rayaan/app/core/asset_text_cache.dart';
import 'package:ar_rayaan/app/core/content_loader.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/widgets/content_loading_view.dart';
import 'package:ar_rayaan/app/theme/widgets/needs_internet_view.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/application/quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Loading, offline and error states: the browser keeps a copy of the
/// libraries after the first load, a slow load explains itself, and Try again
/// really fetches again.
void main() {
  group('ContentLoader', () {
    late AssetTextCache saved;
    setUp(() => saved = ContentLoader.cache);
    tearDown(() => ContentLoader.cache = saved);

    test('first load fetches and stores, later loads need no bundle', () async {
      final _MemCache cache = _MemCache();
      ContentLoader.cache = cache;
      final _Bundle bundle = _Bundle(<String, String>{'a.json': '[1,2]'});

      expect(await ContentLoader.loadString('a.json', bundle: bundle), '[1,2]');
      expect(bundle.loads, 1);
      expect(cache.store['a.json'], '[1,2]');

      // Offline now: the bundle would throw, the stored copy answers.
      bundle.offline = true;
      expect(await ContentLoader.loadString('a.json', bundle: bundle), '[1,2]');
      expect(bundle.loads, 1);
    });

    test('a failed fetch with nothing stored throws (so Retry can retry)',
        () async {
      ContentLoader.cache = _MemCache();
      final _Bundle bundle = _Bundle(<String, String>{})..offline = true;
      await expectLater(
        ContentLoader.loadString('a.json', bundle: bundle),
        throwsA(isA<StateError>()),
      );
      // Back online: the very next call fetches.
      bundle
        ..offline = false
        ..files['a.json'] = 'ok';
      expect(await ContentLoader.loadString('a.json', bundle: bundle), 'ok');
    });

    test('a broken cache never blocks loading', () async {
      ContentLoader.cache = _BrokenCache();
      final _Bundle bundle = _Bundle(<String, String>{'a.json': 'x'});
      expect(await ContentLoader.loadString('a.json', bundle: bundle), 'x');
    });

    test('offline availability: always on the apps, stored-only on the web',
        () async {
      ContentLoader.cache = _MemCache(persistent: false);
      expect(await ContentLoader.isAvailableOffline('q.json'), isTrue);

      final _MemCache web = _MemCache();
      ContentLoader.cache = web;
      expect(await ContentLoader.isAvailableOffline('q.json'), isFalse);
      await web.write('q.json', 'text');
      expect(await ContentLoader.isAvailableOffline('q.json'), isTrue);

      ContentLoader.cache = _BrokenCache();
      expect(await ContentLoader.isAvailableOffline('q.json'), isFalse);
    });

    test('Home tile adds the first-time note only when truly not stored', () {
      const String base = 'Begin Reading · Al-Fatihah';
      expect(quranTileSubtitle(base, offlineReady: true), base);
      expect(quranTileSubtitle(base, offlineReady: null), base);
      // The warning replaces the line (it used to be appended and was cut
      // off on phones), and is short enough for a two-line tile subtitle.
      expect(
        quranTileSubtitle(base, offlineReady: false),
        'Needs internet the first time',
      );
      expect(kQuranNeedsInternetNote.length, lessThan(32));
    });
  });

  group('loading phases', () {
    test('quick, then slow at 2 s, then stalled at 10 s', () {
      expect(loadingPhaseFor(Duration.zero), LoadingPhase.quick);
      expect(
        loadingPhaseFor(const Duration(milliseconds: 1999)),
        LoadingPhase.quick,
      );
      expect(loadingPhaseFor(const Duration(seconds: 2)), LoadingPhase.slow);
      expect(
        loadingPhaseFor(const Duration(seconds: 9)),
        LoadingPhase.slow,
      );
      expect(
        loadingPhaseFor(const Duration(seconds: 10)),
        LoadingPhase.stalled,
      );
    });

    test('wording is honest about web versus phone', () {
      expect(loadingMessageFor(LoadingPhase.quick, 'x', web: true), isEmpty);
      final String web = loadingMessageFor(
        LoadingPhase.slow,
        'the Qur’an',
        sizeHint: 'about 2 MB',
        web: true,
      );
      expect(web, contains('first time only'));
      expect(web, contains('about 2 MB'));
      final String phone = loadingMessageFor(
        LoadingPhase.slow,
        'the Qur’an',
        sizeHint: 'about 2 MB',
        web: false,
      );
      expect(phone, isNot(contains('first time')));
      expect(
        loadingMessageFor(LoadingPhase.stalled, 'x', web: true),
        contains('try again'),
      );
    });
  });

  testWidgets('ContentLoadingView explains itself, then offers Try again', (
    tester,
  ) async {
    int retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentLoadingView(
            what: 'the Qur’an',
            sizeHint: 'about 2 MB',
            web: true,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('first time only'), findsNothing);
    expect(find.text('Try again'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('first time only'), findsOneWidget);
    expect(find.textContaining('about 2 MB'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    await tester.pump(const Duration(seconds: 8));
    expect(find.textContaining('Still loading'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('NeedsInternetView Try again visibly works, then says so if '
      'still failing', (tester) async {
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
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);
    expect(find.text('Checking…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Still could not load'), findsOneWidget);
  });

  group('Qur’an provider error and retry', () {
    test('invalidating after a failure fetches again and succeeds', () async {
      final _FlakyQuran repo = _FlakyQuran(failures: 1);
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[quranRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);

      await expectLater(
        c.read(quranIndexProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(c.read(quranIndexProvider).hasError, isTrue);

      c.invalidate(quranIndexProvider);
      final List<SurahMeta> index = await c.read(quranIndexProvider.future);
      expect(index.single.transliteration, 'Al-Fatihah');
      expect(repo.indexCalls, 2);
    });

    testWidgets('the Qur’an screen: error, Try again, then the list', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      AppHarness.useSurface(tester, height: 1200);
      final _FlakyQuran repo = _FlakyQuran(failures: 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            quranRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: QuranScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NeedsInternetView), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(NeedsInternetView), findsNothing);
      expect(find.textContaining('Al-Fatihah'), findsWidgets);
      expect(repo.indexCalls, 2);
    });
  });
}

class _MemCache implements AssetTextCache {
  _MemCache({this.persistent = true});

  final Map<String, String> store = <String, String>{};

  @override
  final bool persistent;

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String text) async => store[key] = text;

  @override
  Future<bool> has(String key) async => store.containsKey(key);
}

class _BrokenCache implements AssetTextCache {
  @override
  bool get persistent => true;

  @override
  Future<String?> read(String key) => throw StateError('no storage');

  @override
  Future<void> write(String key, String text) => throw StateError('no storage');

  @override
  Future<bool> has(String key) => throw StateError('no storage');
}

class _Bundle extends AssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;
  bool offline = false;
  int loads = 0;

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (offline) throw StateError('offline');
    final String? v = files[key];
    if (v == null) throw StateError('missing $key');
    loads++;
    return v;
  }
}

/// A Qur'an source that fails [failures] times, then works.
class _FlakyQuran implements QuranRepository {
  _FlakyQuran({required this.failures});

  int failures;
  int indexCalls = 0;

  static const SurahMeta _meta = SurahMeta(
    number: 1,
    arabicName: 'الفاتحة',
    transliteration: 'Al-Fatihah',
    englishMeaning: 'The Opening',
    revelationType: 'meccan',
    ayahCount: 7,
  );

  @override
  Future<List<SurahMeta>> index() async {
    indexCalls++;
    if (failures > 0) {
      failures--;
      throw StateError('offline');
    }
    return <SurahMeta>[_meta];
  }

  @override
  Future<List<Surah>> all() async => <Surah>[
        const Surah(meta: _meta, ayahs: <Ayah>[]),
      ];

  @override
  Future<Surah> surah(int number) async =>
      const Surah(meta: _meta, ayahs: <Ayah>[]);
}
