import 'dart:io';

import 'package:ar_rayaan/features/hadi/data/hadi_report_service.dart';
import 'package:ar_rayaan/features/hadi/grounding/madhhab.dart';
import 'package:ar_rayaan/features/hadi/grounding/minor_signal.dart';
import 'package:ar_rayaan/features/hadi/grounding/ruling_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ruling gate', () {
    test('personal rulings are recognised', () {
      for (final String q in <String>[
        'Is my divorce valid if I said it in anger?',
        'Should I divorce my husband?',
        'Can I take a mortgage for my house?',
        'My wife and I are fighting about the inheritance, what should I do?',
      ]) {
        expect(RulingGate.classify(q), RulingClass.personal, reason: q);
      }
    });

    test('missed prayers and fasts in the first person go to a scholar', () {
      for (final String q in <String>[
        'I missed my prayers for years, what do I do?',
        'How do I make up my missed prayers?',
        'I missed many fasts, what is the kaffarah?',
        'Can I make up salah I skipped?',
      ]) {
        expect(RulingGate.classify(q), RulingClass.personal, reason: q);
      }
      expect(RulingGate.classify('Why is the dawn prayer special?'),
          RulingClass.none);
    });

    test('Arabic and Urdu ruling questions are recognised', () {
      expect(RulingGate.classify('ما حكم الصلاة بدون وضوء؟'),
          RulingClass.general);
      expect(RulingGate.classify('ما حكم الطلاق؟'), RulingClass.general);
      expect(RulingGate.classify('هل طلاقي صحيح؟'), RulingClass.personal);
      expect(RulingGate.classify('مجھے نماز کا طریقہ بتائیں'),
          RulingClass.none);
    });

    test('general rulings and ordinary questions are not personal', () {
      expect(RulingGate.classify('What is the ruling on interest loan in Islam?'),
          RulingClass.general);
      expect(RulingGate.classify('How many rakat is fajr?'), RulingClass.none);
      expect(RulingGate.classify('Tell me about patience'), RulingClass.none);
    });

    test('the personal reply hands off to a scholar and names the school', () {
      final String a = RulingGate.personalReply(schoolLabel: 'Hanafi');
      expect(a.toLowerCase(), contains('qualified scholar'));
      expect(a, contains('Hanafi'));
      expect(RulingGate.personalReply().contains('Hanafi'), isFalse);
    });

    test('a live verdict on the person\'s own case is removed', () {
      final ({String text, bool changed}) r = RulingGate.filterLive(
        'Divorce has conditions in Islam. Your marriage is valid. Please be '
        'kind to each other.',
      );
      expect(r.changed, isTrue);
      expect(r.text.contains('Your marriage is valid'), isFalse);
      expect(r.text, contains('qualified scholar'));
      final ({String text, bool changed}) ok =
          RulingGate.filterLive('Patience is beloved to Allah.');
      expect(ok.changed, isFalse);
    });
  });

  group('minor signal', () {
    test('under-18 statements are caught', () {
      for (final String q in <String>[
        'I am 14 and I want to ask about fasting',
        "i'm 15 years old",
        'im 13',
        "i'm in grade 8, how do I pray",
        'I am a teenager and my parents do not let me pray',
        'my age is 16',
        'I am a 12 year old girl',
      ]) {
        expect(MinorSignal.isMinor(q), isTrue, reason: q);
      }
    });

    test('real minors are still caught when they say it plainly', () {
      for (final String q in <String>[
        'I am 14',
        'im 12 years old',
        "i'm just a 14 year old",
        'as a 13 year old muslim I want to fast',
        '14 yo here, how do I pray',
        'A 14 year old muslim asking about hijab',
        'I am 14 and my brother is 8 years old',
        'me and my sister are 15 years old',
      ]) {
        expect(MinorSignal.isMinor(q), isTrue, reason: q);
      }
    });

    test('an age said about someone else does not lock the session', () {
      for (final String q in <String>[
        'How do I teach my 5 year old to pray?',
        'my 5 year old',
        'my 8-year-old son wants to learn wudu',
        'my son is 9 years old and will not pray',
        'my daughter, who is 7 years old, wants to fast',
        'I have a 6 year old daughter who will not pray',
        'a 10 year old girl asked me how to pray',
        'Teach a 10 year old to pray',
        'our 6 year old keeps asking about Allah',
      ]) {
        expect(MinorSignal.isMinor(q), isFalse, reason: q);
      }
    });

    test('adults and non-age numbers are not caught', () {
      for (final String q in <String>[
        'I am 25 and I want to learn about zakat',
        'I am 12 minutes late for prayer',
        "I'm 40 years old",
        'I am 18',
        'What is the ruling on missing 5 prayers?',
      ]) {
        expect(MinorSignal.isMinor(q), isFalse, reason: q);
      }
    });

    test('replies point to a trusted adult and rotate', () {
      expect(MinorSignal.replyFor(0), MinorSignal.firstReply);
      expect(MinorSignal.replyFor(1), isNot(MinorSignal.firstReply));
      expect(MinorSignal.replyFor(1), isNot(MinorSignal.replyFor(2)));
      expect(MinorSignal.firstReply.toLowerCase(), contains('parent'));
    });
  });

  group('madhhab', () {
    test('codes round-trip and unknown falls back to not sure', () {
      for (final Madhhab m in Madhhab.values) {
        expect(Madhhab.fromCode(m.code), m);
      }
      expect(Madhhab.fromCode('nonsense'), Madhhab.notSure);
      expect(Madhhab.fromCode(null), Madhhab.notSure);
    });

    test('the prompt line names the school and never calls another wrong', () {
      expect(Madhhab.hanbali.promptLine, contains('Hanbali'));
      expect(Madhhab.hanbali.promptLine.toLowerCase(), contains('never say'));
      expect(Madhhab.notSure.promptLine.toLowerCase(), contains('differ'));
      expect(kHadiScopeNote, contains('Sunni'));
    });
  });

  group('report service', () {
    test('toMap has no user id and caps the sizes', () {
      final HadiReport r = HadiReport(
        reason: HadiReportReason.wrongQuote,
        answer: 'a' * 5000,
        question: 'q' * 5000,
        sources: const <String>['q:1:1', 'q:1:2', 'q:1:3', 'q:1:4', 'q:1:5', 'q:1:6'],
        live: true,
      );
      final Map<String, Object> m = r.toMap();
      expect((m['answer']! as String).length, 1200);
      expect((m['question']! as String).length, 500);
      expect((m['sources']! as List<String>).length, 5);
      expect(m.keys.toSet(),
          <String>{'reason', 'answer', 'question', 'sources', 'live'});
      expect(m['reason'], 'wrong_quote');
    });

    test('the question is left out unless it was given', () {
      const HadiReport r = HadiReport(
        reason: HadiReportReason.unsafe,
        answer: 'x',
        sources: <String>[],
        live: false,
      );
      expect(r.toMap().containsKey('question'), isFalse);
    });

    test('without Firebase the report is queued on the device, max 20',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiReportService svc = HadiReportService(prefs);
      for (int i = 0; i < 25; i++) {
        final bool sent = await svc.submit(HadiReport(
          reason: HadiReportReason.other,
          answer: 'answer $i',
          sources: const <String>[],
          live: false,
        ));
        expect(sent, isFalse);
      }
      expect(svc.queued.length, HadiReportService.maxQueued);
      expect(svc.queued.last['answer'], 'answer 24');
    });

    test('every reason in the app is allowed by firestore.rules', () {
      final String rules = File('firestore.rules').readAsStringSync();
      final int at = rules.indexOf('match /hadi_reports/');
      expect(at, greaterThan(0));
      final String block = rules.substring(at, rules.indexOf('}', at + 400));
      for (final HadiReportReason r in HadiReportReason.values) {
        expect(block.contains("'${r.code}'"), isTrue, reason: r.code);
      }
      expect(block, contains('allow read: if false'));
      expect(block, contains('allow update, delete: if false'));
      expect(block, contains('hasOnly'));
      expect(block, contains('request.time'));
      expect(block.contains('uid'), isFalse,
          reason: 'a report must not store who sent it');
    });
  });
}
