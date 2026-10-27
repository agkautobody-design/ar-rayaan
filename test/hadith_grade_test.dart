import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Forty Hadith entries carry source, grade and a named grader', () {
    final List<dynamic> data =
        jsonDecode(File('assets/hadith/nawawi40.json').readAsStringSync())
            as List<dynamic>;
    expect(data.length, 42);
    int graded = 0;
    for (final Map<String, dynamic> h in data.cast<Map<String, dynamic>>()) {
      final HadithGrade? g = HadithGrade.fromJson(h);
      expect(h['src'], isA<String>(), reason: 'hadith ${h['n']}');
      expect(g, isNotNull, reason: 'hadith ${h['n']}');
      graded++;
    }
    expect(graded, 42);
  });

  test('hadith 19 names its source, grade and grader (it was ungraded)', () {
    final List<dynamic> data =
        jsonDecode(File('assets/hadith/nawawi40.json').readAsStringSync())
            as List<dynamic>;
    final Map<String, dynamic> h =
        data.cast<Map<String, dynamic>>().firstWhere((m) => m['n'] == 19);
    expect(h['src'], contains('Tirmidhi'));
    expect(HadithGrade.fromJson(h)!.grader, 'at-Tirmidhi');
    expect(HadithGrade.fromJson(h)!.grade, 'hasan sahih');
  });

  test('hadith 12 shows the graders\' disagreement, not one grade alone', () {
    final List<dynamic> data =
        jsonDecode(File('assets/hadith/nawawi40.json').readAsStringSync())
            as List<dynamic>;
    final Map<String, dynamic> h =
        data.cast<Map<String, dynamic>>().firstWhere((m) => m['n'] == 12);
    final HadithGrade g = HadithGrade.fromJson(h)!;
    expect(g.note, isNotNull);
    expect(g.note, contains('Albani'));
    expect(g.note, contains('Darussalam'));
  });

  test('Hadith.sourceLine shows source and grade with grader', () {
    const Hadith h = Hadith(
      number: 11,
      arabic: 'x',
      english: 'y',
      source: 'at-Tirmidhi',
      grade: HadithGrade(grade: 'hasan sahih', grader: 'at-Tirmidhi'),
    );
    expect(h.sourceLine, 'at-Tirmidhi · Hasan sahih — at-Tirmidhi');
  });

  test('hadithSourceNeedsGrade: Bukhari/Muslim top tier only', () {
    expect(hadithSourceNeedsGrade('Sahih al-Bukhari 1'), isFalse);
    expect(hadithSourceNeedsGrade('Sahih Muslim 2699'), isFalse);
    expect(hadithSourceNeedsGrade('Jamiʿ at-Tirmidhi 1956'), isTrue);
    expect(hadithSourceNeedsGrade('Sunan Abi Dawud 5090'), isTrue);
    expect(hadithSourceNeedsGrade('Sunan Ibn Majah 3871'), isTrue);
    expect(hadithSourceNeedsGrade("Sunan an-Nasa'i 1"), isTrue);
  });
}
