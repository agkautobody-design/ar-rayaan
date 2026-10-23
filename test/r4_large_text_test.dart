import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/ask_hadi_pill.dart';
import 'package:ar_rayaan/app/theme/widgets/whole_word_text.dart';
import 'package:ar_rayaan/features/academy/application/academy_providers.dart'
    show mushafLayoutProvider;
import 'package:ar_rayaan/features/academy/application/recitation_player_provider.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/quran/application/quran_providers.dart';
import 'package:ar_rayaan/features/quran/data/bundled_quran_repository.dart';
import 'package:ar_rayaan/features/quran/presentation/surah_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

class _SilentAudio implements AyahAudioPlayer {
  @override
  Future<void> play(String pathOrUrl) async {}
  @override
  Future<void> stop() async {}
}

/// Round 4, large text and Elder Mode: no word is ever broken in the middle,
/// the main screens lay out at 2.0x text on a 360px phone, and the Elder
/// home, the Prayer prompt, the reader and Settings behave for big text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Map<String, Object> located = <String, Object>{
    'ar.location.lat': 24.86,
    'ar.location.lng': 67.0,
    'ar.location.city': 'My Location',
    'ar.location.country': '',
  };

  void bigText(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
    double scale = 2.0,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  List<String> drain(WidgetTester tester) {
    final List<String> errors = <String>[];
    Object? e = tester.takeException();
    while (e != null) {
      errors.add(e.toString().split('\n').first);
      e = tester.takeException();
    }
    return errors;
  }

  // ---- WholeWordText ------------------------------------------------------

  group('WholeWordText', () {
    const TextStyle style = TextStyle(fontSize: 20);

    double factor(String text, double width) => WholeWordText.fitFactor(
      text: text,
      style: style,
      scaler: TextScaler.noScaling,
      direction: TextDirection.ltr,
      maxWidth: width,
    );

    test('leaves text alone when every word fits', () {
      expect(factor('Prayer times', 2000), 1);
    });

    test('shrinks so the longest word fits', () {
      final double f = factor('Prayer times', 100);
      expect(f, lessThan(1));
      // The widest word, drawn at the smaller size, fits the box.
      final TextPainter p = TextPainter(
        text: TextSpan(text: 'Prayer', style: style.copyWith(fontSize: 20 * f)),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(p.width, lessThanOrEqualTo(100));
    });

    test('a hyphen is a place to break, a long word is not', () {
      // "Al-Ikhlas": the widest piece is "Ikhlas" (6), not all nine letters.
      final double hyphen = factor('Al-Ikhlas', 130);
      final double single = factor('Alikhlasx', 130);
      expect(hyphen, greaterThan(single));
    });

    test('never shrinks below the minimum', () {
      expect(factor('Supercalifragilistic', 10), 0.4);
    });

    testWidgets('draws one whole word at a smaller size, no overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 70,
              child: WholeWordText('Praying times', style: style),
            ),
          ),
        ),
      );
      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontSize, lessThan(20));
      expect(tester.takeException(), isNull);
      // Two lines, "Praying" and "times": no word was cut in the middle.
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      expect(p.computeLineMetrics().length, 2);
    });

    testWidgets('keeps the size when the words fit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              child: WholeWordText('Prayer times', style: style),
            ),
          ),
        ),
      );
      expect(tester.widget<Text>(find.byType(Text)).style!.fontSize, 20);
    });
  });

  // ---- The main screens at 360px wide and 2.0x text -----------------------

  Future<void> expectCleanAt(
    WidgetTester tester,
    String path, {
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    await AppHarness.boot(tester, prefsValues: prefs);
    await AppHarness.go(tester, find.byType(Scaffold).first, path);
    tester.takeException();
    bigText(tester);
    await AppHarness.settle(tester);
    await tester.pump(const Duration(seconds: 4));
    final List<String> errors = drain(tester);
    expect(errors, isEmpty, reason: '$path at 360px, text 2.0x: $errors');
  }

  testWidgets('Elder home lays out at 360px and 2.0x text', (tester) async {
    await expectCleanAt(
      tester,
      ElderMode.homeRoute,
      prefs: <String, Object>{ElderMode.pref: true},
    );
  });

  testWidgets('Prayer Times (no place yet) lays out at 360px and 2.0x', (
    tester,
  ) async {
    await expectCleanAt(tester, '/prayer');
  });

  testWidgets('Prayer Times (with a place) lays out at 360px and 2.0x', (
    tester,
  ) async {
    await expectCleanAt(tester, '/prayer', prefs: located);
  });

  testWidgets('Daily Duas lays out at 360px and 2.0x', (tester) async {
    await expectCleanAt(tester, '/adhkar');
  });

  testWidgets('the welcome screens lay out at 360px and 2.0x', (tester) async {
    await expectCleanAt(tester, '/onboarding?replay=1');
    await tester.tap(find.text('Next'));
    await AppHarness.settle(tester);
    expect(drain(tester), isEmpty);
  });

  testWidgets('Home blocks lay out at 360px and 2.0x', (tester) async {
    final List<String> found = <String>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String text = d.toString(minLevel: DiagnosticLevel.debug);
      if (text.contains('overflowed') &&
          RegExp(r'_PictureTile|_NextStepCard|_SemanticTap').hasMatch(text)) {
        found.add(text.split('\n').first);
      }
    };
    await AppHarness.boot(tester);
    bigText(tester);
    await AppHarness.settle(tester);
    FlutterError.onError = previous;
    expect(found.join(', '), '');
  });

  // ---- Settings: nothing floats over the Text size choices ----------------

  testWidgets('Settings draws no Ask Hadi pill over the Text size choices', (
    tester,
  ) async {
    AskHadiPillHost.forceEnabled = true;
    addTearDown(() => AskHadiPillHost.forceEnabled = null);
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, '/settings');
    expect(find.byType(AskHadiPill), findsNothing);
    expect(find.byKey(const Key('text-size-large')), findsOneWidget);
    // One tap on Large selects it and stays on Settings.
    await tester.tap(find.byKey(const Key('text-size-large')));
    await AppHarness.settle(tester);
    expect(
      AppHarness.location(tester, find.byType(Scaffold).first),
      '/settings',
    );
  });

  // ---- Elder home ---------------------------------------------------------

  group('Elder home', () {
    testWidgets('the Qur’an and Daily Duas come before the counter', (
      tester,
    ) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        ElderMode.homeRoute,
      );
      final double quran = tester.getTopLeft(find.text('Qur’an')).dy;
      final double duas = tester.getTopLeft(find.text('Daily Duas')).dy;
      final double counter = tester.getTopLeft(find.text('SUBHAN ALLAH')).dy;
      expect(quran, lessThan(duas));
      expect(duas, lessThan(counter));
    });

    testWidgets('the first tap on Prayer times opens it', (tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        ElderMode.homeRoute,
      );
      await tester.tap(find.text('Prayer times'));
      await AppHarness.settle(tester);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        '/prayer',
      );
    });

    testWidgets('the list has a visible scrollbar', (tester) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        ElderMode.homeRoute,
      );
      expect(find.byType(Scrollbar), findsWidgets);
    });
  });

  // ---- Prayer times -------------------------------------------------------

  group('Prayer times', () {
    testWidgets('with no place, the page offers two big buttons', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/prayer');
      final Finder gps = find.byKey(const Key('prayer-prompt-gps'));
      final Finder city = find.byKey(const Key('prayer-prompt-city'));
      expect(gps, findsOneWidget);
      expect(city, findsOneWidget);
      expect(tester.getSize(gps).height, greaterThanOrEqualTo(56));
      expect(tester.getSize(city).height, greaterThanOrEqualTo(56));
    });

    testWidgets('the list of times is at least 17 px, like its neighbours', (
      tester,
    ) async {
      await AppHarness.boot(tester, prefsValues: located);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/prayer');
      for (final String name in <String>['Fajr', 'Dhuhr', 'Asr', 'Isha']) {
        final Iterable<Text> rows = tester.widgetList<Text>(find.text(name));
        expect(rows, isNotEmpty, reason: name);
        expect(
          rows.any((Text t) => (t.style?.fontSize ?? 0) >= 17),
          isTrue,
          reason: '$name row text size',
        );
      }
    });
  });

  // ---- Welcome screens ----------------------------------------------------

  group('welcome', () {
    testWidgets('big text offers Elder Mode, and one tap turns it on', (
      tester,
    ) async {
      final AppHarness h = await AppHarness.boot(tester);
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        '/onboarding?replay=1',
      );
      bigText(tester);
      await AppHarness.settle(tester);
      final Finder offer = find.byKey(const Key('onboarding-elder-offer'));
      expect(offer, findsOneWidget);
      await tester.ensureVisible(offer);
      await tester.tap(offer);
      await AppHarness.settle(tester);
      expect(h.prefs.getBool(ElderMode.pref), isTrue);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        ElderMode.homeRoute,
      );
    });

    testWidgets('normal text shows no Elder offer', (tester) async {
      await AppHarness.boot(tester);
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        '/onboarding?replay=1',
      );
      expect(find.byKey(const Key('onboarding-elder-offer')), findsNothing);
    });

    testWidgets('big text stacks the goals one per line', (tester) async {
      await AppHarness.boot(tester);
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        '/onboarding?replay=1',
      );
      bigText(tester);
      await AppHarness.settle(tester);
      await tester.tap(find.text('Next'));
      await AppHarness.settle(tester);
      final double a = tester.getTopLeft(find.text('Learning about Islam')).dx;
      final double b = tester.getTopLeft(find.text('Peace for my heart')).dx;
      // Same left edge: stacked, not side by side.
      expect((a - b).abs(), lessThan(40));
      expect(
        tester.getTopLeft(find.text('Peace for my heart')).dy,
        greaterThan(tester.getTopLeft(find.text('Learning about Islam')).dy),
      );
    });
  });

  // ---- The Qur'an reader --------------------------------------------------

  group('Qur’an reader', () {
    Future<Widget> reader(
      WidgetTester tester, {
      Map<String, Object> prefs = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
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
          home: const SurahReaderScreen(number: 2),
        ),
      );
    }

    testWidgets('A- and A+ stay in reach while reading and grow the page', (
      tester,
    ) async {
      bigText(tester, height: 700);
      await tester.pumpWidget(await reader(tester));
      await tester.pumpAndSettle();
      final Finder larger = find.byTooltip('Larger text');
      expect(larger.hitTestable(), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      // The toolbar has scrolled away; the header buttons have not.
      expect(find.text('Jump to ayah').hitTestable(), findsNothing);
      expect(larger.hitTestable(), findsOneWidget);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(SurahReaderScreen)),
      );
      final double before = c.read(arabicSizeProvider);
      await tester.tap(larger);
      await tester.pump();
      expect(c.read(arabicSizeProvider), before + ArabicSizeController.step);
      expect(ArabicSizeController.step, greaterThanOrEqualTo(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Elder Mode: ayah buttons carry words and are 48dp or more', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        await reader(tester, prefs: <String, Object>{ElderMode.pref: true}),
      );
      await tester.pumpAndSettle();
      for (final String label in <String>['Play', 'Save', 'More']) {
        // TextButton.icon builds a subclass, so match by subtype.
        final Finder f = find.ancestor(
          of: find.text(label),
          matching: find.bySubtype<TextButton>(),
        );
        expect(f, findsWidgets, reason: label);
        expect(tester.getSize(f.first).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(f.first).width, greaterThanOrEqualTo(48));
      }
    });
  });
}
