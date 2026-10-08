import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AyahRef', () {
    test('fileName is 3+3 zero-padded', () {
      expect(const AyahRef(1, 1).fileName, '001001.mp3');
      expect(const AyahRef(2, 255).fileName, '002255.mp3');
      expect(const AyahRef(114, 6).fileName, '114006.mp3');
    });

    test('equality by surah+ayah', () {
      expect(const AyahRef(36, 1), const AyahRef(36, 1));
      expect(const AyahRef(36, 1), isNot(const AyahRef(36, 2)));
    });
  });

  group('ReciterPack.alHusary', () {
    test('ayah URL pattern', () {
      expect(
        ReciterPack.alHusary.ayahUrl(const AyahRef(1, 4)),
        'https://server13.mp3quran.net/husr/001004.mp3',
      );
    });

    test('surah URL pattern', () {
      expect(
        ReciterPack.alHusary.surahUrl(2),
        'https://server13.mp3quran.net/husr/002.mp3',
      );
    });
  });

  group('AyahRange', () {
    test('withinSurah inclusive, in order', () {
      final r = AyahRange.withinSurah(surah: 1, fromAyah: 1, toAyah: 7);
      expect(r.refs.length, 7);
      expect(r.refs.first, const AyahRef(1, 1));
      expect(r.refs.last, const AyahRef(1, 7));
    });

    test('single ayah range', () {
      final r = AyahRange.withinSurah(surah: 2, fromAyah: 255, toAyah: 255);
      expect(r.refs, <AyahRef>[const AyahRef(2, 255)]);
    });

    test('concat spans surahs', () {
      final all = AyahRange.concat(<AyahRange>[
        AyahRange.withinSurah(surah: 1, fromAyah: 5, toAyah: 7),
        AyahRange.withinSurah(surah: 2, fromAyah: 1, toAyah: 2),
      ]);
      expect(all.refs.length, 5);
      expect(all.refs[2], const AyahRef(1, 7));
      expect(all.refs[3], const AyahRef(2, 1));
    });

    test('rejects inverted range', () {
      expect(
        () => AyahRange.withinSurah(surah: 1, fromAyah: 5, toAyah: 2),
        throwsAssertionError,
      );
    });
  });

  group('RecitationPlanEngine.buildPlan', () {
    final range = AyahRange.withinSurah(surah: 1, fromAyah: 1, toAyah: 3).refs;

    test('per-ayah repeat expands each ayah N times', () {
      final plan = RecitationPlanEngine.buildPlan(
        range: range,
        perAyahRepeat: 3,
        gapMs: 2000,
        loopRange: 1,
      );
      expect(plan.length, 3);
      expect(plan.every((e) => e.repeats == 3), isTrue);
      expect(plan.map((e) => e.ref.ayah), <int>[1, 2, 3]);
    });

    test('loopRange repeats the whole range in order', () {
      final plan = RecitationPlanEngine.buildPlan(
        range: range,
        perAyahRepeat: 1,
        gapMs: 2000,
        loopRange: 2,
      );
      expect(plan.length, 6);
      expect(plan.map((e) => e.ref.ayah).toList(),
          <int>[1, 2, 3, 1, 2, 3]);
    });

    test('no trailing silence on the very final event only', () {
      final plan = RecitationPlanEngine.buildPlan(
        range: range,
        perAyahRepeat: 1,
        gapMs: 2000,
        loopRange: 2,
      );
      // All events get the gap except the absolute last.
      expect(plan.getRange(0, plan.length - 1).every((e) => e.gapAfterMs == 2000),
          isTrue);
      expect(plan.last.gapAfterMs, 0);
    });

    test('utterance count = events x repeats, loops included', () {
      final plan = RecitationPlanEngine.buildPlan(
        range: range,
        perAyahRepeat: 2,
        gapMs: 500,
        loopRange: 3,
      );
      expect(RecitationPlanEngine.totalUtterances(plan), 3 * 2 * 3);
    });

    test('parameter bounds enforced', () {
      expect(
        () => RecitationPlanEngine.buildPlan(
            range: range, perAyahRepeat: 6, gapMs: 1000, loopRange: 1),
        throwsAssertionError,
      );
      expect(
        () => RecitationPlanEngine.buildPlan(
            range: range, perAyahRepeat: 1, gapMs: 1000, loopRange: 11),
        throwsAssertionError,
      );
    });
  });
}
