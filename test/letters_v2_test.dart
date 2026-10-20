import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/domain/letters_meta.dart';
import 'package:flutter_test/flutter_test.dart';

/// CI gate for Letters v2 (units 5-7: vowels, sukun, shaddah, tanween,
/// joining). Every Qur'an word used as an example must be present, letter for
/// letter, in the bundled Qur'an text at the reference the card names, so a
/// lesson can never show a word the Qur'an does not contain.
void main() {
  final Map<String, dynamic> base = json.decode(
          File('assets/academy/letters_curriculum.json').readAsStringSync())
      as Map<String, dynamic>;
  final Map<String, dynamic> v2 = json.decode(
          File('assets/academy/letters_v2_curriculum.json')
              .readAsStringSync())
      as Map<String, dynamic>;
  final Map<String, dynamic> cur = mergeLettersCurriculum(base, v2);
  final List<Map<String, dynamic>> units = <Map<String, dynamic>>[
    for (final dynamic u in cur['units'] as List<dynamic>)
      Map<String, dynamic>.from(u as Map<dynamic, dynamic>),
  ];
  final List<Map<String, dynamic>> lessons = <Map<String, dynamic>>[
    for (final Map<String, dynamic> u in units)
      for (final dynamic l in u['lessons'] as List<dynamic>)
        Map<String, dynamic>.from(l as Map<dynamic, dynamic>),
  ];

  // surah:ayah -> Arabic text, from the bundled Qur'an.
  final Map<String, String> ayat = <String, String>{};
  for (final dynamic s in json.decode(
      File('assets/quran/quran.json').readAsStringSync()) as List<dynamic>) {
    final Map<dynamic, dynamic> sm = s as Map<dynamic, dynamic>;
    for (final dynamic a in sm['v'] as List<dynamic>) {
      final List<dynamic> al = a as List<dynamic>;
      ayat['${sm['n']}:${al[0]}'] = al[1] as String;
    }
  }

  group('letters school size', () {
    test('merge keeps units 1-4 first and ignores duplicate ids', () {
      expect(mergeLettersCurriculum(base, null), same(base));
      final Map<String, dynamic> twice = mergeLettersCurriculum(cur, v2);
      expect((twice['units'] as List<dynamic>).length, kLettersUnitCount);
      expect((twice['exams'] as List<dynamic>).length, kLettersUnitCount);
      expect(((cur['units'] as List<dynamic>).first as Map<dynamic, dynamic>)['id'],
          'u1');
    });

    test('lesson and unit counts match the constants', () {
      expect(lessons.length, kLettersLessonCount);
      expect(units.length, kLettersUnitCount);
    });

    test('lesson ids run letters-01..letters-40 in order', () {
      for (int i = 0; i < lessons.length; i++) {
        final String n = (i + 1).toString().padLeft(2, '0');
        expect(lessons[i]['id'], 'letters-$n');
      }
    });

    test('every unit has an exam and every exam has a unit', () {
      final Set<String> examIds = <String>{
        for (final dynamic e in cur['exams'] as List<dynamic>)
          (e as Map<dynamic, dynamic>)['id'] as String,
      };
      for (final Map<String, dynamic> u in units) {
        expect(examIds, contains(u['exam']), reason: '${u['id']}');
      }
      expect(examIds.length, units.length);
    });
  });

  group('letters v2 content integrity', () {
    test('every quiz answer index is inside its options', () {
      for (final Map<String, dynamic> l in lessons) {
        for (final dynamic st in l['steps'] as List<dynamic>) {
          final Map<dynamic, dynamic> s = st as Map<dynamic, dynamic>;
          if (s['type'] != 'quiz') continue;
          final List<dynamic> opts = s['options'] as List<dynamic>;
          final int a = (s['answer'] as num).toInt();
          expect(a >= 0 && a < opts.length, isTrue, reason: '${l['id']}');
        }
      }
    });

    test('every exam answer index is inside its options; pass <= total', () {
      for (final dynamic e in cur['exams'] as List<dynamic>) {
        final Map<dynamic, dynamic> em = e as Map<dynamic, dynamic>;
        final List<dynamic> qs = em['questions'] as List<dynamic>;
        for (final dynamic q in qs) {
          final Map<dynamic, dynamic> qm = q as Map<dynamic, dynamic>;
          final int a = (qm['answer'] as num).toInt();
          final int n = (qm['options'] as List<dynamic>).length;
          expect(a >= 0 && a < n, isTrue, reason: '${em['id']}');
        }
        expect((em['pass'] as num).toInt(), lessThanOrEqualTo(qs.length),
            reason: '${em['id']}');
      }
    });

    test('every card that names a Qur’an ref shows a word found there',
        () {
      int checked = 0;
      for (final Map<String, dynamic> l in lessons) {
        for (final dynamic st in l['steps'] as List<dynamic>) {
          final Map<dynamic, dynamic> s = st as Map<dynamic, dynamic>;
          final String? ref = s['ref'] as String?;
          if (ref == null) continue;
          final String? text = ayat[ref];
          expect(text, isNotNull, reason: '${l['id']} cites $ref');
          final List<String> words = text!.split(' ');
          expect(words, contains(s['arabic'] as String),
              reason: '${l['id']}: ${s['arabic']} is not in $ref');
          checked++;
        }
      }
      expect(checked, greaterThan(15));
    });

    test('units 5-7 are present and in order', () {
      expect(units.map((Map<String, dynamic> u) => u['id']).toList(),
          <String>['u1', 'u2', 'u3', 'u4', 'u5', 'u6', 'u7']);
    });
  });
}
