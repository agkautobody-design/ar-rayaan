import 'dart:convert';

import 'package:ar_rayaan/features/hadi/application/hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/groq_hadi_provider.dart';
import 'package:ar_rayaan/features/hadi/data/hosted_ai.dart';
import 'package:ar_rayaan/features/hadi/data/http_hosted_ai.dart';
import 'package:ar_rayaan/features/hadi/data/user_knows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

HostedAiRequest _req({HostedMemory memory = const HostedMemory()}) =>
    HostedAiRequest(
      question: 'What is the wisdom of fasting on Mondays?',
      history: const <HadiMessage>[
        HadiMessage(fromHadi: false, text: 'hello'),
        HadiMessage(fromHadi: true, text: 'a hard moment', sensitive: true),
        HadiMessage(fromHadi: true, text: 'salam'),
      ],
      package: 'free',
      maxReplyChars: 900,
      memory: memory,
    );

Future<String?> _token() async => 'rt_token';
Future<String?> _none() async => null;

void main() {
  test('the request carries ids only, a bearer token, and no sensitive turn', () async {
    late http.Request seen;
    final HttpHostedAi api = HttpHostedAi(
      baseUrl: 'https://api.example.test/',
      readToken: _token,
      client: MockClient((http.Request r) async {
        seen = r;
        return http.Response(jsonEncode(<String, String>{'text': ' Hi there '}), 200);
      }),
    );
    final HostedAiReply r = await api.ask(_req(
      memory: const HostedMemory(
        roles: <String>['parent'],
        topics: <String>['fasting'],
        covered: <String>['tarawih-prayer'],
      ),
    ));
    expect(r.text, 'Hi there');
    expect(seen.url.toString(), 'https://api.example.test/v1/hadi/ask');
    expect(seen.headers['authorization'], 'Bearer rt_token');
    final Map<String, dynamic> body = jsonDecode(seen.body) as Map<String, dynamic>;
    expect((body['history'] as List<dynamic>).length, 2);
    expect(body['memory'], <String, dynamic>{
      'roles': <String>['parent'],
      'topics': <String>['fasting'],
      'covered': <String>['tarawih-prayer'],
    });
    expect(seen.body.contains('a hard moment'), isFalse);
  });

  test('a spent daily allowance becomes the cap exception', () async {
    final HttpHostedAi api = HttpHostedAi(
      baseUrl: 'https://api.example.test',
      readToken: _token,
      client: MockClient((http.Request r) async => http.Response(
          jsonEncode(<String, Object>{
            'error': <String, String>{'code': 'hadi_cap_reached', 'message': 'x'},
          }),
          429)),
    );
    expect(api.ask(_req()), throwsA(isA<HostedAiCapReached>()));
  });

  test('not switched on, not signed in and network failure are plain errors', () async {
    final HttpHostedAi off = HttpHostedAi(
      baseUrl: 'https://api.example.test',
      readToken: _token,
      client: MockClient((http.Request r) async => http.Response('{}', 503)),
    );
    expect(off.ask(_req()), throwsA(isA<HadiProviderException>()));
    final HttpHostedAi anon = HttpHostedAi(
      baseUrl: 'https://api.example.test',
      readToken: _none,
      client: MockClient((http.Request r) async => http.Response('{}', 200)),
    );
    expect(anon.ask(_req()), throwsA(isA<HadiProviderException>()));
    final HttpHostedAi down = HttpHostedAi(
      baseUrl: 'https://api.example.test',
      readToken: _token,
      client: MockClient((http.Request r) async => throw Exception('offline')),
    );
    expect(down.ask(_req()), throwsA(isA<HadiProviderException>()));
  });

  test('HostedMemory takes the strongest subjects and the latest answers', () {
    final UserKnows k = UserKnows(
      roles: const <String>{'parent'},
      topics: <String, KnownTopic>{
        'prayer': const KnownTopic(count: 5, last: '2026-11-01'),
        'zakat': const KnownTopic(count: 1, last: '2026-11-01'),
      },
      covered: <String, KnownTopic>{
        'old-one': const KnownTopic(count: 1, last: '2026-01-01'),
        'new-one': const KnownTopic(count: 1, last: '2026-11-20'),
      },
    );
    final HostedMemory m = HostedMemory.from(k);
    expect(m.roles, <String>['parent']);
    expect(m.topics.first, 'prayer');
    expect(m.covered.first, 'new-one');
    expect(HostedMemory.from(UserKnows.empty).isEmpty, isTrue);
  });
}
