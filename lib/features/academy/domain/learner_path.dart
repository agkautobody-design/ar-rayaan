/// Where a learner is, and what Wasia suggests next.
///
/// Pure Dart. Built from what the research on learning apps agrees on:
///  * the learner (or, for a child, the parent) says where they start; a true
///    beginner is never made to sit a test (Duolingo, Khan Academy Kids);
///  * the path adjusts both ways: "too hard" gets a smaller step and "too easy"
///    gets a bigger one (Khan Academy Kids lets a parent move the level);
///  * the learner chooses (autonomy) and is shown a small next step
///    (competence), never a streak to lose or a score to beat;
///  * a family learns together at different levels, with a short activity per
///    age band that needs no screen (co-play research).
///
/// PRIVACY: everything here runs on the device from numbers the Academy
/// already keeps there. None of it is put in a prompt or sent anywhere. No
/// religious claim is made in this file: it only points at schools and
/// lessons the Academy already has.
library;

/// The three starting points a learner can pick. Changeable at any time.
enum LearnerLevel { fresh, basics, deeper }

const String kLearnerLevelPref = 'ar.academy.level.v1';

extension LearnerLevelX on LearnerLevel {
  String get prefValue => switch (this) {
        LearnerLevel.fresh => 'fresh',
        LearnerLevel.basics => 'basics',
        LearnerLevel.deeper => 'deeper',
      };

  /// Words on the chip.
  String get label => switch (this) {
        LearnerLevel.fresh => 'Brand new',
        LearnerLevel.basics => 'I know the basics',
        LearnerLevel.deeper => 'I want to go deeper',
      };

  /// One line under the chip.
  String get blurb => switch (this) {
        LearnerLevel.fresh => 'Start from the very beginning, one small step at a time.',
        LearnerLevel.basics => 'Skip the first steps. Fill gaps and build on what you have.',
        LearnerLevel.deeper => 'Study, understand and memorise. Everything is open.',
      };
}

LearnerLevel? learnerLevelFromPref(String? v) {
  for (final LearnerLevel l in LearnerLevel.values) {
    if (l.prefValue == v) return l;
  }
  return null;
}

/// A place in the Academy.
class PathStop {
  const PathStop(this.title, this.why, this.route);
  final String title;
  final String why;
  final String route;
}

const PathStop _path = PathStop('The Path',
    'Short lessons that build one on another, from the beginning.', '/academy/course/the-path');
const PathStop _letters = PathStop('School of Letters',
    'The Arabic letters and how they sound, a few minutes at a time.', '/academy/letters');
const PathStop _duas = PathStop('Daily Duas',
    'Short words you can use today, with the Arabic and the meaning.', '/academy/dua');
const PathStop _arabic = PathStop('Arabic Language',
    'Build words and understanding on top of the letters.', '/academy/arabic-language');
const PathStop _understanding = PathStop('Understanding the Qur’an',
    'Learn what the words mean, not only how they sound.', '/academy/understanding');
const PathStop _hifz = PathStop('Hifz Planner',
    'A small daily plan for memorising, with review built in.', '/academy/hifz');
const PathStop _character = PathStop('Character',
    'Everyday manners and kindness, in short lessons.', '/academy/character');
const PathStop _hadith = PathStop('Hadith School',
    'Study the sayings of the Prophet ﷺ, with their sources named.', '/academy/hadith');

/// Three schools to start with, for a level. Never more than three: a long
/// menu is what makes an app feel like a chore.
List<PathStop> startHere(LearnerLevel level) => switch (level) {
      LearnerLevel.fresh => <PathStop>[_path, _letters, _duas],
      LearnerLevel.basics => <PathStop>[_arabic, _duas, _character],
      LearnerLevel.deeper => <PathStop>[_understanding, _hifz, _hadith],
    };

/// What the learner has done, from numbers the Academy keeps on the device.
class LearnerSnapshot {
  const LearnerSnapshot({
    this.level,
    this.lessonsDone = 0,
    this.lettersDone = 0,
    this.lettersTotal = 40,
    this.reviewsDue = 0,
    this.childBand,
    this.nextLessonTitle,
    this.nextLessonRoute,
  });

