import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/elder/application/elder_mode.dart';
import 'package:ar_rayaan/features/habits/application/return_loop.dart';
import 'package:ar_rayaan/features/journey/domain/journey_progress.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_log.dart';
import 'package:ar_rayaan/features/tracking/application/tracking_providers.dart';
import 'package:ar_rayaan/features/tracking/domain/encouragement.dart';
import 'package:ar_rayaan/features/tracking/domain/tracking_math.dart';
import 'package:ar_rayaan/features/tracking/presentation/tracking_card.dart';
import 'package:ar_rayaan/features/tracking/presentation/tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String stamp(DateTime d) => TrackingMath.stamp(d);

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
  Size size = const Size(390, 3000),
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

/// Every piece of text a screen currently shows, lower-cased.
String shownText(WidgetTester tester) => <String>[
  for (final Text t in tester.widgetList<Text>(find.byType(Text)))
    if (t.data != null) t.data!,
  for (final RichText r in tester.widgetList<RichText>(find.byType(RichText)))
    r.text.toPlainText(),
].join('\n').toLowerCase();

const List<String> kBannedWords = <String>[
  'streak',
  'missed',
  'you missed',
  'you failed',
  'broke',
  'broken',
  'lost',
  'lose your',
  'shame',
  'behind',
  'leaderboard',
  'points',
];

String store(Map<String, List<String>> acts) => jsonEncode(<String, List<String>>{
  'quran': <String>[],
  'dhikr': <String>[],
  'lesson': <String>[],
  ...acts,
});

