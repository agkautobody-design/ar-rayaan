import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Forty Hadith file is read straight from the shipped asset: what a
/// person sees must carry no editor markup and no mixed-up numbering.
void main() {
  final List<Map<String, dynamic>> data = (jsonDecode(
    File('assets/hadith/nawawi40.json').readAsStringSync(),
  ) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  test('42 narrations numbered 1 to 42 in order', () {
    expect(data.length, 42);
    for (int i = 0; i < data.length; i++) {
      expect(data[i]['n'], i + 1);
    }
  });

  test('no HTML, no source-book index markers, in the Arabic or English', () {
    for (final Map<String, dynamic> h in data) {
      for (final String k in <String>['ar', 'en']) {
        final String t = h[k] as String;
        expect(t, isNot(contains('<br')), reason: 'hadith ${h['n']} $k');
        expect(t, isNot(contains('[رقم')), reason: 'hadith ${h['n']} $k');
        expect(t, isNot(contains('[راجع')), reason: 'hadith ${h['n']} $k');
        expect(t.trim(), isNotEmpty);
      }
    }
  });

  test('the English has no inline collection tags like [Muslim]', () {
    final RegExp tag = RegExp(
      r'\[(Bukhari|Muslim|Al-Bukhari|At-Tirmidhi|An-Nasai|Abu Dawud|Bukhari & Muslim)[^\]]*\]',
    );
    for (final Map<String, dynamic> h in data) {
      expect(tag.hasMatch(h['en'] as String), isFalse,
          reason: 'hadith ${h['n']}');
    }
  });

  test('every narration has a source, a grade and a named grader', () {
    for (final Map<String, dynamic> h in data) {
      for (final String k in <String>['src', 'grade', 'grader']) {
        expect(h[k], isA<String>(), reason: 'hadith ${h['n']} $k');
        expect((h[k] as String).trim(), isNotEmpty,
            reason: 'hadith ${h['n']} $k');
      }
    }
  });

  test('graders that disagree are both shown (12, 42) or questioned (41)', () {
    String note(int n) =>
        data.firstWhere((Map<String, dynamic> h) => h['n'] == n)['gradeNote']
                as String? ??
            '';
    expect(note(12), contains('Albani'));
    expect(note(42), contains('Albani'));
    expect(note(41), isNotEmpty);
  });
}
