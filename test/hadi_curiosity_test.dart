import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hadi_curiosity_sweep_test.dart' show kCuriosityQuestions;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<String> ask(String q) =>
      const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

  test('chicken and egg gets the honest answer, in both orders', () async {
    for (final String q in <String>[
      'What was made first the chicken or the egg',
      'Which came first, the chicken or the egg?',
      'egg or chicken first',
    ]) {
      final String a = await ask(q);
      expect(a, contains('39:62'), reason: q);
      expect(a, isNot(contains('checked answer for that')), reason: q);
    }
  });

  test('each curious question gets its own answer with a source', () async {
    final Map<String, String> want = <String, String>{
      'What is the meaning of life': '51:56',
      'Is the earth flat': '3:190',
      'Do aliens exist in Islam': '42:29',
      'Did dinosaurs exist': '29:20',
      'What about dinosaurs in Islam': '16:8',
      'Are ghosts real': '23:99',
      'Tell me something interesting': '[GO:/stories]',
      'What is your favourite colour': 'Hadi',
    };
    for (final MapEntry<String, String> e in want.entries) {
      expect(await ask(e.key), contains(e.value), reason: e.key);
    }
  });

  test('neighbouring real questions keep their own answers', () async {
    expect(await ask('is chicken halal'), isNot(contains('39:62')));
    expect(await ask('is it halal to eat chicken or eggs'),
        isNot(contains('39:62')));
    expect(await ask('is the holy ghost real'), isNot(contains('23:99')));
    expect(await ask('what is your favourite surah'),
        isNot(contains('built into this app')));
  });

  test('the sweep list has no question left on the generic fallback',
      () async {
    final List<String> misses = <String>[];
    for (final String q in kCuriosityQuestions) {
      if ((await ask(q)).contains('checked answer for that')) misses.add(q);
    }
    expect(misses, isEmpty, reason: 'declined: $misses');
  });
}
