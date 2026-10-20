/// Recall checks - a real, auto-graded retrieval question for a lesson,
/// generated from the lesson's OWN words.
///
/// Why: 130 of 146 manifest lessons end in "I remembered it" (self-graded),
/// and only two have a real check (research 4, section 0). Hand-writing 144
/// religious questions without a reviewer would invite errors, so this
/// builder writes none. It takes one plain explanatory sentence from the
/// lesson, blanks one content word, and offers that word plus two words that
/// do not occur anywhere in the lesson. The answer is therefore, by
/// construction, the lesson's own wording - the check tests recall of what
/// the lesson said; it asserts nothing new and is never a ruling.
///
/// Deliberately NOT blanked, so a learner is never rewarded for memorising a
/// paraphrase as if it were revelation: any sentence that quotes (quote
/// marks), cites (digits like 2:183, brackets with numbers), names a hadith
/// book or a report ("said", "narrated"), or contains Arabic script.
///
/// Deterministic: the same lesson always yields the same question (seeded by
/// the lesson id), so the question can be tested and re-asked on review.
library;

import 'assessment_engine.dart';

/// Lessons the 20 Oct audit flagged as carrying unsupported or mis-cited
/// claims. They get no generated check until a reviewer clears them: a check
/// must not reinforce a claim nobody has verified.
const Set<String> kRecallExcludedLessons = <String>{
  'path.u9.l4',
  'char.u3.l2',
  'fam.u1.l1',
  'daw.u2.l3',
  'trx.u2.l2',
  'trx.u2.l3',
  'und.u3.l3',
  'wmns.u3.l3',
  'wmns.u3.l4',
  'wmns.u3.l5',
};

/// The blank shown in the prompt.
const String kRecallBlank = '____';

/// Function words and fillers never used as an answer or a distractor.
const Set<String> _stop = <String>{
  'about', 'above', 'after', 'again', 'against', 'almost', 'already', 'also',
  'always', 'among', 'another', 'around', 'because', 'before', 'being',
  'between', 'beyond', 'bring', 'called', 'cannot', 'comes', 'could', 'doing',
  'during', 'either', 'enough', 'every', 'first', 'found', 'given', 'going',
  'great', 'having', 'himself', 'however', 'itself', 'little', 'making',
  'might', 'never', 'nobody', 'nothing', 'often', 'other', 'others', 'people',
  'really', 'rather', 'said', 'same', 'should', 'since', 'still', 'taken',
  'their', 'theirs', 'there', 'these', 'things', 'think', 'those', 'though',
  'through', 'together', 'toward', 'under', 'until', 'upon', 'using',
  'usually', 'very', 'want', 'wants', 'were', 'what', 'when', 'where',
  'whether', 'which', 'while', 'whole', 'whom', 'whose', 'will', 'with',
  'within', 'without', 'would', 'your', 'yours', 'yourself',
};

final RegExp _excludedSentence = RegExp(
  '[\'"‘’“”]'
  r"|\(\s*[A-Za-z' .]*\d"
  r'|\d+:\d+'
  r'|\bBukhari|\bMuslim\b|Tirmidhi|Nasa|Abu Dawud|Ibn Majah'
  r'|[Hh]adith|[Rr]eported|[Nn]arrated|\bsaid\b|\bsays\b',
);

final RegExp _arabicScript = RegExp(
  '[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]',
);

final RegExp _wordToken = RegExp('[A-Za-z’\'-]+');
final RegExp _pureLower = RegExp(r'^[a-z]{6,}$');

class RecallCheck {
  const RecallCheck({
    required this.lessonId,
    required this.sentence,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.correctIndex,
  });

  final String lessonId;

  /// The lesson's own sentence, whole.
  final String sentence;

  /// [sentence] with the answer replaced by [kRecallBlank].
  final String prompt;
  final String answer;
  final List<String> choices;
  final int correctIndex;

  /// The check as a standard (literal) assessment item, so it runs through
  /// the same player and [AssessmentEngine] as the hand-written checks.
  AssessmentItem toItem() => AssessmentItem(
        id: 'recall.$lessonId',
        promptKey: prompt,
        choices: choices,
        correctIndex: correctIndex,
        reteachKey: 'This lesson said: $sentence',
        literal: true,
      );
}

abstract final class RecallCheckBuilder {
  /// Stable small hash (kept under 2^31 so it is identical on the VM and on
  /// the web, where integers are doubles).
  static int seedOf(String id) {
    int h = 7;
    for (final int c in id.codeUnits) {
      h = (h * 31 + c) % 1000003;
    }
    return h;
  }

