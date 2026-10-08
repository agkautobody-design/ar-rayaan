import 'package:ar_rayaan/features/academy/domain/dhikr_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DhikrSet s33 = DhikrSet(id: 't', arabic: 'x', meaning: 'y', target: 33);

  test('tap increments and tracks progress', () {
    var s = DhikrSessionEngine.reset(s33);
    expect(s.count, 0);
    expect(s.progress, 0);
    s = DhikrSessionEngine.tap(s);
    expect(s.count, 1);
    expect(s.progress, closeTo(1 / 33, 0.001));
  });

  test('milestone pause at 33 on a longer set: resume does not double-count', () {
    // A 33-target set COMPLETES at 33 (completion beats milestone) — so
    // milestone behavior is exercised on a 100-target set instead.
    var s = DhikrSessionEngine.reset(const DhikrSet(
        id: 'big', arabic: 'x', meaning: 'y', target: 100));
    for (var i = 0; i < 33; i++) {
      s = DhikrSessionEngine.tap(s);
    }
    expect(s.count, 33);
    expect(s.phase, DhikrPhase.milestonePause);
    s = DhikrSessionEngine.tap(s); // resume
    expect(s.phase, DhikrPhase.counting);
    expect(s.count, 33, reason: 'resume does not count');
    s = DhikrSessionEngine.tap(s); // 34
    expect(s.count, 34);
  });

  test('reaching the target completes immediately at the count', () {
    var s = DhikrSessionEngine.reset(s33);
    for (var i = 0; i < 32; i++) {
      s = DhikrSessionEngine.tap(s);
    }
    expect(s.count, 32);
    expect(s.phase, DhikrPhase.counting,
        reason: '32 of 33 — one short of both target and milestone');
    s = DhikrSessionEngine.tap(s); // the 33rd
    expect(s.count, 33);
    expect(s.phase, DhikrPhase.complete,
        reason: 'target reached — completion wins over milestone pause');
  });

  test('taps after complete are ignored', () {
    var s = DhikrSessionEngine.reset(const DhikrSet(
        id: 'tiny', arabic: 'x', meaning: 'y', target: 2));
    s = DhikrSessionEngine.tap(s);
    s = DhikrSessionEngine.tap(s);
    expect(s.phase, DhikrPhase.complete);
    expect(DhikrSessionEngine.tap(s).count, 2, reason: 'complete is terminal');
  });

  test('100-target set pauses at 33, 66, 99 and completes at 100', () {
    var s = DhikrSessionEngine.reset(const DhikrSet(
        id: 'big', arabic: 'x', meaning: 'y', target: 100));
    for (var i = 0; i < 33; i++) {
      s = DhikrSessionEngine.tap(s);
    }
    expect(s.phase, DhikrPhase.milestonePause);
    s = DhikrSessionEngine.tap(s); // resume
    for (var i = 0; i < 33; i++) {
      s = DhikrSessionEngine.tap(s);
    }
    expect(s.count, 66);
    expect(s.phase, DhikrPhase.milestonePause);
    s = DhikrSessionEngine.tap(s);
    for (var i = 0; i < 33; i++) {
      s = DhikrSessionEngine.tap(s);
    }
    expect(s.count, 99);
    expect(s.phase, DhikrPhase.milestonePause);
    s = DhikrSessionEngine.tap(s); // resume
    s = DhikrSessionEngine.tap(s); // 100
    expect(s.phase, DhikrPhase.complete);
    expect(s.progress, 1.0);
  });

  test('classics sets are all sane', () {
    for (final DhikrSet s in DhikrSet.classics) {
      expect(s.target, greaterThan(0));
      expect(s.arabic, isNotEmpty);
      expect(s.meaning, isNotEmpty);
    }
  });
}
