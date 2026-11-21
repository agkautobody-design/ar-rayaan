import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/hadi_provider.dart';
import 'groq_hadi_provider.dart' show HadiProviderException;
import 'hosted_ai.dart';

/// The real [HostedAi]: one HTTPS call to the owner's own service
/// (`POST /v1/hadi/ask`, backend/openapi.yaml). The app holds no provider key.
/// The service holds it, checks the person is signed in, applies the guardrail
/// prompt and enforces the daily cap. Nothing is logged here.
class HttpHostedAi implements HostedAi {
  HttpHostedAi({
    required String baseUrl,
    required Future<String?> Function() readToken,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  })  : _base = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _readToken = readToken,
        _client = client ?? http.Client(),
        _timeout = timeout;

  final String _base;
  final Future<String?> Function() _readToken;
  final http.Client _client;
  final Duration _timeout;

  void close() => _client.close();

  @override
  bool get isAvailable => true;

  static Map<String, Object> bodyFor(HostedAiRequest r) => <String, Object>{
        'question': r.question,
        'history': <Map<String, String>>[
          for (final HadiMessage m in r.history)
            if (!m.sensitive && m.text.trim().isNotEmpty)
              <String, String>{
                'from': m.fromHadi ? 'hadi' : 'user',
                'text': m.text.length > 1500 ? m.text.substring(0, 1500) : m.text,
              },
        ],
        'package': r.package,
        'maxReplyChars': r.maxReplyChars.clamp(100, 4000),
        'maxOutputTokens': r.maxOutputTokens.clamp(50, 400),
        'preferSmallModel': r.preferSmallModel,
        'memory': r.memory.toJson(),
      };

  @override
  Future<HostedAiReply> ask(HostedAiRequest request) async {
    final String? token = await _readToken();
    if (token == null) {
      throw const HadiProviderException(
          'Sign in to use live answers. The built-in library still works.');
    }
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$_base/v1/hadi/ask'),
            headers: <String, String>{
              'content-type': 'application/json',
              'accept': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode(bodyFor(request)),
          )
          .timeout(_timeout);
    } on Object {
      throw const HadiProviderException(
          'I could not reach the live service just now.');
    }
    String? code;
    try {
      final Object? j = jsonDecode(res.body);
      if (j is Map) {
        final Object? e = j['error'];
        if (e is Map && e['code'] is String) code = e['code'] as String;
        if (res.statusCode == 200 && j['text'] is String) {
          final String t = (j['text'] as String).trim();
          if (t.isNotEmpty) return HostedAiReply(t);
        }
      }
    } catch (_) {}
    if (res.statusCode == 429 && code == 'hadi_cap_reached') {
      throw const HostedAiCapReached();
    }
    throw HadiProviderException(res.statusCode == 503
        ? 'Live answers are not switched on yet.'
        : 'I could not get a live answer just now.');
  }
}
