import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/tasbeeh/application/tasbeeh_providers.dart';
import 'package:ar_rayaan/features/tasbeeh/data/tasbeeh_store.dart';
import 'package:ar_rayaan/features/tasbeeh/presentation/tasbeeh_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tasbeeh_fakes.dart';

void main() {
  final Finder pad = find.byKey(const ValueKey<String>('tasbeeh-tap-pad'));
  final Finder count = find.byKey(const ValueKey<String>('tasbeeh-count'));

  String shown(WidgetTester tester) => tester.widget<Text>(count).data!;

  Future<SharedPreferences> pump(
    WidgetTester tester, {
    required FakeVolumeCounterChannel channel,
    required FakeScreenAwake awake,
    Map<String, Object> seed = const <String, Object>{},
    SharedPreferences? reuse,
  }) async {
    SharedPreferences prefs;
    if (reuse != null) {
      prefs = reuse;
    } else {
      SharedPreferences.setMockInitialValues(seed);
      prefs = await SharedPreferences.getInstance();
    }
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          volumeCounterChannelProvider.overrideWithValue(channel),
          screenAwakeProvider.overrideWithValue(awake),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const TasbeehScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return prefs;
  }

  testWidgets('taps count up and the numbers are saved', (tester) async {
    final FakeVolumeCounterChannel ch = FakeVolumeCounterChannel(
      supported: false,
    );
    final SharedPreferences prefs = await pump(
      tester,
      channel: ch,
      awake: FakeScreenAwake(),
    );
    expect(shown(tester), '0');
    expect(find.text('of 33'), findsOneWidget);
    await tester.tap(pad);
    await tester.tap(pad);
    await tester.tap(pad);
    await tester.pump();
    expect(shown(tester), '3');
    expect(prefs.getInt(TasbeehStore.kCount), 3);
  });

  testWidgets('the whole lower half is the tap area', (tester) async {
    await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
    );
    final Rect r = tester.getRect(pad);
    final double screen = tester.view.physicalSize.height;
    expect(r.top, greaterThanOrEqualTo(screen * 0.4));
    expect(r.bottom, greaterThan(screen * 0.9));
    expect(r.width, greaterThan(380));
  });

  testWidgets('a saved count and target come back after a reload', (
    tester,
  ) async {
    final SharedPreferences prefs = await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
      seed: <String, Object>{
        TasbeehStore.kCount: 12,
        TasbeehStore.kRounds: 3,
        TasbeehStore.kTarget: 99,
        TasbeehStore.kLabel: 'Evening',
      },
    );
    expect(shown(tester), '12');
    expect(find.text('of 99'), findsOneWidget);
    expect(find.textContaining('Rounds completed: 3'), findsOneWidget);
    await tester.tap(pad);
    await tester.pump();
    // A fresh screen over the same storage sees the new number.
    await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
      reuse: prefs,
    );
    expect(shown(tester), '13');
  });

  testWidgets('a custom target is validated and rounds are counted', (
    tester,
  ) async {
    await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.tap(find.text('Set'));
    await tester.pump();
    expect(find.textContaining('1 to 100000'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '2');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.text('of 2'), findsOneWidget);
    await tester.tap(pad);
    await tester.tap(pad);
    await tester.pump();
    expect(shown(tester), '0');
    expect(find.textContaining('Rounds completed: 1'), findsOneWidget);
  });

  testWidgets('Reset asks first, and Cancel keeps the count', (tester) async {
    await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
    );
    await tester.tap(pad);
    await tester.tap(pad);
    await tester.pump();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Reset the counter?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shown(tester), '2');
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Reset'),
    ));
    await tester.pumpAndSettle();
    expect(shown(tester), '0');
  });

  testWidgets('Undo takes one away', (tester) async {
    await pump(
      tester,
      channel: FakeVolumeCounterChannel(supported: false),
      awake: FakeScreenAwake(),
    );
    await tester.tap(pad);
    await tester.tap(pad);
    await tester.pump();
    await tester.tap(find.text('Undo one'));
    await tester.pump();
    expect(shown(tester), '1');
  });

  testWidgets('off Android: honest note and a keep-screen-on switch', (
    tester,
  ) async {
    final FakeScreenAwake awake = FakeScreenAwake();
    final FakeVolumeCounterChannel ch = FakeVolumeCounterChannel(
      supported: false,
    );
    final SharedPreferences prefs = await pump(
      tester,
      channel: ch,
      awake: awake,
    );
    expect(
      find.textContaining('Screen off counting works on Android'),
      findsOneWidget,
    );
    expect(find.textContaining('volume buttons'), findsNothing);
    await tester.tap(find.text('Keep screen on while counting'));
    await tester.pump();
    await tester.pump();
    expect(awake.calls, <bool>[true]);
    expect(prefs.getBool(TasbeehStore.kAwake), isTrue);
  });

  testWidgets('Android: volume switch starts the service, presses count', (
    tester,
  ) async {
    final FakeVolumeCounterChannel ch = FakeVolumeCounterChannel();
    final SharedPreferences prefs = await pump(
      tester,
      channel: ch,
      awake: FakeScreenAwake(),
    );
    expect(
      find.text('Count with volume buttons (works with screen off)'),
      findsOneWidget,
    );
    expect(ch.running, isFalse, reason: 'off by default');
    await tester.tap(find.text('Count with volume buttons (works with screen off)'));
    await tester.pump();
    await tester.pump();
    expect(ch.running, isTrue);
    expect(prefs.getBool(TasbeehStore.kVolume), isTrue);

    ch.press(1);
    ch.press(1);
    ch.press(1);
    ch.press(-1);
    await tester.pump();
    await tester.pump();
    expect(shown(tester), '2');

    // A tap on screen is pushed to the service so its notification agrees.
    await tester.tap(pad);
    await tester.pump();
    expect(ch.updates.last.count, 3);

    // Turning it off collects what is pending, then stops the service.
    ch.press(1, ping: false);
    await tester.tap(find.text('Count with volume buttons (works with screen off)'));
    await tester.pump();
    await tester.pump();
    expect(ch.running, isFalse);
    expect(shown(tester), '4');
    expect(prefs.getBool(TasbeehStore.kVolume), isFalse);
  });

  testWidgets('Android: presses made while away are added on return', (
    tester,
  ) async {
    final FakeVolumeCounterChannel ch = FakeVolumeCounterChannel();
    ch.pending = 5;
    await pump(
      tester,
      channel: ch,
      awake: FakeScreenAwake(),
      seed: <String, Object>{TasbeehStore.kVolume: true},
    );
    await tester.pump();
    await tester.pump();
    expect(shown(tester), '5');
    expect(ch.running, isTrue);
  });

  testWidgets('Android: a service that cannot start says so', (tester) async {
    final FakeVolumeCounterChannel ch = FakeVolumeCounterChannel(
      startResult: false,
    );
    final SharedPreferences prefs = await pump(
      tester,
      channel: ch,
      awake: FakeScreenAwake(),
    );
    await tester.tap(find.text('Count with volume buttons (works with screen off)'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('could not start'), findsOneWidget);
    expect(prefs.getBool(TasbeehStore.kVolume), isNot(true));
  });
}
