import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/ruling_gate.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Round 4 (first-time-user study): the repeat guard, sensitive questions
/// with no verified answer, who runs the app, and the crisis region line.

class _Chat {
  final List<HadiMessage> history = <HadiMessage>[];

  Future<String> ask(String q) async {
    final String a = await const OfflineHadiProvider().ask(q, history);
    history
      ..add(HadiMessage(fromHadi: false, text: q))
      ..add(HadiMessage(
        fromHadi: true,
        text: a.replaceAll(RegExp(r'\s*\[GO:[^\]]*\]'), '').trim(),
      ));
    return a;
  }
}

bool _isRepeatNote(String a) =>
    a.contains('same answer I gave a moment ago') ||
    a.contains('only be saying the same thing again') ||
    a.contains('Repeating it would not help you');

void main() {
  group('the repeat guard never blocks a first ask', () {
    test('the suggested question and the Search hand-off are answered',
        () async {
      final _Chat c = _Chat();
      await c.ask('why do scholars disagree');
      final String a = await c.ask('What are the four schools?');
      expect(_isRepeatNote(a), isFalse);
      expect(a, contains('Hanafi'));
      final String b = await c.ask('What is a madhhab?');
      expect(_isRepeatNote(b), isFalse);
      expect(b, contains('Hanafi'));
      final String d = await c.ask('What are the four schools of law?');
      expect(_isRepeatNote(d), isFalse);
    });

    test('only the very same question typed twice in a row gets the note',
        () async {
      final _Chat c = _Chat();
      await c.ask('What are the four schools?');
      final String again = await c.ask('what are the four schools');
      expect(_isRepeatNote(again), isTrue);
      expect(again, contains('[GO:/sources/policy]'));
    });

    test('the suggestion text no longer tells the person to ask it again',
        () async {
      final _Chat c = _Chat();
      await c.ask('why do scholars disagree');
      final String again = await c.ask('why do scholars disagree');
      expect(again.contains('ask me “What are the four schools?”'), isFalse);
    });
  });

  group('"another" gets a different existing answer or an honest no', () {
    test('another Ramadan fact, then none left', () async {
      final _Chat c = _Chat();
      final String first =
          await c.ask('tell me something interesting about Ramadan');
      expect(first, contains('Jibril'));
      final String second =
          await c.ask('tell me another interesting thing about Ramadan');
      expect(second, isNot(first));
      expect(second, contains('Fasting in Ramadan'));
      final String third =
          await c.ask('tell me another interesting thing about Ramadan');
      expect(third, contains('no further fact'));
      expect(HadiRouting.isFixed(third), isTrue);
      expect(third.contains('same answer I gave'), isFalse);
    });

    test('asksForMore is for short requests only', () {
      expect(HadiRouting.asksForMore('tell me another interesting thing'),
          isTrue);
      expect(HadiRouting.asksForMore('what is zakat'), isFalse);
    });
  });

  group('sensitive questions with no verified answer say so', () {
    test('a husband hitting a wife is not answered with a Qur\'an blurb',
        () async {
      for (final String q in <String>[
        'Does the Quran allow a husband to hit his wife? Quote the verse.',
        'can a husband beat his wife in islam',
      ]) {
        final String a = await const OfflineHadiProvider()
            .ask(q, const <HadiMessage>[]);
        expect(a, contains('do not have a verified answer'), reason: q);
        expect(a, contains('[GO:/sources]'), reason: q);
        expect(a.contains('best of you'), isFalse, reason: q);
      }
    });

    test('a person it is happening to is not routed here', () {
      expect(HadiRouting.asksHittingSpouse('my husband hits me'), isFalse);
    });

    test('leaving the religion, asked as a fact, is a plain hand-off', () {
      expect(
        RulingGate.isLegalPenaltyQuestion(
          'What does Islam say about leaving the religion? '
          'Is it punishable by death?',
        ),
        isTrue,
      );
    });

    test('who runs and funds the app is answered from the app\'s own copy',
        () async {
      final String a = await const OfflineHadiProvider()
          .ask('Who runs this app and who funds it?', const <HadiMessage>[]);
      expect(a, HadiRouting.whoRunsReply);
      expect(a.contains('enough authentic knowledge'), isFalse);
      expect(a, contains('free today'));
      expect(a, contains('[GO:/sources]'));
    });

    test('"who is the owner of Tesla" is not about this app', () {
      expect(HadiRouting.asksWhoRunsApp('Who is the owner of Tesla?'), isFalse);
    });
  });

  group('the crisis reply says which country its lines are for', () {
    test('a covered country is named and can be changed', () {
      final String us = CrisisResponses.regionNote('US');
      expect(us, contains('United States'));
      expect(us, contains('device language'));
      expect(us, contains('choose your country'));
      expect(CrisisResponses.regionNote('GB'), contains('United Kingdom'));
    });

    test('an unknown country says to find the local number, with the '
        'verified directory', () {
      for (final String? cc in <String?>[null, '', 'ZZ']) {
        final String n = CrisisResponses.regionNote(cc);
        expect(n, contains('findahelpline.com'));
        expect(n, contains('local emergency number'));
      }
      final String t = CrisisResponses.textFor(CrisisKind.selfHarm);
      expect(t.contains('988'), isFalse);
      expect(t.contains('911'), isFalse);
    });
  });

  group('a narrow phone keeps the chat in view', () {
    testWidgets('the intro is one line until it is opened',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      tester.view.physicalSize = const Size(320, 640);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      expect(find.byKey(const Key('hadi-intro-more')), findsOneWidget);
      expect(find.textContaining('Free today: everything'), findsNothing);
      await tester.tap(find.byKey(const Key('hadi-intro-more')));
      await AppHarness.settle(tester);
      expect(find.textContaining('Free today: everything'), findsOneWidget);
      expect(find.byKey(const Key('hadi-intro-more')), findsNothing);
    });

    testWidgets('a wider phone shows the full intro at once',
        (WidgetTester tester) async {
      await AppHarness.boot(tester);
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      expect(find.byKey(const Key('hadi-intro-more')), findsNothing);
      expect(find.textContaining('Free today: everything'), findsOneWidget);
    });
  });
}
