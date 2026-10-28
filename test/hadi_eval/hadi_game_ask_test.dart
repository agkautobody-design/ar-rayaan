import 'package:ar_rayaan/features/hadi/data/hadi_game_ask.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a quiz ask is answered from the game fields and is a fixed reply',
      () async {
    final String q = HadiGameAsk.quiz(
      prompt: 'Which surah is read in every rak‘ah?',
      answer: 'Al-Fatihah',
      explanation: 'It is recited in each rak‘ah.',
      citation: 'Qur’an 1:1-7; Sahih al-Bukhari 756',
    );
    expect(HadiGameAsk.isGameAsk(q), isTrue);
    final String a = await const OfflineHadiProvider().ask(q, const []);
    expect(HadiGameAsk.isReply(a), isTrue);
    expect(HadiRouting.isFixed(a), isTrue);
    expect(a, contains('Al-Fatihah'));
    expect(a, contains('[GO:/quran]'));
    expect(a, contains('[GO:/hadith]'));
  });

  test('an order ask and a words ask are answered too', () async {
    final String o = HadiGameAsk.order(
      items: <String>['Intention', 'Hands', 'Face'],
      explanation: 'The order of wudu.',
      citation: 'Qur’an 5:6',
    );
    final String w = HadiGameAsk.words(
      entries: <({String term, String meaning})>[
        (term: 'wudu', meaning: 'washing before prayer'),
      ],
      source: 'The Huda glossary',
    );
    expect(HadiGameAsk.answer(o), contains('Intention, then Hands'));
    expect(HadiGameAsk.answer(w), contains('wudu = washing before prayer'));
  });

  test('an ordinary question is not a game ask', () {
    expect(HadiGameAsk.isGameAsk('how do I make wudu'), isFalse);
    expect(HadiGameAsk.answer('how do I make wudu'), isNull);
  });
}
