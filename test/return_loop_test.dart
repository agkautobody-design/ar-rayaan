import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/application/return_loop.dart';
import 'package:ar_rayaan/features/habits/presentation/quiet_done.dart';
import 'package:ar_rayaan/features/tracking/application/tracking_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> make(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('the switch and the store', () {
    test('there is no way to record a prayer', () {
      expect(ReturnAct.values.map((ReturnAct a) => a.name).toSet(), <String>{
        'quran',
        'adhkar',
        'lesson',
      });
    });

    test('off by default: nothing is recorded', () async {
      final ProviderContainer c = await make(<String, Object>{});
      expect(c.read(returnLoopEnabledProvider), isFalse);
      expect(c.read(quietDoneWarmLineProvider), isNull);
      expect(
        c.read(sharedPreferencesProvider).getString(TrackingStore.key),
        isNull,
      );
    });

    test('on: records once per day and persists', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
      });
      final TrackingStore d = c.read(trackingStoreProvider.notifier);
      await d.record(TrackingAct.quran, now: DateTime(2026, 10, 20));
      await d.record(TrackingAct.quran, now: DateTime(2026, 10, 20));
      await d.record(TrackingAct.dhikr, now: DateTime(2026, 10, 21));
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], <String>{
        '2026-10-20',
      });
      expect(c.read(trackingStoreProvider)[TrackingAct.dhikr], <String>{
        '2026-10-21',
      });
      expect(
        c.read(sharedPreferencesProvider).getString(TrackingStore.key),
        isNotNull,
      );
    });

    test('switching off erases the days it saved', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
        'ar.return.days': <String>['2026-10-20'],
        TrackingStore.key: '{"quran":["2026-10-20"],"dhikr":[],"lesson":[]}',
      });
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], isNotEmpty);
      await c.read(returnLoopEnabledProvider.notifier).set(false);
      expect(c.read(returnLoopEnabledProvider), isFalse);
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], isEmpty);
      final SharedPreferences p = c.read(sharedPreferencesProvider);
      expect(p.containsKey(TrackingStore.key), isFalse);
      expect(p.containsKey('ar.return.days'), isFalse);
    });

    test('the code switch is on and the stored key stays local', () {
      expect(kReturnLoopEnabled, isTrue);
      expect(kQuietDoneEnabled, isTrue);
    });
  });

  group('quiet completion', () {
    test('wording is plain and carries no ruling, points or sharing', () {
      expect(kQuietDoneText, 'Done. May it be accepted.');
      final String l = kQuietDoneText.toLowerCase();
      for (final String bad in <String>[
        'point',
        'badge',
        'share',
        'reward',
        'score',
        'congrat',
      ]) {
        expect(l.contains(bad), isFalse);
      }
    });

    test(
      'the gate shows a moment once per day, the first lesson once',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final DateTime d1 = DateTime(2026, 10, 21);
        final DateTime d2 = DateTime(2026, 10, 22);
        expect(
          await QuietDoneGate.claim(prefs, 'adhkar:morning', day: d1),
          isTrue,
        );
        expect(
          await QuietDoneGate.claim(prefs, 'adhkar:morning', day: d1),
          isFalse,
        );
        expect(
          await QuietDoneGate.claim(prefs, 'adhkar:evening', day: d1),
          isTrue,
        );
        expect(
          await QuietDoneGate.claim(prefs, 'adhkar:morning', day: d2),
          isTrue,
        );
        expect(await QuietDoneGate.claim(prefs, 'lesson:first'), isTrue);
        expect(await QuietDoneGate.claim(prefs, 'lesson:first'), isFalse);
      },
    );

    Future<void> pumpCard(
      WidgetTester tester, {
      required Map<String, Object> prefs,
      TextDirection dir = TextDirection.ltr,
      double scale = 1,
      Size size = const Size(360, 640),
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final SharedPreferences p = await SharedPreferences.getInstance();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(textDirection: dir, child: child!),
            ),
            home: const Scaffold(body: QuietDoneCard()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('card shows the line and a close button', (tester) async {
      await pumpCard(tester, prefs: <String, Object>{});
      expect(find.text('Done. May it be accepted.'), findsOneWidget);
      expect(find.byKey(const Key('quiet-done-returned')), findsNothing);
      expect(find.byKey(const Key('quiet-done-close')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('card welcomes a first log only when opted in', (tester) async {
      final String t1 = _stamp(DateTime.now());
      await pumpCard(
        tester,
        prefs: <String, Object>{
          'ar.return.enabled': true,
          TrackingStore.key: '{"quran":["$t1"],"dhikr":[],"lesson":[]}',
        },
      );
      expect(
        find.text(
          'Your first one is logged. Welcome, and thank you for being here.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('quiet-done-returned')), findsOneWidget);
    });

    testWidgets('card shows no count or run line, ever', (tester) async {
      final DateTime n = DateTime.now();
      final List<String> many = <String>[
        for (int i = 0; i < 30; i++)
          _stamp(DateTime(n.year, n.month, n.day - i)),
      ];
      await pumpCard(
        tester,
        prefs: <String, Object>{
          'ar.return.enabled': true,
          TrackingStore.key:
              '{"quran":${many.map((String e) => '"$e"').toList()},"dhikr":[],"lesson":[]}',
        },
      );
      expect(find.byKey(const Key('quiet-done-returned')), findsNothing);
      expect(find.textContaining('came back'), findsNothing);
      expect(find.textContaining('days'), findsNothing);
    });

    testWidgets('large text, Elder Mode and RTL do not overflow', (
      tester,
    ) async {
      for (final TextDirection dir in TextDirection.values) {
        await pumpCard(
          tester,
          prefs: <String, Object>{ElderMode.pref: true},
          dir: dir,
          scale: 2.5,
          size: const Size(320, 480),
        );
        expect(find.text('Done. May it be accepted.'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$dir');
        final Size btn = tester.getSize(
          find.byKey(const Key('quiet-done-close')),
        );
        expect(btn.height, greaterThanOrEqualTo(48));
      }
    });
  });
}

String _stamp(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
