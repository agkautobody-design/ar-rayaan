import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/academy/domain/learner_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parent-linked tracking summary', () {
    test('summary has counts, level inputs and no name', () {
      final Map<String, dynamic> s = FamilyService.cloudSummary(
        progress: <String, dynamic>{
          'lessons': <String, dynamic>{
            'a': <String, dynamic>{'at': '2026-11-10T10:00:00.000'},
            'b': <String, dynamic>{'at': '2026-11-12T10:00:00.000'},
          },
          'exams': <String, dynamic>{
            'x': <String, dynamic>{'at': '2026-11-11T10:00:00.000', 'score': 8, 'total': 10},
          },
          'mastery': <String, dynamic>{'a': 'mastered', 'b': 'met'},
        },
        lettersTotal: 40,
        surah: 67,
        ayah: 5,
      );
      expect(s['lessonsDone'], 2);
      expect(s['examsTaken'], 1);
      expect(s['bestPct'], 80);
      expect(s['masteredCount'], 1);
      expect(s['lastActiveAt'], '2026-11-12T10:00:00.000');
      expect(s['quran'], <String, dynamic>{'surah': 67, 'ayah': 5});
      expect(s.keys.any((String k) => k.toLowerCase().contains('name')), isFalse);
    });

    test('an empty child gives zeros and no last-active', () {
      final Map<String, dynamic> s = FamilyService.cloudSummary(
        progress: <String, dynamic>{},
        lettersTotal: 40,
      );
      expect(s['lessonsDone'], 0);
      expect(s.containsKey('lastActiveAt'), isFalse);
      expect(s.containsKey('quran'), isFalse);
    });

    test('level names move with progress', () {
      expect(childLevelName(lettersDone: 0, lettersTotal: 40, exams: 0), 'Just starting');
      expect(childLevelName(lettersDone: 5, lettersTotal: 40, exams: 0), 'Learning the letters');
      expect(childLevelName(lettersDone: 30, lettersTotal: 40, exams: 0), 'Nearly through the letters');
      expect(childLevelName(lettersDone: 40, lettersTotal: 40, exams: 0), 'Letters done, take the exam');
      expect(childLevelName(lettersDone: 40, lettersTotal: 40, exams: 1), 'Letters done, ready to read');
    });
  });
}
