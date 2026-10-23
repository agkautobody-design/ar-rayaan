import 'package:ar_rayaan/features/tasbeeh/data/tasbeeh_store.dart';
import 'package:ar_rayaan/features/tasbeeh/domain/tasbeeh_counter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('increment', () {
    test('counts up inside a round', () {
      TasbeehState s = const TasbeehState();
      for (int i = 0; i < 5; i++) {
        s = TasbeehLogic.increment(s).state;
      }
      expect(s.count, 5);
      expect(s.rounds, 0);
    });

    test('the target closes the round, reports it, and starts again at 0', () {
      TasbeehState s = const TasbeehState(count: 32);
      final TasbeehStep step = TasbeehLogic.increment(s);
      expect(step.reachedTarget, isTrue);
      expect(step.state.count, 0);
      expect(step.state.rounds, 1);
      s = TasbeehLogic.increment(step.state).state;
      expect(s.count, 1);
      expect(s.total, 34);
    });

    test('a target of 1 completes a round on every press', () {
      TasbeehState s = const TasbeehState(target: 1);
      for (int i = 0; i < 4; i++) {
        final TasbeehStep step = TasbeehLogic.increment(s);
        expect(step.reachedTarget, isTrue);
        s = step.state;
      }
      expect(s.rounds, 4);
      expect(s.count, 0);
    });

    test('rounds stop at the hard limit instead of overflowing', () {
      final TasbeehState s = const TasbeehState(
        count: 32,
        rounds: kTasbeehMaxRounds,
      );
      final TasbeehStep step = TasbeehLogic.increment(s);
      expect(step.state.rounds, kTasbeehMaxRounds);
      expect(step.reachedTarget, isFalse);
    });
  });

  group('undo', () {
    test('takes one away', () {
      expect(TasbeehLogic.undo(const TasbeehState(count: 3)).count, 2);
    });

    test('steps back across a round boundary', () {
      final TasbeehState s = TasbeehLogic.undo(const TasbeehState(rounds: 2));
      expect(s.rounds, 1);
      expect(s.count, 32);
    });

    test('never goes below zero', () {
      const TasbeehState zero = TasbeehState();
      expect(TasbeehLogic.undo(zero), zero);
    });

    test('undo exactly reverses an increment, also at the boundary', () {
      for (final int start in <int>[0, 10, 32]) {
        final TasbeehState s = TasbeehState(count: start);
        expect(TasbeehLogic.undo(TasbeehLogic.increment(s).state), s);
      }
    });
  });

  group('applyDelta (presses made with the screen off)', () {
    test('folds a positive and a negative net count', () {
      const TasbeehState s = TasbeehState(count: 30);
      final TasbeehState up = TasbeehLogic.applyDelta(s, 5);
      expect(up.rounds, 1);
      expect(up.count, 2);
      expect(TasbeehLogic.applyDelta(up, -5), s);
    });

    test('zero changes nothing and a big negative stops at zero', () {
      const TasbeehState s = TasbeehState(count: 4);
      expect(TasbeehLogic.applyDelta(s, 0), s);
      final TasbeehState z = TasbeehLogic.applyDelta(s, -500);
      expect(z.count, 0);
      expect(z.rounds, 0);
    });
  });

  group('target', () {
    test('parseTarget accepts 1..100000 and nothing else', () {
      expect(TasbeehLogic.parseTarget('1'), 1);
      expect(TasbeehLogic.parseTarget(' 250 '), 250);
      expect(TasbeehLogic.parseTarget('100000'), 100000);
      expect(TasbeehLogic.parseTarget('100001'), isNull);
      expect(TasbeehLogic.parseTarget('0'), isNull);
      expect(TasbeehLogic.parseTarget('-5'), isNull);
      expect(TasbeehLogic.parseTarget('12.5'), isNull);
      expect(TasbeehLogic.parseTarget('abc'), isNull);
      expect(TasbeehLogic.parseTarget(''), isNull);
      expect(TasbeehLogic.parseTarget('99999999999999999999'), isNull);
    });

    test('setTarget clamps and keeps the position inside the new round', () {
      const TasbeehState s = TasbeehState(count: 40, target: 99, rounds: 3);
      final TasbeehState t = TasbeehLogic.setTarget(s, 33);
      expect(t.target, 33);
      expect(t.count, 7);
      expect(t.rounds, 3);
      expect(TasbeehLogic.setTarget(s, 0).target, 1);
      expect(TasbeehLogic.setTarget(s, 9999999).target, kTasbeehMaxTarget);
    });
  });

  test('reset keeps the target and the label', () {
    final TasbeehState s = TasbeehLogic.reset(
      const TasbeehState(count: 9, rounds: 4, target: 99, label: 'x'),
    );
    expect(s.count, 0);
    expect(s.rounds, 0);
    expect(s.target, 99);
    expect(s.label, 'x');
  });

  test('sanitize pulls bad stored values into range', () {
    final TasbeehState s = TasbeehLogic.sanitize(
      TasbeehState(
        count: 500,
        rounds: -3,
        target: 0,
        label: 'a' * 100,
      ),
    );
    expect(s.target, 1);
    expect(s.count, 0);
    expect(s.rounds, 0);
    expect(s.label.length, kTasbeehMaxLabel);
  });

  group('persistence', () {
    test('the count, rounds, target, label and switches survive a reload',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final TasbeehStore store = TasbeehStore(prefs);
      await store.saveCounter(
        const TasbeehState(count: 7, rounds: 2, target: 99, label: 'Evening'),
      );
      await store.saveSettings(
        const TasbeehSettings(volumeMode: true, keepAwake: true),
      );

      final TasbeehStore again = TasbeehStore(prefs);
      final TasbeehState s = again.loadCounter();
      expect(s.count, 7);
      expect(s.rounds, 2);
      expect(s.target, 99);
      expect(s.label, 'Evening');
      expect(again.loadSettings().volumeMode, isTrue);
      expect(again.loadSettings().keepAwake, isTrue);
    });

    test('an empty store gives 0 of 33 with both switches off', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TasbeehStore store = TasbeehStore(
        await SharedPreferences.getInstance(),
      );
      expect(store.loadCounter(), const TasbeehState());
      expect(store.loadSettings().volumeMode, isFalse);
      expect(store.loadSettings().keepAwake, isFalse);
    });

    test('damaged stored numbers are clamped on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        TasbeehStore.kTarget: 33,
        TasbeehStore.kCount: 9000,
        TasbeehStore.kRounds: -1,
      });
      final TasbeehStore store = TasbeehStore(
        await SharedPreferences.getInstance(),
      );
      final TasbeehState s = store.loadCounter();
      expect(s.count, 32);
      expect(s.rounds, 0);
    });
  });
}
