import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<String> ask(String q) =>
      const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

  // Each question was answered wrongly or not at all in the 14 Nov 2026
  // persona test. The answer must now contain its own marker.
  final Map<String, String> want = <String, String>{
    'who made Allah': '112:3',
    'where did Allah come from': '57:3',
    'why cant I see Allah': '6:103',
    'why do we pray': '20:14',
    'is my pet going to heaven': '6:38',
    'my 5 year old is scared of the dark what dua': '5017',
    'what time is fajr': '[GO:/prayer]',
    'sing me a nasheed': '[GO:/player]',
    'what should I eat as a muslim': '2:168',
    'can I work at a bank': '1598',
    'can I keep my old friends': '60:8',
    'I lost my job': '65:2',
    'someone is bullying me at school': 'Hasbunallahu',
    'my teen stopped praying': '20:132',
    'is stock trading halal': 'Stocks and shares',
    'is insurance allowed': 'Takaful',
    'is bitcoin halal': 'Bitcoin',
    'kya main namaz mein urdu mein dua kar sakta hoon': 'Scholars differ',
  };

  for (final MapEntry<String, String> e in want.entries) {
    test('"${e.key}" gets its own answer', () async {
      final String a = await ask(e.key);
      expect(a, contains(e.value), reason: a);
      expect(a, isNot(contains('checked answer for that')));
    });
  }

  test('insurance and stocks no longer open with Bitcoin', () async {
    expect(await ask('is insurance allowed'), isNot(startsWith('Bitcoin')));
    expect(await ask('is stock trading halal'), isNot(startsWith('Bitcoin')));
  });

  test('neighbouring questions keep their own answers', () async {
    expect(await ask('can cats be kept as pets'), contains('Cats'));
    expect(await ask('is music haram'), isNot(contains('[GO:/player]')));
    expect(await ask('how do I take shahada'), contains('shahada'));
    expect(await ask('can I marry someone not Muslim'),
        isNot(contains('60:8')));
  });
}
