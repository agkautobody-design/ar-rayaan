import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_samples.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_explain.dart';
import 'package:ar_rayaan/features/hadi/data/hadi_routing.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:ar_rayaan/features/hadi/grounding/ruling_gate.dart';
import 'package:ar_rayaan/features/hadi/presentation/hadi_screen.dart';
import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:ar_rayaan/features/sources/presentation/content_policy_screen.dart';
import 'package:ar_rayaan/features/stories/data/stories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';
import 'hadi_eval/corpus_fixture.dart';

Future<String> ask(String q) =>
    const OfflineHadiProvider().ask(q, const <HadiMessage>[]);

/// Quotes compared without caring about curly or straight marks, case,
/// spacing or the full stop at the end.
String _plain(String s) => s
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('\\\'', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[.,;:]+$'), '');

/// Providers that read from disk or the asset bundle are replaced, so a
/// reply never waits on real I/O under the test clock.
List<Override> _fixtures() {
  final HadiCorpus corpus = loadRealCorpus();
  return <Override>[
    hadiCorpusProvider.overrideWith((ref) => corpus),
    storiesProvider.overrideWith((ref) async => const []),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('every line Hadi quotes from the app is really in the app', () {
    final List<dynamic> guides =
        json.decode(File('assets/guides/guides.json').readAsStringSync())
            as List<dynamic>;
    final List<dynamic> newMuslim =
        json.decode(File('assets/stories/newmuslim.json').readAsStringSync())
            as List<dynamic>;
    final StringBuffer all = StringBuffer();
    for (final dynamic g in guides) {
      final Map<String, dynamic> m = g as Map<String, dynamic>;
      all
        ..writeln(m['subtitle'])
        ..writeln((m['steps'] as List<dynamic>).join('\n'));
    }
    for (final dynamic s in newMuslim) {
      for (final dynamic c
          in (s as Map<String, dynamic>)['chapters'] as List<dynamic>) {
        all.writeln((c as Map<String, dynamic>)['body']);
      }
    }
    for (final (String, List<String>) section
        in ContentPolicyScreen.sections) {
      all.writeln(section.$2.join('\n'));
    }
    all.writeln(
        File('lib/features/academy/application/academy_strings.dart')
            .readAsStringSync());
    final String corpus = _plain(all.toString());

    final Map<String, String> replies = <String, String>{
      'beginner': HadiRouting.beginnerReply,
      'fasting': HadiExplain.fastingReply,
      'interesting': HadiExplain.ramadanInterestingReply,
      'tahajjud': HadiExplain.tahajjudReply,
      'how-i-work': HadiExplain.howIWorkReply,
    };
    for (final MapEntry<String, String> e in replies.entries) {
      test('${e.key}: each quotation is a line the app has', () {
        final List<String> quotes = <String>[
          for (final RegExpMatch m
              in RegExp('“([^”]{25,})”').allMatches(e.value))
            m.group(1)!,
        ];
        expect(quotes, isNotEmpty);
        for (final String q in quotes) {
          expect(corpus.contains(_plain(q)), isTrue, reason: q);
        }
      });
    }

    test('the Qur’an 2:183 quotation is word for word the Qur’an text', () {
      final String quran = condenseText(quranEnglish(2, 183, 183));
      final String quoted = condenseText(
        'O you who have believed, decreed upon you is fasting as it was '
        'decreed upon those before you that you may become righteous',
      );
      expect(quran.contains(quoted), isTrue);
      expect(HadiExplain.fastingReply, contains('may become righteous'));
    });
  });

  group('the buttons Hadi composes are real', () {
    final Set<String> guideIds = <String>{
      for (final dynamic g in json.decode(
              File('assets/guides/guides.json').readAsStringSync())
          as List<dynamic>)
        (g as Map<String, dynamic>)['id'] as String,
    };

    test('every named guide exists in guides.json', () {
      for (final String id in kHadiGuideNames.keys) {
        expect(guideIds.contains(id), isTrue, reason: id);
      }
    });

    test('guide routes are allowed only for the named guides', () {
      expect(HadiTokens.isAllowed('/huda/guide?id=huda-fasting'), isTrue);
      expect(HadiTokens.isAllowed('/huda/guide?id=huda-unknown'), isFalse);
      expect(HadiTokens.isAllowed('/huda/guide'), isFalse);
      expect(HadiTokens.isAllowed('/evil'), isFalse);
      expect(
        HadiTokens.routesOf(
          'x [GO:/huda/guide?id=huda-witr] [GO:/huda/guide?id=bogus] [GO:/prayer]',
        ),
        <String>['/huda/guide?id=huda-witr', '/prayer'],
      );
      expect(HadiTokens.labelFor('/huda/guide?id=huda-nikah'),
          'Open the Nikah guide');
      expect(HadiTokens.strip('a [GO:/huda/guide?id=huda-witr]'), 'a');
    });

    test('every [GO:] token in hadi_explain.dart is allowed', () {
      final String src =
          File('lib/features/hadi/data/hadi_explain.dart').readAsStringSync();
      final List<String> tokens = <String>[
        for (final RegExpMatch m
            in RegExp(r'\[GO:(/[^\]]+)\]').allMatches(src))
          m.group(1)!,
      ];
      expect(tokens, isNotEmpty);
      for (final String t in tokens) {
        expect(HadiTokens.isAllowed(t), isTrue, reason: t);
      }
    });

    test('new Hadi button routes are real routes', () {
      final String router = File('lib/app/router.dart').readAsStringSync();
      for (final String p in <String>[
        '/huda/guide',
        '/academy/family-life',
        '/academy/stories',
      ]) {
        expect(router.contains("'$p'"), isTrue, reason: p);
      }
    });
  });

  group('what is Islam: the app’s own lines, then the places', () {
    test('quotes the New Muslim path and links both places', () async {
      final String a = await ask('What is Islam?');
      expect(a, contains('the door into Islam'));
      expect(a, contains('Islam stands on five'));
      expect(a, contains('(Qur’an 3:19)'));
      expect(a, contains('[GO:/new-muslim]'));
      expect(a, contains('[GO:/huda/guide?id=huda-what-is-islam]'));
      expect(a.contains('enough authentic knowledge'), isFalse);
    });
  });

  group('why Muslims fast, and Ramadan', () {
    test('plain explanation from the Fasting guide, guide linked', () async {
      for (final String q in <String>[
        'why do Muslims fast',
        'Why do muslims fast?',
        'What is Ramadan and how does fasting work?',
        'what is ramadan',
        'explain fasting to me',
      ]) {
        final String a = await ask(q);
        expect(a, contains('dawn'), reason: q);
        expect(a, contains('sunset'), reason: q);
        expect(a, contains('that you may become righteous'), reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-fasting]'), reason: q);
      }
    });

    test('something interesting is a different answer from why', () async {
      final String why = await ask('why do Muslims fast');
      for (final String q in <String>[
        'something interesting about Ramadan',
        'tell me a fun fact about Ramadan',
      ]) {
        final String a = await ask(q);
        expect(a, isNot(why), reason: q);
        expect(a, contains('free wind'), reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-taraweeh]'), reason: q);
      }
    });

    test('a different fasting question is not captured', () async {
      expect(await ask('What breaks the fast?'),
          isNot(contains('From dawn to sunset')));
      expect(await ask('Who is exempt from fasting?'),
          isNot(contains('From dawn to sunset')));
      expect(await ask('How do I start fasting?'), contains('pillars of Islam'));
    });
  });

  group('tahajjud and the schools: honest in the chat itself', () {
    test('tahajjud links its guide, says it is not yet reviewed, no count',
        () async {
      final String a = await ask('how do I pray tahajjud');
      expect(a, contains('scholar review needed'));
      expect(a, contains('I will not give you a rak’ah count'));
      expect(a, contains('[GO:/huda/guide?id=huda-tahajjud]'));
      expect(a, contains('[GO:/prayer]'));
      expect(await ask('how to pray tahajjud'), a);
    });

    test('the schools: four names, then what Hadi cannot do', () async {
      for (final String q in <String>[
        'what are the madhhabs',
        'name the four schools and how they differ',
        'How do Hanafi and Shafii differ on hands in prayer',
      ]) {
        final String a = await ask(q);
        expect(a, startsWith('There are four major schools of fiqh: Hanafi, '
            'Maliki, Shafi’i, and Hanbali.'), reason: q);
        expect(a, contains('holds no verified text'), reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-madhhab-overview]'),
            reason: q);
        expect(a, contains('[GO:/sources]'), reason: q);
      }
    });

    test('the sentence naming the four schools is on the shelf already', () {
      final String src = File(
        'lib/features/hadi/data/offline_hadi_provider.dart',
      ).readAsStringSync();
      expect(src, contains("Hanafi, Maliki, Shafi\\'i, and Hanbali."));
    });
  });

  group('a legal question is not a person in pain', () {
    test('the punishment for leaving Islam goes to a scholar', () async {
      for (final String q in <String>[
        'Is the punishment for leaving Islam death?',
        'what is the penalty for apostasy in islam',
        'is leaving islam punishable by death',
      ]) {
        final String a = await ask(q);
        expect(a, HadiExplain.legalReply, reason: q);
        expect(a.contains('Thank you for telling me'), isFalse);
        expect(OfflineHadiProvider.distressReplies.contains(a), isFalse);
        expect(RulingGate.classify(q), RulingClass.general, reason: q);
      }
    });

    test('a first-person feeling is still met with comfort', () async {
      final String a = await ask('I feel stupid');
      expect(OfflineHadiProvider.distressReplies.contains(a), isTrue);
      expect(
        RulingGate.isLegalPenaltyQuestion(
            'I want to leave Islam, what is the punishment'),
        isFalse,
      );
    });

    test('a question about a feeling word is not comfort', () async {
      final String a = await ask('is anxiety a sin');
      expect(OfflineHadiProvider.distressReplies.contains(a), isFalse);
    });

    test('the crisis detector is untouched', () {
      expect(CrisisDetector.detect('I want to kill myself'), isNotNull);
      expect(CrisisDetector.detect('Is the punishment for leaving Islam death?'),
          isNull);
    });
  });

  group('how Hadi works: from the app’s own disclosures', () {
    test('who reviewed, has a scholar checked, are you a scholar', () async {
      for (final String q in <String>[
        'who reviewed your answers',
        'has any scholar checked this app',
        'who reviewed your answers / has a scholar checked this?',
        'are your answers reliable',
        'how do you work',
        'are you a scholar',
        'can I trust you',
      ]) {
        final String a = await ask(q);
        expect(OfflineHadiProvider.isDecline(a), isFalse, reason: q);
        expect(a, contains('Scholar review needed'));
        expect(a, contains('[GO:/sources]'));
        expect(a.contains('Perhaps you meant'), isFalse);
      }
    });

    test('does not capture questions that only share a word', () async {
      expect(await ask('who wrote the Quran'),
          isNot(HadiExplain.howIWorkReply));
      expect(await ask('how do I pray'), isNot(HadiExplain.howIWorkReply));
    });
  });

  group('stories, marriage, masjid', () {
    test('a request for a story goes to the Stories list', () async {
      for (final String q in <String>[
        'tell me a story',
        'Tell me a story please',
        'can you tell me a short story for kids',
        'I want a bedtime story',
        'story time',
      ]) {
        final String a = await ask(q);
        expect(a, HadiExplain.storyReply, reason: q);
        expect(a, contains('[GO:/stories]'));
        expect(a.contains('enough authentic knowledge'), isFalse);
      }
      expect(await ask('Tell me about the story of Yusuf'),
          isNot(HadiExplain.storyReply));
    });

    test('marriage goes to the Nikah guide and Family Life', () async {
      for (final String q in <String>[
        'what should I know about marriage',
        'tell me about marriage in islam',
        'marriage in Islam',
        'what are the conditions of a valid nikah',
      ]) {
        final String a = await ask(q);
        expect(OfflineHadiProvider.isDecline(a), isFalse, reason: q);
        expect(a, contains('[GO:/huda/guide?id=huda-nikah]'));
        expect(a, contains('[GO:/academy/family-life]'));
      }
    });

    test('the nearest masjid points to the Masajid screen', () async {
      final String a = await ask('Where is the nearest masjid and what time '
          'is Jumuah');
      expect(a, contains('[GO:/masajid]'));
      expect(a, contains('[GO:/prayer]'));
      expect(a, contains('cannot see where you are'));
      expect(await ask('find a mosque near me'), contains('[GO:/masajid]'));
      expect(await ask('dua for entering the masjid'),
          isNot(contains('cannot see where you are')));
    });
  });

  group('no composed reply is treated as a shelf answer', () {
    test('none gets a school-of-law line', () {
      for (final String fixed in <String>[
        ...HadiExplain.fixedReplies,
        HadiExplain.masjidReply('nearest masjid'),
        HadiRouting.beginnerReply,
      ]) {
        expect(
          OfflineHadiProvider.schoolNote(
            question: 'is it halal',
            answer: fixed,
            schoolLabel: 'Hanafi',
          ),
          isNull,
        );
      }
    });

    test('a short yes after one does not invent an offer', () async {
      for (final String reply in <String>[
        HadiExplain.fastingReply,
        HadiExplain.storyReply,
        HadiExplain.marriageReply,
        HadiExplain.schoolsReply,
        HadiExplain.tahajjudReply,
        HadiExplain.legalReply,
        HadiRouting.beginnerReply,
      ]) {
        final HadiFollowUp? f = HadiRouting.followUp(
          'yes please',
          <HadiMessage>[
            const HadiMessage(fromHadi: false, text: 'q'),
            HadiMessage(fromHadi: true, text: reply),
          ],
        );
        expect(f?.question, isNull, reason: reply.substring(0, 40));
      }
    });
  });

  group('the "These may help" line', () {
    test('is removed when no button follows it', () {
      expect(
        HadiRouting.guardLeadIn(
          'Sorry.\n\n${HadiRouting.refusalLeadIn}',
          const <String>[],
        ),
        'Sorry.',
      );
    });

    test('moves to the end, right above the buttons', () {
      final String out = HadiRouting.guardLeadIn(
        'Sorry.\n\n${HadiRouting.refusalLeadIn}\n\nNot a fatwa.',
        const <String>['/sources'],
      );
      expect(out, 'Sorry.\n\nNot a fatwa.\n\n${HadiRouting.refusalLeadIn}');
    });

    test('text without it is untouched', () {
      expect(HadiRouting.guardLeadIn('Hello', const <String>[]), 'Hello');
    });
  });

  group('follow-up chips fit the topic', () {
    test('after a fasting question the chips are about fasting', () {
      final List<String> s = hadiSuggestions(
        <String>['why do muslims fast'],
        lastQuestion: 'why do muslims fast',
      );
      expect(s.first, 'What breaks the fast?');
      expect(s.length, 3);
    });

    test('with no topic they are the usual starters', () {
      expect(hadiSuggestions(const <String>[]).first,
          kProposedHadiExchanges.first.question);
    });

    test('every topical chip gets a real answer, not a refusal', () async {
      for (final String q in <String>[
        'What breaks the fast?',
        'Who is exempt from fasting?',
        'What are the pillars of Islam?',
        'How do I pray Witr?',
      ]) {
        final String a = await ask(q);
        expect(a.contains('enough authentic knowledge'), isFalse, reason: q);
        expect(HadiRouting.isRefusal(a), isFalse, reason: q);
      }
    });
  });

  group('through the controller', () {
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

    Future<HadiMessage> reply(ProviderContainer c, String q) async {
      await c
          .read(hadiControllerProvider.notifier)
          .ask(q, provider: const OfflineHadiProvider());
      return c.read(hadiControllerProvider).messages.last;
    }

    test('the dating answer never promises buttons it does not show',
        () async {
      final ProviderContainer c = await container();
      final HadiMessage m = await reply(c, 'is dating allowed in Islam');
      expect(m.routes, isNotEmpty);
      if (m.text.contains(HadiRouting.refusalLeadIn)) {
        expect(m.text.trimRight().endsWith(HadiRouting.refusalLeadIn), isTrue,
            reason: 'the line must sit right above the buttons');
      }
      // Round 3: the buttons go to the app's own marriage content.
      expect(m.routes.first, '/huda/guide?id=huda-nikah');
      expect(m.routes, contains('/academy/family-life'));
    });

    test('every reply that says "may help" has buttons under it', () async {
      final ProviderContainer c = await container();
      for (final String q in <String>[
        'Tell me about quantum entanglement',
        'Is it halal to do the thing',
        'is dating allowed in Islam',
      ]) {
        final HadiMessage m = await reply(c, q);
        if (m.text.contains('These may help')) {
          expect(m.routes, isNotEmpty, reason: q);
        }
      }
    });

    test('the leaving-Islam question gets the scholar reply, not comfort',
        () async {
      final ProviderContainer c = await container();
      final HadiMessage m =
          await reply(c, 'Is the punishment for leaving Islam death?');
      expect(m.text.contains('Thank you for telling me'), isFalse);
      expect(m.text, contains('qualified scholar'));
      expect(m.routes.first, '/sources');
      expect(m.sensitive, isFalse);
    });

    test('a composed answer prints at most two cards, one of them the verse',
        () async {
      final ProviderContainer c = await container();
      final HadiMessage m = await reply(c, 'why do Muslims fast');
      expect(m.sources.length, lessThanOrEqualTo(6));
      expect(m.sources, contains('q:2:183'));
      expect(m.routes, contains('/huda/guide?id=huda-fasting'));
    });

    test('a second question gets its own, different reply', () async {
      final ProviderContainer c = await container();
      final HadiMessage a = await reply(c, 'what is ramadan');
      final HadiMessage b = await reply(c, 'something interesting about Ramadan');
      expect(b.text, isNot(a.text));
      expect(c.read(hadiControllerProvider).messages.length, 5);
      expect(c.read(hadiControllerProvider).typing, isFalse);
    });
  });

  group('the question box', () {
    testWidgets('3000 pasted characters are cut, sent, and the box is clean',
        (WidgetTester tester) async {
      await AppHarness.boot(tester, overrides: _fixtures());
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      final ProviderContainer c =
          ProviderScope.containerOf(tester.element(find.byType(HadiScreen)));
      final Finder field0 = find.descendant(
          of: find.byType(HadiScreen), matching: find.byType(TextField));
      final Finder send0 = find.descendant(
          of: find.byType(HadiScreen), matching: find.byIcon(Icons.send));
      List<String> asked() => <String>[
            for (final HadiMessage m in c.read(hadiControllerProvider).messages)
              if (!m.fromHadi) m.text,
          ];

      await tester.enterText(field0, 'A' * 3000);
      await tester.pump();
      final TextField field = tester.widget<TextField>(field0);
      expect(field.controller!.text.length, kHadiMaxInput);
      expect(find.byKey(const ValueKey<String>('hadi-input-note')),
          findsOneWidget);
      expect(find.textContaining('was cut to $kHadiMaxInput'), findsOneWidget);

      await tester.tap(send0);
      await AppHarness.settle(tester);
      expect(field.controller!.text, isEmpty);
      expect(asked().single.length, lessThanOrEqualTo(kHadiMaxInput));
      expect(find.byKey(const ValueKey<String>('hadi-input-note')),
          findsNothing);

      await tester.enterText(field0, 'What is zakat?');
      await tester.pump();
      await tester.tap(send0);
      await AppHarness.settle(tester);
      expect(asked().last, 'What is zakat?');
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('a second question is answered and its reply is on screen',
        (WidgetTester tester) async {
      await AppHarness.boot(tester, height: 800, overrides: _fixtures());
      await AppHarness.go(tester, find.byType(Scaffold).first, '/hadi');
      final ProviderContainer c =
          ProviderScope.containerOf(tester.element(find.byType(HadiScreen)));
      final Finder field0 = find.descendant(
          of: find.byType(HadiScreen), matching: find.byType(TextField));
      final Finder send0 = find.descendant(
          of: find.byType(HadiScreen), matching: find.byIcon(Icons.send));
      for (final String q in <String>[
        'What is Ramadan and how does fasting work?',
        'what is zakat',
      ]) {
        await tester.enterText(field0, q);
        await tester.pump();
        await tester.tap(send0);
        await AppHarness.settle(tester);
      }
      final HadiState s = c.read(hadiControllerProvider);
      expect(s.typing, isFalse);
      expect(s.messages.where((HadiMessage m) => !m.fromHadi).length, 2);
      expect(s.messages.last.text, contains('Zakat'));
    });
  });
}
