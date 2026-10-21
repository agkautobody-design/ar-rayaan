import 'dart:math';

import 'package:ar_rayaan/app/core/notifications/notification_ids.dart';
import 'package:ar_rayaan/app/core/notifications/prayer_notification_scheduler.dart';
import 'package:ar_rayaan/features/academy/domain/academy_entry.dart';
import 'package:ar_rayaan/features/academy/domain/academy_models.dart';
import 'package:ar_rayaan/features/academy/domain/academy_reminders.dart';
import 'package:ar_rayaan/features/academy/domain/assessment_engine.dart';
import 'package:ar_rayaan/features/academy/domain/dhikr_session.dart';
import 'package:ar_rayaan/features/academy/domain/glossary.dart';
import 'package:ar_rayaan/features/academy/domain/hifz_progress.dart';
import 'package:ar_rayaan/features/academy/domain/lesson_grounding.dart';
import 'package:ar_rayaan/features/academy/domain/letter_drills.dart';
import 'package:ar_rayaan/features/academy/domain/review_questions.dart';
import 'package:ar_rayaan/features/academy/domain/spaced_repetition.dart';
import 'package:flutter_test/flutter_test.dart';

const List<LetterCardInfo> _alphabet = <LetterCardInfo>[
  LetterCardInfo('ا', 'Alif'),
  LetterCardInfo('ب', 'Ba'),
  LetterCardInfo('ت', 'Ta'),
  LetterCardInfo('ث', 'Tha'),
  LetterCardInfo('ج', 'Jim'),
];

