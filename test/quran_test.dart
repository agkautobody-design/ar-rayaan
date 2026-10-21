import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart'
    show mushafLayoutProvider;
import 'package:ar_rayaan/features/academy/data/mushaf_layout_pack.dart'
    show kMadinahLayoutSha256;
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:ar_rayaan/features/search/domain/quran_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Silent audio backend so the reader never touches a real plugin.
class _SilentAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) async {}
  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled repository', () {
    final BundledQuranRepository repo = BundledQuranRepository();

    test('index lists all 114 surahs in order with metadata', () async {
      final List<SurahMeta> index = await repo.index();
      expect(index.length, 114);
      expect(index.first.number, 1);
      expect(index.first.transliteration, 'Al-Fatihah');
      expect(index.first.ayahCount, 7);
      expect(index.first.isMeccan, isTrue);
      expect(index.last.number, 114);
      expect(index[17].transliteration, 'Al-Kahf');
      expect(index[17].ayahCount, 110);
    });

    test('surah returns full Arabic + English text', () async {
      final Surah fatiha = await repo.surah(1);
      expect(fatiha.ayahs.length, 7);
      expect(fatiha.ayahs.first.english, contains('In the name of Allah'));

      final Surah ikhlas = await repo.surah(112);
      expect(ikhlas.ayahs.length, 4);
      expect(ikhlas.ayahs.every((a) => a.arabic.isNotEmpty), isTrue);
      expect(ikhlas.ayahs.every((a) => a.english.isNotEmpty), isTrue);
    });

    test('invalid surah number throws', () async {
      expect(() => repo.surah(0), throwsA(isA<ArgumentError>()));
      expect(() => repo.surah(115), throwsA(isA<ArgumentError>()));
    });

    test('the whole Qur’an is there: 114 surahs, 6,236 ayahs, no gaps',
        () async {
      final List<Surah> all = await repo.all();
      expect(all.length, 114);
      int total = 0;
      for (final Surah s in all) {
        expect(s.ayahs.length, s.meta.ayahCount, reason: 'surah ${s.meta.number}');
        for (int i = 0; i < s.ayahs.length; i++) {
          expect(s.ayahs[i].number, i + 1);
          expect(s.ayahs[i].arabic.trim(), isNotEmpty);
          expect(s.ayahs[i].english.trim(), isNotEmpty);
        }
        total += s.ayahs.length;
      }
      expect(total, 6236);
    });

    test('26:78 is "who created me, and it is He who guides me"', () async {
      final Surah shuara = await repo.surah(26);
      final Ayah a = shuara.ayahs[77];
      expect(a.number, 78);
      expect(foldArabic(a.arabic), foldArabic('الَّذِي خَلَقَنِي فَهُوَ يَهْدِينِ'));
      expect(a.english, contains('created me'));
    });

    test('2:255 is Ayat al-Kursi', () async {
      final Surah baqarah = await repo.surah(2);
      expect(foldArabic(baqarah.ayahs[254].arabic), contains('الحي القيوم'));
    });
  });

  group('helpers', () {
    test('Arabic-Indic numeral conversion', () {
      expect(SurahReaderScreen.toArabicIndic(1), '١');
      expect(SurahReaderScreen.toArabicIndic(18), '١٨');
      expect(SurahReaderScreen.toArabicIndic(286), '٢٨٦');
    });
  });

  group('Madinah layout', () {
    test('is honestly unavailable until a verified pack ships', () {
      // No verified 604-page layout is bundled and no checksum is recorded,
      // so the loader refuses and the reader hides the toggle instead of
      // showing guessed lines. If a pack ever ships it must come with its
      // checksum, and this test is then replaced by one that verifies it.
      final bool packShipped =
          File('assets/quran/madinah_layout.json').existsSync();
      expect(packShipped, isFalse);
      expect(kMadinahLayoutSha256, isEmpty);
    });
  });

  group('Qur’an search', () {
    late List<Surah> all;
    setUpAll(() async {
      all = await BundledQuranRepository().all();
    });

    test('verse keys jump straight to the ayah', () {
      final List<QuranHit> hits = searchQuran(all, '2:255');
      expect(hits, isNotEmpty);
      expect(hits.first.surah, 2);
      expect(hits.first.ayah, 255);
      expect(searchQuran(all, '26.78').first.key, '26:78');
      expect(searchQuran(all, '2:9999'), isEmpty);
    });

    test('Arabic without diacritics finds the voweled text', () {
      final List<QuranHit> hits = searchQuran(all, 'الحي القيوم', limit: 50);
      expect(hits.any((QuranHit h) => h.key == '2:255'), isTrue);
      expect(hits.any((QuranHit h) => h.key == '3:2'), isTrue);
    });

    test('English words match the Saheeh text', () {
      final List<QuranHit> hits =
          searchQuran(all, 'created me guides me', limit: 200);
      expect(hits.any((QuranHit h) => h.key == '26:78'), isTrue);
    });

    test('empty and nonsense queries return nothing', () {
      expect(searchQuran(all, ''), isEmpty);
      expect(searchQuran(all, '   '), isEmpty);
      expect(searchQuran(all, 'zzzqqxxnotaword'), isEmpty);
    });

    test('limit is respected', () {
      expect(searchQuran(all, 'Allah', limit: 5).length, 5);
    });
  });

  group('reading position', () {
    test('remembers a place per surah and survives a restart', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      ProviderContainer make() => ProviderContainer(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          );

      final ProviderContainer first = make();
      addTearDown(first.dispose);
      final ReadingPositionController c =
          first.read(readingPositionProvider.notifier);
      expect(c.ayahFor(2), 1, reason: 'never opened');
      await c.save(const ReadingPosition(surah: 2, ayah: 200));
      await c.save(const ReadingPosition(surah: 18, ayah: 10));
      expect(c.ayahFor(2), 200, reason: 'opening Al-Kahf keeps Al-Baqarah');
      expect(c.ayahFor(18), 10);
      expect(first.read(readingPositionProvider)?.surah, 18);

      final ProviderContainer second = make();
      addTearDown(second.dispose);
      final ReadingPositionController again =
          second.read(readingPositionProvider.notifier);
      second.read(readingPositionProvider);
      expect(again.ayahFor(2), 200);
      expect(again.ayahFor(18), 10);
      expect(second.read(readingPositionProvider)?.ayah, 10);
    });
  });

  group('reader', () {
    Future<Widget> app(WidgetTester tester, int surah) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final BundledQuranRepository repo = BundledQuranRepository();
      // rootBundle I/O needs the real event loop - FakeAsync never delivers it.
      await tester.runAsync(() async {
        await repo.all();
        for (final String a in <String>[
          'assets/quran/transliteration.json',
        ]) {
          try {
            await rootBundle.loadString(a);
          } catch (_) {}
        }
      });
      final RecitationPlayerNotifier player = RecitationPlayerNotifier(
        audio: _SilentAudio(),
        sourceResolver: (PlaybackEvent e) async => 'src:${e.ref.ayah}',
        sleeper: (int ms) async {},
      );
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          quranRepositoryProvider.overrideWithValue(repo),
          recitationPlayerProvider.overrideWith((ref) => player),
          // No verified Madinah pack is bundled: the toggle must stay hidden.
          mushafLayoutProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SurahReaderScreen(number: surah),
        ),
      );
    }

    testWidgets('opens Al-Fatihah, hides the Madinah toggle, saves on tap',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await app(tester, 1));
      await tester.pumpAndSettle();

      final Object? error = tester.takeException();
      expect(error, isNull, reason: '$error');
      expect(find.textContaining('In the name of Allah'), findsOneWidget);
      expect(find.text('Madinah page view'), findsNothing);

      await tester.tap(find.textContaining('Sovereign of the Day'));
      await tester.pump();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(SurahReaderScreen)),
      );
      final ReadingPosition? saved = container.read(readingPositionProvider);
      expect(saved?.surah, 1);
      expect(saved?.ayah, 4);
    });

    testWidgets('Continue Reading scrolls to the saved ayah', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.quran.positions': '{"2":200}',
      });
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await app(tester, 2));
      await tester.pumpAndSettle();

      final Object? error = tester.takeException();
      expect(error, isNull, reason: '$error');
      // Ayah 200 (unique wording) is on screen; ayah 1 is far above.
      expect(find.textContaining('remember Allah like your [previous]'),
          findsOneWidget);
      expect(find.textContaining('Alif, Lam, Meem'), findsNothing);
    });

    testWidgets('Al-Baqarah is virtualised: only on-screen ayahs are built',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await app(tester, 2));
      await tester.pumpAndSettle();

      final int built =
          find.byTooltip('Bookmark this ayah').evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(40),
          reason: 'only ayahs near the viewport may exist, not all 286');
      // Ayah 286 is far below: not built until scrolled to.
      expect(find.textContaining('Allah does not charge a soul'), findsNothing);
      expect(find.byType(BackdropFilter).evaluate().length, lessThanOrEqualTo(3));
    });
  });
}
