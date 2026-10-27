import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../huda/domain/guide_glossary.dart';
import '../engine/learning_banks.dart';
import '../engine/order_engine.dart';
import '../engine/quiz_engine.dart';
import '../engine/word_engine.dart';

/// Loads the bundled content the learning games are built from. Everything
/// is read from the app's own assets; nothing is fetched from the network.
abstract final class LearningLoader {
  static Future<Object?> _json(String path) async =>
      json.decode(await rootBundle.loadString(path)) as Object?;

  static List<Map<String, dynamic>> _maps(Object? o) => <Map<String, dynamic>>[
        for (final dynamic e in (o as List<dynamic>? ?? <dynamic>[]))
          e as Map<String, dynamic>,
      ];

  static Future<Map<String, SeerahStory>> _seerahStories() async {
    final List<Map<String, dynamic>> st =
        _maps(await _json('assets/stories/seerah.json'));
    return <String, SeerahStory>{
      for (final Map<String, dynamic> s in st)
        s['id'] as String: (
          title: s['title'] as String,
          sources: ((s['sources'] as List<dynamic>?) ?? <dynamic>[])
              .cast<String>(),
        ),
    };
  }

  static Future<List<Map<String, dynamic>>> _seerahBank() async {
    final Map<String, dynamic> d = (await _json('assets/games/seerah_quiz.json'))
        as Map<String, dynamic>;
    return _maps(d['questions']);
  }

  static Future<List<Map<String, dynamic>>> _forty() async =>
      _maps(await _json('assets/hadith/nawawi40.json'));

  /// The hand-checked list of the Prophet's ﷺ own words the Hadith Knowledge
  /// game asks about (`assets/games/hadith_quiz.json`).
  static Future<List<Map<String, dynamic>>> _hadithBank() async {
    final Map<String, dynamic> d = (await _json('assets/games/hadith_quiz.json'))
        as Map<String, dynamic>;
    return _maps(d['items']);
  }

  static Future<List<ArabicNameRow>> _names() async => <ArabicNameRow>[
        for (final Map<String, dynamic> n
            in _maps(await _json('assets/games/names99.json')))
          (
            n: n['n'] as int,
            name: n['name'] as String,
            arabic: (n['arabic'] as String?) ?? '',
            meaning: (n['meaning'] as String?) ?? '',
            ref: (n['ref'] as String?) ?? '',
          ),
      ];

  static Future<List<ArabicLetterRow>> _letters() async {
    final Map<String, dynamic> d =
        (await _json('assets/academy/letters_curriculum.json'))
            as Map<String, dynamic>;
    final List<ArabicLetterRow> out = <ArabicLetterRow>[];
    int lesson = 0;
    for (final Map<String, dynamic> u in _maps(d['units'])) {
      for (final Map<String, dynamic> l in _maps(u['lessons'])) {
        lesson += 1;
        final String? ar = l['arabic'] as String?;
        String? name;
        for (final Map<String, dynamic> s in _maps(l['steps'])) {
          if (s['type'] == 'card' && s['arabic'] == ar) {
            name = s['translit'] as String?;
            break;
          }
        }
        if (ar != null && ar.isNotEmpty && name != null && name.isNotEmpty) {
          out.add((lesson: lesson, arabic: ar, name: name));
        }
      }
    }
    return out;
  }

  static Future<List<QuizQuestion>> seerahQuiz(Random rnd, int count) async =>
      buildSeerahQuiz(
        await _seerahBank(),
        await _seerahStories(),
        rnd,
        count: count,
      );

  static Future<int> seerahCount() async =>
      seerahPool(await _seerahBank(), await _seerahStories()).length;

  static Future<List<QuizQuestion>> hadithQuiz(Random rnd, int count) async =>
      buildHadithQuiz(await _forty(), await _hadithBank(), rnd, count: count);

  static Future<int> hadithCount() async =>
      hadithQuestionCount(await _forty(), await _hadithBank());

  static Future<List<QuizQuestion>> arabicWordsQuiz(
    Random rnd,
    int count,
    String topic,
  ) async =>
      buildArabicWordsQuiz(
        await _names(),
        await _letters(),
        rnd,
        count: count,
        topic: topic,
      );

