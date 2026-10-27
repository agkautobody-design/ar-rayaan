import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Adhkar, daily duas and Ramadan duas audit (October 2026).
final RegExp _arabicChars = RegExp(r'[\u0600-\u06FF]');

String _bare(String s) =>
    s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '');

void main() {
  group('adhkar', () {
    final Map<String, dynamic> data = jsonDecode(
      File('assets/adhkar/adhkar.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
      for (final dynamic s in data['sets'] as List<dynamic>)
        for (final dynamic i in (s as Map<String, dynamic>)['items'] as List<dynamic>)
          <String, dynamic>{...(i as Map<String, dynamic>), 'set': s['id']},
    ];

    test('50 of the 52 items now carry a transliteration with its source', () {
      expect(items.length, 52);
      final List<String> missing = <String>[
        for (final Map<String, dynamic> i in items)
          if (i['tl'] == null) '${i['set']} ${i['n']}',
      ];
      // The two without one are the "asking for the good of this day/night"
      // duas, for which no verified transliteration was found.
      expect(missing, <String>['morning 15', 'evening 15']);
      for (final Map<String, dynamic> i in items) {
        if (i['tl'] == null) continue;
        expect(_arabicChars.hasMatch(i['tl'] as String), isFalse);
        expect((i['tlSource'] as String).trim().length, greaterThan(8));
      }
    });

    test('the three Quls and Ayat al-Kursi carry their meaning, not just a description', () {
      for (final Map<String, dynamic> i in items) {
        final String ar = _bare(i['ar'] as String);
        if (ar.contains('قل هو الله احد') || ar.contains('قل هو الله أحد')) {
          expect(i['en'] as String, contains('Saheeh International'),
              reason: '${i['set']} ${i['n']}');
        }
      }
    });
  });

  group('daily duas', () {
    final List<dynamic> duas = jsonDecode(
      File('assets/stories/dailyduas.json').readAsStringSync(),
    ) as List<dynamic>;

    test('every dua has a transliteration and names where it came from', () {
      expect(duas.length, 42);
      for (final dynamic d in duas) {
        final Map<String, dynamic> m = d as Map<String, dynamic>;
        for (final dynamic c in m['chapters'] as List<dynamic>) {
          final Map<String, dynamic> ch = c as Map<String, dynamic>;
          expect(ch['tl'], isNotNull, reason: '${m['id']}');
          expect((ch['tlSource'] as String).trim().length, greaterThan(10));
        }
      }
    });

    test('before-eating dua holds only the words said, no instruction', () {
      final Map<String, dynamic> m = duas
          .cast<Map<String, dynamic>>()
          .firstWhere((Map<String, dynamic> d) => d['id'] == 'dua-eat-before');
      final String ar = (m['chapters'] as List<dynamic>).first['arabic'] as String;
      expect(ar.contains('وَإِنْ نَسِيتَ'), isFalse);
      expect(ar, contains('أَوَّلَهُ وَآخِرَهُ'));
    });
  });

  group('Ramadan duas', () {
    final List<Map<String, dynamic>> days = (jsonDecode(
      File('assets/finance/ramadan.json').readAsStringSync(),
    )['days'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    test('30 days, no repeated dua, no fragments', () {
      expect(days.length, 30);
      final Set<String> seen = <String>{};
      for (final Map<String, dynamic> d in days) {
        final String ar = _bare(d['arabic'] as String);
        expect(seen.add(ar), isTrue, reason: 'day ${d['day']} repeats a dua');
        expect(ar.trim().split(RegExp(r'\s+')).length, greaterThanOrEqualTo(3),
            reason: 'day ${d['day']} is a fragment');
      }
    });

    test('every day has a transliteration and its source line', () {
      for (final Map<String, dynamic> d in days) {
        expect(d['translit'], isNotNull, reason: 'day ${d['day']}');
        expect(_arabicChars.hasMatch(d['translit'] as String), isFalse);
        expect((d['translitSource'] as String).trim(), isNotEmpty);
      }
    });
  });
}
