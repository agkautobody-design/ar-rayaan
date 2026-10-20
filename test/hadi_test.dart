import 'dart:async';
import 'dart:convert';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_controller.dart';
import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/groq_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/offline_hadi_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('offline provider (curated authentic knowledge)', () {
    test('answers anxiety with the Bukhari du\'a', () async {
      final String a = await const OfflineHadiProvider()
          .ask('I feel anxiety and worry lately', const <HadiMessage>[]);
      expect(a, contains('Bukhari'));
      expect(a, contains('worry and grief'));
    });

    test('answers sources question with the Sihah Sitta', () async {
      final String a = await const OfflineHadiProvider()
          .ask('What are your hadith sources?', const <HadiMessage>[]);
      expect(a, contains('Sihah Sitta'));
      expect(a, contains('Bukhari'));
      expect(a, contains('Ibn Majah'));
    });

    test('unknown question gets an honest decline, never invention',
        () async {
      final String a = await const OfflineHadiProvider()
          .ask('Who will win the football match?', const <HadiMessage>[]);
      expect(a, contains('would rather not guess'));
      expect(a, contains('Saqib Iqbal'));
    });
  });

  group('groq provider (guardrailed live AI)', () {
    test('sends system guardrails, history, and parses the reply', () async {
      Map<String, dynamic>? sent;
      final http_testing.MockClient client = http_testing.MockClient(
        (http.Request req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            '{"choices":[{"message":{"content":"  Bismillah - tested.  "}}]}',
            200,
          );
        },
      );
      final GroqHadiProvider p = GroqHadiProvider(
        apiKey: 'gsk_test',
        client: client,
      );
      final String answer = await p.ask(
        'What is witr?',
        const <HadiMessage>[HadiMessage(fromHadi: true, text: 'Salam')],
      );
      expect(answer, 'Bismillah - tested.');
      expect(sent, isNotNull);
      final List<dynamic> messages = sent!['messages'] as List<dynamic>;
      expect(messages.first['role'], 'system');
      expect(
        (messages.first['content'] as String),
        contains('six canonical books'),
      );
      expect(
        (messages.first['content'] as String),
        contains('NEVER invent'),
      );
      expect(sent!['model'], GroqHadiProvider.model);
      // History is threaded through before the new question.
      expect(messages.last['content'], 'What is witr?');
      expect(messages[messages.length - 2]['content'], 'Salam');
    });

    test('non-200 raises a typed exception', () {
      final http_testing.MockClient client = http_testing.MockClient(
        (http.Request req) async => http.Response('nope', 401),
      );
      final GroqHadiProvider p = GroqHadiProvider(
        apiKey: 'bad',
        client: client,
      );
      expect(
        () => p.ask('hi', const <HadiMessage>[]),
        throwsA(isA<HadiProviderException>()),
      );
    });
  });

  group('controller routing', () {
    test('no key → offline; key set → live flag on', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(hadiControllerProvider).live, isFalse);
      await c.read(hadiControllerProvider.notifier).saveApiKey(' gsk_abc ');
      expect(c.read(hadiControllerProvider).live, isTrue);
      expect(prefs.getString('ar.hadi.apikey'), 'gsk_abc');
      await c.read(hadiControllerProvider.notifier).saveApiKey('');
      expect(c.read(hadiControllerProvider).live, isFalse);
    });

    test('ask appends user + answer and clears typing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final String answer = await c
          .read(hadiControllerProvider.notifier)
          .ask('Tell me about fasting', provider: const OfflineHadiProvider());
      expect(answer, contains('pillar'));
      final HadiState s = c.read(hadiControllerProvider);
      expect(s.typing, isFalse);
      expect(s.messages.length, 3); // greeting + question + answer
      expect(s.messages.last.fromHadi, isTrue);
    });

    test('live failure falls back to offline knowledge, never a dead end',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final String answer = await c
          .read(hadiControllerProvider.notifier)
          .ask('A du\'a for anxiety', provider: _ExplodingProvider());
      expect(answer, contains('Bukhari'));
      expect(c.read(hadiControllerProvider).typing, isFalse);
    });
  });

  group('crisis safety in the controller', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a crisis message never reaches the provider', () async {
      final ProviderContainer c = await container();
      final _CountingProvider live = _CountingProvider();
      final String answer = await c
          .read(hadiControllerProvider.notifier)
          .ask('I want to kill myself', provider: live);
      expect(live.calls, 0);
      expect(answer, contains('emergency'));
      expect(c.read(hadiControllerProvider).typing, isFalse);
    });

    test('a crisis exchange is never written to the device thread', () async {
      final ProviderContainer c = await container();
      final SharedPreferences prefs = c.read(sharedPreferencesProvider);
      await c
          .read(hadiControllerProvider.notifier)
          .ask('I want to kill myself', provider: _CountingProvider());
      final String saved = prefs.getString('ar.hadi.thread') ?? '';
      expect(saved.contains('kill myself'), isFalse);
      expect(saved.contains('39:53'), isFalse);
    });

    test('after a crisis, later questions do not send it upstream', () async {
      final ProviderContainer c = await container();
      final _CountingProvider live = _CountingProvider();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      await ctrl.ask('I want to kill myself', provider: live);
      await ctrl.ask('What is witr?', provider: live);
      expect(live.calls, 1);
      for (final HadiMessage m in live.histories.single) {
        expect(m.text.contains('kill myself'), isFalse);
      }
    });

    test('a repeated crisis message gets a short follow-up, not the card',
        () async {
      final ProviderContainer c = await container();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final String first = await ctrl.ask('I want to die');
      final String second = await ctrl.ask('I want to die');
      expect(second, isNot(first));
      expect(second.length, lessThan(first.length));
    });

    test('abuse gets help without calling the provider', () async {
      final ProviderContainer c = await container();
      final _CountingProvider live = _CountingProvider();
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final String a = await ctrl.ask('my husband beats me', provider: live);
      expect(live.calls, 0);
      expect(a, contains('not your fault'));
    });
  });

  group('navigation tokens in the controller', () {
    test('tokens are removed from the shown and the saved text', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final HadiController ctrl = c.read(hadiControllerProvider.notifier);
      final List<String> routes = <String>[];
      final StreamSubscription<String> sub =
          ctrl.navigationEvents.stream.listen(routes.add);
      addTearDown(sub.cancel);
      final String shown = await ctrl.ask(
        'Open the Quran please',
        provider: _CountingProvider(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(shown.contains('[GO:'), isFalse);
      expect(shown.contains('[DO:'), isFalse);
      final String saved = prefs.getString('ar.hadi.thread') ?? '';
      expect(saved.contains('[GO:'), isFalse);
      expect(saved.contains('[DO:'), isFalse);
      expect(routes, <String>['/quran']);
    });
  });
}

class _CountingProvider implements HadiProvider {
  int calls = 0;
  final List<List<HadiMessage>> histories = <List<HadiMessage>>[];
  String reply = 'Here you go.\n[GO:/quran]\n[DO:bookmark:no-such-story]';

  @override
  Future<String> ask(String q, List<HadiMessage> h) async {
    calls++;
    histories.add(h);
    return reply;
  }
}

class _ExplodingProvider implements HadiProvider {
  @override
  Future<String> ask(String q, List<HadiMessage> h) =>
      throw const HadiProviderException('boom');
}
