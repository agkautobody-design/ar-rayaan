import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/hadi_provider.dart';

/// Live AI over any OpenAI-compatible chat endpoint with the user's own key.
/// The key is stored in plain text on this device and is sent only to the
/// provider you chose. Two curated backends below (Groq, OpenRouter).
class OpenAIChatHadiProvider implements HadiProvider {
  OpenAIChatHadiProvider({
    required this.apiKey,
    required this.baseUrl,
    required this.modelName,
    this.extraHeaders = const <String, String>{},
    this.timeout = requestTimeout,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String modelName;
  final Map<String, String> extraHeaders;

  /// How long to wait for the service (shortened in tests).
  final Duration timeout;
  final http.Client _client;

  /// How long a live answer may take before Hādi gives up and says so.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// The room a reply has. Reasoning models spend part of it thinking, so
  /// it is generous; the prompt keeps answers short.
  static const int maxTokens = 1500;

  /// A plain sentence for each kind of failure, so a rate limit is not
  /// reported as a bad key.
  static String describeStatus(int code) {
    if (code == 401 || code == 403) {
      return 'The guidance service did not accept your API key. Check it in '
          'Hādi settings.';
    }
    if (code == 429) {
      return 'The guidance service is busy, or the free limit for now is '
          'used up. Try again in a minute.';
    }
    if (code >= 500) {
      return 'The guidance service is having trouble right now. Try again '
          'shortly.';
    }
    return 'The guidance service returned $code.';
  }

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final http.Response resp;
    try {
      resp = await _post(question, history).timeout(timeout);
    } on TimeoutException {
      throw const HadiProviderException(
        'The guidance service took too long to answer.',
      );
    }
    if (resp.statusCode != 200) {
      throw HadiProviderException(describeStatus(resp.statusCode));
    }
    final Object? body = jsonDecode(resp.body);
    final Object? choices = body is Map<String, dynamic> ? body['choices'] : null;
    if (choices is! List<dynamic> || choices.isEmpty) {
      throw const HadiProviderException(
        'The guidance service sent an empty reply.',
      );
    }
    final Object? first = choices.first;
    final Object? message = first is Map<String, dynamic> ? first['message'] : null;
    final Object? content =
        message is Map<String, dynamic> ? message['content'] : null;
    final String text = content is String ? content.trim() : '';
    final bool cutOff =
        first is Map<String, dynamic> && first['finish_reason'] == 'length';
    if (text.isEmpty) {
      throw HadiProviderException(
        cutOff
            ? 'The answer ran out of room before it began. Please ask again.'
            : 'The guidance service sent an empty reply.',
      );
    }
    if (cutOff) {
      return '$text\n\n(This answer was cut off. Ask me to continue and I '
          'will carry on.)';
    }
    return text;
  }

  Future<http.Response> _post(String question, List<HadiMessage> history) {
    return _client.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
      body: jsonEncode(<String, dynamic>{
        'model': modelName,
        'temperature': 0.5, // low drift — authenticity over creativity
        'max_tokens': maxTokens,
        'messages': <Map<String, String>>[
          const <String, String>{
            'role': 'system',
            'content': kHadiSystemPrompt,
          },
          // Recent history for continuity (cap keeps context rich).
          for (final HadiMessage m in history.length > 16
              ? history.sublist(history.length - 16)
              : history)
            <String, String>{
              'role': m.fromHadi ? 'assistant' : 'user',
              'content': m.text,
            },
          <String, String>{'role': 'user', 'content': question},
        ],
      }),
    );
  }
}

class HadiProviderException implements Exception {
  const HadiProviderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Groq — fastest free tier, no training on data, generous daily quota.
class GroqHadiProvider extends OpenAIChatHadiProvider {
  /// Current production model on Groq (tests assert requests carry it).
  static const String model = 'openai/gpt-oss-120b';

  GroqHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
          modelName: model,
        );
}

/// xAI (Grok) — OpenAI-compatible; requires an xAI API key (x.ai/api).
class XaiHadiProvider extends OpenAIChatHadiProvider {
  XaiHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://api.x.ai/v1/chat/completions',
          modelName: 'grok-4.3',
        );
}

/// OpenRouter — one API key, many models (incl. long-standing free ones).
class OpenRouterHadiProvider extends OpenAIChatHadiProvider {
  OpenRouterHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
          modelName: 'meta-llama/llama-3.3-70b-instruct:free',
          extraHeaders: const <String, String>{
            'HTTP-Referer': 'https://ar-rayaan.onrender.com',
            'X-Title': 'Ar-Rayaan',
          },
        );
}
