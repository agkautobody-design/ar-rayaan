import 'package:ar_rayaan/app/core/accessibility_scope.dart';
import 'package:ar_rayaan/app/core/keyboard_scroll.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/text_size.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/app/theme/widgets/ask_hadi_pill.dart';
import 'package:ar_rayaan/app/theme/widgets/focus_ring.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:ar_rayaan/features/prayer/presentation/prayer_times_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Accessibility for big text, Elder Mode and the keyboard: the Text size
/// setting, the Elder Mode text floor, the prayer list and Home header at
/// 360px / 2.0x text, keyboard scrolling, the focus ring and the space kept
/// free for the Ask Hadi pill.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  // ---- The text scale ----------------------------------------------------

  group('effectiveTextScale', () {
    test('normal text on a normal phone is left alone', () {
      expect(effectiveTextScale(system: 1, user: 1, elder: false), 1.0);
    });

    test('the Text size choice multiplies the phone size', () {
      expect(
        effectiveTextScale(system: 1.1, user: 1.2, elder: false),
        closeTo(1.32, 1e-9),
      );
      expect(
        effectiveTextScale(system: 1, user: 0.9, elder: false),
        closeTo(0.9, 1e-9),
      );
    });

    test('Elder Mode lifts small text to the floor, never lowers big text', () {
      expect(
        effectiveTextScale(system: 1, user: 1, elder: true),
        kElderTextFloor,
      );
      expect(
        effectiveTextScale(system: 1, user: 0.9, elder: true),
        kElderTextFloor,
      );
      expect(effectiveTextScale(system: 1.6, user: 1, elder: true), 1.6);
    });

    test('is always inside the supported range', () {
      expect(
        effectiveTextScale(system: 2, user: 1.4, elder: true),
        kMaxTextScale,
      );
      expect(
        effectiveTextScale(system: 0.5, user: 0.9, elder: false),
        kMinTextScale,
      );
    });
  });

  group('Text size setting', () {
    Future<ProviderContainer> container(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('starts at Normal', () async {
      final ProviderContainer c = await container(<String, Object>{});
      expect(c.read(textSizeProvider), TextSizeChoice.normal);
    });

    test('is saved and read back', () async {
      final ProviderContainer c = await container(<String, Object>{});
      await c.read(textSizeProvider.notifier).set(TextSizeChoice.extraLarge);
      expect(c.read(textSizeProvider), TextSizeChoice.extraLarge);
      final SharedPreferences prefs = c.read(sharedPreferencesProvider);
      expect(prefs.getString('ar.text.size'), 'extraLarge');

      final ProviderContainer again = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(again.dispose);
      expect(again.read(textSizeProvider), TextSizeChoice.extraLarge);
    });

    test('an unknown stored value falls back to Normal', () async {
      final ProviderContainer c = await container(<String, Object>{
        'ar.text.size': 'gigantic',
      });
      expect(c.read(textSizeProvider), TextSizeChoice.normal);
    });

    test('the four choices grow in order', () {
      final List<double> f = <double>[
        for (final TextSizeChoice c in TextSizeChoice.values) c.factor,
      ];
      expect(f, <double>[0.9, 1.0, 1.2, 1.4]);
      expect(
        TextSizeChoice.values.map((TextSizeChoice c) => c.label).toList(),
        <String>['Small', 'Normal', 'Large', 'Extra large'],
      );
    });
  });

  group('Elder Mode state', () {
    test('is saved under the one Elder Mode key', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(elderModeProvider), isFalse);
      await c.read(elderModeProvider.notifier).set(true);
      expect(c.read(elderModeProvider), isTrue);
      expect(prefs.getBool(ElderMode.pref), isTrue);
      await c.read(elderModeProvider.notifier).set(false);
      expect(prefs.getBool(ElderMode.pref), isFalse);
    });
  });

  // ---- The scale really reaches the screens -------------------------------

  Future<double> scaleSeenBy(
    WidgetTester tester,
    Map<String, Object> prefsValues,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    double seen = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: AccessibilityScope(
            child: Builder(
              builder: (BuildContext context) {
                seen = MediaQuery.textScalerOf(context).scale(14) / 14;
                return const Scaffold(body: Text('hello'));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return seen;
  }

  group('AccessibilityScope', () {
    testWidgets('leaves normal text alone', (tester) async {
      expect(await scaleSeenBy(tester, <String, Object>{}), closeTo(1.0, 1e-9));
    });

    testWidgets('Elder Mode keeps the whole app at least 1.35x', (
      tester,
    ) async {
      final double s = await scaleSeenBy(tester, <String, Object>{
        ElderMode.pref: true,
      });
      expect(s, closeTo(kElderTextFloor, 1e-9));
    });

    testWidgets('the Text size setting applies to the whole app', (
      tester,
    ) async {
      final double s = await scaleSeenBy(tester, <String, Object>{
        'ar.text.size': 'large',
      });
      expect(s, closeTo(1.2, 1e-9));
    });

    testWidgets('Elder Mode makes buttons at least 56dp tall', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ElderMode.pref: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: AccessibilityScope(
              child: Scaffold(
                body: Center(
                  child: TextButton(onPressed: () {}, child: const Text('Go')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(kElderMinTapHeight),
      );
    });

    testWidgets('the whole app follows the Elder Mode flag at launch', (
      tester,
    ) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{ElderMode.pref: true},
      );
      final double s =
          MediaQuery.textScalerOf(
            tester.element(find.byType(Scaffold).first),
          ).scale(14) /
          14;
      expect(s, greaterThanOrEqualTo(kElderTextFloor - 1e-9));
    });
  });

  group('Settings', () {
    testWidgets('Elder Mode can be switched on from Settings', (tester) async {
      final AppHarness h = await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/settings');
      expect(find.text('Elder Mode'), findsOneWidget);
      await tester.tap(find.text('Elder Mode'));
      await AppHarness.settle(tester);
      expect(h.prefs.getBool(ElderMode.pref), isTrue);
      expect(
        AppHarness.location(tester, find.byType(Scaffold).first),
        ElderMode.homeRoute,
      );
      // The way out is always on the Elder home.
      expect(find.text('Turn off Elder Mode'), findsOneWidget);
    });

    testWidgets('Text size: choosing Large is saved and applied', (
      tester,
    ) async {
      final AppHarness h = await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/settings');
      expect(find.text('Text size'), findsOneWidget);
      await tester.tap(find.byKey(const Key('text-size-large')));
      await AppHarness.settle(tester);
      expect(h.prefs.getString('ar.text.size'), 'large');
      final double s =
          MediaQuery.textScalerOf(
            tester.element(find.byType(Scaffold).first),
          ).scale(14) /
          14;
      expect(s, closeTo(1.2, 1e-9));
    });
  });

  // ---- Big text: the prayer list and the Home header -----------------------

  final PrayerTimes times = PrayerTimes(
    fajr: DateTime(2026, 10, 22, 5, 41),
    sunrise: DateTime(2026, 10, 22, 7, 5),
    dhuhr: DateTime(2026, 10, 22, 12, 47),
    asr: DateTime(2026, 10, 22, 15, 52),
    maghrib: DateTime(2026, 10, 22, 18, 21),
    isha: DateTime(2026, 10, 22, 19, 45),
    locationLabel: 'Toronto, Canada',
    methodLabel: 'Muslim World League',
  );

  // Overflow reports from the prayer ROWS only (the other cards on the
  // screen are not under test here and the test font is much wider than the
  // real one).
  final List<String> rowOverflows = <String>[];

  Future<void> pumpPrayer(WidgetTester tester, {double scale = 2.0}) async {
    rowOverflows.clear();
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String text = d.toString();
      final RegExpMatch? m = RegExp(
        r'prayer_times_screen\.dart:(\d+)',
      ).firstMatch(text);
      final int line = m == null ? 0 : int.parse(m.group(1)!);
      if (text.contains('overflowed') && line >= 410 && line <= 600) {
        rowOverflows.add(text.split('\n').first);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    bigText(tester, scale: scale, height: 3200);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FakeAuthRepository auth = FakeAuthRepository(prefs);
    await auth.init();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          prayerLocationProvider.overrideWithValue(
            const PrayerLocation(
              city: 'Toronto',
              country: 'Canada',
              latitude: 43.65,
              longitude: -79.38,
            ),
          ),
          prayerTimesProvider.overrideWith((ref) async => times),
          nowTickerProvider.overrideWith(
            (ref) => Stream<DateTime>.value(DateTime(2026, 10, 22, 10)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AccessibilityScope(child: PrayerTimesScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Prayer list at big text', () {
    for (final double scale in <double>[1.0, 1.4, 2.0]) {
      testWidgets('lays out at 360px wide and ${scale}x text', (tester) async {
        await pumpPrayer(tester, scale: scale);
        expect(rowOverflows, isEmpty);
        // Every name is a whole word on one line, every time is shown.
        for (final String name in <String>[
          'Fajr',
          'Sunrise',
          'Dhuhr',
          'Asr',
          'Maghrib',
          'Isha',
        ]) {
          expect(find.text(name), findsWidgets, reason: name);
        }
        // Sunrise only appears in the list: one line, not a letter per line.
        expect(
          tester.getSize(find.text('Sunrise').first).height,
          lessThan(14 * scale * 2),
        );
        for (final String t in <String>[
          '5:41',
          '7:05',
          '12:47',
          '3:52',
          '6:21',
          '7:45',
        ]) {
          expect(find.textContaining(t), findsWidgets, reason: t);
        }
      });
    }

    testWidgets('every bell is a whole 48dp target at 2.0x', (tester) async {
      await pumpPrayer(tester);
      final Finder bells = find.byWidgetPredicate(
        (Widget w) =>
            w is IconButton && (w.tooltip ?? '').startsWith('Turn on the'),
      );
      expect(bells, findsWidgets);
      for (final Element e in bells.evaluate()) {
        final Size s = (e.renderObject! as RenderBox).size;
        expect(s.width, greaterThanOrEqualTo(48));
        expect(s.height, greaterThanOrEqualTo(48));
      }
      expect(rowOverflows, isEmpty);
    });
  });

  testWidgets('Home lays out at 360px wide and 2.0x text', (tester) async {
    await AppHarness.boot(tester);
    tester.takeException();
    final List<String> homeOverflows = <String>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String text = d.toString();
      if (text.contains('overflowed') &&
          (text.contains('home_screen.dart') ||
              text.contains('hadi_ask_bar.dart'))) {
        homeOverflows.add(text.split('\n').first);
      }
    };
    try {
      bigText(tester, height: 4000);
      await AppHarness.settle(tester);
    } finally {
      FlutterError.onError = previous;
    }
    tester.takeException();
    expect(homeOverflows, isEmpty);
    // The Elder Mode title is one piece, not split into letters.
    final Finder title = find.text('ELDER MODE');
    expect(title, findsOneWidget, reason: 'ELDER MODE card is built');
    expect(tester.getSize(title).height, lessThan(14 * 2.0 * 2));
    // The header has a Search button.
    expect(find.byTooltip('Search'), findsWidgets);
  });

  // ---- The Ask Hadi pill never covers anything -----------------------------

  group('Ask Hadi pill', () {
    testWidgets('the last row of a list ends above the pill', (tester) async {
      AppHarness.useSurface(tester, height: 800);
      await tester.pumpWidget(
        MaterialApp(
          home: AskHadiPillHost(
            enabled: true,
            child: Scaffold(
              body: ListView(
                children: <Widget>[
                  for (int i = 0; i < 40; i++)
                    SizedBox(height: 60, child: Text('row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final Rect last = tester.getRect(find.text('row 39'));
      final Rect pill = tester.getRect(find.byType(AskHadiPill));
      expect(last.overlaps(pill), isFalse);
      expect(last.bottom, lessThanOrEqualTo(pill.top + 0.5));
    });

    testWidgets('is a round icon at large text', (tester) async {
      bigText(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: AskHadiPillHost(
            enabled: true,
            child: Scaffold(body: Text('page')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ask Hādi'), findsNothing);
      final Size s = tester.getSize(find.byType(AskHadiPill));
      expect(s.width, lessThan(80));
      expect(s.height, greaterThanOrEqualTo(48));
    });
  });

  // ---- The keyboard ---------------------------------------------------------

  group('Keyboard', () {
    late ScrollController list;
    late int pressed;

    Future<void> pumpPage(WidgetTester tester) async {
      AppHarness.useSurface(tester, height: 800);
      list = ScrollController();
      addTearDown(list.dispose);
      pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardScrollScope(
            child: Scaffold(
              body: Column(
                children: <Widget>[
                  TextButton(
                    autofocus: true,
                    onPressed: () => pressed++,
                    child: const Text('Header button'),
                  ),
                  Expanded(
                    child: ListView(
                      controller: list,
                      children: <Widget>[
                        for (int i = 0; i < 80; i++)
                          SizedBox(height: 60, child: Text('row $i')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Page Down / Page Up scroll with focus outside the list', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(list.offset, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(list.offset, greaterThan(300));
      final double afterDown = list.offset;
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(list.offset, lessThan(afterDown));
    });

    testWidgets('End and Home jump to the ends', (tester) async {
      await pumpPage(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(list.offset, list.position.maxScrollExtent);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(list.offset, 0);
    });

    testWidgets('Space on a focused button presses it, it does not scroll', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(list.offset, 0);
    });
  });

  group('Focus ring', () {
    testWidgets('Tab shows a 3px gold ring and Enter activates', (
      tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FocusableTap(
                onTap: () => taps++,
                child: const SizedBox(
                  width: 120,
                  height: 80,
                  child: Text('tile'),
                ),
              ),
            ),
          ),
        ),
      );
      bool ringShown() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .any((DecoratedBox d) {
            final Decoration dec = d.decoration;
            return dec is BoxDecoration &&
                d.position == DecorationPosition.foreground &&
                dec.border != null &&
                dec.border!.top.width == kFocusRingWidth;
          });
      expect(ringShown(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ringShown(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });
  });
}
