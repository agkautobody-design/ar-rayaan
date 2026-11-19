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
}
