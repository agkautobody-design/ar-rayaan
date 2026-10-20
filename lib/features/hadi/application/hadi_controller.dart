import 'dart:async';
import 'dart:convert';
import '../../stories/domain/story.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/content/content_sync.dart';
import '../../../app/core/providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../stories/application/saved_stories_controller.dart';
import '../../stories/data/stories_repository.dart';
import '../../hadith/application/feeling_providers.dart';
import '../../hadith/domain/daily_hadith.dart';
import '../../../app/core/subscription/subscription_service.dart';
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


  /// Hadi's hands, level two: [DO:] tokens perform a small, reversible
  /// app action the USER explicitly asked for. Whitelist of three —
  /// nothing else is ever executed, and the token never reaches the UI.
  Future<String> _executeActions(String answer) async {
    final List<RegExpMatch> actions =
        RegExp(r'\[DO:([a-z\-]+)(?::([^\]]+))?\]')
            .allMatches(answer)
            .toList();
    if (actions.isEmpty) return answer;
    final List<String> confirmations = <String>[];
    for (final RegExpMatch m in actions) {
      final String kind = m.group(1)!;
      final String? arg = m.group(2);
      try {
        switch (kind) {
          case 'bookmark':
            if (arg != null) {
              final List<Story> all =
                  await ref.read(storiesProvider.future);
              final bool exists = all.any((Story s) => s.id == arg);
              if (exists) {
                await ref.read(savedStoriesProvider.notifier).save(arg);
                confirmations.add('Done — it is in your Bookmarks '
                    '(My Journey).');
              }
            }
          case 'save-hadith':
            final DailyHadith hadith = ref.read(todaysHadithProvider);
            await ref
                .read(savedDailyHadithsProvider.notifier)
                .toggle(hadith.text);
            confirmations.add("Today's hadith is saved for you.");
          case 'feeling':
            if (arg != null) {
              final List<dynamic> feelings =
                  json.decode(await ContentSync.load('feelings/feelings.json'))
                      as List<dynamic>;
              final bool exists =
                  feelings.any((dynamic e) => (e as Map)['id'] == arg);
              if (exists) {
                await ref
                    .read(feelingCheckInProvider.notifier)
                    .checkIn(arg);
                confirmations.add('Done — I have checked you in.');
              }
            }
        }
      } catch (_) {}
    }
    String clean =
        answer.replaceAll(RegExp(r'\s*\[DO:[^\]]+\]'), '').trim();
    if (confirmations.isNotEmpty) {
      clean = '$clean\n\n${confirmations.join(' ')}'.trim();
    }
    final List<HadiMessage> msgs = <HadiMessage>[...state.messages];
    msgs[msgs.length - 1] = HadiMessage(fromHadi: true, text: clean);
    state = state.copy(messages: msgs);
    return clean;
  }

  /// Screen-jump requests extracted from Hadi's replies ([GO:/path] tokens).
  final navigationEvents = StreamController<String>.broadcast();
  static const String _keyPref = 'ar.hadi.apikey';
  static const String _providerPref = 'ar.hadi.provider';
  static const String _threadPref = 'ar.hadi.thread';
  static const String _memoryPref = 'ar.hadi.memory';
  static const String _seedPref = 'ar.hadi.seed';

  @override
  HadiState build() {
    List<HadiMessage> messages = const <HadiMessage>[
      HadiMessage(fromHadi: true, text: kHadiGreeting),
    ];
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_threadPref);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        final List<HadiMessage> restored = <HadiMessage>[
          for (final dynamic e in decoded)
            HadiMessage(
              fromHadi: (e as Map)['fromHadi'] as bool,
              text: e['text'] as String,
            ),
        ];
        if (restored.length > 1) {
          String topic = '';
          for (final HadiMessage m in restored.reversed) {
            if (!m.fromHadi) {
              topic = m.text.split(' ').take(8).join(' ');
              break;
            }
          }
          messages = <HadiMessage>[
            ...restored,
            HadiMessage(
              fromHadi: true,
              text: topic.isEmpty
                  ? 'Welcome back. Where shall we continue?'
                  : 'Welcome back. Last time we spoke about "$topic". '
                      'How is it going?',
            ),
          ];
        } else if (restored.isNotEmpty) {
          messages = restored;
        }
      }
      // Feelings bridge: a feeling sent from For Your Heart arrives here.
      // Consume exactly once, then let Hadi answer it like any question.
      final String? seed = prefs.getString(_seedPref);
      if (seed != null && seed.isNotEmpty) {
        prefs.remove(_seedPref); // fire-and-forget: sync build() cannot await
        Future<void>.microtask(() => ask(seed));
      }
    } catch (_) {}
    return HadiState(messages: messages, live: _apiKey != null);
  }

  void _persistThread(List<HadiMessage> messages) {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final List<HadiMessage> tail = messages.length > 20
          ? messages.sublist(messages.length - 20)
          : messages;
      prefs.setString(
        _threadPref,
        json.encode(<Map<String, dynamic>>[
          for (final HadiMessage m in tail)
            <String, dynamic>{'fromHadi': m.fromHadi, 'text': m.text},
        ]),
      );
    } catch (_) {}
  }

  /// Fresh conversation: wipe the persisted thread and start over.
  Future<void> clearThread() async {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_threadPref);
    } catch (_) {}
    state = HadiState(
      messages: const <HadiMessage>[
        HadiMessage(fromHadi: true, text: kHadiGreeting),
      ],
      live: _apiKey != null,
    );
  }

  /// Effective key: the user's own key wins; otherwise an active
  /// subscription's managed key (per-user, server-issued — never a
  /// founder key shipped in the app). Offline shelf when both are absent.
  String? get _apiKey {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? k = prefs.getString(_keyPref);
      if (k != null && k.trim().isNotEmpty) return k.trim();
      return ref.watch(subscriptionServiceProvider.notifier).managedKey;
    } catch (_) {
      return null;
    }
  }

  /// True when the live key comes from the subscription rather than the
  /// user — only those calls count against the daily quota.
  bool get _usingManagedKey {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final String? k = prefs.getString(_keyPref);
      return (k == null || k.trim().isEmpty);
    } catch (_) {
      return false;
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
    if (k.startsWith('xai-')) return 'xai';
    if (k.startsWith('sk-or-')) return 'openrouter';
    if (k.startsWith('gsk_') || k.startsWith('gsk-')) return 'groq';
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
    HadiProvider p = provider ?? resolveProvider(_apiKey);
    // Subscription quota: managed-key calls count against the daily tier
    // quota. When the quota is spent, answer from the shelf and say so.
    String? quotaNote;
    if (provider == null && _usingManagedKey && _apiKey != null) {
      final SubscriptionService sub =
          ref.read(subscriptionServiceProvider.notifier);
      if (sub.isEntitled && !sub.consumeQuestion()) {
        p = const OfflineHadiProvider();
        quotaNote = 'Your live questions for today are finished — the '
            'subscription resets at midnight. Meanwhile, from my built-in '
            'shelf:\n\n';
      }
    }
    String answer;
    try {
      final tocDigest = await _toc();
      if (tocDigest.isNotEmpty) {
        // Opt-in memory: only what the user deliberately enabled, and only
        // the name — nothing else leaves the device.
        String memoryContext = '';
        try {
          final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
          if (prefs.getBool(_memoryPref) == true) {
            final profile = await ref.read(userProfileProvider.future);
            final String? name = profile?.displayName;
            if (name != null && name.trim().isNotEmpty) {
              memoryContext = 'The user chose to share their name with you: '
                  '${name.trim()}. Use it once per answer, naturally.\n';
            }
          }
        } catch (_) {}
        question = 'The app\u2019s table of contents (so you can answer about '
            'what the app CONTAINS, e.g. which stories or guides exist — never '
            'claim to know the user\u2019s private data):\n$tocDigest\n$memoryContext\n'
            'User\u2019s question: $question';
      }
      // History = everything before this question (the question itself is
      // sent once, as the final user turn). Live models get the app's
      // table of contents and the opt-in name; the offline shelf matches on
      // the user's own words only.
      final List<HadiMessage> history =
          state.messages.sublist(0, state.messages.length - 1);
      answer = await p.ask(p is OfflineHadiProvider ? q : question, history);
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
    if (quotaNote != null) answer = quotaNote + answer;
    answer = await _executeActions(answer);
    _persistThread(state.messages);
    // Hadi's hands: a [GO:/path] token means "take the user there".
    final nav = RegExp(r'\[GO:(/[a-z0-9\-/:]+)\]').firstMatch(answer);
    if (nav != null) {
      final route = nav.group(1);
      const known = <String>{
        '/home', '/stories', '/games', '/player', '/finance', '/masajid',
        '/feelings', '/family-tree', '/huda', '/majlis', '/elder-care',
        '/qibla', '/hadith', '/sakina', '/share', '/notes',
        '/quran', '/prayer', '/zakat', '/calendar', '/adhkar', '/explore',
        '/journey', '/community', '/settings', '/sources', '/hadi', '/noor',
        '/academy/review', '/academy/letters', '/academy/audio-packs',
        '/academy', '/academy/gate', '/academy/family', '/home/quick',
        '/new-muslim', '/academy/qa', '/academy/hisn', '/ramadan',
        '/academy/ramadan-mode', '/academy/family-life', '/games/names99',
        '/academy/transactions', '/academy/end-of-life', '/academy/dawah',
        '/academy/health', '/academy/arabic-language', '/academy/aqeedah',
        '/academy/hadith', '/academy/seerah', '/academy/history',
        '/academy/stories', '/academy/character',
        '/academy/youth', '/academy/womens', '/academy/understanding',
        '/academy/dua', '/academy/hifz', '/academy/recitation',
        '/academy/quranic-arabic', '/academy/hajj-umrah-pack',
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
    'authentic knowledge. Ask me about worship, the Qur\'an, or where '
    'anything lives in this app. And when the weight is heavy, tell me '
    'that too — I will stay with it.';

final NotifierProvider<HadiController, HadiState> hadiControllerProvider =
    NotifierProvider<HadiController, HadiState>(HadiController.new);
