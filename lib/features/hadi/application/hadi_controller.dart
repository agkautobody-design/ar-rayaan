import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
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
import '../../sakina/application/sakina_providers.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../data/groq_hadi_provider.dart';
import '../data/offline_hadi_provider.dart';
import '../grounding/answer_verifier.dart';
import '../grounding/corpus.dart';
import '../grounding/madhhab.dart';
import '../grounding/minor_signal.dart';
import '../grounding/passage.dart';
import '../grounding/ruling_gate.dart';
import 'hadi_provider.dart';

/// Every screen Hādi is allowed to take a person to. Each entry MUST be a
/// real route in router.dart (test/hadi_nav_test.dart parses router.dart and
/// fails if one is not), and every path the system prompt advertises MUST
/// be here (the same test checks that too).
const Set<String> kHadiNavWhitelist = <String>{
  '/home', '/stories', '/games', '/player', '/finance', '/masajid',
  '/feelings', '/family-tree', '/huda', '/elder-care',
  '/qibla', '/hadith', '/sakina', '/share', '/notes',
  '/quran', '/prayer', '/zakat', '/calendar', '/adhkar', '/explore',
  '/journey', '/settings', '/sources', '/hadi', '/noor',
  '/search', '/profile', '/home/elder', '/games/trivia',
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

/// Short names for the screens Hādi offers as buttons. A route that is not
/// listed still works; its button says "Open this screen".
const Map<String, String> kHadiRouteNames = <String, String>{
  '/stories': 'Stories',
  '/prayer': 'Prayer Times',
  '/qibla': 'Qibla',
  '/quran': 'the Qur’an',
  '/zakat': 'the Zakat calculator',
  '/calendar': 'the Islamic Calendar',
  '/hadith': 'the Forty Hadith',
  '/adhkar': 'Dhikr and Du’a',
  '/sakina': 'Sakina',
  '/feelings': 'For Your Heart',
  '/games': 'the Games',
  '/games/names99': 'the 99 Names',
  '/academy': 'the Wasia Academy',
  '/academy/gate': 'the Wasia Academy',
  '/academy/hisn': 'the Daily Duas',
  '/huda': 'the Huda guides',
  '/journey': 'your Journey',
  '/notes': 'Notes',
  '/settings': 'Settings',
  '/search': 'Find Anything',
  '/sources': 'Our Sources',
  '/masajid': 'Masajid and Halal',
  '/family-tree': 'the Messengers’ family tree',
  '/finance': 'Tayyib Finance',
  '/share': 'verse cards',
};

/// Reads the [GO:] / [DO:] tokens a reply may carry. Pure, so it is tested
/// without a controller.
abstract final class HadiTokens {
  static final RegExp _go = RegExp(r'\[GO:(/[a-z0-9\-/:]+)\]');
  static final RegExp _goAny = RegExp(r'\s*\[GO:[^\]]*\]');
  static final RegExp _doAny = RegExp(r'\s*\[DO:[^\]]*\]');

  /// The first [GO:] route that is on the whitelist, or null.
  static String? routeOf(String answer) {
    for (final RegExpMatch m in _go.allMatches(answer)) {
      final String? route = m.group(1);
      if (route != null && kHadiNavWhitelist.contains(route)) return route;
    }
    return null;
  }

  /// Every distinct whitelisted [GO:] route in [answer], in order, at most
  /// [limit]. Each becomes an "Open …" button; nothing moves on its own.
  static List<String> routesOf(String answer, {int limit = 2}) {
    final List<String> out = <String>[];
    for (final RegExpMatch m in _go.allMatches(answer)) {
      final String? route = m.group(1);
      if (route != null &&
          kHadiNavWhitelist.contains(route) &&
          !out.contains(route)) {
        out.add(route);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  /// Button text for [route], for example "Open Prayer Times".
  static String labelFor(String route) =>
      'Open ${kHadiRouteNames[route] ?? 'this screen'}';

  /// [answer] with every [GO:] and [DO:] token removed.
  static String strip(String answer) =>
      answer.replaceAll(_goAny, '').replaceAll(_doAny, '').trim();
}

class HadiState {
  const HadiState({
    required this.messages,
    this.typing = false,
    this.live = false,
    this.madhhab = Madhhab.notSure,
  });

  final List<HadiMessage> messages;
  final bool typing;

  /// True when answering through the live provider (user key present).
  final bool live;

  /// The school of law the person chose (kept on the device).
  final Madhhab madhhab;

  HadiState copy({
    List<HadiMessage>? messages,
    bool? typing,
    bool? live,
    Madhhab? madhhab,
  }) {
    return HadiState(
      messages: messages ?? this.messages,
      typing: typing ?? this.typing,
      live: live ?? this.live,
      madhhab: madhhab ?? this.madhhab,
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
  /// Returns the reply text with the tokens removed and a plain
  /// confirmation added for each action that really happened.
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
            // Idempotent: asking to save never UN-saves a hadith that is
            // already saved (the underlying controller toggles).
            final DailyHadith hadith = ref.read(todaysHadithProvider);
            final bool already =
                ref.read(savedDailyHadithsProvider).contains(hadith.text);
            if (!already) {
              await ref
                  .read(savedDailyHadithsProvider.notifier)
                  .toggle(hadith.text);
            }
            confirmations.add(already
                ? "Today's hadith was already saved for you."
                : "Today's hadith is saved for you.");
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
    return clean;
  }

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
            if (!_isWelcomeBack((e as Map)['text'] as String))
              HadiMessage(
                fromHadi: e['fromHadi'] as bool,
                text: e['text'] as String,
                sources: <String>[
                  for (final dynamic x in (e['sources'] as List<dynamic>? ??
                      const <dynamic>[]))
                    x as String,
                ],
                routes: <String>[
                  for (final dynamic x in (e['routes'] as List<dynamic>? ??
                      const <dynamic>[]))
                    x as String,
                ],
              ),
        ];
        if (restored.length > 1) {
          // A short line for this visit only: it never repeats what the
          // person said last time, and it is not saved.
          messages = <HadiMessage>[
            ...restored,
            const HadiMessage(
              fromHadi: true,
              text: 'Welcome back. Where shall we continue?',
              ephemeral: true,
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
    return HadiState(messages: messages, live: _apiKey != null, madhhab: madhhab);
  }

  /// Older versions saved their "Welcome back" line into the thread; drop it
  /// when the thread is read so it does not pile up.
  static bool _isWelcomeBack(String text) => text.startsWith('Welcome back.');

  void _persistThread(List<HadiMessage> messages) {
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      // Anything said during a crisis exchange stays on screen for this
      // visit only; it is never written to the device thread.
      final List<HadiMessage> savable = <HadiMessage>[
        for (final HadiMessage m in messages)
          if (!m.sensitive && !m.ephemeral) m,
      ];
      final List<HadiMessage> tail = savable.length > 20
          ? savable.sublist(savable.length - 20)
          : savable;
      prefs.setString(
        _threadPref,
        json.encode(<Map<String, dynamic>>[
          for (final HadiMessage m in tail)
            <String, dynamic>{
              'fromHadi': m.fromHadi,
              'text': m.text,
              if (m.sources.isNotEmpty) 'sources': m.sources,
              if (m.routes.isNotEmpty) 'routes': m.routes,
            },
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
    // A fresh conversation starts with no age on record.
    _minorSession = false;
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
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      final String? k = prefs.getString(_keyPref);
      if (k != null && k.trim().isNotEmpty) return k.trim();
      return ref.read(subscriptionServiceProvider.notifier).managedKey;
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
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
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

  /// True when a crisis reply was shown in the last few messages.
  bool _crisisShownRecently() {
    final List<HadiMessage> m = state.messages;
    final int from = m.length > 6 ? m.length - 6 : 0;
    for (int i = from; i < m.length; i++) {
      if (m[i].crisis != null) return true;
    }
    return false;
  }

  /// Short, different replies for when a person keeps talking about wanting
  /// to die. Never a question the offline shelf could not follow up.
  static const List<String> _selfHarmFollowUps = <String>[
    'I am still here, and I am glad you are telling me more. You do not '
        'have to make sense of all of it tonight. Please keep the lines '
        'above close, and stay near someone if you can.',
    'I hear you. Pain this heavy is not weakness, and it does not mean '
        'Allah has left you: He told His Prophet ﷺ, “Your Lord has not '
        'taken leave of you, [O Muhammad], nor has He detested [you].” '
        '(Qur’an 93:3). If '
        'the thoughts get stronger, call the number for your country above '
        'or your local emergency number right then.',
    'I am staying right here. One small step: message or call one person '
        'you trust and tell them just one sentence, “I am not okay.” You do '
        'not need to explain more than that tonight.',
  ];

  /// The fixed reply for a crisis message, or null when the message should
  /// go on to the normal flow (an abuse follow-up question, answered from
  /// the on-device shelf only).
  String? _crisisReply(CrisisKind kind) {
    final String? cc = ref.read(deviceCountryProvider);
    if (!_crisisShownRecently()) {
      return CrisisResponses.textFor(kind, countryCode: cc);
    }
    switch (kind) {
      case CrisisKind.selfHarm:
        final int n = state.messages
            .where((HadiMessage m) => m.crisis == CrisisKind.selfHarm)
            .length;
        return _selfHarmFollowUps[n % _selfHarmFollowUps.length];
      case CrisisKind.suicideQuestion:
        return 'Judgement of any person belongs to Allah alone, and His '
            'mercy is vast. For a ruling about a particular person, please '
            'ask a qualified scholar in person; Our Sources lists one. If '
            'any part of this is about you, the help lines above are still '
            'here.';
      case CrisisKind.abuse:
        return null;
      case CrisisKind.childSafety:
      case CrisisKind.eatingDisorder:
      case CrisisKind.extremism:
        return CrisisResponses.followUpFor(kind);
    }
  }

  // ── Madhhab ────────────────────────────────────────────────────────
  static const String _madhhabPref = 'ar.hadi.madhhab';

  Madhhab get madhhab {
    try {
      return Madhhab.fromCode(
          ref.read(sharedPreferencesProvider).getString(_madhhabPref));
    } catch (_) {
      return Madhhab.notSure;
    }
  }

  Future<void> setMadhhab(Madhhab m) async {
    try {
      await ref.read(sharedPreferencesProvider).setString(_madhhabPref, m.code);
    } catch (_) {}
    state = state.copy(madhhab: m);
  }

  // ── Grounding helpers (pure where possible) ────────────────────────
  static final RegExp _navLike = RegExp(
    r'\b(where|open|take me|go to|show me|how do i|how can i|app|feature|'
    r'story|stories|khutbah|find|section|page|screen|academy|game|games|'
    r'settings|bookmark|save|school|wasia|journey|notes|calendar|qibla|'
    r'zakat|prayer times?|which|what do you have|contains?)\b',
    caseSensitive: false,
  );

  /// True when the question is about the app itself, so the table of
  /// contents is worth sending.
  static bool isNavigationLike(String q) => _navLike.hasMatch(q);

  Future<HadiCorpus> _corpus() async {
    try {
      return await ref.read(hadiCorpusProvider.future);
    } catch (_) {
      return HadiCorpus.fromJson(
        corpus: <String, dynamic>{
          'quran': <dynamic>[],
          'hadith': <dynamic>[],
          'checked': '',
        },
        quran: <dynamic>[],
      );
    }
  }

  void _append(HadiMessage m) {
    state = state.copy(
      messages: <HadiMessage>[...state.messages, m],
      typing: false,
    );
    _persistThread(state.messages);
  }

  /// Set once a person says they are under 18. Memory only, this visit.
  bool _minorSession = false;

  /// Test hook: runs once an answer exists, just before the steps that act
  /// on it (tokens, verification, ruling filter). A throw here stands in for
  /// any failure in those steps.
  @visibleForTesting
  void Function(String answer)? debugBeforeTail;

  static const String _askFailed =
      'Something went wrong on my side and I could not finish that answer. '
      'Please ask again in a moment. If you are in danger right now, please '
      'contact your local emergency number.';

  /// Never leaves Hādi stuck "typing": whatever fails anywhere in [_ask],
  /// the person gets a plain reply and can ask again.
  Future<String> ask(String question, {HadiProvider? provider}) async {
    final int before = state.messages.length;
    try {
      return await _ask(question, provider: provider);
    } catch (_) {
      try {
        final List<HadiMessage> shown = <HadiMessage>[...state.messages];
        if (shown.length == before) {
          // Failed before the question was even shown: show it, privately
          // (never saved), then the reply.
          shown.add(HadiMessage(
              fromHadi: false, text: question.trim(), sensitive: true));
        }
        shown.add(const HadiMessage(
            fromHadi: true, text: _askFailed, sensitive: true));
        state = state.copy(messages: shown, typing: false);
      } catch (_) {
        // Even recording the failure failed: at least free the input.
        try {
          state = state.copy(typing: false);
        } catch (_) {}
      }
      return _askFailed;
    }
  }

  Future<String> _ask(String question, {HadiProvider? provider}) async {
    if (question.trim().isEmpty || state.typing) return '';
    final String q = question.trim();

    if (MinorSignal.isMinor(q)) _minorSession = true;

    // SAFETY FIRST. Runs before any provider, offline or live. When it
    // fires, no provider is called, nothing is sent over the network, no
    // quota is spent, and the exchange is never saved to the device.
    final CrisisKind? crisis = CrisisDetector.detect(q);
    if (crisis != null) {
      final String? fixed = _crisisReply(crisis);
      if (fixed != null) {
        state = state.copy(
          messages: <HadiMessage>[
            ...state.messages,
            HadiMessage(fromHadi: false, text: q, sensitive: true),
            HadiMessage(
              fromHadi: true,
              text: fixed,
              crisis: crisis,
              sensitive: true,
            ),
          ],
          typing: false,
        );
        _persistThread(state.messages);
        return fixed;
      }
    }

    // Hādi is for adults. Someone who says they are under 18 gets a short
    // fixed reply and the children's lines; no live model is called.
    if (_minorSession && crisis == null) {
      final int prior = state.messages
          .where((HadiMessage m) =>
              m.fromHadi && m.crisis == CrisisKind.childSafety && m.sensitive)
          .length;
      final String reply = MinorSignal.replyFor(prior);
      state = state.copy(
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q, sensitive: true),
          HadiMessage(
            fromHadi: true,
            text: reply,
            crisis: CrisisKind.childSafety,
            sensitive: true,
          ),
        ],
        typing: false,
      );
      _persistThread(state.messages);
      return reply;
    }

    // Rulings about one person's own case are never answered by a model.
    final RulingClass ruling =
        crisis == null ? RulingGate.classify(q) : RulingClass.none;
    if (ruling == RulingClass.personal) {
      final HadiCorpus corpus = await _corpus();
      final Madhhab m = madhhab;
      final String reply = RulingGate.personalReply(
        schoolLabel: m == Madhhab.notSure ? null : m.label,
      );
      state = state.copy(
        messages: <HadiMessage>[
          ...state.messages,
          HadiMessage(fromHadi: false, text: q),
        ],
        typing: false,
      );
      _append(HadiMessage(
        fromHadi: true,
        text: reply,
        sources: <String>[
          for (final Passage p in corpus.retrieve(q, limit: 2)) p.id,
        ],
      ));
      return reply;
    }

    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: false, text: q, sensitive: crisis != null),
      ],
      typing: true,
    );
    // An abuse follow-up stays on the device: the on-device shelf answers.
    final bool onDeviceOnly = crisis != null;
    HadiProvider p = onDeviceOnly
        ? const OfflineHadiProvider()
        : (provider ?? resolveProvider(_apiKey));
    // Subscription quota: managed-key calls count against the daily tier
    // quota. When the quota is spent, answer from the shelf and say so.
    String? quotaNote;
    if (!onDeviceOnly &&
        provider == null &&
        _usingManagedKey &&
        _apiKey != null) {
      final SubscriptionService sub =
          ref.read(subscriptionServiceProvider.notifier);
      if (sub.isEntitled && !sub.consumeQuestion()) {
        p = const OfflineHadiProvider();
        quotaNote = 'Your live questions for today are finished — the '
            'subscription resets at midnight. Meanwhile, from my built-in '
            'shelf:\n\n';
      }
    }
    // History = everything before this question, minus anything said during
    // a crisis exchange (that never leaves the device).
    final List<HadiMessage> history = <HadiMessage>[
      for (final HadiMessage m
          in state.messages.sublist(0, state.messages.length - 1))
        if (!m.sensitive && !m.ephemeral) m,
    ];
    final HadiCorpus corpus = await _corpus();
    bool usedLive = false;
    bool failedLive = false;
    String answer;
    try {
      String liveQuestion = q;
      if (p is! OfflineHadiProvider) {
        usedLive = true;
        final StringBuffer ctx = StringBuffer();
        if (isNavigationLike(q)) {
          final String tocDigest = await _toc();
          if (tocDigest.isNotEmpty) {
            ctx.write('The app’s table of contents (so you can answer '
                'about what the app CONTAINS, e.g. which stories or guides '
                'exist — never claim to know the user’s private '
                'data):\n$tocDigest\n');
          }
        }
        // Opt-in memory: only what the user deliberately enabled, and only
        // the name. (Settings says so; the key sheet says where it goes.)
        try {
          final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
          if (prefs.getBool(_memoryPref) == true) {
            final profile = await ref.read(userProfileProvider.future);
            final String? name = profile?.displayName;
            if (name != null && name.trim().isNotEmpty) {
              ctx.write('The user chose to share their name with you: '
                  '${name.trim()}. Use it once per answer, naturally.\n');
            }
          }
        } catch (_) {}
        ctx.write('${madhhab.promptLine}\n');
        if (ruling == RulingClass.general) {
          ctx.write('This is a general question about a ruling. Explain the '
              'general position and that schools differ. Do not apply it to '
              'the user’s own case.\n');
        }
        final List<Passage> found = corpus.retrieve(q, limit: 4);
        if (found.isEmpty) {
          ctx.write('PASSAGES: none in the library match this question. Cite '
              'no verse or hadith.\n');
        } else {
          ctx.write('PASSAGES you may cite (write only the ID token, never '
              'the text):\n');
          for (final Passage f in found) {
            ctx.write('${HadiCorpus.describeForModel(f)}\n');
          }
        }
        liveQuestion = '${ctx.toString()}\nUser’s question: $q';
      }
      // The offline shelf matches on the user's own words only.
      answer = await p.ask(p is OfflineHadiProvider ? q : liveQuestion, history);
    } catch (e) {
      // Live failure never dead-ends: the curated knowledge answers — but
      // say WHY, so a bad key, a blocked region, or CORS is visible instead
      // of masquerading as ignorance. Never the raw exception text.
      usedLive = false;
      String offline;
      try {
        offline = await OfflineHadiProvider(hasKey: _apiKey != null)
            .ask(q, history);
      } catch (_) {
        offline = OfflineHadiProvider.declineFor(_apiKey != null);
      }
      failedLive = true;
      final String why = e is HadiProviderException
          ? e.message
          : 'I could not connect. Check your internet connection, or '
              'whether your browser is blocking the AI service.';
      answer = 'I could not reach my live knowledge engine just now ($why) '
          'Offline guidance: $offline';
    }
    if (quotaNote != null) answer = quotaNote + answer;
    debugBeforeTail?.call(answer);
    // Tokens are acted on, then removed, BEFORE the message is shown or
    // saved — so the thread never holds a raw [GO:] / [DO:] token.
    final List<String> routes = HadiTokens.routesOf(answer);
    String clean = HadiTokens.strip(await _executeActions(answer));

    // Live answers are checked before anyone sees them.
    List<String> sources = const <String>[];
    final List<String> notes = <String>[];
    if (usedLive) {
      final VerifiedAnswer v = AnswerVerifier.verify(
        clean,
        corpus,
        keepUserScript: OfflineHadiProvider.scriptOf(q) != HadiScript.latin,
      );
      clean = v.text;
      sources = v.sourceIds;
      if (v.changed) {
        notes.add('Hādi removed a reference or quotation it could not check '
            'against its library.');
      }
      if (v.unsupportedGrade) {
        notes.add('Any hadith grade in this reply is not checked. Grades '
            'are shown only under passages from Hādi’s library.');
      }
      final ({String text, bool changed}) f = RulingGate.filterLive(clean);
      if (f.changed) {
        clean = f.text;
        notes.add('A sentence about your own situation was removed.');
      }
    } else if (crisis == null) {
      // The built-in shelf is written by hand. Whatever Qur'an verse or
      // library hadith its answer cites is printed under it from the app's
      // own library (Arabic, translation, grade), exactly as for a live
      // answer. A reference that is not in the library gets no card.
      sources = AnswerVerifier.citedIds(clean, corpus);
      // The school of law applies to the shelf's fiqh answers only where
      // the shelf holds a verified text for that school. It holds none, so
      // say so plainly and offer the scholar hand-off; never guess a ruling.
      final Madhhab school = madhhab;
      if (school != Madhhab.notSure) {
        final String? schoolNote = OfflineHadiProvider.schoolNote(
          question: q,
          answer: clean,
          schoolLabel: school.label,
        );
        if (schoolNote != null) {
          clean = '$clean\n\n$schoolNote';
          if (!routes.contains('/sources')) routes.add('/sources');
        }
      }
    }
    if (ruling == RulingClass.general) {
      clean = '$clean\n\n${RulingGate.generalFooter}';
    }
    if (crisis != null) {
      clean = '$clean\n\n${CrisisResponses.reminderFor(crisis)}';
    }
    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(
          fromHadi: true,
          text: clean,
          sensitive: crisis != null,
          sources: sources,
          live: usedLive,
          notes: notes,
          routes: routes,
          retryQuestion: failedLive ? q : null,
        ),
      ],
      typing: false,
    );
    _persistThread(state.messages);
    return clean;
  }
}

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek '
    'authentic knowledge. Ask me about worship, the Qur\'an, or where '
    'anything lives in this app. And when the weight is heavy, tell me '
    'that too — I will stay with it.';

final NotifierProvider<HadiController, HadiState> hadiControllerProvider =
    NotifierProvider<HadiController, HadiState>(HadiController.new);
