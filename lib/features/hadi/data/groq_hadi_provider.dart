import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/hadi_provider.dart';

/// Live AI on Groq's free tier (OpenAI-compatible chat API) with the user's
/// own key — the recommended best-of-class free backend: fast Llama models,
/// generous free quota, no card required. The key stays on the device.
class GroqHadiProvider implements HadiProvider {
  GroqHadiProvider({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Free-tier flagship on Groq — strong instruction following for the
  /// guardrail prompt, fast enough for chat.
  static const String model = 'llama-3.3-70b-versatile';

  @override
  Future<String> ask(String question, List<HadiMessage> history) async {
    final http.Response resp = await _client.post(
      Uri.parse(_endpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
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
