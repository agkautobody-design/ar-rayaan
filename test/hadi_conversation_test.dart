import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_explain.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asks [questions] one after another in a single conversation and returns
/// the replies, the way the screen does.
Future<List<String>> _talk(List<String> questions) async {
  final List<HadiMessage> history = <HadiMessage>[];
  final List<String> replies = <String>[];
  for (final String q in questions) {
    final String a = await const OfflineHadiProvider().ask(
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
  group('a "close to me" ask is a request for a place', () {
    test('the question that failed on a phone goes to the finder', () async {
      final List<String> r = await _talk(<String>[
        'Can I make it for juma prayer anywhere close to me ?',
      ]);
      expect(r.single, contains('[GO:/masajid]'));
      expect(r.single, isNot(contains('two rak')));
    });

    test('the rules of Jumu’ah are still answered', () async {
      final List<String> r = await _talk(<String>['what is jumuah']);
      expect(r.single, contains('two rak'));
    });

    test('a ruling question is never taken for a place search', () {
      expect(HadiExplain.asksNearestMasjidFirst('is jumuah obligatory for a man near me'), isFalse);
      expect(HadiExplain.asksNearestMasjidFirst('what is jumuah'), isFalse);
      expect(HadiExplain.asksNearestMasjidFirst('halal food close to me'), isTrue);
      expect(HadiExplain.asksNearestMasjidFirst('mosque nearby'), isTrue);
    });
  });

  group('Hadi keeps the thread', () {
    test('"why?" after a follow-up answer gives the reasons', () async {
      final List<String> r = await _talk(<String>[
        'how many rakah is fajr',
        'and maghrib?',
        'why?',
      ]);
      expect(r[1], contains('three'));
      expect(r[2], contains('The reasons are in the answer above'));
      expect(r[2], isNot(contains('not on my shelf')));
    });

    test('"how much do I pay?" after zakat is about zakat', () async {
      final List<String> r = await _talk(<String>[
        'what is zakat',
        'how much do I pay?',
        'on gold?',
      ]);
      expect(r[1], contains('2.5%'));
      expect(r[2], contains('school'));
      expect(HadiRouting.isRefusal(r[1]), isFalse);
      expect(HadiRouting.isRefusal(r[2]), isFalse);
    });

    test('a follow-up that changes who it is about is not guessed at', () async {
      final List<String> r = await _talk(<String>[
        'how many rakah is fajr',
        'for women?',
      ]);
      expect(HadiRouting.isRefusal(r[1]), isTrue);
    });

    test('"where is that from?" reads the sources of the last answer', () async {
      final List<String> r = await _talk(<String>[
        'what is wudu',
        'what breaks it',
        'where is that from?',
        'source?',
      ]);
      expect(r[2], contains('Sahih al-Bukhari 135'));
      expect(r[2], isNot(contains('..')));
      expect(r[2], contains('[GO:/sources]'));
      // Asked twice, it is still about the answer, not about the last reply.
      expect(r[3], contains('Sahih al-Bukhari 135'));
    });

    test('a source asked after a failed question looks at the real answer', () async {
      final List<String> r = await _talk(<String>[
        'what is wudu',
        'qwertyuiop zzz',
        'where is that from?',
      ]);
      expect(r[2], contains("Qur'an 5:6"));
    });

    test('goodbyes are met warmly, not declined', () async {
      for (final String bye in <String>[
        'ok bye',
        'bye',
        'that is all for now',
        'no thanks',
        'I am done',
        'nothing else',
      ]) {
        final List<String> r = await _talk(<String>['what is wudu', bye]);
        expect(r[1], contains('Fi amanillah'), reason: bye);
      }
    });
  });
}