  static Future<int> arabicWordsCount(String topic) async {
    final int names = (await _names()).length;
    final int letters = (await _letters()).length;
    return switch (topic) {
      ArabicWordTopics.names => names * 2,
      ArabicWordTopics.letters => letters * 2,
      _ => names * 2 + letters * 2,
    };
  }

  /// The rounds of an ordering game. [topic] picks wudu or salah.
  static Future<List<OrderRound>> orderRounds(
    String gameId,
    String topic,
    Random rnd,
  ) async {
    if (gameId == 'seerah-timeline') {
      final Map<String, dynamic> d =
          (await _json('assets/games/order_rounds.json'))
              as Map<String, dynamic>;
      final Map<String, dynamic> sec = d['seerah'] as Map<String, dynamic>;
      final List<TimelineEvent> events = <TimelineEvent>[
        for (final Map<String, dynamic> e in _maps(sec['events']))
          (
            id: e['id'] as String,
            story: e['story'] as String,
            label: e['label'] as String,
            fact: e['fact'] as String,
          ),
      ];
      final List<Map<String, dynamic>> st =
          _maps(await _json('assets/stories/seerah.json'));
      final Map<String, TimelineStory> stories = <String, TimelineStory>{
        for (final Map<String, dynamic> s in st)
          s['id'] as String: (
            title: s['title'] as String,
            firstSource: ((s['sources'] as List<dynamic>?) ?? <dynamic>['']).first
                as String,
            number: int.tryParse((s['id'] as String).split('-').last) ?? 0,
          ),
      };
      return buildSeerahOrder(events, stories, rnd);
    }
    if (gameId == 'prophets-order') {
      final Map<String, dynamic> d =
          (await _json('assets/games/order_rounds.json'))
              as Map<String, dynamic>;
      final Map<String, dynamic> sec = d['prophets'] as Map<String, dynamic>;
      final List<List<String>> bank = <List<String>>[
        for (final dynamic r in sec['rounds'] as List<dynamic>)
          (r as List<dynamic>).cast<String>(),
      ];
      final Map<String, dynamic> tree =
          (await _json('assets/family/tree.json')) as Map<String, dynamic>;
      final Map<String, Map<String, dynamic>> nodes =
          <String, Map<String, dynamic>>{
        for (final Map<String, dynamic> n in _maps(tree['nodes']))
          n['id'] as String: n,
      };
      return buildProphetOrder(bank, nodes, rnd);
    }
    if (gameId == 'salah-wudu') {
      final String guideId = topic == 'salah' ? 'huda-prayer' : 'huda-wudu';
      for (final Map<String, dynamic> g
          in _maps(await _json('assets/guides/guides.json'))) {
        if (g['id'] != guideId) continue;
        return buildStepOrder((
          id: guideId,
          title: g['title'] as String,
          steps: ((g['steps'] as List<dynamic>?) ?? <dynamic>[]).cast<String>(),
          sources:
              ((g['sources'] as List<dynamic>?) ?? <dynamic>[]).cast<String>(),
          madhhabNote: g['madhhabNote'] as String?,
        ));
      }
    }
    return <OrderRound>[];
  }

  /// The words for Word Search and Word Scramble: the Huda glossary.
  static List<WordClue> wordPool() => wordsFromGlossary(
        <({String term, String gloss})>[
          for (final GlossaryEntry e in kGuideGlossary)
            (term: e.term, gloss: e.gloss),
        ],
      );
}

/// How many questions a quiz game can supply, so the setup screen offers
/// only counts that exist. The key is `gameId|topic`.
final poolSizeProvider =
    FutureProvider.family<int, String>((Ref ref, String key) async {
  final List<String> parts = key.split('|');
  final String game = parts.first;
  final String topic = parts.length > 1 ? parts[1] : 'mixed';
  switch (game) {
    case 'seerah':
      return LearningLoader.seerahCount();
    case 'hadith':
      return LearningLoader.hadithCount();
    case 'arabic-words':
      return LearningLoader.arabicWordsCount(topic);
  }
  return 0;
});
