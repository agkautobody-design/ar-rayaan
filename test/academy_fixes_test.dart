import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/data/word_deck_repository.dart';
import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/domain/hifz_planner.dart';
import 'package:ar_rayaan/features/academy/domain/recitation_audio.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:ar_rayaan/features/academy/domain/word_deck.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 5, 9);

  WordCard card(String key) => WordCard(
        key: key,
        arabic: 'كِتَاب',
        gloss: 'book',
        sourceAyah: const AyahRef(2, 2),
        review: ReviewCard(wordKey: key, dueDate: now),
      );

  group('word deck', () {
    test('a card graded Again comes back in the due lane', () {
      var deck = <String, WordCard>{'a': card('a')};
      deck = WordDeckEngine.grade(
          deck: deck, key: 'a', grade: ReviewGrade.again, now: now);
      final List<WordCard> later = WordDeckEngine.buildSession(
          deck: deck, now: now.add(const Duration(days: 2)));
      expect(later.map((WordCard c) => c.key), contains('a'));
    });

    test('hasMeaning rejects truncated glosses', () {
      final WordCard bad = WordCard(
        key: 'b',
        arabic: 'x',
        gloss: 'In the name of … (in context)',
        review: ReviewCard(wordKey: 'b', dueDate: now),
      );
      expect(bad.hasMeaning, isFalse);
      expect(card('a').hasMeaning, isTrue);
    });

    test('word pack matches its pinned checksum and has no placeholder glosses',
        () {
      final String raw = File('assets/academy/word_pack.json').readAsStringSync();
      expect(sha256.convert(utf8.encode(raw)).toString(), kWordPackSha256);
      expect(raw.contains('(in context)'), isFalse);
    });
  });

  group('manifest', () {
    test('course counts are consistent', () {
      expect(kManifestCourseCount, kAcademyCourses.length);
      expect(kManifestCoursesWithLessons,
          kAcademyCourses.where((c) => c.hasLessons).length);
      expect(kManifestCoursesWithLessons, lessThanOrEqualTo(kManifestCourseCount));
    });

    test('every check answer index is valid and answers vary', () {
      final Set<int> positions = <int>{};
      for (final items in kAssessments.values) {
        for (final it in items) {
          expect(it.correctIndex, inInclusiveRange(0, it.choices.length - 1));
          positions.add(it.correctIndex);
        }
      }
      expect(positions.length, greaterThan(1));
    });
  });

  group('hifz planner', () {
    test('ayah counts match quran.json', () {
      final List<dynamic> q = jsonDecode(
          File('assets/quran/quran.json').readAsStringSync()) as List<dynamic>;
      expect(kAyahCounts.length, 114);
      for (int i = 0; i < 114; i++) {
        final Map<String, dynamic> s = q[i] as Map<String, dynamic>;
        expect(kAyahCounts[i], s['c'], reason: 'surah ${i + 1}');
      }
      expect(kAyahCounts.reduce((a, b) => a + b), 6236);
      expect(ayatInSurah(0), 0);
      expect(ayatInSurah(18), 110);
    });
  });

  group('data files', () {
    test('trivia answers are in range and spread across positions', () {
      final List<dynamic> t = jsonDecode(
          File('assets/games/trivia.json').readAsStringSync()) as List<dynamic>;
      final Set<int> positions = <int>{};
      for (final dynamic e in t) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final int a = m['answer'] as int;
        expect(a, inInclusiveRange(0, (m['options'] as List<dynamic>).length - 1));
        positions.add(a);
      }
      expect(positions.length, 4);
    });

    test('letters curriculum answers are not all one position', () {
      final String raw =
          File('assets/academy/letters_curriculum.json').readAsStringSync();
      final Set<int> positions = <int>{};
      void walk(dynamic n) {
        if (n is Map<String, dynamic>) {
          if (n['answer'] is int) positions.add(n['answer'] as int);
          if (n['correct'] is int) positions.add(n['correct'] as int);
          n.values.forEach(walk);
        } else if (n is List<dynamic>) {
          n.forEach(walk);
        }
      }
      walk(jsonDecode(raw));
      expect(positions.length, greaterThan(1));
    });

    test('the Arabic ligature glyph U+FB51 is not used for salawat', () {
      final Directory dir = Directory('lib/features');
      for (final FileSystemEntity f in dir.listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          expect(f.readAsStringSync().contains('ﭑ'), isFalse,
              reason: f.path);
        }
      }
    });
  });
}