void main() {
  // 2026-10-21 is a Wednesday, so Mon 19 .. Sun 25 is one week.
  final DateTime wed = DateTime(2026, 10, 21);

  group('totals add up what is inside the period', () {
    test('week, month and all time', () {
      final Set<String> d = oct(<int>[1, 2, 5, 19, 21]);
      expect(TrackingMath.daysIn(d, LogPeriod.week, wed), 2);
      expect(TrackingMath.daysIn(d, LogPeriod.month, wed), 5);
      expect(TrackingMath.daysIn(d, LogPeriod.allTime, wed), 5);
    });

    test('a week starts on Monday and is not a run', () {
      expect(stamp(TrackingMath.weekStart(wed)), '2026-10-19');
      expect(
        TrackingMath.daysIn(oct(<int>[18]), LogPeriod.week, wed),
        0,
        reason: 'Sunday belongs to the week before',
      );
    });

    test('counts do not reset after a gap', () {
      final Set<String> before = oct(<int>[1, 2, 3, 4, 5]);
      // Nothing for 16 days, then one day.
      final Set<String> after = <String>{...before, ...oct(<int>[21])};
      expect(TrackingMath.daysIn(before, LogPeriod.allTime, wed), 5);
      expect(TrackingMath.daysIn(after, LogPeriod.allTime, wed), 6);
      expect(TrackingMath.daysIn(after, LogPeriod.month, wed), 6);
      // The same days in a different order, or with a long gap in the middle,
      // add up to the same totals: there is no run length anywhere.
      final Set<String> spaced = oct(<int>[1, 8, 15, 21]);
      expect(TrackingMath.daysIn(spaced, LogPeriod.allTime, wed), 4);
    });

    test('junk and future days are ignored', () {
      expect(
        TrackingMath.daysIn(
          <String>{'junk', '2026-10-21', 'a-b-c', '2030-01-01'},
          LogPeriod.allTime,
          wed,
        ),
        1,
      );
    });

    test('last logged and first logged', () {
      expect(
        stamp(TrackingMath.lastLogged(oct(<int>[3, 9, 25]), wed)!),
        '2026-10-09',
      );
      expect(
        stamp(TrackingMath.firstLogged(oct(<int>[3, 9, 25]), wed)!),
        '2026-10-03',
      );
      expect(TrackingMath.lastLogged(<String>{}, wed), isNull);
    });

    test('the view adds up and has no run length', () {
      final TrackingView v = TrackingView(
        track: TrackingTrack.quran,
        perDay: <String, int>{
          '2026-10-02': 1,
          '2026-10-19': 1,
          '2026-10-21': 1,
        },
        today: wed,
      );
      expect(v.total(LogPeriod.week), 2);
      expect(v.total(LogPeriod.month), 3);
      expect(v.total(LogPeriod.allTime), 3);
      expect(stamp(v.lastLogged!), '2026-10-21');
      expect(v.daysInMonth(wed), 3);
    });
  });

  group('encouragement', () {
    Encouragement e(Set<String> days) => EncouragementMath.forDays(days, wed);

    test('nobody logged yet: an open door', () {
      final Encouragement r = e(<String>{});
      expect(r.kind, EncouragementKind.startAnyTime);
      expect(r.text, contains('Start whenever you like'));
      expect(r.nudge, isNull);
    });

    test('the first log is celebrated', () {
      final Encouragement r = e(oct(<int>[21]));
      expect(r.kind, EncouragementKind.firstLog);
      expect(r.text, contains('Welcome'));
    });

    test('the first week is welcomed', () {
      final Encouragement r = e(oct(<int>[17, 21]));
      expect(r.kind, EncouragementKind.firstWeek);
      expect(r.text, contains('Glad you are here'));
    });

    test('a return after a gap gets the welcome-back line', () {
      // Logged until 2 Oct, then back today.
      final Encouragement r = e(oct(<int>[1, 2, 21]));
      expect(r.kind, EncouragementKind.welcomeBack);
      expect(r.text, 'Welcome back, glad you’re here.');
      expect(r.nudge, isNull, reason: 'they just logged: no nudge');
    });

    test('opening the app after a long gap is also a welcome', () {
      final Encouragement r = e(oct(<int>[1, 2, 3]));
      expect(r.kind, EncouragementKind.welcomeBack);
      expect(r.text, 'Welcome back, glad you’re here.');
      expect(r.nudge, 'A small step today?');
    });

    test('a short pause gets only the optional small-step nudge', () {
      final Encouragement r = e(oct(<int>[1, 2, 3, 4, 17]));
      expect(r.kind, EncouragementKind.quiet);
      expect(r.text, isNull);
      expect(r.nudge, 'A small step today?');
    });

    test('someone logging every few days hears nothing special', () {
      final Encouragement r = e(oct(<int>[1, 2, 3, 4, 17, 19, 20]));
      expect(r.kind, EncouragementKind.none);
      expect(r.text, isNull);
      expect(r.nudge, isNull);
    });

    test('no line ever scolds, compares or counts a run', () {
      final List<String> all = <String>[
        EncouragementMath.startText,
        EncouragementMath.firstLogText,
        EncouragementMath.firstWeekText,
        EncouragementMath.welcomeBackText,
        EncouragementMath.nudgeText,
        for (final TrackingTrack t in TrackingTrack.values)
          for (final LogPeriod p in LogPeriod.values)
            for (int n = 0; n < 12; n++) totalSentence(t, p, n),
      ];
      for (final String line in all) {
        final String l = line.toLowerCase();
        for (final String b in kBannedWords) {
          expect(l.contains(b), isFalse, reason: '"$line" has "$b"');
        }
        for (final String b in <String>[
          'in a row',
          'consecutive',
          'chain',
          'reward',
          'rank',
          'best',
          'others',
        ]) {
          expect(l.contains(b), isFalse, reason: '"$line" has "$b"');
        }
      }
    });
  });

  group('store and gate', () {
    test('records once per day, persists, and clears', () async {
      final ProviderContainer c = await make(<String, Object>{});
      final TrackingStore s = c.read(trackingStoreProvider.notifier);
      await s.record(TrackingAct.quran, now: DateTime(2026, 10, 20));
      await s.record(TrackingAct.quran, now: DateTime(2026, 10, 20));
      await s.record(TrackingAct.lesson, now: DateTime(2026, 10, 21));
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], <String>{
        '2026-10-20',
      });
      expect(c.read(trackingStoreProvider)[TrackingAct.lesson], <String>{
        '2026-10-21',
      });
      await s.clear();
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], isEmpty);
      expect(
        c.read(sharedPreferencesProvider).containsKey(TrackingStore.key),
        isFalse,
      );
    });

    test('days saved by the earlier release are kept, under the new key', () async {
      final ProviderContainer c = await make(<String, Object>{
        TrackingStore.legacyKey: store(<String, List<String>>{
          'quran': <String>['2026-10-01'],
        }),
      });
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], <String>{
        '2026-10-01',
      });
      await c
          .read(trackingStoreProvider.notifier)
          .record(TrackingAct.dhikr, now: DateTime(2026, 10, 2));
      final SharedPreferences p = c.read(sharedPreferencesProvider);
      expect(p.containsKey(TrackingStore.key), isTrue);
      expect(p.containsKey(TrackingStore.legacyKey), isFalse);
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], <String>{
        '2026-10-01',
      });
    });

    test('there is no act for a prayer in the store', () {
      expect(
        TrackingAct.values.map((TrackingAct a) => a.name).toSet(),
        <String>{'quran', 'dhikr', 'lesson'},
      );
    });

    test('a damaged store reads as empty', () async {
      final ProviderContainer c = await make(<String, Object>{
        TrackingStore.key: '{not json',
      });
      expect(c.read(trackingStoreProvider)[TrackingAct.quran], isEmpty);
    });

    test('old days are kept for years so totals never shrink', () {
      expect(TrackingStore.keepDays, greaterThanOrEqualTo(3650));
      expect(PrayerLogController.keepDays, greaterThanOrEqualTo(3650));
    });

    testWidgets('noteTracking records only while the log is on', (
      tester,
    ) async {
      late WidgetRef captured;
      Future<void> run(Map<String, Object> prefs) async {
        await pumpApp(
          tester,
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              captured = ref;
              return const SizedBox();
            },
          ),
          prefs: prefs,
        );
        await noteTracking(captured, TrackingAct.dhikr);
      }

      await run(<String, Object>{});
      expect(
        captured.read(trackingStoreProvider)[TrackingAct.dhikr],
        isEmpty,
      );
      await run(<String, Object>{'ar.return.enabled': true});
      expect(
        captured.read(trackingStoreProvider)[TrackingAct.dhikr],
        <String>{stamp(DateTime.now())},
      );
    });
  });

  group('prayers come from the log', () {
    PrayerLogState log() => PrayerLogState(
      days: <String, Map<String, PrayerMark>>{
        '2026-10-20': <String, PrayerMark>{
          'Fajr': PrayerMark.prayed,
          'Dhuhr': PrayerMark.prayedLate,
          'Asr': PrayerMark.missed,
        },
        '2026-10-19': <String, PrayerMark>{'Fajr': PrayerMark.excused},
        '2026-10-18': <String, PrayerMark>{'Isha': PrayerMark.missed},
      },
    );

    test('only prayed marks are counted; excused and not prayed add nothing', () {
      final Map<String, int> c = prayerCounts(log());
      expect(c, <String, int>{'2026-10-20': 2});
    });

    test('"you have prayed X times this week"', () {
      final TrackingView v = TrackingView(
        track: TrackingTrack.prayers,
        perDay: prayerCounts(log()),
        today: wed,
      );
      expect(v.total(LogPeriod.week), 2);
      expect(
        totalSentence(TrackingTrack.prayers, LogPeriod.week, 2),
        'You have prayed 2 times this week.',
      );
      expect(
        totalSentence(TrackingTrack.prayers, LogPeriod.week, 1),
        'You have prayed once this week.',
      );
    });

    test('no track is offered for sharing', () {
      for (final TrackingTrack t in TrackingTrack.values) {
        expect(t.shareable, isFalse);
      }
    });

    test('the view reads the log, fasting and the union of acts', () async {
      final String t0 = stamp(daysAgo(0));
      final String t1 = stamp(daysAgo(1));
      final ProviderContainer c = await make(<String, Object>{
        'ar.return.enabled': true,
        TrackingStore.key: store(<String, List<String>>{
          'quran': <String>[t0],
        }),
        'ar.habits.fasting': <String>[t1],
        'ar.prayer.log.v1': jsonEncode(<String, Object>{
          'days': <String, Object>{
            t1: <String, String>{'Fajr': 'prayed'},
          },
          'qada': <String>[],
        }),
      });
      expect(
        c.read(trackingViewProvider(TrackingTrack.quran)).days,
        <String>{t0},
      );
      expect(
        c.read(trackingViewProvider(TrackingTrack.fasting)).days,
        <String>{t1},
      );
      expect(
        c.read(trackingViewProvider(TrackingTrack.prayers)).days,
        <String>{t1},
      );
      expect(
        c.read(trackingViewProvider(TrackingTrack.all)).days,
        <String>{t0, t1},
      );
    });
  });

  group('journey ring', () {
    test('keeps its weights and depends on no run', () {
      final List<double> w = ringParts(
        const RingInputs(),
      ).map((RingPart p) => p.weight).toList();
      expect(w, <double>[0.45, 0.10, 0.15, 0.15, 0.15]);
      expect(ringValue(const RingInputs()), 0);
      expect(
        ringValue(const RingInputs(lessonsDone: 1)),
        closeTo(0.15, 1e-9),
      );
    });

    test('an empty ring is an invitation, not a failure', () {
      final String l = kRingExplanation.toLowerCase();
      expect(l, contains('start whenever you like'));
      expect(kRingEmptyLine, 'Start whenever you like.');
      for (final String b in kBannedWords) {
        expect(l.contains(b), isFalse, reason: b);
      }
      expect(daysThisWeekText(0), contains('start whenever you like'));
    });
  });

  group('wording and routes', () {
    test('the route has a page title and the switch is on in code', () {
      expect(RouteTitles.forPath('/my-log'), 'My log · Ar-Rayaan');
      expect(kReturnLoopEnabled, isTrue);
    });

    test('screen sources carry no streak, loss or guilt words', () {
      final String src = <String>[
        'lib/features/tracking/presentation/tracking_screen.dart',
        'lib/features/tracking/presentation/tracking_card.dart',
        'lib/features/tracking/presentation/gentle_nudge.dart',
        'lib/features/tracking/domain/encouragement.dart',
      ]
          .map((String p) => File(p).readAsStringSync())
          .join('\n')
          .toLowerCase()
          // The one stored key an earlier release used; never shown.
          .replaceAll('ar.streaks.invite.dismissed', '');
      for (final String b in <String>[
        'streak',
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
        'grace day',
        'forgiven',
      ]) {
        expect(src.contains(b), isFalse, reason: b);
      }
    });

    test('no streak feature, screen or route is left in the app', () {
      expect(Directory('lib/features/streaks').existsSync(), isFalse);
      final String router = File('lib/app/router.dart').readAsStringSync();
      expect(router.contains("'/streaks'"), isFalse);
    });
  });

  group('screens', () {
    Map<String, Object> seeded() => <String, Object>{
      'ar.return.enabled': true,
      TrackingStore.key: store(<String, List<String>>{
        'quran': <String>[
          stamp(daysAgo(0)),
          stamp(daysAgo(1)),
          stamp(daysAgo(2)),
        ],
        'dhikr': <String>[stamp(daysAgo(0))],
      }),
      'ar.prayer.log.v1': jsonEncode(<String, Object>{
        'days': <String, Object>{
          stamp(daysAgo(0)): <String, String>{
            'Fajr': 'prayed',
            'Dhuhr': 'prayedLate',
          },
          stamp(daysAgo(1)): <String, String>{'Fajr': 'excused'},
          stamp(daysAgo(2)): <String, String>{'Fajr': 'prayed'},
        },
        'qada': <String>[],
      }),
    };

    /// Logged long ago, nothing for twelve days.
    Map<String, Object> awayForAWhile() => <String, Object>{
      'ar.return.enabled': true,
      TrackingStore.key: store(<String, List<String>>{
        'quran': <String>[
          stamp(daysAgo(40)),
          stamp(daysAgo(39)),
          stamp(daysAgo(14)),
          stamp(daysAgo(13)),
          stamp(daysAgo(12)),
        ],
      }),
    };

    testWidgets('prayers: a plain total, nothing to share', (tester) async {
      await pumpApp(tester, const TrackingScreen(), prefs: seeded());
      await tester.tap(find.byKey(const Key('log-track-prayers')));
      await tester.pump();
      expect(find.byKey(const Key('log-total-all')), findsOneWidget);
      final String t = shownText(tester);
      expect(t.contains('prayers you marked as prayed'), isTrue);
      expect(find.textContaining('Share'), findsNothing);
      expect(find.textContaining('share'), findsNothing);
    });

    testWidgets('off: invites, then turns on', (tester) async {
      await pumpApp(tester, const TrackingScreen(), prefs: <String, Object>{});
      await tester.tap(find.byKey(const Key('log-track-quran')));
      await tester.pump();
      expect(find.text('The private log is off.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('log-screen-turn-on')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('The private log is off.'), findsNothing);
      expect(find.byKey(const Key('log-total-week')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on: totals, last logged date and a calendar', (tester) async {
      await pumpApp(tester, const TrackingScreen(), prefs: seeded());
      expect(find.byKey(const Key('log-headline')), findsOneWidget);
      expect(find.byKey(const Key('log-total-week')), findsOneWidget);
      expect(find.byKey(const Key('log-total-month')), findsOneWidget);
      expect(find.byKey(const Key('log-total-all')), findsOneWidget);
      expect(find.textContaining('Last logged:'), findsOneWidget);
      expect(
        find.byKey(Key('log-day-${stamp(daysAgo(0))}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('previous month works and next is blocked on this month', (
      tester,
    ) async {
      await pumpApp(tester, const TrackingScreen(), prefs: seeded());
      final Finder month = find.byKey(const Key('log-month'));
      final String before = tester.widget<Text>(month).data!;
      await tester.tap(find.byKey(const Key('log-prev-month')));
      await tester.pump();
      expect(tester.widget<Text>(month).data, isNot(before));
      await tester.tap(find.byKey(const Key('log-next-month')));
      await tester.pump();
      expect(tester.widget<Text>(month).data, before);
      final IconButton next = tester.widget<IconButton>(
        find.byKey(const Key('log-next-month')),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('no screen text says streak, missed or broke', (tester) async {
      for (final Map<String, Object> prefs in <Map<String, Object>>[
        <String, Object>{},
        seeded(),
        awayForAWhile(),
      ]) {
        await pumpApp(tester, const TrackingScreen(), prefs: prefs);
        for (final TrackingTrack t in TrackingTrack.values) {
          await tester.tap(find.byKey(Key('log-track-${t.name}')));
          await tester.pump();
          final String text = shownText(tester);
          for (final String b in kBannedWords) {
            expect(text.contains(b), isFalse, reason: '${t.name}: "$b"');
          }
        }
      }
    });

    testWidgets('counts do not reset after a gap', (tester) async {
      await pumpApp(tester, const TrackingScreen(), prefs: awayForAWhile());
      await tester.tap(find.byKey(const Key('log-track-quran')));
      await tester.pump();
      Text tile(String key) => tester.widget<Text>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(Text),
        ).first,
      );
      expect(tile('log-total-all').data, '5');
      expect(tile('log-total-week').data, isNot('5'));
      final String text = shownText(tester);
      expect(text.contains('broke'), isFalse);
      expect(text.contains('start over'), isFalse);
    });

    testWidgets('a first log is celebrated', (tester) async {
      await pumpApp(
        tester,
        const TrackingScreen(),
        prefs: <String, Object>{
          'ar.return.enabled': true,
          TrackingStore.key: store(<String, List<String>>{
            'dhikr': <String>[stamp(daysAgo(0))],
          }),
        },
      );
      expect(
        find.text(
          'Your first one is logged. Welcome, and thank you for being here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('someone back after a gap is welcomed and never shamed', (
      tester,
    ) async {
      await pumpApp(tester, const TrackingScreen(), prefs: awayForAWhile());
      expect(
        find.text('Welcome back, glad you’re here.'),
        findsOneWidget,
      );
      expect(find.text('A small step today?'), findsOneWidget);
      final String text = shownText(tester);
      for (final String b in <String>[
        ...kBannedWords,
        'you haven',
        'days since',
        'days ago',
        'no activity',
        'inactive',
      ]) {
        expect(text.contains(b), isFalse, reason: b);
      }
      // The nudge can always be dismissed, and stays away for the day.
      await tester.tap(find.byKey(const Key('log-nudge-dismiss')));
      await tester.pump();
      expect(find.text('A small step today?'), findsNothing);
      expect(find.text('Welcome back, glad you’re here.'), findsOneWidget);
    });

    testWidgets('an empty week reads as an open invitation', (tester) async {
      await pumpApp(tester, const TrackingScreen(), prefs: awayForAWhile());
      await tester.tap(find.byKey(const Key('log-track-fasting')));
      await tester.pump();
      expect(find.textContaining('Nothing logged here yet.'), findsOneWidget);
      expect(
        find.textContaining('Start whenever you like'),
        findsWidgets,
      );
    });

    testWidgets('Elder Mode, 2.5x text and a narrow screen do not overflow', (
      tester,
    ) async {
      final Map<String, Object> p = seeded()..[ElderMode.pref] = true;
      await pumpApp(
        tester,
        const TrackingScreen(),
        prefs: p,
        scale: 2.5,
        size: const Size(320, 4000),
      );
      expect(find.byKey(const Key('log-headline')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('log-track-prayers')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home card: invitation can be turned on or dismissed', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TrackingCard())),
        prefs: <String, Object>{},
      );
      expect(find.byKey(const Key('my-log-invite')), findsOneWidget);
      expect(shownText(tester).contains('streak'), isFalse);
      await tester.tap(find.byKey(const Key('my-log-not-now')));
      await tester.pump();
      expect(find.byKey(const Key('my-log-invite')), findsNothing);

      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TrackingCard())),
        prefs: <String, Object>{},
      );
      await tester.tap(find.byKey(const Key('my-log-turn-on')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('my-log-card')), findsOneWidget);
      expect(find.textContaining('Start whenever you like'), findsWidgets);
    });

    testWidgets('Home card lists what was logged and never a zero', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(body: SingleChildScrollView(child: TrackingCard())),
        prefs: seeded(),
      );
      expect(find.text('Qur’an reading'), findsOneWidget);
      expect(find.text('Prayers'), findsOneWidget);
      expect(find.text('Fasting'), findsNothing);
      expect(find.textContaining('this week'), findsWidgets);
      expect(find.textContaining('0 days'), findsNothing);
      expect(find.textContaining('0 prayers'), findsNothing);
      final String text = shownText(tester);
      for (final String b in kBannedWords) {
        expect(text.contains(b), isFalse, reason: b);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
