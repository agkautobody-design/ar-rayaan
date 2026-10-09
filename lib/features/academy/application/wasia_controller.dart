import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../hadi/application/hadi_provider.dart';
import '../../hadi/data/groq_hadi_provider.dart';

const String kWasiaSystemPrompt =
    'You are Wasia, the beloved teacher of Wasia Academy inside the Ar-Rayaan '
    'app, named after the founder\u2019s daughter. You teach Qur\u2019an, Arabic '
    'letters, tajweed, duas, and Islamic knowledge to students of every age.\n'
    'Teaching laws:\n'
    '1. Greet with warmth; praise effort, not just results.\n'
    '2. Teach in small steps; one idea at a time; end with a tiny question.\n'
    '3. Never invent religious rulings — if fiqh arises, give the mainstream '
    'view and advise asking a local scholar.\n'
    '4. Keep answers under 90 words: gentle, clear, hopeful.\n'
    '5. When teaching Qur\u2019an or hadith content, stay with the established text.';

/// Wasia reuses the same user-owned AI key as Hadi — one key, both teachers.
class WasiaController extends StateNotifier<AsyncValue<String?>> {
  WasiaController(this.ref) : super(const AsyncData<String?>(null));

  final Ref ref;

  static const String _keyPref = 'ar.hadi.apikey';

  Future<String?> _key() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(_keyPref);
    return (k == null || k.trim().isEmpty) ? null : k.trim();
  }

  Future<String> ask(String question) async {
    final k = await _key();
    if (k == null) {
      return 'Wasia needs your AI key to speak freely — add it once in '
          'H\u0101di\u2019s settings and both of us can teach. Until then, '
          'walk the scripted lessons; they carry everything.';
    }
    state = const AsyncLoading<String?>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('ar.hadi.provider') ?? 'groq';
      final HadiProvider p = switch (provider) {
        'openrouter' => OpenRouterHadiProvider(apiKey: k),
        'xai' => XaiHadiProvider(apiKey: k),
        _ => GroqHadiProvider(apiKey: k),
      };
      // Persona rides inside the question itself: it lands in the message
      // the model reads first, regardless of provider.
      final answer = await p.ask(
        '\$kWasiaSystemPrompt\n\nStudent\u2019s question: \$question',
        const <HadiMessage>[],
      );
      state = AsyncData<String?>(answer);
      return answer;
    } catch (e) {
      state = AsyncError<String?>(e, StackTrace.current);
      return 'Wasia could not reach her voice just now ($e). '
          'The lesson above still carries everything — keep walking it.';
    }
  }
}

final wasiaControllerProvider =
    StateNotifierProvider<WasiaController, AsyncValue<String?>>((ref) {
  return WasiaController(ref);
});
