/// Questions asked during a review, and how their answers become a grade.
///
/// A lesson in the review queue used to be graded by the learner alone ("say
/// aloud what this lesson taught", then four buttons). FSRS is only as good
/// as honest retrieval, so a review now asks the lesson's OWN question and
/// grades the answer itself:
///  * a manifest lesson asks the check it already ends with (hand-written or
///    generated), see [ReviewQuestion.fromAssessment];
///  * a School of Letters lesson for one letter asks about THAT letter: its
///    name from its shape and its shape from its name, see
///    [letterReviewQuestions];
///  * the vowel / sukun / shaddah / joining lessons ask their own quiz steps.
///
/// A lesson with no question of its own keeps the self-grade (the screen
/// says so); nothing here invents a question.
///
/// Pure Dart, deterministic (seeded), so tests can pin it.
library;

import 'dart:math';

import 'assessment_engine.dart';
import 'letter_drills.dart';
import 'recall_check.dart';
import 'spaced_repetition.dart';

/// One multiple-choice question in a review.
class ReviewQuestion {
  const ReviewQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.why,
    this.glyph,
  });

  final String prompt;

  /// A big letter shown above the options (shape to name questions).
  final String? glyph;
  final List<String> options;

  /// Index into [options] of the right choice.
  final int answer;

  /// Shown after the learner answers: why the right choice is right.
  final String why;

  /// True when there are at least two choices and [answer] points at one.
  bool get isValid =>
      options.length >= 2 && answer >= 0 && answer < options.length;

  /// A manifest check item. [text] resolves a string key (AcademyStrings.get);
  /// generated recall checks carry their text and are used as is.
  factory ReviewQuestion.fromAssessment(
    AssessmentItem item,
    String Function(String key) text,
  ) {
    String label(String s) => item.literal ? s : text(s);
    return ReviewQuestion(
      prompt: label(item.promptKey),
      options: <String>[for (final String c in item.choices) label(c)],
      answer: item.correctIndex,
      why: label(item.reteachKey),
    );
  }

  /// The same question with its choices in another (seeded) order, so a
  /// learner cannot pass a later review by remembering a position.
  ReviewQuestion shuffled(Random rng) {
    final List<int> order = List<int>.generate(options.length, (int i) => i)
      ..shuffle(rng);
    return ReviewQuestion(
      prompt: prompt,
      glyph: glyph,
      options: <String>[for (final int i in order) options[i]],
      answer: order.indexOf(answer),
      why: why,
    );
  }
}

/// The FSRS grade for a finished review.
///
/// Every question right at the first pick is [ReviewGrade.good]. Any miss is
/// [ReviewGrade.again]: the lesson comes back soon. There is no automatic
/// "easy" (effortless recall cannot be measured by a tap) and no automatic
/// "hard". Never a fail state on screen: "again" only schedules sooner.
ReviewGrade gradeForAnswers(List<bool> correctAtFirstPick) {
  if (correctAtFirstPick.isEmpty) return ReviewGrade.again;
  return correctAtFirstPick.every((bool c) => c)
      ? ReviewGrade.good
      : ReviewGrade.again;
}

/// Two questions about one letter of the alphabet: its name from its shape,
/// and its shape from its name. [alphabet] is the 28 letters in lesson order
/// and [index] the letter being reviewed. [round] changes the order of the
/// choices (and which other letters are offered) from one review to the next.
List<ReviewQuestion> letterReviewQuestions({
  required String lessonId,
  required List<LetterCardInfo> alphabet,
  required int index,
  int round = 0,
}) {
  if (index < 0 || index >= alphabet.length || alphabet.length < 3) {
    return const <ReviewQuestion>[];
  }
  final Random rng =
      Random(RecallCheckBuilder.seedOf('$lessonId#review#$round'));
  final LetterCardInfo letter = alphabet[index];

  List<LetterCardInfo> others() {
    final List<LetterCardInfo> pool = <LetterCardInfo>[
      for (final LetterCardInfo c in alphabet)
        if (c.arabic != letter.arabic && c.name != letter.name) c,
    ]..shuffle(rng);
    return pool.take(2).toList();
  }

  ({List<String> options, int answer}) place(
      String correct, List<String> wrong) {
    final int at = rng.nextInt(wrong.length + 1);
    return (
      options: <String>[...wrong.take(at), correct, ...wrong.skip(at)],
      answer: at,
    );
  }

  final ({List<String> options, int answer}) byShape = place(
    letter.name,
    <String>[for (final LetterCardInfo o in others()) o.name],
  );
  final ({List<String> options, int answer}) byName = place(
    letter.arabic,
    <String>[for (final LetterCardInfo o in others()) o.arabic],
  );
  return <ReviewQuestion>[
    ReviewQuestion(
      prompt: 'What is this letter called?',
      glyph: letter.arabic,
      options: byShape.options,
      answer: byShape.answer,
      why: 'This is ${letter.name} — ${letter.arabic}.',
    ),
    ReviewQuestion(
      prompt: 'Which one is ${letter.name}?',
      options: byName.options,
      answer: byName.answer,
      why: '${letter.name} is ${letter.arabic}.',
    ),
  ];
}
