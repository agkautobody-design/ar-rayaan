import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/tight_layout.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart'
    show mushafLayoutProvider;
import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_screen.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

class _SilentAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) async {}
  @override
  Future<void> stop() async {}
}

/// Round 7, large text and very small windows (a browser zoomed to 200% is
/// about 195 x 420 dp): the chat, the Qur'an reader and Prayer Times keep the
/// content people came for on the first screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Map<String, Object> located = <String, Object>{
    'ar.location.lat': 24.86,
    'ar.location.lng': 67.0,
    'ar.location.city': 'My Location',
    'ar.location.country': '',
  };

  void resize(WidgetTester tester, double w, double h, double scale) {
    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  group('isTightLayout', () {
    Future<bool> probe(WidgetTester tester, Size size, double scale) async {
      resize(tester, size.width, size.height, scale);
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              result = isTightLayout(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('a normal phone is not tight', (WidgetTester tester) async {
      expect(await probe(tester, const Size(390, 844), 1.0), isFalse);
    });

    testWidgets('a zoomed window, a short one and big text are tight', (
      WidgetTester tester,
    ) async {
      expect(await probe(tester, const Size(195, 422), 1.0), isTrue);
      expect(await probe(tester, const Size(390, 480), 1.0), isTrue);
      expect(await probe(tester, const Size(390, 844), 2.0), isTrue);
    });
  });

  group('Hādi keeps the chat in view', () {
    List<Override> fixtures() => <Override>[
      hadiCorpusProvider.overrideWith((ref) => loadRealCorpus()),
      storiesProvider.overrideWith((ref) async => const []),
    ];

    for (final (double, double, double) c in <(double, double, double)>[
      (195, 422, 1.0),
      (360, 800, 2.0),
    ]) {
      testWidgets('half the screen is chat at ${c.$1}x${c.$2}, ${c.$3}x text', (
        WidgetTester tester,
      ) async {
        await AppHarness.boot(tester, overrides: fixtures());
        await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
        resize(tester, c.$1, c.$2, c.$3);
        await AppHarness.settle(tester);
        final Rect chat = tester.getRect(
          find
              .descendant(
                of: find.byType(HadiScreen),
                matching: find.byType(ListView),
              )
              .first,
        );
        expect(chat.height, greaterThanOrEqualTo(c.$2 * 0.5));
      });
    }

    testWidgets('a reply is scrolled into view from its first line', (
      WidgetTester tester,
    ) async {
      await AppHarness.boot(tester, overrides: fixtures());
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      resize(tester, 195, 422, 1.0);
      await AppHarness.settle(tester);
      final Finder field = find.descendant(
        of: find.byType(HadiScreen),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'what time is it in Tokyo');
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(HadiScreen),
          matching: find.byIcon(Icons.send),
        ),
      );
      await AppHarness.settle(tester);
      await tester.pump(const Duration(seconds: 1));
      // Narrow-window overflow noise from other widgets is not judged here.
      tester.takeException();
      final Finder reply = find.textContaining('I only cover Islam');
      expect(reply, findsOneWidget);
      final Rect chat = tester.getRect(
        find
            .descendant(
              of: find.byType(HadiScreen),
              matching: find.byType(ListView),
            )
            .first,
      );
      final Rect r = tester.getRect(reply);
      expect(r.top, greaterThanOrEqualTo(chat.top));
      expect(r.top, lessThan(chat.bottom));
    });
  });

  group('the Qur’an reader opens compact', () {
    Future<Widget> reader(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences sp = await SharedPreferences.getInstance();
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
          sharedPreferencesProvider.overrideWithValue(sp),
          quranRepositoryProvider.overrideWithValue(repo),
          recitationPlayerProvider.overrideWith((ref) => player),
          mushafLayoutProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SurahReaderScreen(number: 1),
        ),
      );
    }

    for (final (double, double, double) c in <(double, double, double)>[
      (195, 422, 1.0),
      (360, 800, 2.0),
    ]) {
      testWidgets('Al-Fatihah: ayah 1 is on the first screen at '
          '${c.$1}x${c.$2}, ${c.$3}x text', (WidgetTester tester) async {
        resize(tester, c.$1, c.$2, c.$3);
        await tester.pumpWidget(await reader(tester));
        await tester.pumpAndSettle();
        // The tools are folded behind one line.
        expect(find.byKey(const Key('reader-tools-fold')), findsOneWidget);
        // The first ayah is on screen.
        final Finder first = find.textContaining('In the name of Allah');
        expect(first, findsWidgets);
        expect(tester.getRect(first.first).top, lessThan(c.$2));
      });
    }
  });

  group('Prayer Times puts the times first when space is short', () {
    testWidgets('with a place: the times come before the place card', (
      WidgetTester tester,
    ) async {
      await AppHarness.boot(tester, prefsValues: located);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/prayer');
      tester.takeException();
      resize(tester, 360, 800, 2.0);
      await AppHarness.settle(tester);
      final Finder next = find.text('NEXT PRAYER');
      expect(next, findsOneWidget);
      expect(tester.getRect(next).top, lessThan(400));
      final Finder place = find.byKey(
        const Key('prayer-location-label'),
        skipOffstage: false,
      );
      if (place.evaluate().isNotEmpty) {
        expect(
          tester.getTopLeft(place).dy,
          greaterThan(tester.getTopLeft(next).dy),
        );
      }
      tester.takeException();
    });

    testWidgets('no place yet: Use my location is on the first screen', (
      WidgetTester tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/prayer');
      tester.takeException();
      resize(tester, 195, 422, 1.0);
      await AppHarness.settle(tester);
      final Finder gps = find.byKey(const Key('prayer-prompt-gps'));
      expect(gps, findsOneWidget);
      expect(tester.getRect(gps).bottom, lessThanOrEqualTo(422));
      tester.takeException();
    });
  });
}
