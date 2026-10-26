import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ar_rayaan/features/games/engine/game_registry.dart';
import 'package:ar_rayaan/features/games/engine/quiz_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared quiz engine over the real bundled data: the Qur'an text and
/// the story trivia. Every question needs a source and an explanation, hints
/// are free and limited, and there is nothing to buy or time.
void main() {
  late List<dynamic> quran;
  late List<TriviaRow> trivia;

  setUpAll(() {
    quran = json.decode(File('assets/quran/quran.json').readAsStringSync())
        as List<dynamic>;
    trivia = <TriviaRow>[
      for (final dynamic e in json
          .decode(File('assets/games/trivia.json').readAsStringSync())
          as List<dynamic>)
        (
          id: (e as Map<String, dynamic>)['id'] as String,
          category: e['category'] as String,
          question: e['question'] as String,
          options: (e['options'] as List<dynamic>).cast<String>(),
          answer: e['answer'] as int,
          why: e['why'] as String,
        ),
    ];
  });

  void checkQuestion(QuizQuestion q) {
    expect(q.citation.trim(), isNotEmpty, reason: q.id);
    expect(q.explanation.trim(), isNotEmpty, reason: q.id);
    expect(q.options.length, greaterThan(1), reason: q.id);
    expect(q.options.toSet().length, q.options.length, reason: q.id);
    expect(q.answer >= 0 && q.answer < q.options.length, isTrue, reason: q.id);
  }

  group('Qur’an Knowledge', () {
    test('every difficulty and topic builds the full count, each sourced', () {
      for (final GameDifficulty d in GameDifficulty.values) {
        for (final String t in QuranTopics.all) {
          for (int seed = 0; seed < 8; seed++) {
            final List<QuizQuestion> qs = buildQuranQuiz(
              quran,
              Random(seed),
              count: 30,
              difficulty: d,
              topic: t,
            );
            expect(qs.length, 30, reason: '$d $t $seed');
            expect(qs.map((QuizQuestion q) => q.id).toSet().length, 30);
            qs.forEach(checkQuestion);
          }
        }
      }
    });

    test('an ayah question blanks one word and cites surah and ayah', () {
      final List<QuizQuestion> qs = buildQuranQuiz(
        quran,
        Random(1),
        count: 12,
        difficulty: GameDifficulty.standard,
        topic: QuranTopics.ayah,
      );
      for (final QuizQuestion q in qs) {
        expect(q.promptIsArabic && q.optionsAreArabic, isTrue);
        expect(RegExp('_____').allMatches(q.prompt).length, 1);
        expect(RegExp(r'^Qur’an \d+:\d+').hasMatch(q.citation), isTrue,
            reason: q.citation);
        // The right word, put back, makes the real ayah from the text.
        final String restored = q.prompt.replaceFirst('_____', q.options[q.answer]);
        final List<String> m = RegExp(r'(\d+):(\d+)')
            .firstMatch(q.citation)!
            .groups(<int>[1, 2]).cast<String>();
        final Map<String, dynamic> surah =
            quran[int.parse(m[0]) - 1] as Map<String, dynamic>;
        final List<dynamic> row =
            (surah['v'] as List<dynamic>)[int.parse(m[1]) - 1] as List<dynamic>;
        String strip(String s) => s.replaceAll(RegExp(r'[ۖ-۞۩]'), '');
        expect(strip(restored).replaceAll(RegExp(r'\s+'), ' '),
            strip(row[1] as String).replaceAll(RegExp(r'\s+'), ' '));
      }
    });

    test('surah questions agree with the surah list', () {
      final List<QuizQuestion> qs = buildQuranQuiz(
        quran,
        Random(5),
        count: 30,
        difficulty: GameDifficulty.standard,
        topic: QuranTopics.surahs,
      );
      for (final QuizQuestion q in qs) {
        final RegExpMatch? name = RegExp(r'^qk-(name|number|count)-(\d+)$')
            .firstMatch(q.id);
        expect(name, isNotNull, reason: q.id);
        final Map<String, dynamic> s =
            quran[int.parse(name!.group(2)!) - 1] as Map<String, dynamic>;
        switch (name.group(1)) {
          case 'name':
            expect(q.options[q.answer], s['tl']);
          case 'number':
            expect(q.options[q.answer], '${s['n']}');
          default:
            expect(q.options[q.answer], '${s['c']}');
        }
      }
    });

    test('Easy stays in the last part of the Qur’an and Al-Fatihah', () {
      final List<QuizQuestion> qs = buildQuranQuiz(
        quran,
        Random(2),
        count: 30,
        difficulty: GameDifficulty.easy,
      );
      for (final QuizQuestion q in qs.where((QuizQuestion q) => q.promptIsArabic)) {
        final int surah = int.parse(
          RegExp(r'^Qur’an (\d+):').firstMatch(q.citation)!.group(1)!,
        );
        expect(surah == 1 || surah >= 78, isTrue, reason: q.citation);
        expect(q.context, isNotNull);
      }
    });

    test('nothing asks the weak Ya-Sin saying or any unsourced claim', () {
      final String all = <String>[
        for (final GameDifficulty d in GameDifficulty.values)
          for (final QuizQuestion q in buildQuranQuiz(
            quran,
            Random(9),
            count: 30,
            difficulty: d,
          ))
            '${q.prompt} ${q.explanation}',
      ].join(' ').toLowerCase();
      expect(all.contains('heart of the qur'), isFalse);
      expect(all.contains('yaseen'), isFalse);
    });
  });

  group('Stories Trivia', () {
    test('only questions that name a source are used', () {
      final List<QuizQuestion> pool = storiesPool(trivia);
      expect(pool.length, greaterThan(20));
      expect(pool.length, lessThan(trivia.length));
      pool.forEach(checkQuestion);
      final Set<String> ids = pool.map((QuizQuestion q) => q.id).toSet();
      // These carry no reference in their explanation.
      for (final String dropped in <String>['tq-09', 'tq-21', 'tq-24']) {
        expect(ids.contains(dropped), isFalse, reason: dropped);
      }
    });

    test('citations are read from the explanation', () {
      expect(triviaCitation('He was saved (21:69).'), 'Qur’an 21:69');
      expect(triviaCitation('Cleared (Tirmidhi 3505, sahih)'), 'Tirmidhi 3505');
      expect(triviaCitation('seerah sources: Ibn Hisham, Ibn Sa\'d'),
          'Seerah: Ibn Hisham, Ibn Sa\'d');
      expect(triviaCitation('Surah Maryam (19) is named for her.'),
          'Qur’an, Surah 19');
      expect(triviaCitation('He led the prayer in his illness.'), isNull);
      expect(triviaCitation('See page 115:3 of the notes'), isNull);
    });

    test('shuffled options keep the right answer', () {
      final List<QuizQuestion> base = storiesPool(trivia);
      for (int seed = 0; seed < 5; seed++) {
        final List<QuizQuestion> qs = buildStoriesQuiz(
          trivia,
          Random(seed),
          count: 10,
        );
        expect(qs.length, 10);
        for (final QuizQuestion q in qs) {
          final QuizQuestion b = base.firstWhere((QuizQuestion e) => e.id == q.id);
          expect(q.options[q.answer], b.options[b.answer]);
        }
      }
    });

    test('topics need at least three sourced questions', () {
      final List<String> topics = storiesTopics(trivia);
      expect(topics, isNotEmpty);
      for (final String t in topics) {
        expect(storiesPool(trivia, topic: t).length, greaterThan(2));
      }
    });

    test('count choices never exceed the pool', () {
      expect(countChoices(100), <int>[5, 10, 15, 20, 30]);
      expect(countChoices(12), <int>[5, 10]);
      expect(countChoices(3), <int>[3]);
      expect(countChoices(0), isEmpty);
    });
  });

  group('session', () {
    QuizSession make({int players = 1, bool hints = true}) => QuizSession(
          config: QuizConfig(gameId: 'stories', count: 4, players: players, hints: hints),
          questions: buildStoriesQuiz(trivia, Random(3), count: 4),
        );

    test('scores right answers and moves on only after an answer', () {
      final QuizSession s = make();
      expect(s.next(), isFalse);
      expect(s.pick(s.current.answer), isTrue);
      expect(s.pick(0), isFalse, reason: 'one answer per question');
      expect(s.correct, 1);
      expect(s.next(), isTrue);
      expect(s.pick((s.current.answer + 1) % s.current.options.length), isTrue);
      expect(s.correct, 1);
    });

    test('a hint is free, hides two wrong options and is limited to three', () {
      final QuizSession s = make();
      final Random rnd = Random(1);
      final List<int>? hid = s.useHint(rnd);
      expect(hid, isNotNull);
      expect(hid!.length, 2);
      expect(hid.contains(s.current.answer), isFalse);
      expect(s.hintsLeft, kHintsPerGame - 1);
      expect(s.useHint(rnd), isNull, reason: 'one hint a question');
      expect(s.pick(hid.first), isFalse, reason: 'a hidden option is gone');
      expect(s.pick(s.current.answer), isTrue);
      for (int i = 0; i < 2; i++) {
        s.next();
        s.useHint(rnd);
        s.pick(s.current.answer);
      }
      expect(s.hintsLeft, 0);
      s.next();
      expect(s.useHint(rnd), isNull);
    });

    test('hints off means no hints at all', () {
      final QuizSession s = make(hints: false);
      expect(s.hintsLeft, 0);
      expect(s.useHint(Random(1)), isNull);
    });

    test('pass and play: players take turns and the scores add up', () {
      final QuizSession s = make(players: 2);
      expect(s.player, 0);
      s.pick(s.current.answer);
      s.next();
      expect(s.player, 1);
      s.pick((s.current.answer + 1) % s.current.options.length);
      s.next();
      expect(s.player, 0);
      s.pick(s.current.answer);
      s.next();
      s.pick(s.current.answer);
      expect(s.finished, isTrue);
      expect(s.scores, <int>[2, 1]);
      expect(s.correct, 3);
      expect(questionsFor(4, 2, 0) + questionsFor(4, 2, 1), 4);
      expect(questionsFor(10, 3, 0), 4);
      expect(questionsFor(10, 3, 2), 3);
    });

    test('a saved game comes back exactly', () {
      final QuizSession s = make(players: 2);
      s.pick(s.current.answer);
      s.next();
      s.useHint(Random(2));
      final QuizSession back = QuizSession.fromJson(
        json.decode(s.encode()) as Map<String, dynamic>,
      );
      expect(back.index, s.index);
      expect(back.scores, s.scores);
      expect(back.hintsLeft, s.hintsLeft);
      expect(back.picks, s.picks);
      expect(back.hiddenNow, s.hiddenNow);
      expect(back.current.prompt, s.current.prompt);
      expect(back.config.players, 2);
    });

    test('the setup choices survive the route query', () {
      const QuizConfig c = QuizConfig(
        gameId: 'qk',
        topic: 'ayah',
        count: 15,
        difficulty: GameDifficulty.challenge,
        players: 3,
        hints: false,
      );
      final QuizConfig back = QuizConfig.fromQuery('qk', c.toQuery());
      expect(back.topic, 'ayah');
      expect(back.count, 15);
      expect(back.difficulty, GameDifficulty.challenge);
      expect(back.players, 3);
      expect(back.hints, isFalse);
      final QuizConfig odd = QuizConfig.fromQuery(
        'qk',
        <String, String>{'n': '9999', 'players': '0', 'd': 'nonsense'},
      );
      expect(odd.count, 30);
      expect(odd.players, 1);
      expect(odd.difficulty, GameDifficulty.standard);
    });
  });
}
