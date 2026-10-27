import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/hifz_planner.dart';
import 'package:ar_rayaan/features/academy/domain/hifz_progress.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lesson_v3_model.dart';
import 'package:ar_rayaan/features/academy/domain/v3/lessons_v3.dart';
import 'package:ar_rayaan/features/academy/domain/v3/phrase_registry.dart';
import 'package:ar_rayaan/features/academy/domain/v3/quran_verses.dart';
import 'package:ar_rayaan/features/journey/domain/journey_progress.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _read(String dir) => <String>[
      for (final FileSystemEntity f in Directory(dir).listSync())
        if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
    ];

LessonsV3 _load() {
  final PhraseRegistry reg =
      PhraseRegistry.parseAll(_read('assets/academy/phrases'));
  final QuranVerses quran = QuranVerses.parse(
    File('assets/quran/quran.json').readAsStringSync(),
    transliterationJson:
        File('assets/quran/transliteration.json').readAsStringSync(),
  );
  final List<LessonsFile> files = <LessonsFile>[
    for (final String raw in _read('assets/academy/lessons_v3'))
      parseLessonsFile(jsonDecode(raw) as Map<String, dynamic>),
  ];
  return LessonsV3.build(files, reg, quran);
}

void main() {
  final LessonsV3 all = _load();

  const List<String> arabicIds = <String>[
    'arabic.u1.l1',
    'arabic.u1.l2',
    'arabic.u1.l3',
    'arabic.u1.l4',
    'arabic.u2.l1',
    'arabic.u2.l2',
    'arabic.u2.l3',
  ];
  const List<String> hifzIds = <String>[
    'hfz.u1.l1',
    'hfz.u1.l2',
    'hfz.u1.l3',
    'hfz.u2.l1',
    'hfz.u2.l2',
    'hfz.u2.l3',
  ];

  group('Arabic Language and Hifz lessons', () {
    test('every listed lesson is present and the merge reports no problem', () {
      expect(all.problems, isEmpty);
      for (final String id in <String>[...arabicIds, ...hifzIds]) {
        expect(all.has(id), isTrue, reason: id);
      }
    });

    test('pass validation', () {
      for (final String id in <String>[...arabicIds, ...hifzIds]) {
        expect(validateLesson(all[id]!, all.resolver), isEmpty, reason: id);
      }
    });

    test('12 to 15 steps, 8 to 12 checks, many modes', () {
      for (final String id in <String>[...arabicIds, ...hifzIds]) {
        final LessonV3 l = all[id]!;
        expect(l.steps.length, inInclusiveRange(12, 15), reason: id);
        expect(l.checkItems.length, inInclusiveRange(8, 12), reason: id);
        final Set<String> kinds = l.steps.map((V3Step s) => s.kind).toSet();
        expect(kinds.length, greaterThanOrEqualTo(7), reason: id);
        expect(kinds, contains('arrange'), reason: id);
        expect(kinds, contains('match'), reason: id);
        expect(kinds, contains('recap'), reason: id);
        expect(kinds, contains('doit'), reason: id);
      }
    });

    test('the Hifz lessons may open the planner', () {
      expect(isDoItRoute('/academy/hifz'), isTrue);
      expect(isDoItRoute('/academy/hifz/x'), isFalse);
    });
  });

  group('Juz Amma plan', () {
    test('has 564 ayat in surahs 78 to 114', () {
      expect(juzAmmaAyat(), 564);
      expect(kJuzAmmaFirstSurah, 78);
      expect(kJuzAmmaLastSurah, 114);
    });

    test('a fresh state is the Juz Amma plan, starting with An-Nas', () {
      const HifzState s = HifzState();
      expect(s.juzAmma, isTrue);
      expect(s.workingSurah, 114);
      expect(s.remainingInTarget, 564);
      final HifzDay d = s.dayFor(DateTime(2026, 3, 4));
      expect(d.fresh, const AyahChunk(114, 1, 3));
      expect(d.recent, isEmpty);
      expect(d.older, isNull);
    });

    test('finishing a surah moves the plan back one surah', () {
      final HifzState s = const HifzState().addRange(114, 1, 6);
      expect(s.workingSurah, 113);
      expect(s.juzAmmaMemorised, 6);
      expect(s.remainingInTarget, 558);
      expect(s.dayFor(DateTime(2026, 3, 4)).fresh, const AyahChunk(113, 1, 3));
    });

    test('new ayat continue after what is written down, and stop at the end',
        () {
      final HifzState s =
          const HifzState().addRange(114, 1, 5).withPlan(daily: 3);
      expect(s.workingSurah, 114);
      expect(s.dayFor(DateTime(2026, 3, 4)).fresh, const AyahChunk(114, 6, 6));
    });

    test('choosing a surah switches to the one-surah plan', () {
      final HifzState s = const HifzState().withPlan(surah: 18);
      expect(s.juzAmma, isFalse);
      expect(s.workingSurah, 18);
      expect(s.withPlan(juzAmma: true).workingSurah, 114);
    });

    test('an old saved plan without the Juz Amma flag stays one surah', () {
      final HifzState s = HifzState.decode('{"surah":18,"daily":5}');
      expect(s.juzAmma, isFalse);
      expect(s.targetSurah, 18);
      expect(s.dailyNewAyat, 5);
    });

    test('the plan and the log survive a round trip', () {
      final int day = hifzDayNumber(DateTime(2026, 3, 4));
      final HifzState s = const HifzState()
          .addRange(114, 1, 6, day: day)
          .addRange(113, 1, 2, day: day);
      final HifzState back = HifzState.decode(s.encode());
      expect(back.juzAmma, isTrue);
      expect(back.log.length, 2);
      expect(back.memorisedIn(114), 6);
      expect(back.memorisedIn(113), 2);
    });
  });

  group('Today\'s lanes come from what was written down', () {
    final DateTime now = DateTime(2026, 3, 10);
    final int today = hifzDayNumber(now);

    test('the last week is recent, the rest is older', () {
      final HifzState s = const HifzState()
          .addRange(112, 1, 4, day: today - 20)
          .addRange(114, 1, 6, day: today - 2);
      final HifzDay d = s.dayFor(now);
      expect(d.recent, <AyahChunk>[const AyahChunk(114, 1, 6)]);
      expect(d.older, const AyahChunk(112, 1, 4));
    });

    test('with only recent work there is no older section yet', () {
      final HifzState s =
          const HifzState().addRange(114, 1, 6, day: today - 1);
      final HifzDay d = s.dayFor(now);
      expect(d.recent.length, 1);
      expect(d.older, isNull);
    });

    test('ayat on the list with no date count as older', () {
      final HifzState s = const HifzState().addRange(112, 1, 4);
      final HifzDay d = s.dayFor(now);
      expect(d.recent, isEmpty);
      expect(d.older, const AyahChunk(112, 1, 4));
    });

    test('older sections cycle, one a day', () {
      final HifzState s = const HifzState()
          .addRange(112, 1, 4)
          .addRange(108, 1, 3)
          .addRange(103, 1, 3);
      final Set<AyahChunk> seen = <AyahChunk>{
        for (int i = 0; i < 3; i++) s.dayFor(now.add(Duration(days: i))).older!,
      };
      expect(seen.length, 3);
    });

    test('a long older range is cut into sections of at most 20 ayat', () {
      final HifzState s = const HifzState().addRange(78, 1, 40);
      final Set<AyahChunk> seen = <AyahChunk>{
        for (int i = 0; i < 4; i++) s.dayFor(now.add(Duration(days: i))).older!,
      };
      expect(seen, <AyahChunk>{
        const AyahChunk(78, 1, 20),
        const AyahChunk(78, 21, 40),
      });
    });

    test('removing a range takes it out of the lanes', () {
      final HifzState s =
          const HifzState().addRange(114, 1, 6, day: today).removeRange(114, 0);
      final HifzDay d = s.dayFor(now);
      expect(d.recent, isEmpty);
      expect(d.older, isNull);
    });

    test('is the same for the same state and date', () {
      final HifzState s =
          const HifzState().addRange(112, 1, 4).addRange(108, 1, 3);
      expect(s.dayFor(now).older, s.dayFor(now).older);
    });
  });

  group('Journey ring and the Hifz planner', () {
    test('writing down memorised ayat moves the ring', () {
      expect(ringValue(const RingInputs()), 0);
      expect(
        ringValue(const RingInputs(ayatMemorised: 5)),
        closeTo(0.15, 1e-9),
      );
    });

    test('the five parts add up to the whole ring', () {
      final double sum = ringParts(const RingInputs())
          .fold<double>(0, (double a, RingPart p) => a + p.weight);
      expect(sum, closeTo(1, 1e-9));
      expect(ringParts(const RingInputs()).length, 5);
    });
  });
}
