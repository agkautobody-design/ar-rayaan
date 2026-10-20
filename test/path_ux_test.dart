import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/academy/domain/path_ux.dart';
import 'package:ar_rayaan/features/academy/presentation/widgets/path_ux_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ActivityLog', () {
    test('dayKey is zero padded local date', () {
      expect(ActivityLog.dayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('add dedupes, sorts and survives garbage', () {
      String? raw = ActivityLog.add(null, DateTime(2026, 10, 20));
      raw = ActivityLog.add(raw, DateTime(2026, 10, 19));
      raw = ActivityLog.add(raw, DateTime(2026, 10, 20, 23));
      expect(ActivityLog.decode(raw), <String>{'2026-10-19', '2026-10-20'});
      expect(ActivityLog.decode('not json'), isEmpty);
      expect(ActivityLog.decode(null), isEmpty);
    });

    test('the log is trimmed to maxDays, oldest first', () {
      String? raw;
      final DateTime start = DateTime(2026, 1, 1);
      for (int i = 0; i < ActivityLog.maxDays + 10; i++) {
        raw = ActivityLog.add(raw, DateTime(start.year, start.month, start.day + i));
      }
      final Set<String> days = ActivityLog.decode(raw);
      expect(days.length, ActivityLog.maxDays);
      expect(days.contains('2026-01-01'), isFalse);
    });
  });

  group('WeeklyRhythm', () {
    final DateTime today = DateTime(2026, 10, 20); // a Tuesday

    test('seven days, oldest first, ending today', () {
      final WeeklyRhythm r = WeeklyRhythm.of(<String>{}, today);
      expect(r.days.length, 7);
      expect(r.days.first, '2026-10-14');
      expect(r.days.last, '2026-10-20');
      expect(r.count, 0);
    });

    test('counts only the last seven days, across a month boundary', () {
      final WeeklyRhythm r = WeeklyRhythm.of(
          <String>{'2026-10-20', '2026-10-18', '2026-10-13'}, today);
      expect(r.count, 2);
      final WeeklyRhythm m = WeeklyRhythm.of(
          <String>{'2026-09-30'}, DateTime(2026, 10, 2));
      expect(m.days.first, '2026-09-26');
      expect(m.count, 1);
    });

    test('messages are gentle and never mention losing anything', () {
      final List<String> all = <String>[
        for (final int n in <int>[0, 1, 3, 7])
          WeeklyRhythm(
            days: List<String>.filled(7, ''),
            active: <bool>[for (int i = 0; i < 7; i++) i < n],
          ).message,
      ];
      for (final String m in all) {
        expect(m.toLowerCase().contains('lost'), isFalse);
        expect(m.toLowerCase().contains('streak'), isFalse);
        expect(m.toLowerCase().contains('missed'), isFalse);
      }
      expect(all[2], contains('3 of the last 7'));
    });
  });

  group('PlacementQuiz', () {
    test('every answer index is valid, two questions per unit', () {
      for (final PlacementQuestion q in PlacementQuiz.questions) {
        expect(q.answer, inInclusiveRange(0, q.options.length - 1));
        expect(q.options.toSet().length, q.options.length);
      }
      for (int level = 1; level <= 7; level++) {
        expect(
            PlacementQuiz.questions
                .where((PlacementQuestion q) => q.level == level)
                .length,
            2);
      }
    });

    test('recommends the first unit not fully answered', () {
      final int n = PlacementQuiz.questions.length;
      expect(PlacementQuiz.recommend(List<bool>.filled(n, true)), isNull);
      expect(PlacementQuiz.recommend(List<bool>.filled(n, false)),
          'letters-01');
      final List<bool> c = List<bool>.filled(n, true);
      c[5] = false; // a unit 3 question
      expect(PlacementQuiz.recommend(c), 'letters-15');
      final List<bool> v = List<bool>.filled(n, true);
      v[8] = false; // unit 5
      expect(PlacementQuiz.recommend(v), 'letters-29');
      expect(PlacementQuiz.recommend(<bool>[]), 'letters-01');
    });
  });

  group('widgets', () {
    Future<void> pump(WidgetTester t, Widget w,
        {Map<String, Object>? prefs}) async {
      SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await t.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        child: MaterialApp(home: Scaffold(body: Center(child: w))),
      ));
    }

    testWidgets('rhythm card marks the days the learner was active',
        (WidgetTester t) async {
      await pump(
        t,
        WeeklyRhythmCard(now: DateTime(2026, 10, 20)),
        prefs: <String, Object>{
          ActivityLog.prefKey: '["2026-10-19","2026-10-20"]',
        },
      );
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.textContaining('2 of the last 7'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('rhythm-2026-10-20')),
          findsOneWidget);
    });

    testWidgets('placement quiz: all correct points to the Word Decks',
        (WidgetTester t) async {
      await pump(t, Builder(builder: (BuildContext c) {
        return ElevatedButton(
            onPressed: () => showPlacementQuiz(c), child: const Text('open'));
      }));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      for (final PlacementQuestion q in PlacementQuiz.questions) {
        await t.tap(find.byKey(ValueKey<String>('placement-opt-${q.answer}')));
        await t.pumpAndSettle();
      }
      expect(find.textContaining('Word Decks'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('placement-go')), findsNothing);
    });

    testWidgets('placement quiz: a wrong answer suggests a lesson',
        (WidgetTester t) async {
      await pump(t, Builder(builder: (BuildContext c) {
        return ElevatedButton(
            onPressed: () => showPlacementQuiz(c), child: const Text('open'));
      }));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      for (final PlacementQuestion q in PlacementQuiz.questions) {
        final int pick = (q.answer + 1) % q.options.length;
        await t.tap(find.byKey(ValueKey<String>('placement-opt-$pick')));
        await t.pumpAndSettle();
      }
      expect(find.textContaining('lesson 1'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('placement-go')),
          findsOneWidget);
    });
  });
}