  /// Null until the learner has said.
  final LearnerLevel? level;
  final int lessonsDone;
  final int lettersDone;
  final int lettersTotal;
  final int reviewsDue;

  /// '5-8', '9-12', '13-17' when a child is learning; null for a grown-up.
  final String? childBand;
  final String? nextLessonTitle;
  final String? nextLessonRoute;

  bool get isChild => childBand != null;
  bool get lettersFinished => lettersTotal > 0 && lettersDone >= lettersTotal;
}

/// What a learner can ask Wasia about their own journey.
enum CoachAsk {
  whatNext,
  whereAmI,
  iAmNew,
  iKnowBasics,
  goDeeper,
  tooHard,
  tooEasy,
  boredOrTired,
}

/// One suggestion: words, plus a place to go (null = nothing to open).
class CoachReply {
  const CoachReply(this.text, {this.route, this.routeLabel, this.setLevel});
  final String text;
  final String? route;
  final String? routeLabel;

  /// When the learner told Wasia their level in words, the level to save.
  final LearnerLevel? setLevel;
}

class LearnerCoach {
  const LearnerCoach._();

  static String _n(String q) => q
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final RegExp _next = RegExp(
      r'\b(what (should|do|can|shall) i (do|learn|study|start|try|work on)( next| now| today)?|what (is|s) next|what next|where (do|should|can) i (start|begin|go)|what now|i dont know where to start|where to start|what should we (do|learn)|what is my next)\b');
  static final RegExp _where = RegExp(
      r'\b(where am i|how am i doing|how far (am i|have i)|my progress|how much (have i|did i) (done|learned|finished)|have i done enough|am i doing (ok|okay|well|good))\b');
  static final RegExp _new = RegExp(
      r'\b(i am (brand )?new|im (brand )?new|i (know|have) nothing|i know (nothing|zero)|complete beginner|total beginner|absolute beginner|never (learned|learnt|studied)|from scratch|from the beginning|new to (islam|arabic|this|quran))\b');
  static final RegExp _basics = RegExp(
      r'\b(i know (some|a little|the basics|a bit)|i already know (some|the basics|a little)|know the basics|some experience|a bit of experience|intermediate)\b');
  static final RegExp _deeper = RegExp(
      r'\b(go deeper|more advanced|something advanced|advanced|i know (a lot|plenty|the letters|how to read)|i can already read|i want more|harder stuff|challenge me|i want to study)\b');
  static final RegExp _hard = RegExp(
      r'\b(too hard|too difficult|so hard|its hard|that is hard|i cant do (this|it)|im lost|i am lost|too fast|going too fast|struggling|i am struggling|im struggling|confusing|so confusing)\b');
  static final RegExp _easy = RegExp(
      r'\b(too easy|so easy|its easy|already know (this|that|it)|i know this|know this already|too simple|boring and easy|i want something harder|something harder|more difficult)\b');
  static final RegExp _bored = RegExp(
      r'\b(im bored|i am bored|bored|so boring|i am tired|im tired|dont feel like|do not feel like|not in the mood|no motivation|cant be bothered|lost interest|dont want to (study|learn|do)|do not want to (study|learn|do))\b');

  /// Which coaching question this is, or null. Conservative on purpose: a
  /// religious or lesson question must never be taken for a coaching one.
  static CoachAsk? classify(String question) {
    final String n = _n(question);
    if (n.isEmpty || n.split(' ').length > 14) return null;
    if (_easy.hasMatch(n)) return CoachAsk.tooEasy;
    if (_hard.hasMatch(n)) return CoachAsk.tooHard;
    if (_new.hasMatch(n)) return CoachAsk.iAmNew;
    if (_basics.hasMatch(n)) return CoachAsk.iKnowBasics;
    if (_deeper.hasMatch(n)) return CoachAsk.goDeeper;
    if (_bored.hasMatch(n)) return CoachAsk.boredOrTired;
    if (_where.hasMatch(n)) return CoachAsk.whereAmI;
    if (_next.hasMatch(n)) return CoachAsk.whatNext;
    return null;
  }

