import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/application/return_loop.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_log.dart';
import 'package:ar_rayaan/features/streaks/application/streaks_providers.dart';
import 'package:ar_rayaan/features/streaks/domain/streak_math.dart';
import 'package:ar_rayaan/features/streaks/presentation/streaks_card.dart';
import 'package:ar_rayaan/features/streaks/presentation/streaks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String stamp(DateTime d) => StreakMath.stamp(d);

DateTime daysAgo(int n) {
  final DateTime t = DateTime.now();
  return DateTime(t.year, t.month, t.day - n);
}

Set<String> oct(List<int> d) => <String>{
  for (final int x in d) '2026-10-${x.toString().padLeft(2, '0')}',
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

Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  required Map<String, Object> prefs,
  double scale = 1,
  Size size = const Size(390, 900),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences p = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  // 2026-10-21 is a Wednesday, so Mon 19 .. Sun 25 is one week.
  final DateTime wed = DateTime(2026, 10, 21);

  group('streak maths', () {
    test('agrees with the days-returned maths when nothing is excused', () {
      final List<int> seeds = <int>[1, 2, 3, 4, 5, 6, 7, 8];
      for (final int seed in seeds) {
        int x = seed * 7919;
        int next() {
          x = (x * 1103515245 + 12345) & 0x7fffffff;
          return x;
        }

        for (int t = 0; t < 300; t++) {
          final Set<String> s = <String>{};
          for (int i = 0; i < 30; i++) {
            if (next() % 10 < 6) s.add(stamp(DateTime(2026, 10, 21 - i)));
          }
          expect(
            StreakMath.run(s, wed).days,
            ReturnLoop.daysReturned(s, wed),
            reason: '$s',
          );
        }
      }
    });

    test('empty, one day and junk', () {
      expect(StreakMath.run(<String>{}, wed).days, 0);
      expect(StreakMath.run(oct(<int>[21]), wed).days, 1);
      expect(
        StreakMath.run(<String>{'junk', '2026-10-21', 'a-b-c'}, wed).days,
        1,
      );
      expect(StreakMath.line(1), isNull);
      expect(StreakMath.line(3), '3 days');
    });

    test('one grace day per week carries the run, a second ends it', () {
      final StreakRun r = StreakMath.run(oct(<int>[19, 21]), wed);
      expect(r.days, 2);
      expect(r.bridged, oct(<int>[20]));
      expect(StreakMath.graceAvailable(r, wed), isFalse);
      expect(StreakMath.graceAvailable(StreakMath.run(oct(<int>[19, 20, 21]), wed), wed), isTrue);
      expect(
        StreakMath.run(oct(<int>[19, 21, 23]), DateTime(2026, 10, 23)).days,
        2,
      );
    });

    test('two days off in a row quietly start fresh', () {
      expect(StreakMath.run(oct(<int>[10, 11, 12]), wed).days, 0);
    });

    test('excused days are skipped and never use the grace day', () {
      // 19 and 21 done, 20 excused: a run of two with the grace day unused.
      final StreakRun r = StreakMath.run(
        oct(<int>[19, 21]),
        wed,
        neutral: oct(<int>[20]),
      );
      expect(r.days, 2);
      expect(r.bridged, isEmpty);
      expect(StreakMath.graceAvailable(r, wed), isTrue);
      // Same week: 19, 21, 23 with 20 excused and 22 off: all three join,
      // because 22 is the one grace day.
      final StreakRun r3 = StreakMath.run(
        oct(<int>[19, 21, 23]),
        DateTime(2026, 10, 23),
        neutral: oct(<int>[20]),
      );
      expect(r3.days, 3);
      // Several excused days in a row do not end a run.
      expect(
        StreakMath.run(
          oct(<int>[15, 21]),
          wed,
          neutral: oct(<int>[16, 17, 18, 19, 20]),
        ).days,
        2,
      );
    });

    test('a neutral day that was also done still counts as done', () {
      expect(
        StreakMath.run(oct(<int>[20, 21]), wed, neutral: oct(<int>[20])).days,
        2,
      );
    });
  });

  group('store and gate', () {
    test('records once per day, persists, and clears', () async {
      final ProviderContainer c = await make(<String, Object>{});
      final StreaksStore s = c.read(streaksStoreProvider.notifier);
      await s.record(StreakAct.quran, now: DateTime(2026, 10, 20));
      await s.record(StreakAct.quran, now: DateTime(2026, 10, 20));
      await s.record(StreakAct.dhikr, now: DateTime(2026, 10, 21));
      expect(c.read(streaksStoreProvider)[StreakAct.quran], oct(<int>[20]));
      final String raw = c
          .read(sharedPreferencesProvider)
          .getString(StreaksStore.key)!;
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      expect(j['quran'], <String>['2026-10-20']);
      expect(j['dhikr'], <String>['2026-10-21']);
      await s.clear();
      expect(c.read(streaksStoreProvider)[StreakAct.quran], isEmpty);
      expect(
        c.read(sharedPreferencesProvider).containsKey(StreaksStore.key),
        isFalse,
      );
    });

    test('there is no act for a prayer in the store', () {
      expect(StreakAct.values.map((StreakAct a) => a.name).toSet(), <String>{
        'quran',
        'dhikr',
        'lesson',
      });
    });

    test('switching streaks off erases the stored days', () async {
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
        StreaksStore.key: jsonEncode(<String, List<String>>{
          'quran': <String>['2026-10-20'],
        }),
      });
      expect(c.read(streaksStoreProvider)[StreakAct.quran], isNotEmpty);
      await c.read(returnLoopEnabledProvider.notifier).set(false);
      expect(c.read(streaksStoreProvider)[StreakAct.quran], isEmpty);
    });

    test('a damaged store reads as empty', () async {
      final ProviderContainer c = await make(<String, Object>{
        StreaksStore.key: 'not json',
      });
      expect(c.read(streaksStoreProvider)[StreakAct.quran], isEmpty);
    });

    testWidgets('noteStreak records only while streaks are on', (tester) async {
      Future<ProviderContainer> run(bool on) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          if (on) 'ar.return.enabled': true,
        });
        final SharedPreferences p = await SharedPreferences.getInstance();
        late WidgetRef captured;
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: <Override>[sharedPreferencesProvider.overrideWithValue(p)],
            child: Consumer(
              builder: (BuildContext c, WidgetRef ref, Widget? w) {
                captured = ref;
                return const SizedBox();
              },
            ),
          ),
        );
        await noteStreak(captured, StreakAct.dhikr);
        await noteReturn(captured, ReturnAct.quran);
        return ProviderScope.containerOf(tester.element(find.byType(Consumer)));
      }

      ProviderContainer c = await run(false);
      expect(c.read(streaksStoreProvider)[StreakAct.dhikr], isEmpty);
      expect(c.read(streaksStoreProvider)[StreakAct.quran], isEmpty);
      c = await run(true);
      final String today = stamp(DateTime.now());
      expect(c.read(streaksStoreProvider)[StreakAct.dhikr], <String>{today});
      expect(c.read(streaksStoreProvider)[StreakAct.quran], <String>{today});
    });
  });

  group('prayers come from the log', () {
    test('prayed counts, excused is neutral, missed is neither', () {
      final ({Set<String> done, Set<String> neutral}) p = prayerDays(
        const PrayerLogState(
          days: <String, Map<String, PrayerMark>>{
            '2026-10-19': <String, PrayerMark>{'Fajr': PrayerMark.prayed},
            '2026-10-20': <String, PrayerMark>{
              'Fajr': PrayerMark.excused,
              'Dhuhr': PrayerMark.excused,
            },
            '2026-10-21': <String, PrayerMark>{'Fajr': PrayerMark.missed},
            '2026-10-22': <String, PrayerMark>{
              'Fajr': PrayerMark.prayedLate,
              'Dhuhr': PrayerMark.missed,
            },
            '2026-10-23': <String, PrayerMark>{
              'Fajr': PrayerMark.excused,
              'Dhuhr': PrayerMark.missed,
            },
          },
        ),
      );
      expect(p.done, oct(<int>[19, 22]));
      expect(p.neutral, oct(<int>[20]));
    });

    test('the prayers track is not shareable, the others are', () {
      expect(StreakTrack.prayers.shareable, isFalse);
      expect(streakShareSubject(StreakTrack.prayers), isNull);
      for (final StreakTrack t in StreakTrack.values) {
        if (t == StreakTrack.prayers) continue;
        expect(t.shareable, isTrue);
        expect(streakShareSubject(t), isNotNull);
      }
    });

    test('the view reads the log and the union of acts', () async {
      final String d0 = stamp(daysAgo(0));
      final String d1 = stamp(daysAgo(1));
      final ProviderContainer c = await make(<String, Object>{
        'ar.prayer.log.v1': jsonEncode(<String, Object>{
          'days': <String, Object>{
            d0: <String, String>{'Fajr': 'prayed'},
            d1: <String, String>{'Fajr': 'prayed'},
          },
          'qada': <String>[],
        }),
        StreaksStore.key: jsonEncode(<String, List<String>>{
          'quran': <String>[d1],
          'dhikr': <String>[d0],
          'lesson': <String>[],
        }),
      });
      expect(c.read(streakViewProvider(StreakTrack.prayers)).days, 2);
      expect(c.read(streakViewProvider(StreakTrack.quran)).days, 1);
      expect(c.read(streakViewProvider(StreakTrack.dhikr)).days, 1);
      expect(c.read(streakViewProvider(StreakTrack.returned)).days, 2);
    });
  });

  group('wording is gentle', () {
    test('phrases never scold', () {
      const List<String> bad = <String>[
        'lost',
        'lose',
        'broke',
        'fail',
        'shame',
        'only',
        'behind',
        'don’t',
        'streak',
      ];
      for (final StreakTrack t in StreakTrack.values) {
        for (int n = 0; n < 40; n++) {
          final String l = streakPhrase(t, n).toLowerCase();
          for (final String b in bad) {
            expect(l.contains(b), isFalse, reason: '$t $n: $l');
          }
        }
      }
    });

    test('screen sources carry no loss or guilt words', () {
      final String src = <String>[
        'lib/features/streaks/presentation/streaks_screen.dart',
        'lib/features/streaks/presentation/streaks_card.dart',
      ].map((String p) => File(p).readAsStringSync()).join('\n').toLowerCase();
      for (final String b in <String>[
        'you lost',
        'lost your',
        'broke your',
        'broken',
        'you failed',
        'you missed',
        'don’t break',
        'do not break',
        'shame',
        'behind',
      ]) {
        expect(src.contains(b), isFalse, reason: b);
      }
    });

    test('the route has a page title and the switch is on in code', () {
      expect(RouteTitles.forPath('/streaks'), 'Streaks · Ar-Rayaan');
      expect(kReturnLoopEnabled, isTrue);
    });
  });

  group('screens', () {
    Map<String, Object> seeded({bool prayers = false}) {
      final Map<String, List<String>> acts = <String, List<String>>{
        'quran': <String>[
          stamp(daysAgo(0)),
          stamp(daysAgo(1)),
          stamp(daysAgo(2)),
        ],
        'dhikr': <String>[stamp(daysAgo(0))],
        'lesson': <String>[],
      };
      return <String, Object>{
        'ar.return.enabled': true,
        StreaksStore.key: jsonEncode(acts),
        if (prayers)
          'ar.prayer.log.v1': jsonEncode(<String, Object>{
            'days': <String, Object>{
              stamp(daysAgo(0)): <String, String>{'Fajr': 'prayed'},
              stamp(daysAgo(1)): <String, String>{'Fajr': 'excused'},
              stamp(daysAgo(2)): <String, String>{'Fajr': 'prayed'},
            },
            'qada': <String>[],
          }),
      };
    }

    testWidgets('off: invites, then turns on', (tester) async {
      await pumpApp(
        tester,
        const StreaksScreen(),
        prefs: <String, Object>{},
      );
      expect(find.text('Streaks are off.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('streaks-screen-turn-on')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Streaks are off.'), findsNothing);
      expect(find.byKey(const Key('streak-headline')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on: shows the run, grace line and a calendar', (tester) async {
      await pumpApp(tester, const StreaksScreen(), prefs: seeded());
      // Default track is days returned: 3 days (quran today..2 days ago).
      expect(find.text('Came back 3 days'), findsOneWidget);
      expect(find.byKey(const Key('streak-grace')), findsOneWidget);
      final DateTime today = DateTime.now();
      expect(
        find.byKey(Key('streak-day-${stamp(DateTime(today.year, today.month, today.day))}')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('streak-month')), findsOneWidget);
      await tester.tap(find.byKey(const Key('streak-track-quran')));
      await tester.pump();
      expect(find.text('Came back to the Qur’an for 3 days'), findsOneWidget);
      await tester.tap(find.byKey(const Key('streak-track-dhikr')));
      await tester.pump();
      expect(find.text('Begin whenever you are ready. Today is a good day.'), findsNothing);
      expect(find.text('One day so far. A good start.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('previous month works and next is blocked on this month', (
      tester,
    ) async {
      await pumpApp(tester, const StreaksScreen(), prefs: seeded());
      final Finder month = find.byKey(const Key('streak-month'));
      final String before = tester.widget<Text>(month).data!;
      await tester.tap(find.byKey(const Key('streak-prev-month')));
      await tester.pump();
      expect(tester.widget<Text>(month).data, isNot(before));
      await tester.tap(find.byKey(const Key('streak-next-month')));
      await tester.pump();
      expect(tester.widget<Text>(month).data, before);
      final IconButton next = tester.widget<IconButton>(
        find.byKey(const Key('streak-next-month')),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('prayers: private, excused skipped, never shareable', (
      tester,
    ) async {
      await pumpApp(tester, const StreaksScreen(), prefs: seeded(prayers: true));
      await tester.tap(find.byKey(const Key('streak-track-prayers')));
      await tester.pump();
      // 2 and 0 days ago prayed, yesterday excused and skipped: a run of 2.
      expect(find.text('Logged prayers for 2 days'), findsOneWidget);
      expect(find.byKey(const Key('streak-prayers-note')), findsOneWidget);
      expect(find.byKey(const Key('streak-prayers-private')), findsOneWidget);
      expect(find.byKey(const Key('streak-share')), findsNothing);
    });

    testWidgets('a shareable streak previews before anything is sent', (
      tester,
    ) async {
      await pumpApp(tester, const StreaksScreen(), prefs: seeded());
      await tester.tap(find.byKey(const Key('streak-share')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final String shown = tester
          .widget<SelectableText>(find.byKey(const Key('share-preview-text')))
          .data!;
      expect(shown, contains('I came back to my daily practice for 3 days'));
      expect(shown, contains('https://ar-rayaan.onrender.com'));
      expect(shown, contains('Shared from Ar-Rayaan'));
      expect(find.byKey(const Key('share-preview-note')), findsOneWidget);
    });

    testWidgets('Elder Mode, 2.5x text and a narrow screen do not overflow', (
      tester,
    ) async {
      final Map<String, Object> p = seeded(prayers: true)
        ..[ElderMode.pref] = true;
      await pumpApp(
        tester,
        const StreaksScreen(),
        prefs: p,
        scale: 2.5,
        size: const Size(320, 700),
      );
      expect(find.byKey(const Key('streak-headline')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('streak-track-prayers')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home card: invitation can be turned on or dismissed', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: StreaksCard())),
        prefs: <String, Object>{},
      );
      expect(find.byKey(const Key('streaks-invite')), findsOneWidget);
      await tester.tap(find.byKey(const Key('streaks-not-now')));
      await tester.pump();
      expect(find.byKey(const Key('streaks-invite')), findsNothing);

      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: StreaksCard())),
        prefs: <String, Object>{},
      );
      await tester.tap(find.byKey(const Key('streaks-turn-on')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('streaks-card')), findsOneWidget);
      expect(find.text('Begin today'), findsWidgets);
    });

    testWidgets('Home card lists every streak, never a zero', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: StreaksCard())),
        prefs: seeded(),
      );
      for (final StreakTrack t in StreakTrack.values) {
        expect(find.text(t.label), findsOneWidget);
      }
      expect(find.text('3 days'), findsWidgets);
      expect(find.textContaining('0 days'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
