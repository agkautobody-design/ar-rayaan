import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_samples.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

Future<String> ask(String q, [List<HadiMessage> history = const <HadiMessage>[]]) =>
    const OfflineHadiProvider().ask(q, history);

/// The conversation so far as the controller hands it to the provider.
List<HadiMessage> thread(List<(String, String)> turns) => <HadiMessage>[
      for (final (String q, String a) in turns) ...<HadiMessage>[
        HadiMessage(fromHadi: false, text: q),
        HadiMessage(
          fromHadi: true,
          text: a.replaceAll(RegExp(r'\s*\[GO:[^\]]*\]'), '').trim(),
        ),
      ],
    ];

String _plain(String s) => s
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[.,;:]+$'), '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a question with no verified answer is not answered with another', () {
    test('combining Dhuhr and Asr says so plainly and opens the Travel guide',
        () async {
      for (final String q in <String>[
        'can I combine Dhuhr and Asr when travelling',
        'Can I combine prayers while travelling?',
        'is it allowed to combine maghrib and isha on a trip',
      ]) {
        final String a = await ask(q);
        expect(a, contains('do not have a verified answer'), reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-travel]'), reason: q);
        expect(a.contains('Dhuhr is four'), isFalse, reason: q);
        expect(a.contains('Perhaps you meant'), isFalse, reason: q);
      }
    });

    test('shortening a prayer still gets the shelf answer', () async {
      final String a = await ask('shorten prayer travel');
      expect(a.contains('do not have a verified answer'), isFalse);
    });

    test('the apostasy question with "give me the source" is a ruling hand-off',
        () async {
      final String a = await ask(
        'Is it true that Islam says apostates must be killed? Give me the source.',
      );
      expect(a.contains('builds only on'), isFalse);
      expect(a, contains('qualified scholar'));
    });
  });

  group('people Hadi has no source on', () {
    test('the shaykh Our Sources names is not described as the Prophet',
        () async {
      for (final String q in <String>[
        'who is Shaykh Muhammad Saqib Iqbal',
        'Who is Muhammad Saqib Iqbal and what are his credentials?',
      ]) {
        final String a = await ask(q);
        expect(a, contains('cannot speak about individuals I have no source'),
            reason: q);
        expect(a.contains('Seal of the Prophets'), isFalse, reason: q);
        expect(a, contains('[GO:/sources]'), reason: q);
      }
    });

    test('an unknown titled person gets the same plain guard', () async {
      final String a = await ask('who is Shaykh Ahmad Zubair');
      expect(a, HadiRouting.unknownPersonReply);
    });

    test('topics, the app and its own characters are not caught', () async {
      expect(await ask('who is Wasia'), contains('Wasia is the AI teacher'));
      expect(HadiRouting.unknownPersonReply,
          isNot(await ask('Tell me about quantum entanglement')));
      expect(HadiRouting.unknownPersonReply, isNot(await ask('who is Allah')));
    });
  });

  group('medicine: see the doctor, do not stop', () {
    test('the offline reply says it, with the guide line', () async {
      final String a = await ask('tell me about anxiety medication');
      expect(a, contains('do not stop or change a medicine on your own'));
      expect(a, contains('doctor or pharmacist'));
      expect(a.contains('seek refuge'), isFalse);
      expect(a, contains('[GO:/huda/guide?id=huda-illness]'));
    });

    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HadiCorpus corpus = loadRealCorpus();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          hadiCorpusProvider.overrideWith((ref) => corpus),
          storiesProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a "should I ... is it haram" medicine question is not a marriage '
        'ruling hand-off', () async {
      final ProviderContainer c = await container();
      await c.read(hadiControllerProvider.notifier).ask(
            'Should I take the anxiety medication my doctor prescribed, '
            'is it haram?',
            provider: const OfflineHadiProvider(),
          );
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.text, contains('follow'));
      expect(m.text, contains('doctor'));
      expect(m.text.contains('marriage'), isFalse);
      expect(m.text.contains('['), isFalse);
      expect(m.sources, isEmpty);
      expect(m.routes, contains('/huda/guide?id=huda-illness'));
    });
  });

  group('relationship questions get one calm, consistent answer', () {
    test('"dating" and "boyfriend" are treated alike, with no assumed sin',
        () async {
      final String a = await ask('is dating allowed in islam');
      final String b = await ask('can I have a boyfriend');
      expect(a, b);
      expect(a, contains('not assuming anything about you'));
      expect(a.contains('17:32'), isFalse);
      expect(a.contains('already happened'), isFalse);
      expect(a, contains('[GO:/huda/guide?id=huda-nikah]'));
    });

    test('a person who is hurting gets comfort, never a verse about sin',
        () async {
      final String a = await ask('I feel so guilty about my boyfriend');
      expect(OfflineHadiProvider.distressReplies.contains(a), isTrue);
      expect(a.contains('17:32'), isFalse);
    });
  });

  group('differences between scholars and groups', () {
    test('the same question typed twice is not answered with the same '
        'paragraph again', () async {
      final String first = await ask('why do scholars disagree');
      final List<HadiMessage> h1 =
          thread(<(String, String)>[('why do scholars disagree', first)]);
      final String second = await ask('why do scholars disagree', h1);
      expect(second, contains('same answer I gave a moment ago'));
      expect(second, contains('[GO:/sources/policy]'));
      expect(second, contains('Your school of law'));
      final List<HadiMessage> h2 = thread(<(String, String)>[
        ('why do scholars disagree', first),
        ('why do scholars disagree', second),
      ]);
      final String third = await ask('why do scholars disagree', h2);
      expect(third, isNot(second));
      expect(third, contains('only be saying the same thing again'));
    });

    test('the first time, the shelf answer is given', () async {
      expect(await ask('why do scholars disagree'), contains('ijtihad'));
    });

    test('Sunni and Shia is an honest hand-off, not "not enough knowledge"',
        () async {
      final String a = await ask('what is the difference between sunni and shia');
      expect(a.contains('enough authentic knowledge'), isFalse);
      expect(a, contains('[GO:/sources/policy]'));
      expect(a.contains('free API key'), isFalse);
    });

    test('a crisis reply is never varied away', () async {
      final String a = await ask('I want to kill myself');
      final String b = await ask(
        'I want to kill myself',
        thread(<(String, String)>[('I want to kill myself', a)]),
      );
      expect(b, a);
    });
  });

  group('routes to screens the app already has', () {
    test('memorising a surah goes to the Hifz planner', () async {
      for (final String q in <String>[
        'how do I memorise Surah Al-Mulk',
        'how can I memorise and track Al-Mulk',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/academy/hifz]'), reason: q);
        expect(a.contains('Sunan Abi Dawud'), isFalse, reason: q);
      }
      expect(await ask('memorization tips'), contains('memorizer'));
    });

    test('rights of husband and wife go to the Nikah guide', () async {
      final String a = await ask('what are the rights of husband and wife');
      expect(a, contains('[GO:/huda/guide?id=huda-nikah]'));
      expect(a, contains('one side only'));
    });

    test('someone new to Islam, or about to marry, is routed', () async {
      expect(await ask('I am new to Islam where do I start'),
          contains('[GO:/new-muslim]'));
      expect(await ask('I just converted to Islam'),
          contains('[GO:/new-muslim]'));
      expect(await ask('I want to get married what should I know'),
          contains('[GO:/huda/guide?id=huda-nikah]'));
    });

    test('night prayer how-to goes to the Tahajjud guide and Prayer Times',
        () async {
      for (final String q in <String>[
        'how do I pray night prayer',
        'how to pray tahajjud',
        'teach me qiyam',
      ]) {
        final String a = await ask(q);
        expect(a, contains('[GO:/huda/guide?id=huda-tahajjud]'), reason: q);
        expect(a, contains('[GO:/prayer]'), reason: q);
      }
    });
  });

  group('every button and quotation in the new replies is real', () {
    final List<String> replies = <String>[
      HadiRouting.travelPrayerReply,
      HadiRouting.unknownPersonReply,
      HadiRouting.sourceShaykhReply,
      HadiRouting.relationshipReply,
      HadiRouting.spouseRightsReply,
      HadiRouting.groupDifferenceReply,
      HadiRouting.memoriseReply,
      HadiRouting.medicalReply('anxiety medication'),
    ];

    test('each [GO:] is on the whitelist', () {
      for (final String r in replies) {
        for (final RegExpMatch m
            in RegExp(r'\[GO:([^\]]+)\]').allMatches(r)) {
          expect(HadiTokens.isAllowed(m.group(1)!), isTrue, reason: m.group(1));
        }
      }
    });

    test('quoted lines are lines in the guides', () {
      final List<dynamic> guides =
          json.decode(File('assets/guides/guides.json').readAsStringSync())
              as List<dynamic>;
      final StringBuffer all = StringBuffer();
      for (final dynamic g in guides) {
        final Map<String, dynamic> m = g as Map<String, dynamic>;
        all
          ..writeln(m['subtitle'])
          ..writeln(m['madhhabNote'])
          ..writeln((m['steps'] as List<dynamic>).join('\n'));
      }
      final String corpus = _plain(all.toString());
      for (final String r in replies) {
        for (final RegExpMatch m in RegExp('“([^”]{25,})”').allMatches(r)) {
          expect(corpus.contains(_plain(m.group(1)!)), isTrue,
              reason: m.group(1));
        }
      }
    });

    test('the new replies count as fixed replies', () {
      for (final String r in replies) {
        expect(HadiRouting.isFixed(r), isTrue);
      }
    });
  });

  group('suggestion chips follow the topic', () {
    test('after a relationship question they are about marriage and family',
        () {
      final List<String> s = hadiSuggestions(
        <String>['can I have a boyfriend'],
        lastQuestion: 'can I have a boyfriend',
      );
      expect(s.first, 'Tell me about marriage in Islam');
    });

    test('after a question about memorising they are about the Qur\'an', () {
      final List<String> s = hadiSuggestions(
        <String>['how do I memorise Al-Mulk'],
        lastQuestion: 'how do I memorise Al-Mulk',
      );
      expect(s.first, 'I want to memorize Quran');
    });

    test('after a question on no topic they are about what Hadi can do', () {
      final List<String> s = hadiSuggestions(
        <String>['tell me about quantum entanglement'],
        lastQuestion: 'tell me about quantum entanglement',
      );
      expect(s, <String>[
        'What can you do?',
        'How do you work?',
        'Take me to the Stories',
      ]);
    });

    test('every topical chip gets a real answer, not a refusal', () async {
      for (final String q in kHadiTopicalChips) {
        final String a = await ask(q);
        expect(a.contains('enough authentic knowledge'), isFalse, reason: q);
        expect(HadiRouting.isRefusal(a), isFalse, reason: q);
      }
    });
  });
}
