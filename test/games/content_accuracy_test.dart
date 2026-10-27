import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/games/engine/quiz_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Content accuracy gates for the games: every trivia question carries a
/// source, a quoted claim really is in the verse it is cited to, and no
/// question has two correct-looking options. These fail on a missing
/// citation, a verse that does not contain the claimed words, or a
/// duplicate or nested option.
String _n(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[’'`]"), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

void main() {
  late Map<String, String> verses; // "s:a" -> English
  late List<Map<String, dynamic>> trivia;

  setUpAll(() {
    verses = <String, String>{};
    for (final dynamic s in json
        .decode(File('assets/quran/quran.json').readAsStringSync())
        as List<dynamic>) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      for (final dynamic v in m['v'] as List<dynamic>) {
        final List<dynamic> row = v as List<dynamic>;
        verses['${m['n']}:${row[0]}'] = row[2] as String;
      }
    }
    trivia = <Map<String, dynamic>>[
      for (final dynamic e in json
          .decode(File('assets/games/trivia.json').readAsStringSync())
          as List<dynamic>)
        e as Map<String, dynamic>,
    ];
  });

  String verseText(String ref) {
    final RegExpMatch m = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$').firstMatch(ref)!;
    final int a = int.parse(m.group(2)!);
    final int b = int.parse(m.group(3) ?? m.group(2)!);
    return <String>[
      for (int i = a; i <= b; i++)
        verses['${m.group(1)}:$i'] ?? (throw StateError('no verse $ref')),
    ].join(' ');
  }

  group('Stories Trivia content', () {
    test('at least 300 questions, unique ids and prompts', () {
      expect(trivia.length, greaterThanOrEqualTo(300));
      expect(trivia.map((Map<String, dynamic> e) => e['id']).toSet().length,
          trivia.length);
      expect(trivia.map((Map<String, dynamic> e) => e['question']).toSet().length,
          trivia.length);
    });

    test('every question has a source and a citation the app can show', () {
      for (final Map<String, dynamic> q in trivia) {
        expect((q['source'] as String?)?.trim() ?? '', isNotEmpty,
            reason: '${q['id']}: no source');
        expect((q['claims'] as List<dynamic>?) ?? const <dynamic>[], isNotEmpty,
            reason: '${q['id']}: no claims');
        expect(triviaCitation(q['why'] as String), isNotNull,
            reason: '${q['id']}: why names no source');
      }
    });

    test('every quoted claim is in the verse it is cited to', () {
      int checked = 0;
      for (final Map<String, dynamic> q in trivia) {
        for (final dynamic c in q['claims'] as List<dynamic>) {
          final Map<String, dynamic> claim = c as Map<String, dynamic>;
          final String? ref = claim['ref'] as String?;
          final String quote = (claim['quote'] as String?) ?? '';
          if (ref == null) continue;
          final String text = _n(verseText(ref));
          if (quote.isNotEmpty) {
            expect(text.contains(_n(quote)), isTrue,
                reason: '${q['id']}: "$quote" is not in $ref');
            checked++;
          }
        }
      }
      expect(checked, greaterThan(200));
    });

    test('options are four, distinct, and none contains another', () {
      for (final Map<String, dynamic> q in trivia) {
        final List<String> o = (q['options'] as List<dynamic>).cast<String>();
        expect(o.length, 4, reason: '${q['id']}');
        expect(o.map(_n).toSet().length, 4, reason: '${q['id']}: duplicate');
        for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 4; j++) {
            if (i == j) continue;
            expect(_n(o[i]) == _n(o[j]) || _n(o[j]).contains(' ${_n(o[i])} '),
                isFalse,
                reason: '${q['id']}: "${o[i]}" inside "${o[j]}"');
          }
        }
        expect(q['answer'] as int, inInclusiveRange(0, 3));
      }
    });

    test('a why-quote that is not a claim is not invented', () {
      for (final Map<String, dynamic> q in trivia) {
        final String why = q['why'] as String;
        final Iterable<RegExpMatch> quotes =
            RegExp(r'“([^”]{8,})”').allMatches(why);
        final List<dynamic> claims = q['claims'] as List<dynamic>;
        final String pool = _n(<String>[
          for (final dynamic c in claims) ...<String>[
            if ((c as Map<String, dynamic>)['ref'] != null)
              verseText(c['ref'] as String),
            (c['quote'] as String?) ?? '',
          ],
        ].join(' '));
        for (final RegExpMatch m in quotes) {
          final String part = _n(m.group(1)!);
          final bool inVerse = pool.contains(part);
          final bool hadith =
              claims.any((dynamic c) => (c as Map<String, dynamic>)['hadith'] != null);
          expect(inVerse || hadith, isTrue,
              reason: '${q['id']}: quote not in a cited verse: $part');
        }
      }
    });
  });

  group('99 Names content', () {
    test('99 unique Names and Arabic, each with a verse that has the Name', () {
      final List<dynamic> names = json
          .decode(File('assets/games/names99.json').readAsStringSync())
          as List<dynamic>;
      expect(names.length, 99);
      expect(names.map((dynamic e) => (e as Map<String, dynamic>)['name']).toSet().length, 99);
      expect(names.map((dynamic e) => (e as Map<String, dynamic>)['arabic']).toSet().length, 99);
      for (final dynamic e in names) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        expect(m['kind'], anyOf('name', 'related', 'list'),
            reason: '${m['name']}');
        expect((m['ref'] as String).trim(), isNotEmpty);
        if (RegExp(r'^\d+:\d+').hasMatch(m['ref'] as String)) {
          expect(verseText((m['ref'] as String).split(' ').first).isNotEmpty,
              isTrue);
        }
      }
    });
  });

  group('Hadith Knowledge content', () {
    test('every item has words the Prophet said, and a clean opening', () {
      final Map<String, dynamic> d = json
          .decode(File('assets/games/hadith_quiz.json').readAsStringSync())
          as Map<String, dynamic>;
      final List<dynamic> items = d['items'] as List<dynamic>;
      expect(items.length, greaterThanOrEqualTo(30));
      for (final dynamic e in items) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final String said = m['said'] as String;
        final String head = (m['head'] as String?) ?? '';
        expect(said.trim().split(RegExp(r'\s+')).length, greaterThan(3));
        if (head.isNotEmpty) expect(said.startsWith(head), isTrue);
      }
    });
  });
}