  /// The single next step for this learner. One thing, not a menu.
  static PathStop nextStep(LearnerSnapshot s) {
    if (s.reviewsDue > 0 && s.lessonsDone > 0) {
      return PathStop(
        'A short review',
        '${s.reviewsDue} ${s.reviewsDue == 1 ? 'thing is' : 'things are'} ready to go over. It takes a few minutes and makes it stick.',
        '/academy/review',
      );
    }
    if (s.nextLessonTitle != null && s.nextLessonRoute != null && s.lessonsDone > 0) {
      return PathStop(s.nextLessonTitle!, 'Your next lesson, where you left off.',
          s.nextLessonRoute!);
    }
    if (s.isChild) {
      return s.lettersFinished
          ? _duas
          : PathStop('The next letter lesson',
              'A few minutes, then you are done.', '/academy/letters');
    }
    final LearnerLevel level = s.level ?? LearnerLevel.fresh;
    if (s.lessonsDone == 0 || s.nextLessonTitle == null) {
      return startHere(level).first;
    }
    return PathStop(s.nextLessonTitle!, 'Your next lesson.',
        s.nextLessonRoute ?? '/academy/course/the-path');
  }

  static CoachReply reply(CoachAsk ask, LearnerSnapshot s) {
    switch (ask) {
      case CoachAsk.whatNext:
        final PathStop p = nextStep(s);
        return CoachReply('${p.title}. ${p.why}\n\nJust this one. When it is done, ask me again.',
            route: p.route, routeLabel: 'Open ${p.title}');
      case CoachAsk.whereAmI:
        return CoachReply(_where_(s), route: nextStep(s).route, routeLabel: 'Next step');
      case CoachAsk.iAmNew:
        final List<PathStop> t = startHere(LearnerLevel.fresh);
        return CoachReply(
            'Welcome. Nobody starts as an expert, and you do not need a test. '
            'I will keep it small: begin with ${t.first.title}. ${t.first.why} '
            'Anything else can wait.',
            route: t.first.route,
            routeLabel: 'Begin',
            setLevel: LearnerLevel.fresh);
      case CoachAsk.iKnowBasics:
        final List<PathStop> t = startHere(LearnerLevel.basics);
        return CoachReply(
            'Good. Then we skip the first steps. Try ${t.first.title}: ${t.first.why} '
            'If it feels too easy, tell me and I will move you on; if it is too hard, I will go back a step.',
            route: t.first.route,
            routeLabel: 'Open ${t.first.title}',
            setLevel: LearnerLevel.basics);
      case CoachAsk.goDeeper:
        final List<PathStop> t = startHere(LearnerLevel.deeper);
        return CoachReply(
            'Everything is open to you. A good place to go deeper is ${t.first.title}: ${t.first.why} '
            'You can also pick ${t[1].title} or ${t[2].title}.',
            route: t.first.route,
            routeLabel: 'Open ${t.first.title}',
            setLevel: LearnerLevel.deeper);
      case CoachAsk.tooHard:
        return CoachReply(
            'That is not you failing, it means the step is too big. Let us make it smaller. '
            'Go back one lesson and go over it slowly, or ask me about just the one part that is unclear. '
            'There is no clock and nothing is marked wrong.',
            route: s.isChild || s.level == LearnerLevel.fresh || s.level == null
                ? '/academy/letters'
                : '/academy/review',
            routeLabel: 'Go back a step');
      case CoachAsk.tooEasy:
        final PathStop p = s.isChild
            ? _duas
            : startHere(
                s.level == LearnerLevel.fresh || s.level == null
                    ? LearnerLevel.basics
                    : LearnerLevel.deeper,
              ).first;
        return CoachReply(
            'Then you are ready for more. Try ${p.title}: ${p.why} '
            'You can always come back.',
            route: p.route,
            routeLabel: 'Open ${p.title}',
            setLevel: s.isChild
                ? null
                : (s.level == LearnerLevel.fresh || s.level == null
                    ? LearnerLevel.basics
                    : LearnerLevel.deeper));
      case CoachAsk.boredOrTired:
        return CoachReply(
            'That is fine. Learning is not a chore, so do the smallest thing: one short review, '
            'or just listen to a few verses, then stop. Come back when you want to. Nothing is lost.',
            route: s.reviewsDue > 0 ? '/academy/review' : null,
            routeLabel: s.reviewsDue > 0 ? 'One short review' : null);
    }
  }

