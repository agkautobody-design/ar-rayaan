import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Follow-ups keep their context, declines are honest and varied, and repeat
/// greetings are not the same canned line.
Future<List<String>> chat(List<String> turns) async {
  final history = <HadiMessage>[];
  final replies = <String>[];
  for (final q in turns) {
    final r = await const OfflineHadiProvider().ask(q, List<HadiMessage>.of(history));
    replies.add(r);
    history
      ..add(HadiMessage(fromHadi: false, text: q))
      ..add(HadiMessage(fromHadi: true, text: r));
  }
  return replies;
}

void main() {
  test('"why?" after an answer points at that answer\'s sources', () async {
    final r = await chat(<String>['Is gelatin halal?', 'why?']);
    expect(r[1], contains('Qur\'an 2:173'));
    expect(HadiRouting.isRefusal(r[1]), isFalse);
  });

  test('"how do I play it" after a game question explains that game', () async {
    final r = await chat(<String>['what is the 99 Names', 'how do I play it']);
    expect(r[1], contains('How to play'));
    expect(r[1], contains('flashcard'));
  });

  test('a repeated greeting is not answered with the same words', () async {
    final r = await chat(<String>['hi', 'hello']);
    expect(r[1], isNot(r[0]));
    expect(HadiRouting.isRefusal(r[1]), isFalse);
  });

  test('out-of-scope asks are declined, each with its own reason', () async {
    final joke = await chat(<String>['Tell me a joke']);
    final weather = await chat(<String>['What is the weather today?']);
    expect(HadiRouting.isRefusal(joke.single), isTrue);
    expect(HadiRouting.isRefusal(weather.single), isTrue);
    expect(joke.single, isNot(weather.single));
    expect(weather.single, contains('weather'));
  });

  test('beginner prayer and Roman-Urdu wudu questions get real answers', () async {
    final r = await chat(<String>['How do I learn to pray as a beginner?', 'wuzu kaise karte hain']);
    expect(r[0], contains('Subhana Rabbiyal-\'Azim'));
    expect(r[1], contains('Wash your face'));
    expect(HadiRouting.isRefusal(r[0]) || HadiRouting.isRefusal(r[1]), isFalse);
  });
}
