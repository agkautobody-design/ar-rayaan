import 'dart:async';
import 'dart:convert';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/groq_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/grounding/corpus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hadi_eval/corpus_fixture.dart';

class _Stub implements HadiProvider {
  _Stub(this.reply);
  final String reply;
  int calls = 0;

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    return reply;
  }
}

class _Gate implements HadiProvider {
  _Gate(this.gate);
  final Completer<String> gate;

  @override
  Future<String> ask(String q, List<HadiMessage> h) => gate.future;
}

class _Boom implements HadiProvider {
  @override
  Future<String> ask(String q, List<HadiMessage> h) =>
      throw const HadiProviderException('The service is down.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container([
    Map<String, Object> initial = const <String, Object>{},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final HadiCorpus corpus = loadRealCorpus();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hadiCorpusProvider.overrideWith((ref) => corpus),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('the under-18 lock', () {
    test('a parent asking about a child is answered, and stays answered',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _Stub live = _Stub('Start with love and patience.');
      await ctrl.ask('How do I teach my 5 year old to pray?', provider: live);
      await ctrl.ask('What is witr?', provider: live);
      expect(live.calls, 2);
      expect(
        c.read(hadiControllerProvider).messages.last.crisis,
        isNull,
        reason: 'no child-safety reply for a question about a child',
      );
    });

    test('a real under-18 still locks, and a new conversation clears it',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final _Stub live = _Stub('Hello.');
      await ctrl.ask('im 12 years old, how do I pray?', provider: live);
      await ctrl.ask('What is witr?', provider: live);
      expect(live.calls, 0, reason: 'locked for the rest of the visit');
      await ctrl.clearThread();
      await ctrl.ask('What is witr?', provider: live);
      expect(live.calls, 1, reason: 'a fresh conversation starts clean');
      await ctrl.ask('I am 14', provider: live);
      await ctrl.ask('What is zakat?', provider: live);
      expect(live.calls, 1, reason: 'and it locks again if they say so');
    });
  });

  group('rulings and replies', () {
    test('missed prayers for years never reaches a model', () async {
      final ProviderContainer c = await container();
      final _Stub live = _Stub('You must pray them all today.');
      final String a = await c
          .read(hadiControllerProvider.notifier)
          .ask('I missed my prayers for years, what do I do?', provider: live);
      expect(live.calls, 0);
      expect(a.toLowerCase(), contains('qualified scholar'));
    });

    test('a [GO:] token becomes buttons on the reply and nothing moves',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final String shown = await ctrl.ask(
        'Take me somewhere',
        provider: _Stub('Here.\n[GO:/quran]\n[GO:/sakina]\n[GO:/evil]'),
      );
      expect(shown.contains('[GO:'), isFalse);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.routes, <String>['/quran', '/sakina']);
      final String saved =
          c.read(sharedPreferencesProvider).getString('ar.hadi.thread') ?? '';
      expect(saved.contains('[GO:'), isFalse);
      expect(saved, contains('/sakina'), reason: 'the buttons survive a restart');
    });

    test('a distress reply from the shelf carries both comfort buttons',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('I feel stupid', provider: const OfflineHadiProvider());
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.routes, <String>['/sakina', '/feelings']);
      expect(HadiTokens.labelFor('/sakina'), 'Open Sakina');
      expect(HadiTokens.labelFor('/feelings'), 'Open For Your Heart');
    });
  });

  group('failure states', () {
    test('typing while Hadi answers is not swallowed or double-sent',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final Completer<String> gate = Completer<String>();
      final Future<String> first =
          ctrl.ask('What is witr?', provider: _Gate(gate));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(hadiControllerProvider).typing, isTrue);
      final int before = c.read(hadiControllerProvider).messages.length;
      expect(await ctrl.ask('What is zakat?'), '');
      expect(c.read(hadiControllerProvider).messages.length, before);
      gate.complete('Done.');
      await first;
      expect(c.read(hadiControllerProvider).typing, isFalse);
    });

    test('a failed live call says why, offers a retry, and never says "add a key" to a keyed user',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.saveApiKey('gsk_test');
      final String a = await ctrl.ask(
        'Tell me about quantum entanglement',
        provider: _Boom(),
      );
      expect(a, contains('The service is down.'));
      expect(a, contains('Offline guidance'));
      expect(a.contains('API key'), isFalse);
      final HadiMessage m = c.read(hadiControllerProvider).messages.last;
      expect(m.retryQuestion, 'Tell me about quantum entanglement');
      expect(m.live, isFalse);
    });

    test('with no key the decline may still suggest one', () async {
      final ProviderContainer c = await container();
      final String a = await c
          .read(hadiControllerProvider.notifier)
          .ask('Tell me about quantum entanglement', provider: _Boom());
      expect(a, contains('API key'));
    });
  });

  group('returning to a saved conversation', () {
    String thread(List<Map<String, Object>> messages) => json.encode(messages);

    test('the welcome line does not echo the last question and is not saved',
        () async {
      final ProviderContainer c = await container(<String, Object>{
        'ar.hadi.thread': thread(<Map<String, Object>>[
          <String, Object>{'fromHadi': true, 'text': 'Salam.'},
          <String, Object>{
            'fromHadi': false,
            'text': 'I feel so ashamed of what I did last night',
          },
          <String, Object>{'fromHadi': true, 'text': 'Allah is merciful.'},
        ]),
      });
      final HadiState s = c.read(hadiControllerProvider);
      final HadiMessage last = s.messages.last;
      expect(last.ephemeral, isTrue);
      expect(last.text.contains('ashamed'), isFalse);
      expect(last.text, startsWith('Welcome back'));

      await c
          .read(hadiControllerProvider.notifier)
          .ask('What is zakat?', provider: const OfflineHadiProvider());
      final String saved =
          c.read(sharedPreferencesProvider).getString('ar.hadi.thread') ?? '';
      expect(saved.contains('Welcome back'), isFalse);
      expect(saved, contains('What is zakat?'));
    });

    test('old saved "Welcome back" lines are dropped when the thread loads',
        () async {
      final ProviderContainer c = await container(<String, Object>{
        'ar.hadi.thread': thread(<Map<String, Object>>[
          <String, Object>{'fromHadi': true, 'text': 'Salam.'},
          <String, Object>{'fromHadi': false, 'text': 'What is zakat?'},
          <String, Object>{
            'fromHadi': true,
            'text': 'Welcome back. Last time we spoke about "What is zakat?". '
                'How is it going?',
          },
          <String, Object>{
            'fromHadi': true,
            'text': 'Welcome back. Last time we spoke about "x". Fine.',
          },
        ]),
      });
      final List<String> texts = c
          .read(hadiControllerProvider)
          .messages
          .map((HadiMessage m) => m.text)
          .toList();
      expect(
        texts.where((String t) => t.startsWith('Welcome back')).length,
        1,
      );
      expect(texts.any((String t) => t.contains('Last time')), isFalse);
    });
  });
}
