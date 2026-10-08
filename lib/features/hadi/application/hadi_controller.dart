import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/groq_hadi_provider.dart';
import '../data/offline_hadi_provider.dart';
import 'hadi_provider.dart';

class HadiState {
  const HadiState({
    required this.messages,
    this.typing = false,
    this.live = false,
  });

  final List<HadiMessage> messages;
  final bool typing;

  /// True when answering through the live provider (user key present).
  final bool live;

  HadiState copy({
    List<HadiMessage>? messages,
    bool? typing,
    bool? live,
  }) {
    return HadiState(
      messages: messages ?? this.messages,
      typing: typing ?? this.typing,
      live: live ?? this.live,
    );
  }
}

/// O-7 conversation controller. Routing rule: user key present → live Groq
/// with guardrails; otherwise → curated offline knowledge. On any live
/// failure the offline provider answers instead (never a dead end).
class HadiController extends Notifier<HadiState> {
  static const String _keyPref = 'ar.hadi.apikey';

  @override
  HadiState build() {
    return HadiState(
      messages: const <HadiMessage>[
        HadiMessage(fromHadi: true, text: kHadiGreeting),
      ],
      live: _apiKey != null,
    );
  }

  String? get _apiKey {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? k = prefs.getString(_keyPref);
      return (k == null || k.trim().isEmpty) ? null : k.trim();
    } catch (_) {
      return null;
    }
  }

  bool get hasKey => _apiKey != null;

  Future<void> saveApiKey(String key) async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final String trimmed = key.trim();
      if (trimmed.isEmpty) {
        await prefs.remove(_keyPref);
      } else {
        await prefs.setString(_keyPref, trimmed);
      }
    } catch (_) {
      // In-memory only.
    }
    state = state.copy(live: _apiKey != null);
  }

  /// Injectable for tests — returns the provider to answer with.
  HadiProvider resolveProvider(String? apiKey) {
    final String? k = apiKey;
    if (k != null) return GroqHadiProvider(apiKey: k);
    return const OfflineHadiProvider();
  }

  Future<String> ask(String question, {HadiProvider? provider}) async {
    if (question.trim().isEmpty || state.typing) return '';
    final String q = question.trim();
    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: false, text: q),
      ],
      typing: true,
    );
    final HadiProvider p = provider ?? resolveProvider(_apiKey);
    String answer;
    try {
      answer = await p.ask(q, state.messages);
    } catch (_) {
      // Live failure never dead-ends: the curated knowledge answers.
      try {
        answer = await const OfflineHadiProvider().ask(q, state.messages);
      } catch (_) {
        answer = OfflineHadiProvider.decline;
      }
    }
    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: true, text: answer),
      ],
      typing: false,
    );
    return answer;
  }
}

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek '
    'authentic knowledge. Ask me anything.';

final NotifierProvider<HadiController, HadiState> hadiControllerProvider =
    NotifierProvider<HadiController, HadiState>(HadiController.new);