  /// Sentences of [text], split after . ! ? that are followed by space/end.
  static List<String> sentences(String text) {
    final List<String> out = <String>[];
    final StringBuffer cur = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      cur.write(ch);
      final bool enders = ch == '.' || ch == '!' || ch == '?';
      if (enders && (i + 1 == text.length || text[i + 1].trim().isEmpty)) {
        final String s = cur.toString().trim();
        if (s.isNotEmpty) out.add(s);
        cur.clear();
      }
    }
    final String tail = cur.toString().trim();
    if (tail.isNotEmpty) out.add(tail);
    return out;
  }

  /// Blank-able words of [sentence]: plain lower-case words of 6+ letters
  /// that occur once in it and are not filler.
  static List<String> candidateWords(String sentence) {
    final List<String> tokens = <String>[
      for (final RegExpMatch m in _wordToken.allMatches(sentence)) m.group(0)!,
    ];
    final Map<String, int> count = <String, int>{};
    for (final String t in tokens) {
      count[t] = (count[t] ?? 0) + 1;
    }
    final List<String> out = <String>[];
    for (final String t in tokens) {
      if (_pureLower.hasMatch(t) && count[t] == 1 && !_stop.contains(t)) {
        if (!out.contains(t)) out.add(t);
      }
    }
    return out;
  }

  /// Every blank-able word in [text] (the distractor pool is built from all
  /// lessons).
  static Set<String> poolWords(String text) {
    final Set<String> out = <String>{};
    for (final RegExpMatch m in _wordToken.allMatches(text)) {
      final String t = m.group(0)!;
      if (_pureLower.hasMatch(t) && !_stop.contains(t)) out.add(t);
    }
    return out;
  }

  /// All lower-cased word tokens of [text], for "does this word occur".
  static Set<String> allWords(String text) => <String>{
        for (final RegExpMatch m in _wordToken.allMatches(text))
          m.group(0)!.toLowerCase(),
      };

  static bool _eligibleSentence(String s) {
    final int n =
        s.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;
    if (n < 6 || n > 45) return false;
    if (_arabicScript.hasMatch(s)) return false;
    if (s.contains('_')) return false;
    if (_excludedSentence.hasMatch(s)) return false;
    return true;
  }

  /// Build the check for [lessonId].
  ///
  /// [teachingText] is the lesson's explanatory text (text-step bodies);
  /// [fullText] is every string the lesson shows (titles, prompts, bodies),
  /// used to keep distractors out of the lesson; [poolSorted] is the sorted
  /// distractor pool drawn from all lessons. Returns null when the lesson
  /// offers no suitable sentence or no safe distractors.
  static RecallCheck? build({
    required String lessonId,
    required List<String> teachingText,
    required String fullText,
    required List<String> poolSorted,
  }) {
    if (kRecallExcludedLessons.contains(lessonId)) return null;
    final List<(String, List<String>)> eligible = <(String, List<String>)>[];
    for (final String block in teachingText) {
      for (final String s in sentences(block)) {
        if (!_eligibleSentence(s)) continue;
        final List<String> cw = candidateWords(s);
        if (cw.isNotEmpty) eligible.add((s, cw));
      }
    }
    if (eligible.isEmpty) return null;

    final int seed = seedOf(lessonId);
    final (String, List<String>) pick = eligible[seed % eligible.length];
    final String sentence = pick.$1;
    String answer = pick.$2.first;
    for (final String w in pick.$2) {
      if (w.length > answer.length ||
          (w.length == answer.length && w.compareTo(answer) > 0)) {
        answer = w;
      }
    }

    final Set<String> inLesson = allWords(fullText);
    final List<String> ds = <String>[];
    for (final String w in poolSorted) {
      if (inLesson.contains(w) || w == answer) continue;
      if ((w.length - answer.length).abs() > 2) continue;
      if (w.substring(w.length - 2) != answer.substring(answer.length - 2)) {
        continue;
      }
      if (w.substring(0, 4) == answer.substring(0, 4)) continue;
      ds.add(w);
    }
    if (ds.length < 2) return null;
    final String d1 = ds[seed % ds.length];
    final List<String> rest = <String>[
      for (final String d in ds)
        if (d != d1 && d.substring(0, 4) != d1.substring(0, 4)) d,
    ];
    if (rest.isEmpty) return null;
    final String d2 = rest[(seed ~/ 13) % rest.length];

    final int pos = (seed ~/ 31) % 3;
    final List<String> choices = <String>[d1, d2]..insert(pos, answer);
    String prompt = sentence;
    for (final RegExpMatch m in _wordToken.allMatches(sentence)) {
      if (m.group(0) == answer) {
        prompt = sentence.substring(0, m.start) +
            kRecallBlank +
            sentence.substring(m.end);
        break;
      }
    }
    return RecallCheck(
      lessonId: lessonId,
      sentence: sentence,
      prompt: prompt,
      answer: answer,
      choices: choices,
      correctIndex: pos,
    );
  }
}
