import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/minor_signal.dart';
import 'package:ar_rayaan/features/hadi/grounding/ruling_gate.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answer quality, not just safety: what Hādi's offline shelf actually says
/// to the 25 questions the review asked, plus the awkward phrasings around
/// them. No model and no network. A reply "counts" only when it is a real
/// answer (not a decline or a stock reply) on the right topic.

Future<String> offline(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

class AnswerCase {
  const AnswerCase(
    this.id,
    this.question,
    this.mustContain, {
    this.mustNotContain = const <String>[],
  });

  final String id;
  final String question;
  final String mustContain;
  final List<String> mustNotContain;
}

/// Questions the shelf now answers on topic.
const List<AnswerCase> kAnswerCases = <AnswerCase>[
  AnswerCase('fajr', 'How many rakats is Fajr?', 'Fajr 2'),
  AnswerCase('breaks-wudu', 'What breaks my wudu?', 'Wudu is broken by',
      mustNotContain: <String>['purification before prayer']),
  // Round 3: the shelf only holds shortening, so combining is said plainly
  // to be unanswered instead of answered with a different question.
  AnswerCase('combine', 'Can I combine prayers while travelling?', 'Combining:',
      mustNotContain: <String>['do not have a verified answer']),
  AnswerCase('kursi', 'What is the virtue of Ayat al-Kursi?', 'Ayat al-Kursi'),
  AnswerCase(
      'sleep-surah', 'Which surah should I read before sleeping?', 'Before sleep'),
  AnswerCase('ikhlas', 'What does Surah Ikhlas mean?', 'oneness of Allah'),
  AnswerCase(
      'grief',
      "My mother passed away last month and I can't stop crying",
      'belong to Allah'),
  AnswerCase('stressed', "I'm so stressed about my exams", 'worry and grief'),
  AnswerCase('allah-hates-me', 'I feel like Allah hates me',
      'taken leave of you',
      mustNotContain: <String>['enough authentic knowledge']),
  AnswerCase('teach-5yo', 'How do I teach my 5 year old to pray?', 'seven',
      mustNotContain: <String>['istikhara']),
  AnswerCase(
      'son-wont-pray', "My son doesn't want to pray, what should I do?", 'seven',
      mustNotContain: <String>['istikhara', 'astakhiruka']),
  AnswerCase('music', 'Is music haram?', 'musical instruments'),
  AnswerCase('roman-urdu-namaz', 'namaz ka tareeqa batao', 'two-rak'),
  AnswerCase('same-sin', 'I keep making the same sin',
      'despair of the mercy of Allah'),
  AnswerCase('patience-quran', 'What does Allah say about patience in the Quran',
      'Allah is with the patient',
      mustNotContain: <String>['114 surahs']),
  AnswerCase('friday', 'Do you have a khutbah for Friday', 'Friday',
      mustNotContain: <String>['light will shine for him']),
  AnswerCase('witr', 'How do I pray Witr?', 'odd-numbered'),
  AnswerCase('two-rakahs', "How do I pray two rak'ahs?", 'two-rak'),
  // Round 2: answers built from the app's own guides, never a wall of verses.
  AnswerCase('why-fast', 'Why do Muslims fast?', 'until sunset',
      mustNotContain: <String>['2:183-185']),
  AnswerCase('ramadan-fact', 'Tell me something interesting about Ramadan',
      'free wind',
      mustNotContain: <String>['2:183-185']),
  AnswerCase('marriage', 'What should I know about marriage?', 'Nikah'),
  AnswerCase('story', 'Tell me a story', 'Stories',
      mustNotContain: <String>['enough authentic knowledge']),
  AnswerCase('reviewed', 'Who reviewed your answers?', 'Not yet scholar-reviewed',
      mustNotContain: <String>['Perhaps you meant']),
  AnswerCase('schools', 'What are the madhhabs?', 'Hanafi, Maliki',
      mustNotContain: <String>['Shariah is the divine law']),
  AnswerCase('tahajjud', 'How do I pray tahajjud?', 'not yet scholar-reviewed'),
  AnswerCase('apostasy', 'Is the punishment for leaving Islam death?',
      'legal ruling',
      mustNotContain: <String>['Thank you for telling me']),
];

void main() {
  final Set<String> stock = <String>{
    OfflineHadiProvider.decline,
    OfflineHadiProvider.rulingDecline,
    OfflineHadiProvider.scriptReply,
    OfflineHadiProvider.scriptReplyArabic,
    OfflineHadiProvider.scriptReplyUrdu,
    ...OfflineHadiProvider.rudeReplies,
    ...OfflineHadiProvider.distressReplies,
  };

  group('the 25 questions: right topic, never a stock reply', () {
    for (final AnswerCase c in kAnswerCases) {
      test('${c.id}: ${c.question}', () async {
        final String a = await offline(c.question);
        expect(stock.contains(a), isFalse, reason: 'got a stock reply');
        expect(a, contains(c.mustContain));
        for (final String bad in c.mustNotContain) {
          expect(a.contains(bad), isFalse, reason: 'must not say: $bad');
        }
      });
    }

    test('missed prayers for years is a question for a scholar', () {
      expect(
        RulingGate.classify('I missed my prayers for years, what do I do?'),
        RulingClass.personal,
      );
    });

    test('"I want to die" meets the crisis layer first', () {
      expect(CrisisDetector.detect('I want to die'), isNotNull);
    });

    test('a parent asking about a 5 year old is not treated as a child', () {
      expect(MinorSignal.isMinor('How do I teach my 5 year old to pray?'),
          isFalse);
      expect(MinorSignal.isMinor("I am 15 and my parents don't let me wear hijab"),
          isTrue);
    });

    test('rulings: personal goes to a scholar, no verdict on tattoos or bitcoin',
        () async {
      expect(RulingGate.classify('Should I divorce my wife?'),
          RulingClass.personal);
      // Bitcoin: scholars differ, and the answer says so without a verdict.
      final String btc = await offline('Is bitcoin halal?');
      expect(btc, contains('scholars disagree'));
      expect(btc.toLowerCase(), contains('scholar you trust'));
      // Tattoos: the sourced answer, not a refusal.
      final String tat = await offline('What is the ruling on tattoos?');
      expect(tat, contains('Sahih al-Bukhari 5937'));
      expect(OfflineHadiProvider.isDecline(tat), isFalse);
    });
  });

  group('no stock istikhara for things that are not decisions', () {
    for (final String q in <String>[
      "I'm being bullied at school, what should I do",
      'What should I do about my friend who left Islam',
      'what should I do',
    ]) {
      test(q, () async {
        final String a = await offline(q);
        expect(a.toLowerCase().contains('istikhara'), isFalse);
        expect(a.contains('astakhiruka'), isFalse);
      });
    }

    test('the istikhara question itself still finds istikhara', () async {
      expect(await offline('Tell me about istikhara'),
          contains('astakhiruka'));
    });
  });

  group('distress is met with warmth, never the cold decline', () {
    for (final String q in <String>[
      'I feel stupid',
      'i feel like a failure',
      "I'm exhausted all the time",
      'nobody cares about me',
      'i am so tired and burned out',
      'I cry every night',
      'I feel so heavy today',
    ]) {
      test(q, () async {
        final String a = await offline(q);
        expect(OfflineHadiProvider.distressReplies.contains(a), isTrue);
        expect(a, isNot(OfflineHadiProvider.decline));
        expect(a, contains('[GO:/sakina]'));
        expect(a, contains('[GO:/feelings]'));
        expect(a, anyOf(contains('Qur'), contains('Allah')));
      });
    }

    test('a heavy feeling never gets the scholar-and-key decline', () async {
      final String a = await offline('I feel stupid');
      expect(a.contains('API key'), isFalse);
      expect(a.contains('Saqib'), isFalse);
    });
  });

  group('rude, off-topic and other-script input', () {
    test('rude input gets a calm, short reply with no lecture', () async {
      for (final String q in <String>[
        'You are useless, stupid bot',
        "You're a stupid useless bot",
        'shut up',
      ]) {
        final String a = await offline(q);
        expect(OfflineHadiProvider.rudeReplies.contains(a), isTrue, reason: q);
        expect(a.length, lessThan(200));
      }
    });

    test('a feeling about oneself is not mistaken for rudeness', () async {
      final String a = await offline('I feel useless');
      expect(OfflineHadiProvider.rudeReplies.contains(a), isFalse);
      expect(OfflineHadiProvider.distressReplies.contains(a), isTrue);
    });

    test('off-topic input says what Hadi covers', () async {
      for (final String q in <String>[
        'Who won the world cup?',
        'What is the weather today',
        'tell me a joke',
      ]) {
        expect(OfflineHadiProvider.isDecline(await offline(q)), isTrue, reason: q);
      }
    });

    test('Arabic and Urdu script is named honestly, not declined as unknown',
        () async {
      expect(await offline('ما حكم الصلاة بدون وضوء؟'),
          OfflineHadiProvider.scriptReplyArabic);
      expect(await offline('مجھے نماز کا طریقہ بتائیں'),
          OfflineHadiProvider.scriptReplyUrdu);
      expect(
        await const OfflineHadiProvider(hasKey: true)
            .ask('مجھے نماز کا طریقہ بتائیں', const <HadiMessage>[]),
        OfflineHadiProvider.scriptReplyUrduKeyed,
      );
      expect(
        await const OfflineHadiProvider(hasKey: true)
            .ask('ما حكم الصلاة بدون وضوء؟', const <HadiMessage>[]),
        OfflineHadiProvider.scriptReplyArabicKeyed,
      );
    });

    test('someone with a live key is never told to add one', () async {
      const OfflineHadiProvider keyed = OfflineHadiProvider(hasKey: true);
      final String a = await keyed.ask(
          'Tell me about quantum entanglement', const <HadiMessage>[]);
      expect(OfflineHadiProvider.isDecline(a), isTrue);
      expect(a.contains('API key'), isFalse);
      expect(OfflineHadiProvider.decline.contains('API key'), isFalse);
    });
  });

  group('take me to …', () {
    test('a plain request to go somewhere becomes a button', () async {
      final Map<String, String> routes = <String, String>{
        'Take me to the Stories': '/stories',
        'take me to qibla': '/qibla',
        'open the games': '/games',
        'go to the zakat calculator': '/zakat',
        'Can you please take me to my journey': '/journey',
        'where is the qibla': '/qibla',
      };
      for (final MapEntry<String, String> e in routes.entries) {
        expect(await offline(e.key), contains('[GO:${e.value}]'),
            reason: e.key);
      }
    });

    test('an ordinary question is not mistaken for a request to move',
        () async {
      final String a = await offline('Tell me about quantum entanglement');
      expect(a.contains('[GO:'), isFalse);
      final String b = await offline('show me the dua for leaving home');
      expect(b.contains('Leaving home'), isTrue);
    });
  });
}
