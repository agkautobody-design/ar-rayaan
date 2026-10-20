import 'dart:io';

import 'package:ar_rayaan/features/academy/application/academy_strings.dart';
import 'package:ar_rayaan/features/academy/application/recall_checks.dart';
import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
import 'package:ar_rayaan/features/academy/domain/course_manifest.dart';
import 'package:ar_rayaan/features/academy/domain/lesson_provenance.dart';
import 'package:flutter_test/flutter_test.dart';

/// CI gate: lesson provenance and review status.
///
///  * every manifest lesson has a provenance entry (and no entry is orphaned)
///  * no lesson claims scholar review without a named reviewer and a date
///  * every Qur'an reference a lesson cites exists
///  * the words "scholar-reviewed" only ever appear as "Not yet ..."
void main() {
  final List<AcademyLesson> lessons = <AcademyLesson>[
    for (final AcademyCourse c in kAcademyCourses)
      for (final AcademyUnit u in c.units) ...u.lessons,
  ];

  group('lesson provenance', () {
    test('there are lessons to check, with unique ids', () {
      expect(lessons.length, 146);
      expect(lessons.map((AcademyLesson l) => l.id).toSet().length,
          lessons.length);
    });

    test('every manifest lesson has a provenance entry, and none is orphaned',
        () {
      final Set<String> ids =
          lessons.map((AcademyLesson l) => l.id).toSet();
      final Set<String> have = kLessonProvenance.keys.toSet();
      expect(ids.difference(have), isEmpty,
          reason: 'lessons without provenance');
      expect(have.difference(ids), isEmpty,
          reason: 'provenance for lessons that do not exist');
    });

    test('every entry has an origin and a coherent review status', () {
      for (final MapEntry<String, LessonProvenance> e
          in kLessonProvenance.entries) {
        final LessonProvenance p = e.value;
        expect(p.origin.trim(), isNotEmpty, reason: e.key);
        expect(p.version, greaterThanOrEqualTo(1), reason: e.key);
        if (p.status == LessonReviewStatus.scholarReviewed) {
          expect(p.reviewer?.trim() ?? '', isNotEmpty,
              reason: '${e.key} claims review but names no reviewer');
          expect(
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(p.reviewedOn ?? ''),
            isTrue,
            reason: '${e.key} claims review but has no review date',
          );
          expect(p.label, startsWith('Reviewed by '));
        } else {
          expect(p.label, kNotYetReviewedLabel, reason: e.key);
          expect(p.reviewer, isNull, reason: e.key);
        }
      }
    });

    test('today no lesson is marked scholar-reviewed (no reviewer exists)',
        () {
      // Flip this deliberately, with a named reviewer, when a review happens.
      expect(
        kLessonProvenance.values.every((LessonProvenance p) =>
            p.status == LessonReviewStatus.notYetScholarReviewed),
        isTrue,
      );
    });

    test('every Qur’an reference a lesson cites exists', () {
      int checked = 0;
      for (final AcademyLesson l in lessons) {
        for (final LessonSource s
            in extractSources(RecallChecks.fullTextOf(l))) {
          if (s.kind != 'quran') continue;
          checked++;
          expect(quranRefValid(s.ref), isTrue,
              reason: '${l.id} cites ${s.ref}');
        }
      }
      expect(checked, greaterThan(50));
    });

    test('hadith references are read from the text, with book and number',
        () {
      final List<LessonSource> s = extractSources(
          'He said (Bukhari 1903) and also Muslim 223; see 2:183 and 9:60-61.');
      expect(s, <LessonSource>[
        const LessonSource(kind: 'quran', ref: '2:183'),
        const LessonSource(kind: 'quran', ref: '9:60-61'),
        const LessonSource(kind: 'hadith', ref: 'Bukhari 1903'),
        const LessonSource(kind: 'hadith', ref: 'Muslim 223'),
      ]);
    });

    test('quranRefValid rejects impossible references', () {
      expect(quranRefValid('2:286'), isTrue);
      expect(quranRefValid('2:287'), isFalse);
      expect(quranRefValid('115:1'), isFalse);
      expect(quranRefValid('0:1'), isFalse);
      expect(quranRefValid('9:61-60'), isFalse);
      expect(quranRefValid('1:1-7'), isTrue);
      expect(quranRefValid('1:1–7'), isTrue);
    });

    test('lesson titles resolve (no raw keys leak into the UI)', () {
      for (final AcademyLesson l in lessons) {
        expect(AcademyStrings.get(l.titleKey), isNot(l.titleKey),
            reason: l.id);
      }
    });
  });

  group('review-claim wording', () {
    test('"scholar-reviewed" only appears as "Not yet scholar-reviewed"', () {
      final List<String> roots = <String>[
        'lib/features/academy',
        'lib/features/games',
        'lib/features/family',
        'lib/features/journey',
        'lib/features/profile',
        'lib/features/onboarding',
        'assets/academy',
        'assets/games',
        'assets/qa',
      ];
      final List<String> offenders = <String>[];
      for (final String r in roots) {
        final Directory d = Directory(r);
        if (!d.existsSync()) continue;
        for (final FileSystemEntity f in d.listSync(recursive: true)) {
          if (f is! File) continue;
          if (!(f.path.endsWith('.dart') || f.path.endsWith('.json'))) {
            continue;
          }
          // The provenance model documents the rule itself.
          if (f.path.endsWith('lesson_provenance.dart')) continue;
          final String text = f.readAsStringSync().toLowerCase();
          int at = text.indexOf('scholar-reviewed');
          while (at >= 0) {
            final String before =
                text.substring(at < 8 ? 0 : at - 8, at);
            if (!before.endsWith('not yet ')) offenders.add(f.path);
            at = text.indexOf('scholar-reviewed', at + 1);
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
