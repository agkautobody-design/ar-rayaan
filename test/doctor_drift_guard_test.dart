import 'dart:io';

import 'package:ar_rayaan/features/doctor/application/drift_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drift guard counts lessons across Letters v1 and v2 (>= 40)', () {
    int total = 0;
    for (final String path in DriftGuard.letterCurricula) {
      total += DriftGuard.lessonsIn(File(path).readAsStringSync());
    }
    expect(DriftGuard.minLetterLessons, 40);
    expect(total, greaterThanOrEqualTo(DriftGuard.minLetterLessons));
  });

  test('v1 alone would trip the guard, so v2 must be included', () {
    final int v1 = DriftGuard.lessonsIn(
        File('assets/academy/letters_curriculum.json').readAsStringSync());
    expect(v1, lessThan(DriftGuard.minLetterLessons));
  });
}
