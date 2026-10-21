/// Practice questions for the 28 letter lessons (units 1-4), built from the
/// lessons' own cards.
///
/// Those lessons used to end with one question, "Which letter did we meet
/// today?", answered by looking at the card two steps earlier, the same
/// question in all 28 lessons. [buildLetterDrills] replaces it with:
///  * today's letter, shape to name (what is this letter called?);
///  * an EARLIER letter, name to shape (spaced: it comes back after its own
///    lesson);
///  * a second earlier letter, shape to name (interleaved with today's).
///
/// There is no sound question: the app does not play letter recordings yet,
/// so a "which sound" question would have no sound to test.
///
/// Pure and deterministic (seeded by the lesson id), so the same lesson asks
/// the same questions every time and tests can pin them.
library;

import 'dart:math';

import 'recall_check.dart';

/// The old, trivial question these drills replace.
const String kTrivialLetterQuestion = 'Which letter did we meet today?';

class LetterCardInfo {
  const LetterCardInfo(this.arabic, this.name);

  final String arabic;
  final String name;
}

class LetterDrill {
  const LetterDrill({
    required this.question,
    required this.options,
    required this.answer,
    required this.why,
    this.glyph,
  });

  final String question;

  /// A big letter shown above the options (shape to name questions).
  final String? glyph;
  final List<String> options;
  final int answer;
  final String why;
}

List<LetterDrill> buildLetterDrills({
  required String lessonId,
  required List<LetterCardInfo> alphabet,
  required int index,
}) {
  assert(index >= 0 && index < alphabet.length);
  final Random rng = Random(RecallCheckBuilder.seedOf(lessonId));
  final LetterCardInfo today = alphabet[index];

  /// Two others from the whole alphabet (so even the first lesson has
  /// distractors), none sharing [keep]'s shape or name.
  List<LetterCardInfo> others(LetterCardInfo keep) {
    final List<LetterCardInfo> pool = <LetterCardInfo>[
      for (final LetterCardInfo c in alphabet)
        if (c.arabic != keep.arabic && c.name != keep.name) c,
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

  LetterDrill shapeToName(LetterCardInfo c, {required bool earlier}) {
    final ({List<String> options, int answer}) p = place(
      c.name,
      <String>[for (final LetterCardInfo o in others(c)) o.name],
    );
    return LetterDrill(
      question: earlier
          ? 'From an earlier lesson: what is this letter called?'
          : 'What is this letter called?',
      glyph: c.arabic,
      options: p.options,
      answer: p.answer,
      why: 'This is ${c.name} — ${c.arabic}.',
    );
  }

  LetterDrill nameToShape(LetterCardInfo c, {required bool earlier}) {
    final ({List<String> options, int answer}) p = place(
      c.arabic,
      <String>[for (final LetterCardInfo o in others(c)) o.arabic],
    );
    return LetterDrill(
      question: earlier
          ? 'From an earlier lesson: which one is ${c.name}?'
          : 'Which one is ${c.name}?',
      options: p.options,
      answer: p.answer,
      why: '${c.name} is ${c.arabic}.',
    );
  }

  final List<LetterDrill> out = <LetterDrill>[shapeToName(today, earlier: false)];
  if (index == 0) {
    out.add(nameToShape(today, earlier: false));
    return out;
  }
  final List<LetterCardInfo> before = alphabet.sublist(0, index)..shuffle(rng);
  out.add(nameToShape(before.first, earlier: true));
  if (before.length >= 2) {
    out.add(shapeToName(before[1], earlier: true));
  }
  return out;
}
