import 'dart:async';
import 'dart:convert';
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

  String? _tocDigest;

  Future<String> _toc() async {
    if (_tocDigest != null) return _tocDigest!;
    try {
      final raw = await ContentSync.load('share/app_toc.json');
      final d = json.decode(raw) as Map<String, dynamic>;
      final parts = <String>[];
      for (final e in (d['rooms'] as Map<String, dynamic>).entries) {
        final titles = (e.value as List<dynamic>)
            .map((x) => (x as Map)['title'] as String).toList();
        if (titles.isNotEmpty) {
          parts.add('${e.key}: ' + titles.take(6).join('; ') +
              (titles.length > 6 ? '; and ${titles.length - 6} more' : ''));
        }
      }
      _tocDigest = parts.join('\n');
      return _tocDigest!;
    } catch (_) {
      _tocDigest = '';
      return '';
    }
  }

  /// Screen-jump requests extracted from Hadi's replies ([GO:/path] tokens).
  final navigationEvents = StreamController<String>.broadcast();
  static const String _keyPref = 'ar.hadi.apikey';
  static const String _providerPref = 'ar.hadi.provider';

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

  String get _provider {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getString(_providerPref) ?? 'groq';
    } catch (_) {
      return 'groq';
    }
  }

  String get providerName => _provider;

  Future<void> saveApiProvider(String provider) async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_providerPref, provider);
    } catch (_) {
      // In-memory only.
    }
  }

  /// Reads the provider straight from the key's fingerprint, so the user
  /// never has to think about which engine a key belongs to.
  static String detectProvider(String key) {
    final String k = key.trim();
    if (k.startsWith('xai-') || k.startsWith('ai-')) return 'xai';
    if (k.startsWith('sk-or-')) return 'openrouter';
    if (k.startsWith('gsk-')) return 'groq';
    return 'groq'; // default
  }

  Future<void> saveApiKey(String key) async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final String trimmed = key.trim();
      if (trimmed.isNotEmpty) {
        await prefs.setString(_providerPref, detectProvider(trimmed));
      }
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
    if (k != null) {
      // Routing is a pure function of the key itself — every call re-derives
      // the provider from the key's fingerprint, so a stale stored preference
      // can never send a key to the wrong engine again.
      switch (detectProvider(k)) {
        case 'openrouter':
          return OpenRouterHadiProvider(apiKey: k);
        case 'xai':
          return XaiHadiProvider(apiKey: k);
        default:
          return GroqHadiProvider(apiKey: k);
      }
    }
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
      final tocDigest = await _toc();
      if (tocDigest.isNotEmpty) {
        question = 'The app\u2019s table of contents (so you can answer about '
            'what the app CONTAINS, e.g. which stories or guides exist — never '
            'claim to know the user\u2019s private data):\n$tocDigest\n\n'
            'User\u2019s question: $question';
      }
      answer = await p.ask(q, state.messages);
    } catch (e) {
      // Live failure never dead-ends: the curated knowledge answers — but
      // say WHY, so a bad key, a blocked region, or CORS is visible instead
      // of masquerading as ignorance.
      String offline;
      try {
        offline = await const OfflineHadiProvider().ask(q, state.messages);
      } catch (_) {
        offline = OfflineHadiProvider.decline;
      }
      answer = 'I could not reach my knowledge engine just now ($e). '
          'Offline guidance: $offline';
    }
    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: true, text: answer),
      ],
      typing: false,
    );
    // Hadi's hands: a [GO:/path] token means "take the user there".
    final nav = RegExp(r'\[GO:(/[a-z0-9\-/:]+)\]').firstMatch(answer);
    if (nav != null) {
      final route = nav.group(1);
      const known = <String>{
        '/home', '/stories', '/games', '/player', '/finance', '/masajid',
        '/feelings', '/family-tree', '/huda', '/majlis', '/elder-care',
        '/qibla', '/hadith', '/sakina', '/share', '/notes', '/founder',
        '/academy', '/academy/gate', '/academy/family', '/home/quick',
      };
      if (route != null && known.contains(route)) {
        navigationEvents.add(route);
      }
      final clean = answer.replaceAll(RegExp(r'\s*\[GO:[^\]]+\]'), '').trim();
      if (clean.isNotEmpty && clean != answer) {
        final msgs = [...state.messages];
        msgs[msgs.length - 1] = HadiMessage(fromHadi: true, text: clean);
        state = state.copy(messages: msgs);
        return clean;
      }
    }
    return answer;
  }
}

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek '
    'authentic knowledge. Ask me anything.';

final NotifierProvider<HadiController, HadiState> hadiControllerProvider =
    NotifierProvider<HadiController, HadiState>(HadiController.new);
