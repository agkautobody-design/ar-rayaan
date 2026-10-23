import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/application/return_loop.dart';
import 'package:ar_rayaan/features/habits/presentation/quiet_done.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Set<String> days(List<int> dayOfOct) => <String>{
  for (final int d in dayOfOct) '2026-10-${d.toString().padLeft(2, '0')}',
};

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
  // 2026-10-21 is a Wednesday, so Mon 19 .. Sun 25 is one week.
  final DateTime wed = DateTime(2026, 10, 21);

  group('days returned maths', () {
    test('empty is zero and one day is not mentioned', () {
      expect(ReturnLoop.daysReturned(<String>{}, wed), 0);
      expect(ReturnLoop.daysReturned(days(<int>[21]), wed), 1);
      expect(ReturnLoop.message(1), isNull);
      expect(ReturnLoop.message(0), isNull);
    });

    test('consecutive days count', () {
      expect(ReturnLoop.daysReturned(days(<int>[19, 20, 21]), wed), 3);
      expect(ReturnLoop.message(3), 'You came back 3 days.');
    });

    test('today not done yet still shows yesterday run', () {
      expect(ReturnLoop.daysReturned(days(<int>[19, 20]), wed), 2);
    });

    test('one grace day per week carries the run over', () {
      // 19, (20 missed), 21 : grace used in the week of the 20th.
      expect(ReturnLoop.daysReturned(days(<int>[19, 21]), wed), 2);
      // Yesterday missed, today not yet done: still alive.
      expect(ReturnLoop.daysReturned(days(<int>[18, 19]), wed), 2);
    });

    test('a second missed day in the same week ends the run silently', () {
      // 19 done, 20 missed, 21 done, 22 missed, 23 done: the grace for that
      // week covers 22 only, so 19 is not joined to the run.
      expect(
        ReturnLoop.daysReturned(
          days(<int>[19, 21, 23]),
          DateTime(2026, 10, 23),
        ),
        2,
      );
    });

    test('two missed days in a row lapse to zero without any message', () {
      expect(ReturnLoop.daysReturned(days(<int>[10, 11, 12]), wed), 0);
      expect(ReturnLoop.message(0), isNull);
    });

    test('each calendar week has its own grace day', () {
      // Sat 17 missed (week of Mon 12) and Mon 19 missed (week of Mon 19).
      expect(ReturnLoop.daysReturned(days(<int>[16, 18, 20, 21]), wed), 4);
    });

    test('junk entries are ignored', () {
      expect(
        ReturnLoop.daysReturned(<String>{'junk', '2026-10-21', 'a-b-c'}, wed),
        1,
      );
    });

    test('wording never scolds', () {
      for (int n = 0; n < 40; n++) {
        final String? m = ReturnLoop.message(n);
        if (m == null) continue;
        final String l = m.toLowerCase();
        for (final String bad in <String>[
          'lost',
          'miss',
          'broke',
          'streak',
          'streak',
          'fail',
          'only',
        ]) {
          expect(l.contains(bad), isFalse, reason: m);
        }
      }
    });

    test('there is no way to record a prayer', () {
      expect(ReturnAct.values.map((ReturnAct a) => a.name).toSet(), <String>{
        'quran',
        'adhkar',
        'lesson',
      });
    });
  });

  group('providers', () {
    test('off by default: nothing is recorded', () async {
      final ProviderContainer c = await make(<String, Object>{});
      expect(c.read(returnLoopEnabledProvider), isFalse);
      await c.read(returnDaysProvider.notifier).record(ReturnAct.adhkar);
      expect(c.read(returnDaysProvider), isEmpty);
      expect(
        c.read(sharedPreferencesProvider).getStringList('ar.return.days'),
        isNull,
      );
      expect(c.read(returnMessageProvider), isNull);
    });

    test('on: records once per day and persists', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
      });
      final ReturnDaysController d = c.read(returnDaysProvider.notifier);
      await d.record(ReturnAct.quran, now: DateTime(2026, 10, 20));
      await d.record(ReturnAct.lesson, now: DateTime(2026, 10, 20));
      await d.record(ReturnAct.adhkar, now: DateTime(2026, 10, 21));
      expect(c.read(returnDaysProvider), days(<int>[20, 21]));
      expect(
        c.read(sharedPreferencesProvider).getStringList('ar.return.days'),
        <String>['2026-10-20', '2026-10-21'],
      );
    });

    test('switching off erases the days', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
        'ar.return.days': <String>['2026-10-20'],
      });
      expect(c.read(returnDaysProvider), isNotEmpty);
      await c.read(returnLoopEnabledProvider.notifier).set(false);
      expect(c.read(returnLoopEnabledProvider), isFalse);
      expect(c.read(returnDaysProvider), isEmpty);
      expect(
        c.read(sharedPreferencesProvider).containsKey('ar.return.days'),
        isFalse,
      );
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

    testWidgets('card shows the positive count only when opted in', (
      tester,
    ) async {
      final String t1 = _stamp(DateTime.now());
      final String t0 = _stamp(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      await pumpCard(
        tester,
        prefs: <String, Object>{
          'ar.return.enabled': true,
          'ar.return.days': <String>[t0, t1],
        },
      );
      expect(find.text('You came back 2 days.'), findsOneWidget);
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
