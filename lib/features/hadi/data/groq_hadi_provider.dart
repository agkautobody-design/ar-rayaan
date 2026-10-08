import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/hadi_provider.dart';

/// Live AI over any OpenAI-compatible chat endpoint with the user's own key.
/// Keys never leave the device. Two curated backends below (Groq, OpenRouter).
class OpenAIChatHadiProvider implements HadiProvider {
  OpenAIChatHadiProvider({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.extraHeaders = const <String, String>{},
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String model;
  final Map<String, String> extraHeaders;
  final http.Client _client;

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final http.Response resp = await _client.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        ...extraHeaders,
      },
      body: jsonEncode(<String, dynamic>{
        'model': model,
        'temperature': 0.3, // low drift — authenticity over creativity
        'max_tokens': 350,
        'messages': <Map<String, String>>[
          const <String, String>{
            'role': 'system',
            'content': kHadiSystemPrompt,
          },
          // Recent history for continuity (cap keeps requests small).
          for (final HadiMessage m in history.length > 8
              ? history.sublist(history.length - 8)
              : history)
            <String, String>{
              'role': m.fromHadi ? 'assistant' : 'user',
              'content': m.text,
            },
          <String, String>{'role': 'user', 'content': question},
        ],
      }),
    );
    if (resp.statusCode != 200) {
      throw HadiProviderException(
        'The guidance service returned ${resp.statusCode}. '
        'Check your API key in Hādi settings.',
      );
    }
    final Map<String, dynamic> body =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> choices = body['choices'] as List<dynamic>;
    if (choices.isEmpty) throw const HadiProviderException('Empty reply.');
    final String text =
        ((choices.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>)['content']
            as String;
    return text.trim();
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
  GroqHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
          model: 'openai/gpt-oss-120b',
        );
}

/// xAI (Grok) — OpenAI-compatible; requires an xAI API key (x.ai/api).
class XaiHadiProvider extends OpenAIChatHadiProvider {
  XaiHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://api.x.ai/v1/chat/completions',
          model: 'grok-3',
        );
}

/// OpenRouter — one API key, many models (incl. long-standing free ones).
class OpenRouterHadiProvider extends OpenAIChatHadiProvider {
  OpenRouterHadiProvider({required super.apiKey, super.client})
      : super(
          baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
          model: 'meta-llama/llama-3.3-70b-instruct:free',
          extraHeaders: const <String, String>{
            'HTTP-Referer': 'https://ar-rayaan.onrender.com',
            'X-Title': 'Ar-Rayaan',
          },
        );
}
