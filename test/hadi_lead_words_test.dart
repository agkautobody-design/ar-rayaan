import 'package:ar_rayaan/features/hadi/data/hadi_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hadi drops polite openings ("tell me", "can you", "please") before the
/// library patterns see a question, so a pattern must never need them.
void main() {
  const Map<String, String> cases = <String, String>{
    'tell me something inspiring': 'something-inspiring',
    'give me something inspiring': 'something-inspiring',
    'something inspiring': 'something-inspiring',
    'please tell me something uplifting': 'something-inspiring',
    'inspire me': 'something-inspiring',
    'tell me something interesting': 'curious-something-interesting',
    'show me something interesting': 'curious-something-interesting',
    'give me a fun fact that is cool': 'curious-something-interesting',
    'tell me about uhud': 'battle-uhud',
    'tell me about the trench': 'battle-trench',
    'tell me about the companions': 'companions-sahabah',
    'tell me about prophet muhammad': 'prophet-biography',
    'tell me about the quran': 'quran-what',
    'tell me about yourself': 'hadi-who',
    'tell me about wasia': 'wasia-who',
    'a dua for anxiety': 'dua-anxiety',
    "a du'a for anxiety": 'dua-anxiety',
    'dua for worry': 'dua-anxiety',
    'what should i read when i am anxious': 'dua-anxiety',
  };
  cases.forEach((String q, String id) {
    test('"$q" reaches $id', () {
      expect(HadiCore.match(q)?.id, id);
    });
  });

  test('a person in despair is not given the inspiring pack', () {
    expect(HadiCore.match('tell me something inspiring i feel hopeless')?.id,
        isNot('something-inspiring'));
  });

  test('the anxiety du\'a gives the du\'a itself, cited, with the Arabic', () {
    final String a = HadiCore.match('a dua for anxiety')!.answer;
    expect(a, contains('Sahih al-Bukhari 6369'));
    expect(RegExp(r'[\u0600-\u06FF]').hasMatch(a), isTrue);
    expect(a, contains('Allahumma inni a'));
  });
}
