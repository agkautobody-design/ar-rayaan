import 'package:flutter_test/flutter_test.dart';

import 'package:ar_rayaan/features/academy/domain/learner_path.dart';

CoachAsk? _c(String q) => LearnerCoach.classify(q);

void main() {
  group('classify: coaching questions', () {
    test('what next', () {
      for (final String q in <String>[
        'what should I do next?',
        'what should i learn today',
        'where do I start',
        'what next',
        "I don't know where to start",
      ]) {
        expect(_c(q) == CoachAsk.whatNext, isTrue, reason: q);
      }
    });
    test('where am I', () {
      expect(_c('how am I doing?') == CoachAsk.whereAmI, isTrue);
      expect(_c('where am I') == CoachAsk.whereAmI, isTrue);
      expect(_c('have I done enough') == CoachAsk.whereAmI, isTrue);
    });
    test('levels in words', () {
      expect(_c('I am brand new') == CoachAsk.iAmNew, isTrue);
      expect(_c("I'm a complete beginner") == CoachAsk.iAmNew, isTrue);
      expect(_c('I know the basics') == CoachAsk.iKnowBasics, isTrue);
      expect(_c('I know a little') == CoachAsk.iKnowBasics, isTrue);
      expect(_c('I want to go deeper') == CoachAsk.goDeeper, isTrue);
      expect(_c('challenge me') == CoachAsk.goDeeper, isTrue);
    });
    test('too hard, too easy, bored', () {
      expect(_c('this is too hard') == CoachAsk.tooHard, isTrue);
      expect(_c("I'm lost") == CoachAsk.tooHard, isTrue);
      expect(_c('this is too easy') == CoachAsk.tooEasy, isTrue);
      expect(_c('I already know this') == CoachAsk.tooEasy, isTrue);
      expect(_c("I'm bored") == CoachAsk.boredOrTired, isTrue);
      expect(_c('I am tired') == CoachAsk.boredOrTired, isTrue);
    });
    test('lesson and religious questions are never taken for coaching', () {
      for (final String q in <String>[
        'what is the first letter of the alphabet',
        'how do I make wudu',
        'is it obligatory to pray in the mosque',
        'what does alif sound like',
        'what is the meaning of bismillah',
        'why is the letter ba written with a dot below',
        'tell me the story of the prophet Yusuf and what happened next to him in the well',
      ]) {
        expect(_c(q) == null, isTrue, reason: q);
      }
    });
  });

  group('replies', () {
    const LearnerSnapshot fresh = LearnerSnapshot();
    test('a new learner is told no test is needed and is given one step', () {
      final CoachReply r = LearnerCoach.reply(CoachAsk.iAmNew, fresh);
      expect(r.text, contains('you do not need a test'));
      expect(r.route == '/academy/course/the-path', isTrue);
      expect(r.setLevel == LearnerLevel.fresh, isTrue);
    });
    test('what next with reviews due, and lessons done, goes to review', () {
      const LearnerSnapshot s = LearnerSnapshot(lessonsDone: 3, reviewsDue: 2);
      final CoachReply r = LearnerCoach.reply(CoachAsk.whatNext, s);
      expect(r.route == '/academy/review', isTrue);
      expect(r.text, contains('2 things are'));
    });
    test('what next for a child with letters left goes to the letters', () {
      const LearnerSnapshot s = LearnerSnapshot(childBand: '5-8', lettersDone: 4);
      final CoachReply r = LearnerCoach.reply(CoachAsk.whatNext, s);
      expect(r.route == '/academy/letters', isTrue);
    });
    test('what next after a lesson uses the learner\'s own next lesson', () {
      const LearnerSnapshot s = LearnerSnapshot(
        lessonsDone: 2,
        nextLessonTitle: 'Wudu',
        nextLessonRoute: '/academy/lesson/the-path/u1/l3',
      );
      final CoachReply r = LearnerCoach.reply(CoachAsk.whatNext, s);
      expect(r.route == '/academy/lesson/the-path/u1/l3', isTrue);
      expect(r.text, contains('Wudu'));
    });
    test('too hard shrinks the step and says nothing is marked wrong', () {
      final CoachReply r = LearnerCoach.reply(CoachAsk.tooHard, fresh);
      expect(r.text, contains('step is too big'));
      expect(r.text, contains('nothing is marked wrong'));
    });
    test('too easy moves a learner up one level', () {
      final CoachReply a = LearnerCoach.reply(CoachAsk.tooEasy, fresh);
      expect(a.setLevel == LearnerLevel.basics, isTrue);
      final CoachReply b = LearnerCoach.reply(
          CoachAsk.tooEasy, const LearnerSnapshot(level: LearnerLevel.basics));
      expect(b.setLevel == LearnerLevel.deeper, isTrue);
    });
    test('too easy never changes a child\'s level (the parent sets it)', () {
      final CoachReply r = LearnerCoach.reply(
          CoachAsk.tooEasy, const LearnerSnapshot(childBand: '9-12'));
      expect(r.setLevel == null, isTrue);
    });
    test('bored: smallest thing, no guilt, no streak talk', () {
      final CoachReply r = LearnerCoach.reply(CoachAsk.boredOrTired, fresh);
      expect(r.text, contains('Nothing is lost'));
      final String t = r.text.toLowerCase();
      for (final String bad in <String>['streak', 'you should', 'must', 'behind']) {
        expect(t.contains(bad), isFalse, reason: bad);
      }
    });
    test('where am I: honest numbers', () {
      const LearnerSnapshot s = LearnerSnapshot(lessonsDone: 1, lettersDone: 5, reviewsDue: 1);
      final String t = LearnerCoach.reply(CoachAsk.whereAmI, s).text;
      expect(t, contains('1 lesson.'));
      expect(t, contains('5 of 40 letter lessons'));
      expect(t, contains('1 review is'));
    });
  });

  group('start here and the family', () {
    test('never more than three schools, one set per level', () {
      for (final LearnerLevel l in LearnerLevel.values) {
        final int n = startHere(l).length;
        expect(n == 3, isTrue, reason: '$l has $n');
      }
    });
    test('every route is an Academy route', () {
      for (final LearnerLevel l in LearnerLevel.values) {
        for (final PathStop p in startHere(l)) {
          expect(p.route.startsWith('/academy/'), isTrue, reason: p.route);
        }
      }
    });
    test('level prefs round-trip', () {
      for (final LearnerLevel l in LearnerLevel.values) {
        expect(learnerLevelFromPref(l.prefValue) == l, isTrue);
      }
      expect(learnerLevelFromPref('x') == null, isTrue);
    });
    test('every age band has three activities that rotate', () {
      for (final String b in <String>['5-8', '9-12', '13-17', 'adult']) {
        final Set<String> seen = <String>{
          for (int w = 0; w < 6; w++) familyActivity(b, week: w).title,
        };
        expect(seen.length == 3, isTrue, reason: b);
      }
      expect(familyActivity('nope').title.isNotEmpty, isTrue);
    });
    test('child summary is honest and has no score wording', () {
      expect(childSummaryLine(lettersDone: 0, lettersTotal: 40, exams: 0),
          contains('Not started yet'));
      expect(childSummaryLine(lettersDone: 10, lettersTotal: 40, exams: 0),
          contains('10 of 40 letter lessons done, 30 to go'));
      expect(childSummaryLine(lettersDone: 40, lettersTotal: 40, exams: 1),
          contains('Finished every letter lesson'));
    });
  });
}
