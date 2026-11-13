import 'package:ar_rayaan/features/academy/data/offline_wasia_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _talk(List<String> questions) async {
  final List<HadiMessage> history = <HadiMessage>[];
  final List<String> replies = <String>[];
  for (final String q in questions) {
    final String a = await const OfflineWasiaProvider().ask(
      q,
      List<HadiMessage>.of(history),
    );
    replies.add(a);
    history
      ..add(HadiMessage(fromHadi: false, text: q))
      ..add(HadiMessage(fromHadi: true, text: a));
  }
  return replies;
}

void main() {
  group('Wasia keeps the thread', () {
    test('"say it again" repeats the letter just taught', () async {
      final List<String> r =
          await _talk(<String>['what is alif', 'how do I say it?']);
      expect(r[1], startsWith('Of course!'));
      expect(r[1], contains('Alif'));
    });

    test('a child who does not understand is not sent away', () async {
      final List<String> r =
          await _talk(<String>['what is baa', 'I dont understand']);
      expect(r[1], contains('That is okay'));
      expect(r[1], contains('Bā'));
      expect(r[1], isNot(contains('beyond what I can teach')));
    });

    test('"next" goes to the following letter, in order', () async {
      final List<String> r =
          await _talk(<String>['what is alif', 'next', 'next']);
      expect(r[1], contains('The next letter is Bā'));
      expect(r[2], contains('The next letter is Tā'));
    });

    test('"teach me something" starts at the first letter', () async {
      final List<String> r = await _talk(<String>['teach me something']);
      expect(r.single, contains('very beginning'));
      expect(r.single, contains('Alif'));
    });

    test('"how are you" is answered honestly: Wasia is a program', () async {
      final List<String> r = await _talk(<String>['how are you']);
      expect(r.single, contains('computer program'));
    });

    test('a letter named in the question still wins over the thread', () async {
      final List<String> r =
          await _talk(<String>['what is alif', 'what is kaf']);
      expect(r[1], contains('Kāf'));
    });

    test('a question outside the shelf is still declined honestly', () async {
      final List<String> r = await _talk(<String>['what is the capital of france']);
      expect(r.single, equals(OfflineWasiaProvider.decline));
    });
  });
}