  static String _where_(LearnerSnapshot s) {
    final StringBuffer b = StringBuffer();
    if (s.lessonsDone == 0) {
      b.write('You are at the start, and that is a good place to be. ');
    } else {
      b.write('You have finished ${s.lessonsDone} ${s.lessonsDone == 1 ? 'lesson' : 'lessons'}. ');
    }
    if (s.lettersDone > 0) {
      b.write('${s.lettersDone} of ${s.lettersTotal} letter lessons are done. ');
    }
    if (s.reviewsDue > 0) {
      b.write('${s.reviewsDue} ${s.reviewsDue == 1 ? 'review is' : 'reviews are'} ready, whenever you like. ');
    }
    final PathStop p = nextStep(s);
    b.write('A good next step: ${p.title}.');
    return b.toString();
  }
}

/// A short, screen-free activity for a family to do together, by the age band
/// of the child. [week] rotates the suggestion so it is not the same one
/// every time. Nothing here is a religious claim: it only gets people talking
/// and practising together.
class FamilyActivity {
  const FamilyActivity(this.title, this.body);
  final String title;
  final String body;
}

const Map<String, List<FamilyActivity>> _family = <String, List<FamilyActivity>>{
  '5-8': <FamilyActivity>[
    FamilyActivity('Teach me a letter',
        'Ask your child to teach you one letter they know, the way a teacher would. Say it wrong once and let them correct you.'),
    FamilyActivity('Letter hunt',
        'Pick one letter and look for it for five minutes: on a page, a sign, a mug. Whoever finds it says its name.'),
    FamilyActivity('Take turns',
        'Open the next letter lesson and take turns, you then your child. Stop while it is still fun.'),
  ],
  '9-12': <FamilyActivity>[
    FamilyActivity('Two-minute teacher',
        'Your child explains what they learned this week in two minutes. You may ask one question, but not correct them.'),
    FamilyActivity('Learn together',
        'Pick a short lesson and do it side by side. Each of you says one thing you noticed.'),
    FamilyActivity('Quiz each other',
        'Take turns asking each other one review question from a lesson you both know. Keep no score.'),
  ],
  '13-17': <FamilyActivity>[
    FamilyActivity('Ask, do not test',
        'Ask one real question about something they are studying, and listen. The goal is their voice, not their score.'),
    FamilyActivity('Choose together',
        'Let them pick the school they want to explore this week. Your job is to be curious about their choice.'),
    FamilyActivity('Teach back',
        'Ask them to teach you one thing they learned that you did not know. Thank them for it.'),
  ],
  'adult': <FamilyActivity>[
    FamilyActivity('A shared five minutes',
        'Pick one short lesson and do it at the same time as your family, then say one thing you each noticed.'),
    FamilyActivity('Learn in front of them',
        'Children copy what they see. Let them see you learning, and say out loud when something is hard for you.'),
    FamilyActivity('Ask them',
        'Ask each person at home what they would like to learn next, and write the answers down.'),
  ],
};

FamilyActivity familyActivity(String band, {int week = 0}) {
  final List<FamilyActivity> l = _family[band] ?? _family['9-12']!;
  return l[week.abs() % l.length];
}

/// A line for a parent's card about one child. Honest about what the
/// Academy knows: lessons finished in the Letters school and exams taken.
String childSummaryLine({
  required int lettersDone,
  required int lettersTotal,
  required int exams,
}) {
  if (lettersDone == 0 && exams == 0) {
    return 'Not started yet. A first lesson takes a few minutes.';
  }
  if (lettersTotal > 0 && lettersDone >= lettersTotal) {
    return 'Finished every letter lesson. Time for a new challenge.';
  }
  final int left = lettersTotal - lettersDone;
  return '$lettersDone of $lettersTotal letter lessons done, $left to go.';
}
