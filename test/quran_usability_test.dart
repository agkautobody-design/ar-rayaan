import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart'
    show mushafLayoutProvider;
import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/presentation/verse_range_player_bar.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/domain/quran_marks.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_marks_link_card.dart';
import 'package:ar_rayaan/features/quran/presentation/quran_screen.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) async {}
  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> app(WidgetTester tester, Widget home) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final BundledQuranRepository repo = BundledQuranRepository();
    await tester.runAsync(() async {
      await repo.all();
      try {
        await rootBundle.loadString('assets/quran/transliteration.json');
      } catch (_) {}
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
        mushafLayoutProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: home),
    );
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('surah list', () {
    testWidgets('search filters by name, meaning and number', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      phone(tester);
      await tester.pumpWidget(await app(tester, const QuranScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ayat al-Kursi · 2:255'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yasin');
      await tester.pumpAndSettle();
      expect(find.text('Ya-Sin'), findsOneWidget);
      expect(find.text('Al-Fatihah'), findsNothing);
      // The shortcut steps aside while searching.
      expect(find.text('Ayat al-Kursi · 2:255'), findsNothing);

      // Other common spellings of the same name find it too.
      await tester.enterText(find.byType(TextField), 'Yaseen');
      await tester.pumpAndSettle();
      expect(find.text('Ya-Sin'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'cow');
      await tester.pumpAndSettle();
      expect(find.text('Al-Baqarah'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '67');
      await tester.pumpAndSettle();
      expect(find.text('Al-Mulk'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No surah matches'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Al-Fatihah'), findsOneWidget);
    });
  });

  group('reader', () {
    testWidgets('startAyah opens at that ayah (Ayat al-Kursi)', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      phone(tester);
      await tester.pumpWidget(
        await app(tester, const SurahReaderScreen(number: 2, startAyah: 255)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('there is no deity except Him, the Ever-Living'),
        findsWidgets,
      );
    });

    testWidgets('big text: controls scroll away and reading keeps the screen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        await app(tester, const SurahReaderScreen(number: 2)),
      );
      await tester.pumpAndSettle();

      // The list (the reading area) gets most of the screen: only the slim
      // header and the one-row player bar sit outside it.
      final Size list = tester.getSize(find.byType(ListView).first);
      expect(list.height, greaterThan(700 * 0.6));
      // Controls start inside the list, folded into one line at this size
      // so the verses come first...
      expect(find.text('Jump to ayah'), findsNothing);
      await tester.tap(find.text('Reader tools'));
      await tester.pumpAndSettle();
      expect(find.text('Jump to ayah').hitTestable(), findsOneWidget);
      // ...and scroll away with it.
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Jump to ayah').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Jump to ayah validates and scrolls', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      phone(tester);
      await tester.pumpWidget(
        await app(tester, const SurahReaderScreen(number: 2)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jump to ayah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a number from 1 to 286.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '255');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Enter a number from 1 to 286.'), findsNothing);
      expect(
        find.textContaining('there is no deity except Him, the Ever-Living'),
        findsWidgets,
      );
    });

    testWidgets('player bar stays slim and reachable at big text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        await app(
          tester,
          const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: VerseRangePlayerBar(surah: 36, ayahCount: 83),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // One line: the range is not broken across lines.
      expect(find.text('1 – 83'), findsOneWidget);
      expect(
        tester.getSize(find.byType(VerseRangePlayerBar)).height,
        lessThan(700 * 0.25),
      );
      expect(find.byTooltip('Show controls'), findsOneWidget);
      // One slim row: no "Repeat" word to be cut off, just the icon.
      expect(find.text('Repeat'), findsNothing);

      await tester.tap(find.byTooltip('Show controls'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Repeat each ayah'), findsOneWidget);
      expect(find.byTooltip('Hide controls'), findsOneWidget);
    });
  });

  group('Qur’an marks on the You screens', () {
    test('summary words', () {
      expect(
        QuranMarksLinkCard.summary(const QuranMarks()),
        startsWith('Nothing yet'),
      );
      const QuranMarks one = QuranMarks(
        marks: <String, AyahMark>{
          '1:1': AyahMark(surah: 1, ayah: 1, bookmarked: true),
        },
      );
      expect(QuranMarksLinkCard.summary(one), '1 ayah');
      const QuranMarks two = QuranMarks(
        marks: <String, AyahMark>{
          '1:1': AyahMark(surah: 1, ayah: 1, bookmarked: true, note: 'x'),
          '2:255': AyahMark(surah: 2, ayah: 255, bookmarked: true),
        },
      );
      expect(QuranMarksLinkCard.summary(two), '2 ayahs, 1 note');
    });

    testWidgets('card shows the saved count from the reader’s store', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.quran.marks.v1': '{"v":1,"collections":[],"marks":[{"s":1,"a":1,"b":true,"n":"hi","c":[],"t":1}]}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: QuranMarksLinkCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 ayah, 1 note'), findsOneWidget);
    });
  });
}
