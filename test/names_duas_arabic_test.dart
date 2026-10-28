import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/academy/presentation/dua_school_screen.dart';
import 'package:ar_rayaan/features/games/presentation/games_screens.dart';
import 'package:ar_rayaan/features/stories/presentation/story_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Round 4: Arabic script for the 99 Names, and transliteration (with its
/// source) for the dua and adhkar pages. The sources are listed in
/// docs/content_needed/VERIFICATION_LOG_NAMES_DUAS.md.
final RegExp _arabicChars = RegExp(r'[؀-ۿ]');

List<dynamic> _list(String path) =>
    jsonDecode(File(path).readAsStringSync()) as List<dynamic>;

void main() {
  group('99 Names show Arabic', () {
    testWidgets('card front and the All 99 list carry the Arabic, RTL',
        (WidgetTester tester) async {
      await AppHarness.boot(
        tester,
        overrides: <Override>[
          namesProvider.overrideWith(
            (ref) async => <Name99>[
              for (int i = 1; i <= 3; i++)
                Name99(
                  n: i,
                  name: 'Name $i',
                  meaning: 'Meaning $i',
                  ref: '1:$i',
                  arabic: 'ٱللَّه$i',
                ),
            ],
          ),
        ],
      );
      await AppHarness.go(
        tester,
        find.byType(Scaffold).first,
        AppRoutes.names99,
      );
      final Finder front = find.byKey(const Key('names-card-arabic'));
      expect(front, findsOneWidget);
      final Text frontText = tester.widget<Text>(front);
      expect(frontText.textDirection, TextDirection.rtl);
      expect(frontText.style?.fontFamily, 'Amiri');
      expect(frontText.style!.fontSize, greaterThanOrEqualTo(48));

      await tester.tap(find.text('All 99'));
      await AppHarness.settle(tester);
      for (int i = 1; i <= 3; i++) {
        final Finder row = find.byKey(Key('names-row-arabic-$i'));
        expect(row, findsOneWidget);
        expect(tester.widget<Text>(row).textDirection, TextDirection.rtl);
      }
    });
  });

  group('Names data', () {
    test('every Name has Arabic script, only Arabic characters', () {
      final List<dynamic> names = _list('assets/games/names99.json');
      expect(names.length, 99);
      for (final dynamic e in names) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final String ar = m['arabic'] as String;
        expect(ar.trim(), isNotEmpty, reason: '${m['name']}');
        expect(RegExp(r'^[؀-ۿ ]+$').hasMatch(ar), isTrue,
            reason: '${m['name']}');
      }
    });
  });

  group('dua transliteration data', () {
    final RegExp latinOnly = RegExp(r'^[^؀-ۿ]+$');

    test('dailyduas: tl is Latin letters and always names its source', () {
      int withTl = 0;
      for (final dynamic d in _list('assets/stories/dailyduas.json')) {
        final Map<String, dynamic> m = d as Map<String, dynamic>;
        for (final dynamic c in m['chapters'] as List<dynamic>) {
          final Map<String, dynamic> ch = c as Map<String, dynamic>;
          final String? tl = ch['tl'] as String?;
          final String? src = ch['tlSource'] as String?;
          if (tl == null) {
            expect(src, isNull, reason: '${m['id']}: source without tl');
            continue;
          }
          withTl++;
          expect(latinOnly.hasMatch(tl), isTrue, reason: '${m['id']}');
          expect(ch['arabic'], isNotNull, reason: '${m['id']}: tl, no Arabic');
          expect(src, isNotNull, reason: '${m['id']}: tl without source');
          expect(src!.trim().length, greaterThan(10), reason: '${m['id']}');
        }
      }
      expect(withTl, greaterThan(25));
    });

    test('adhkar: tl is Latin letters and always names its source', () {
      final Map<String, dynamic> data = jsonDecode(
        File('assets/adhkar/adhkar.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      int withTl = 0;
      for (final dynamic s in data['sets'] as List<dynamic>) {
        for (final dynamic i
            in (s as Map<String, dynamic>)['items'] as List<dynamic>) {
          final Map<String, dynamic> it = i as Map<String, dynamic>;
          final String? tl = it['tl'] as String?;
          if (tl == null) {
            expect(it['tlSource'], isNull);
            continue;
          }
          withTl++;
          expect(latinOnly.hasMatch(tl), isTrue, reason: '${s['id']} ${it['n']}');
          expect((it['tlSource'] as String?)?.trim(), isNotEmpty,
              reason: '${s['id']} ${it['n']}: tl without source');
        }
      }
      expect(withTl, greaterThan(20));
    });

    test('Dua School lessons: transliteration names its source', () {
      int withTl = 0;
      final List<DuaLesson> lessons = DuaLesson.parse(
        File('assets/academy/dua_lessons.json').readAsStringSync(),
      );
      expect(lessons.length, greaterThan(10));
      for (final DuaLesson l in lessons) {
        final String? tl = l.translit;
        final String? src = l.translitSource;
        if (tl == null) continue;
        withTl++;
        expect(latinOnly.hasMatch(tl), isTrue, reason: tl);
        expect(src, isNotNull, reason: tl);
        expect(src!.trim(), isNotEmpty, reason: tl);
      }
      expect(withTl, greaterThan(5));
    });
  });

  group('no dua is shown in part', () {
    final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
      for (final dynamic d in _list('assets/stories/dailyduas.json'))
        (d as Map<String, dynamic>)['id'] as String: d,
    };
    Map<String, dynamic> chapter(String id) =>
        (byId[id]!['chapters'] as List<dynamic>).first as Map<String, dynamic>;

    test('formerly elided entries now carry the full Arabic', () {
      for (final String id in <String>[
        'dua-istikhlas',
        'dua-istikhara-full',
        'dua-witr-qunut',
        'dua-sleep',
        'dua-sleep2',
      ]) {
        final String ar = chapter(id)['arabic'] as String;
        expect(arabicIsElided(ar), isFalse, reason: id);
        expect(ar.contains('continue'), isFalse, reason: id);
        expect(ar.contains('complete'), isFalse, reason: id);
        expect(_arabicChars.hasMatch(ar), isTrue, reason: id);
      }
      // The short form of the istikhara no longer repeats the elided text.
      expect(chapter('dua-istikhara')['dua'], isNull);
    });

    test('dua-sleep and dua-sleep2 are the Qur’an text of this app', () {
      final List<dynamic> quran = _list('assets/quran/quran.json');
      String verse(int s, int a) =>
          (((quran[s - 1] as Map<String, dynamic>)['v']
              as List<dynamic>)[a - 1] as List<dynamic>)[1] as String;
      expect(chapter('dua-sleep')['arabic'], verse(2, 255));
      final String quls = chapter('dua-sleep2')['arabic'] as String;
      for (final int s in <int>[112, 113, 114]) {
        final int n = (quran[s - 1] as Map<String, dynamic>)['c'] as int;
        for (int a = 1; a <= n; a++) {
          expect(quls.contains(verse(s, a)), isTrue, reason: '$s:$a');
        }
      }
    });
  });
}
