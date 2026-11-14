import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Curious, playful and "big" questions that a child or a newcomer asks.
/// Hadi may answer them, point somewhere, or say honestly that it has no
/// verified answer, but it must not hit the generic "no checked answer"
/// fallback for a question like these, which reads as a failure to understand.
const List<String> kCuriosityQuestions = <String>[
  // Riddles and "which came first"
  'What was made first the chicken or the egg',
  'Which came first, the chicken or the egg?',
  'Who created Allah',
  'Who made God',
  'What was there before Allah',
  'Where was Allah before He created the universe',
  'Can Allah create a rock He cannot lift',
  'Can God make a square circle',
  'Why did Allah create us',
  'What is the meaning of life',
  'Why are we here',
  'Where is Allah',
  'Does Allah sleep',
  'Does Allah have a body',
  'Why can we not see Allah',
  'Who created the first human',
  'How did Allah make Adam',
  // Science meets faith
  'Is the earth flat',
  'Are there aliens',
  'Do aliens exist in Islam',
  'Did dinosaurs exist',
  'What about dinosaurs in Islam',
  'Is evolution allowed in Islam',
  'How old is the universe',
  'Is time travel possible',
  'Are we living in a simulation',
  'How big is the universe',
  'Is the big bang in the Quran',
  // Animals and pets
  'Do animals go to heaven',
  'Do animals have souls',
  'Will my cat go to jannah',
  'Can I keep a dog as a pet',
  'Can I have a pet cat',
  'Are unicorns real',
  'Are dragons real',
  // Kids why-questions
  'Why is the sky blue',
  'Why is the sea salty',
  'Why do we dream',
  'Why do we sleep',
  'Why do we have to die',
  'Why do we have to pray five times a day',
  'Who made the moon',
  'What do angels look like',
  'What are jinn made of',
  'Are ghosts real',
  'Is Santa real',
  'Why do we fast',
  'Why do we have two eyes',
  'Why do cats purr',
  'How do birds fly',
  // Playful fiqh
  'Can I pray in my pajamas',
  'Can I pray on a plane',
  'Is it ok to say happy birthday',
  'Is it haram to play video games',
  'Is it haram to draw',
  'Can I listen to music',
  'Can Muslims have tattoos',
  'Can I eat gummy bears',
  'Is it haram to have a girlfriend',
  'Can a Muslim celebrate Halloween',
  // Small talk and the app itself
  'Who are you',
  'Are you a real person',
  'Are you smart',
  'Tell me a joke',
  'Tell me something interesting',
  'What is your favourite colour',
  'Do you like pizza',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curiosity sweep: list the questions that hit the generic fallback',
      () async {
    final List<String> misses = <String>[];
    for (final String q in kCuriosityQuestions) {
      final String a =
          await const OfflineHadiProvider().ask(q, const <HadiMessage>[]);
      if (a.contains('checked answer for that')) misses.add(q);
    }
    // ignore: avoid_print
    print('SWEEP_MISSES(${misses.length}/${kCuriosityQuestions.length}):\n'
        '${misses.join('\n')}\nSWEEP_END');
    expect(misses, isEmpty, reason: 'declined: $misses');
  });
}