void main() {
  group('review questions', () {
    test('a letter review asks name from shape and shape from name', () {
      final List<ReviewQuestion> qs = letterReviewQuestions(
        lessonId: 'letters-02',
        alphabet: _alphabet,
        index: 1,
      );
      expect(qs.length, 2);
      for (final ReviewQuestion q in qs) {
        expect(q.isValid, isTrue);
        expect(q.options.length, 3);
      }
      expect(qs[0].glyph, 'ب');
      expect(qs[0].options[qs[0].answer], 'Ba');
      expect(qs[1].options[qs[1].answer], 'ب');
    });

    test('the same inputs give the same questions', () {
      List<String> flat(int round) => <String>[
            for (final ReviewQuestion q in letterReviewQuestions(
              lessonId: 'letters-03',
              alphabet: _alphabet,
              index: 2,
              round: round,
            ))
              ...q.options,
          ];
      expect(flat(0), flat(0));
    });

    test('an index outside the alphabet asks nothing', () {
      expect(
        letterReviewQuestions(
          lessonId: 'x',
          alphabet: _alphabet,
          index: 9,
        ),
        isEmpty,
      );
    });

    test('grading: all right is good, any miss or nothing is again', () {
      expect(gradeForAnswers(<bool>[true, true]), ReviewGrade.good);
      expect(gradeForAnswers(<bool>[true, false]), ReviewGrade.again);
      expect(gradeForAnswers(<bool>[]), ReviewGrade.again);
    });

    test('a manifest check keeps its answer when shuffled', () {
      const AssessmentItem item = AssessmentItem(
        id: 'a',
        promptKey: 'Which is first?',
        choices: <String>['one', 'two', 'three'],
        correctIndex: 1,
        reteachKey: 'Because.',
        literal: true,
      );
      final ReviewQuestion q =
          ReviewQuestion.fromAssessment(item, (String k) => 'X$k');
      expect(q.prompt, 'Which is first?');
      expect(q.options[q.answer], 'two');
      for (int seed = 0; seed < 8; seed++) {
        final ReviewQuestion s = q.shuffled(Random(seed));
        expect(s.options[s.answer], 'two');
      }
    });
  });

  group('glossary', () {
    test('finds whole words only, any case, every occurrence', () {
      final List<GlossaryMatch> m =
          findGlossaryTerms('Riba is forbidden. Zakatable? No. RIBA again.');
      expect(m.map((GlossaryMatch e) => e.entry.term).toList(),
          <String>['riba', 'riba']);
    });

    test('finds aliases and does not overlap', () {
      final List<GlossaryEntry> e = glossaryEntriesIn('Zakah and zakat.');
      expect(e.length, 1);
      expect(e.first.term, 'zakat');
    });

    test('every definition is short and unchanged by lookup', () {
      for (final GlossaryEntry g in kGlossary) {
        expect(g.definition.length, lessThan(220));
        expect(g.definition.trim(), isNotEmpty);
      }
    });
  });

  group('lesson grounding', () {
    const String lesson = 'Tawaf is walking around the Kaaba seven times. '
        'It is done in Hajj and in Umrah. The pilgrim begins at the Black '
        'Stone. See Qur’an 2:158 for the hills of Safa and Marwah.';

    test('answers from the lesson only, prefixed', () {
      final String? a = LessonAnswerer.answer('How many times is tawaf?', lesson);
      expect(a, isNotNull);
      expect(a!.startsWith('From this lesson: '), isTrue);
      expect(a.contains('seven times'), isTrue);
    });

    test('says nothing when the lesson does not cover it', () {
      expect(LessonAnswerer.answer('What is the price of gold?', lesson),
          isNull);
    });

    test('verifier removes a hadith reference the lesson lacks', () {
      final VerifiedWasiaAnswer v = WasiaAnswerVerifier.verify(
        'Tawaf is seven rounds (Sahih Bukhari 1234).',
        lesson,
      );
      expect(v.changed, isTrue);
      expect(v.text.contains('1234'), isFalse);
    });

    test('verifier keeps a verse the lesson names and drops another', () {
      final VerifiedWasiaAnswer keep =
          WasiaAnswerVerifier.verify('See Qur’an 2:158.', lesson);
      expect(keep.changed, isFalse);
      final VerifiedWasiaAnswer drop =
          WasiaAnswerVerifier.verify('See Qur’an 3:97.', lesson);
      expect(drop.changed, isTrue);
      expect(drop.text.contains('3:97'), isFalse);
    });

    test('a time of day is not a verse reference', () {
      final VerifiedWasiaAnswer v =
          WasiaAnswerVerifier.verify('Come at 10:30 for tawaf.', lesson);
      expect(v.changed, isFalse);
    });

    test('plain lesson-grounded text passes untouched', () {
      final VerifiedWasiaAnswer v = WasiaAnswerVerifier.verify(
        'Tawaf is walking around the Kaaba seven times.',
        lesson,
      );
      expect(v.changed, isFalse);
    });
  });

  group('entry, tracks and routes', () {
    test('door prefs round trip and unknown is null', () {
      for (final AcademyDoor d in AcademyDoor.values) {
        expect(doorFromPref(d.prefValue), d);
      }
      expect(doorFromPref('nope'), isNull);
      expect(doorFromPref(null), isNull);
    });

    test('doors set the matching track; returning leaves it', () {
      expect(AcademyDoor.myChild.track, 'child');
      expect(AcademyDoor.newToIslam.track, 'teen');
      expect(AcademyDoor.returning.track, isNull);
      expect(AcademyDoor.returning.route, isNull);
      expect(AcademyDoor.myChild.route, '/academy/letters');
    });

    test('onboarding need suggests a door', () {
      expect(suggestedDoor('new'), AcademyDoor.newToIslam);
      expect(suggestedDoor('children'), AcademyDoor.myChild);
      expect(suggestedDoor('other'), isNull);
    });

    test('the switch changes the layout', () {
      expect(TrackLayout.of('child').lettersFirst, isTrue);
      expect(TrackLayout.of('child').simpleCopy, isTrue);
      expect(TrackLayout.of('child').foldSchools, isTrue);
      expect(TrackLayout.of('parent').familyCard, isTrue);
      expect(TrackLayout.of('teen').lettersFirst, isFalse);
    });

    test('first unfinished letter lesson', () {
      expect(
        firstUnfinishedLetterLesson(
          <String>['a', 'b', 'c'],
          <String, LessonProgress>{},
        ),
        'a',
      );
    });

    test('every school page maps to a course and keeps its static link', () {
      for (final MapEntry<String, String> e in kSchoolRouteToCourse.entries) {
        expect(courseRoute(e.value), '/academy/course/${e.value}');
        expect(staticLinkFor(e.value)!.route, e.key);
      }
      expect(staticLinkFor('the-path'), isNull);
    });
  });

  group('hifz progress', () {
    test('adjacent and overlapping ranges merge', () {
      expect(
        mergeRanges(<AyahRange>[
          const AyahRange(5, 8),
          const AyahRange(1, 4),
          const AyahRange(7, 10),
        ]),
        <AyahRange>[const AyahRange(1, 10)],
      );
    });

    test('add, count, remove and round trip', () {
      HifzState s = const HifzState().withPlan(surah: 1, daily: 2);
      s = s.addRange(1, 1, 3).addRange(1, 5, 6);
      expect(s.memorisedIn(1), 5);
      expect(s.totalMemorised, 5);
      expect(s.remainingInTarget, 2);
      final HifzState back = HifzState.decode(s.encode());
      expect(back.memorisedIn(1), 5);
      expect(back.targetSurah, 1);
      expect(back.dailyNewAyat, 2);
      expect(s.removeRange(1, 0).memorisedIn(1), 2);
    });

    test('impossible ranges are ignored and bad data reads as empty', () {
      final HifzState s = const HifzState().addRange(1, 1, 99);
      expect(s.totalMemorised, 0);
      expect(HifzState.decode('{not json').totalMemorised, 0);
      expect(HifzState.decode(null).targetSurah, 18);
    });
  });

  group('dhikr snapshot', () {
    final DateTime now = DateTime(2026, 3, 4, 10);
    const DhikrSet big = DhikrSet(
      id: 'istighfar',
      arabic: 'x',
      meaning: 'y',
      target: 100,
    );

    test('only a started, unfinished count is saved', () {
      expect(DhikrSnapshot.encode(DhikrSessionEngine.reset(big), now), isNull);
    });

    test('restores the same day and not the next', () {
      DhikrSessionState s = DhikrSessionEngine.reset(DhikrSet.classics.last);
      for (int i = 0; i < 10; i++) {
        s = DhikrSessionEngine.tap(s);
      }
      final String? raw = DhikrSnapshot.encode(s, now);
      expect(raw, isNotNull);
      expect(DhikrSnapshot.decode(raw, now)!.count, 10);
      expect(DhikrSnapshot.decode(raw, now.add(const Duration(days: 1))),
          isNull);
      expect(DhikrSnapshot.decode('garbage', now), isNull);
    });
  });

  group('reminders', () {
    final DateTime now = DateTime(2026, 3, 4, 10);

    test('off by default: nothing is planned', () {
      expect(
        planAcademyReminders(
          now: now,
          settings: const AcademyReminderSettings(),
          reviewsWaiting: true,
        ),
        isEmpty,
      );
      expect(AcademyReminderSettings.decode(null).any, isFalse);
    });

    test('one a day at the chosen time for the window', () {
      final List<AcademyReminder> p = planAcademyReminders(
        now: now,
        settings: const AcademyReminderSettings(lesson: true, hour: 18),
        reviewsWaiting: false,
      );
      expect(p.length, kAcademyReminderDays);
      expect(p.first.at, DateTime(2026, 3, 4, 18));
      expect(p.map((AcademyReminder r) => r.dayOffset).toSet().length,
          kAcademyReminderDays);
    });

    test('a time already past today is skipped', () {
      final List<AcademyReminder> p = planAcademyReminders(
        now: now,
        settings: const AcademyReminderSettings(lesson: true, hour: 8),
        reviewsWaiting: false,
      );
      expect(p.length, kAcademyReminderDays - 1);
      expect(p.first.dayOffset, 1);
    });

    test('reviews alone plan nothing while the queue is empty', () {
      const AcademyReminderSettings s = AcademyReminderSettings(reviews: true);
      expect(planAcademyReminders(now: now, settings: s, reviewsWaiting: false),
          isEmpty);
      expect(planAcademyReminders(now: now, settings: s, reviewsWaiting: true),
          isNotEmpty);
    });

    test('settings round trip; garbage reads as all off', () {
      const AcademyReminderSettings s = AcademyReminderSettings(
        lesson: true,
        reviews: true,
        hour: 6,
        minute: 45,
      );
      final AcademyReminderSettings b = AcademyReminderSettings.decode(
        s.encode(),
      );
      expect(b.lesson, isTrue);
      expect(b.reviews, isTrue);
      expect(b.hour, 6);
      expect(b.minute, 45);
      expect(AcademyReminderSettings.decode('[1]').any, isFalse);
    });

    test('the copy carries no count, streak or child', () {
      for (final bool l in <bool>[true, false]) {
        final String body = academyReminderBody(lesson: l, reviews: !l);
        expect(RegExp(r'\d').hasMatch(body), isFalse);
        expect(body.toLowerCase().contains('streak'), isFalse);
        expect(body.toLowerCase().contains('missed'), isFalse);
      }
    });

    test('academy ids sit above the zakat/reminder block and apart', () {
      final int first = kAcademyReminderIdBase;
      final int last = kAcademyReminderIdBase + kAcademyReminderDays - 1;
      expect(isAcademyReminderId(first), isTrue);
      expect(isAcademyReminderId(last), isTrue);
      expect(isReminderId(first), isFalse);
      expect(isReminderId(kReminderIdBase + 1), isTrue);
      expect(isAcademyReminderId(kReminderIdBase + 1), isFalse);
    });
  });
}
