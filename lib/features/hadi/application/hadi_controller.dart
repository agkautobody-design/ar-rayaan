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
import '../../../app/core/packages/hadi_package.dart';
import '../../../app/core/packages/usage_meter.dart';
import '../../../app/core/subscription/subscription_service.dart';
import '../../sakina/application/sakina_providers.dart';
import '../../sakina/domain/crisis_detector.dart';
import '../data/groq_hadi_provider.dart';
import '../data/hadi_explain.dart';
import '../data/hadi_finder.dart';
import '../data/hadi_routing.dart';
import '../data/hosted_ai.dart';
import '../data/hosted_cache.dart';
import '../data/local_knowledge.dart';
import '../data/offline_hadi_provider.dart';
import '../grounding/answer_verifier.dart';
import '../grounding/corpus.dart';
import '../grounding/madhhab.dart';
import '../grounding/minor_signal.dart';
import '../grounding/passage.dart';
import '../grounding/ruling_gate.dart';
import 'hadi_bookmark.dart';
import 'hadi_stats.dart';
import 'local_knowledge_provider.dart';
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
  '/sources/policy',
  '/journey', '/settings', '/sources', '/hadi', '/noor',
  '/streaks', '/downloads',
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
  '/tasbeeh', '/settings/language', '/quran/bookmarks',
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
  '/streaks': 'your Streaks',
  '/downloads': 'Downloads',
  '/search': 'Find Anything',
  '/sources': 'Our Sources',
  '/masajid': 'Masajid and Halal',
  '/family-tree': 'the Messengers’ family tree',
  '/finance': 'Tayyib Finance',
  '/share': 'verse cards',
  '/new-muslim': 'the New Muslim path',
  '/academy/aqeedah': 'the Aqeedah school',
  '/academy/qa': 'Questions and Answers',
  '/academy/quranic-arabic': 'the Quranic Arabic school',
  '/academy/ramadan-mode': 'Ramadan Mode',
  '/ramadan': 'the Ramadan screen',
  '/academy/family-life': 'Family Life School',
  '/academy/stories': 'Stories School',
  '/academy/hifz': 'the Hifz planner',
  '/sources/policy': 'How we handle religious content',
  '/tasbeeh': 'the Tasbeeh counter',
  '/settings/language': 'Language and Voice',
  '/quran/bookmarks': 'your Qur’an bookmarks',
  '/player': 'the Nasheed Player',
  '/explore': 'Explore',
  '/home/elder': 'Elder Home',
  '/academy/seerah': 'the Seerah school',
  '/academy/hadith': 'the Hadith school',
  '/academy/hajj-umrah-pack': 'the Hajj and Umrah pack',
  '/academy/recitation': 'the Recitation school',
  '/academy/letters': 'the Arabic letters',
  '/academy/arabic-language': 'the Arabic language school',
  '/games/trivia': 'Trivia',
};

/// The Huda guides Hādi may open directly, as `/huda/guide?id=<id>`, with the
/// button text for each. Each id MUST be a guide in assets/guides/guides.json
/// (test/hadi_round2_test.dart checks).
const Map<String, String> kHadiGuideNames = <String, String>{
  'huda-fasting': 'the Fasting guide',
  'huda-taraweeh': 'the Ramadan Nights guide',
  'huda-witr': 'the Witr and night guide',
  'huda-tahajjud': 'the Tahajjud guide',
  'huda-what-is-islam': 'the What Is Islam guide',
  'huda-madhhab-overview': 'the guide to the four schools',
  'huda-nikah': 'the Nikah guide',
  'huda-travel': 'the Travel guide',
  'huda-illness': 'the Illness and Patience guide',
  'huda-prayer': 'the How to Pray guide',
  'huda-wudu': 'the Wudu guide',
  'huda-ghusl': 'the Ghusl guide',
  'huda-tayammum': 'the Tayammum guide',
  'huda-adhan': 'the The Adhan and Iqamah guide',
  'huda-jumuah': 'the Friday Prayer guide',
  'huda-qada': 'the Making Up Missed Prayers guide',
  'huda-nawafil': 'the The Rawatib guide',
  'huda-mosque': 'the Mosque Manners guide',
  'huda-home': 'the Entering and Leaving the Home guide',
  'huda-janazah-wash': 'the Washing the Deceased guide',
  'huda-janazah-prayer': 'the The Funeral Prayer guide',
  'huda-janazah-burial': 'the The Burial and Visiting Graves guide',
  'huda-condolence': 'the Consoling the Bereaved guide',
  'huda-food': 'the Eating Manners guide',
  'huda-sleep': 'the Sleeping Manners guide',
  'huda-speech': 'the Speech guide',
  'huda-greeting': 'the Greetings and Sneezing guide',
  'huda-hajj-intro': 'the Hajj guide',
  'huda-ihram': 'the Ihram guide',
  'huda-tawaf': 'the Tawaf and Sa\'i guide',
  'huda-arafat': 'the The Day of Arafah guide',
  'huda-istikhara': 'the Istikhara guide',
  'huda-tawba': 'the Tawba guide',
  'huda-earning': 'the Earning guide',
  'huda-gratitude': 'the Gratitude guide',
  'huda-adhkar': 'the The Morning and Evening Adhkar guide',
  'huda-baby': 'the The New Baby guide',
  'huda-parents': 'the The Rights of Parents guide',
  'huda-neighbors': 'the The Rights of Neighbors guide',
  'huda-oaths': 'the Oaths and Vows guide',
  'huda-knowledge': 'the Seeking Knowledge guide',
  'huda-hardship': 'the Hardship and Relief guide',
  'huda-death-prep': 'the Preparing guide',
  'huda-hajj-overview': 'the Hajj guide',
  'huda-umrah': 'the Umrah guide',
  'huda-arafat-day': 'the The Day of Arafah guide',
  'huda-ihram-rites': 'the Ihram guide',
  'huda-zakat': 'the How Zakat Works guide',
  'huda-sadaqah': 'the Giving Beyond the Obligation guide',
  'huda-quran-daily': 'the A Daily Portion of Qur\'an guide',
  'huda-children-deen': 'the Teaching Your Children the Deen guide',
  'huda-masah': 'the Wiping Over Socks guide',
  'huda-menstruation': 'the Menstruation and Post-Natal Bleeding guide',
  'huda-sujud-sahw': 'the Forgetting in Prayer guide',
  'huda-prayer-times': 'the Five Prayer Times guide',
  'huda-congregation': 'the Praying in Congregation guide',
  'huda-travel-prayer': 'the Travel, Sick and Fear Prayer guide',
  'huda-eid': 'the Eid guide',
  'huda-udhiyah': 'the Udhiyah guide',
  'huda-zakat-fitr': 'the Zakat al-Fitr guide',
  'huda-halal-food': 'the Halal Food guide',
};

/// Reads the [GO:] / [DO:] tokens a reply may carry. Pure, so it is tested
/// without a controller.
abstract final class HadiTokens {
  static final RegExp _go =
      RegExp(r'\[GO:(/[a-z0-9\-/:]+(?:\?id=[a-z0-9\-]+)?)\]');
  static final RegExp _guideRoute = RegExp(r'^/huda/guide\?id=([a-z0-9\-]+)$');

  /// True when [route] is a whitelisted screen, or a Huda guide on
  /// [kHadiGuideNames].
  static bool isAllowed(String route) {
    if (kHadiNavWhitelist.contains(route)) return true;
    final RegExpMatch? g = _guideRoute.firstMatch(route);
    return g != null && kHadiGuideNames.containsKey(g.group(1));
  }
  static final RegExp _goAny = RegExp(r'\s*\[GO:[^\]]*\]');
  static final RegExp _doAny = RegExp(r'\s*\[DO:[^\]]*\]');

  /// The first [GO:] route that is on the whitelist, or null.
  static String? routeOf(String answer) {
    for (final RegExpMatch m in _go.allMatches(answer)) {
      final String? route = m.group(1);
      if (route != null && isAllowed(route)) return route;
    }
    return null;
  }

  /// Every distinct whitelisted [GO:] route in [answer], in order, at most
  /// [limit]. Each becomes an "Open …" button; nothing moves on its own.
  static List<String> routesOf(String answer, {int limit = 2}) {
    final List<String> out = <String>[];
    for (final RegExpMatch m in _go.allMatches(answer)) {
      final String? route = m.group(1);
      if (route != null && isAllowed(route) && !out.contains(route)) {
        out.add(route);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  /// Button text for [route], for example "Open Prayer Times".
  static String labelFor(String route) {
    final RegExpMatch? g = _guideRoute.firstMatch(route);
    if (g != null) {
      return 'Open ${kHadiGuideNames[g.group(1)] ?? 'this guide'}';
    }
    return 'Open ${kHadiRouteNames[route] ?? 'this screen'}';
  }

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

  /// A request to save a story ("bookmark Yusuf") is carried out here, for
  /// real, on the device: no model is asked, and the reply says "saved" only
  /// once the story is in the saved set. Null when [q] is not such a request
  /// or names no story (it then goes through the normal flow).
  Future<String?> _tryBookmark(String q) async {
    final List<String>? words = HadiBookmark.titleWords(q);
    if (words == null) return null;
    final List<Story> stories;
    try {
      stories = await ref.read(storiesProvider.future);
    } catch (_) {
      return null;
    }
    final List<Story> hits = HadiBookmark.match(words, stories);
    if (hits.isEmpty) return null;
    if (hits.length > 1) {
      final String names = <String>[
        for (final Story s in hits.take(4)) '“${s.title}”',
      ].join(', ');
      return 'More than one story fits that: $names. Which one shall I '
          'save? Tell me its full title.';
    }
    final Story story = hits.first;
    try {
      await ref.read(savedStoriesProvider.notifier).save(story.id);
    } catch (_) {}
    if (ref.read(savedStoriesProvider).contains(story.id)) {
      return 'Saved. “${story.title}” is now in your Bookmarks: open your '
          'Journey, then Bookmarks.';
    }
    return 'I could not save “${story.title}” just now, so it is not in '
        'your Bookmarks. Please try again in a moment.';
  }

  static const String _keyPref = 'ar.hadi.apikey';
  static const String _providerPref = 'ar.hadi.provider';
  static const String _threadPref = 'ar.hadi.thread';
  static const String _memoryPref = 'ar.hadi.memory';
  static const String _seedPref = 'ar.hadi.seed';

  @override
  HadiState build() {
    // Start loading the local index now, so it is ready by the first
    // question. Nothing waits for it.
    try {
      ref.read(localKnowledgeProvider);
    } catch (_) {}
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
      return '${CrisisResponses.textFor(kind, countryCode: cc)}\n\n'
          '${CrisisResponses.regionNote(cc)}';
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

  bool _asking = false;

  /// Never leaves Hādi stuck "typing": whatever fails anywhere in [_ask],
  /// the person gets a plain reply and can ask again.
  Future<String> ask(String question, {HadiProvider? provider}) async {
    // `typing` is only set after the first awaits inside [_ask]; this flag is
    // set at once, so a chip tapped twice in a row asks one question, not two.
    if (_asking) return '';
    _asking = true;
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
    } finally {
      _asking = false;
    }
  }

  /// The hosted provider for [q], or null when the built-in library answers
  /// it (the normal case) or a configured package limit is reached (the
  /// library's own reply is then shown, with no message about it).
  Future<HadiProvider?> _hostedFor(String q, List<HadiMessage> history) async {
    try {
      final String shelf = await const OfflineHadiProvider().ask(q, history);
      if (!HadiRouting.isRefusal(shelf)) return null;
    } catch (_) {
      return null;
    }
    final HadiPackage pkg = ref.read(hadiPackageProvider);
    final HadiPackageLimits limits = kHadiPackageLimits[pkg]!;
    final UsageMeter meter = ref.read(usageMeterProvider);
    if (!meter.snapshot(limits).canUse) return null;
    final String norm = normaliseQuestion(q);
    // A very short message may be a follow-up that depends on the thread:
    // never cached.
    final bool cacheable = norm.split(' ').length >= 3;
    return HostedHadiProvider(
      backend: ref.read(hostedAiProvider),
      meter: meter,
      package: pkg,
      limits: limits,
      cache: HostedAnswerCache(ref.read(sharedPreferencesProvider)),
      cacheKey: cacheable ? '${madhhab.name}|$norm' : '',
    );
  }

  /// The local index if it has finished loading, else null. Never waits: the
  /// load starts when the controller is built, and a question asked before it
  /// is ready is simply answered the old way.
  LocalKnowledge? _knowledge() {
    try {
      return ref.read(localKnowledgeProvider).valueOrNull;
    } catch (_) {
      return null;
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
        await _stat(HadiAnswerKind.safety);
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
      await _stat(HadiAnswerKind.safety);
      return reply;
    }

    // Someone who says a person they love has died, or a baby was lost, is
    // answered with care from the on-device reply, not with a ruling hand-off
    // and not by a model.
    final bool grief =
        crisis == null && OfflineHadiProvider.griefReply(q) != null;

    // Rulings about one person's own case are never answered by a model.
    final RulingClass ruling = (crisis == null && !grief)
        ? RulingGate.classify(q)
        : RulingClass.none;
    if (ruling == RulingClass.personal) {
      final HadiCorpus corpus = await _corpus();
      final Madhhab m = madhhab;
      // A question about a medicine is for the doctor first: say so, and
      // never the marriage-and-family wording meant for rulings.
      final bool medical = OfflineHadiProvider.asksMedical(q);
      final String reply = medical
          ? HadiRouting.medicalReply(q)
          : RulingGate.personalReply(
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
        text: medical ? HadiTokens.strip(reply) : reply,
        sources: medical
            ? const <String>[]
            : <String>[
                for (final Passage p in corpus.retrieve(q, limit: 2)) p.id,
              ],
        routes: medical ? HadiTokens.routesOf(reply) : const <String>[],
      ));
      await _stat(HadiAnswerKind.safety);
      return medical ? HadiTokens.strip(reply) : reply;
    }

    if (crisis == null && !grief) {
      final String? saved = await _tryBookmark(q);
      if (saved != null) {
        state = state.copy(
          messages: <HadiMessage>[
            ...state.messages,
            HadiMessage(fromHadi: false, text: q),
          ],
          typing: false,
        );
        _append(HadiMessage(
          fromHadi: true,
          text: saved,
          routes: const <String>['/journey'],
        ));
        return saved;
      }
    }

    state = state.copy(
      messages: <HadiMessage>[
        ...state.messages,
        HadiMessage(fromHadi: false, text: q, sensitive: crisis != null),
      ],
      typing: true,
    );
    // An abuse follow-up stays on the device: the on-device shelf answers.
    final bool onDeviceOnly = crisis != null || grief;
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
    // Local knowledge first: the app's own verified guides and Q&A, quoted
    // (never rewritten). Above the confidence threshold this answers alone,
    // with zero API calls. Below it, the closest entry is offered and only
    // then may hosted AI be considered.
    KnowledgeMatch? closestMatch;
    if (!onDeviceOnly &&
        provider == null &&
        p is OfflineHadiProvider &&
        ruling != RulingClass.personal &&
        !OfflineHadiProvider.asksMedical(q)) {
      final LocalKnowledge? lk = _knowledge();
      if (lk != null) {
        String shelf = '';
        try {
          shelf = await const OfflineHadiProvider().ask(q, history);
        } catch (_) {}
        final bool refusal = HadiRouting.isRefusal(shelf);
        final bool pointer = !refusal && shelf.contains('[GO:');
        if ((refusal || pointer) &&
            !isNavigationLike(q) &&
            !LocalKnowledge.looksLikeLookup(q)) {
          final KnowledgeMatch? hit = lk.confident(q);
          if (hit != null) {
            final String route = hit.entry.route ?? '';
            String text = LocalKnowledge.compose(hit.entry);
            if (ruling == RulingClass.general) {
              text = '$text\n\n${RulingGate.generalFooter}';
            }
            state = state.copy(
              messages: <HadiMessage>[
                ...state.messages,
                HadiMessage(
                  fromHadi: true,
                  text: text,
                  routes: HadiTokens.isAllowed(route)
                      ? <String>[route]
                      : const <String>[],
                ),
              ],
              typing: false,
            );
            _persistThread(state.messages);
            await _stat(HadiAnswerKind.local);
            return text;
          }
          if (refusal) closestMatch = lk.closest(q);
        }
      }
    }
    // Hosted AI (package-capped): only for a question the built-in library
    // cannot answer, and never on any safety path above. The library always
    // answers first and is never metered or gated.
    bool hosted = false;
    if (!onDeviceOnly &&
        provider == null &&
        p is OfflineHadiProvider &&
        ruling == RulingClass.none &&
        !isRulingShaped(q) &&
        isHostedScope(q) &&
        !OfflineHadiProvider.asksMedical(q) &&
        ref.read(hostedAiProvider).isAvailable) {
      final HadiProvider? h = await _hostedFor(q, history);
      if (h != null) {
        p = h;
        hosted = true;
      }
    }
    final HadiCorpus corpus = await _corpus();
    bool usedLive = false;
    bool failedLive = false;
    String answer;
    try {
      String liveQuestion = q;
      if (p is! OfflineHadiProvider) {
        usedLive = true;
        final StringBuffer ctx = StringBuffer();
        if (!hosted && isNavigationLike(q)) {
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
        if (hosted) ctx.write(kHostedAiScopeRules);
        final KnowledgeMatch? near = closestMatch;
        if (hosted && near != null) {
          final String note = LocalKnowledge.compose(near.entry);
          ctx.write('Closest checked entry in the app (background only, do '
              'not repeat numbers from it):\n'
              '${note.length > 600 ? note.substring(0, 600) : note}\n');
        }
        if (ruling == RulingClass.general) {
          ctx.write('This is a general question about a ruling. Explain the '
              'general position and that schools differ. Do not apply it to '
              'the user’s own case.\n');
        }
        final List<Passage> found =
            corpus.retrieve(q, limit: hosted ? kHostedMaxPassages : 4);
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
        final String asked = hosted && q.length > kHostedMaxQuestionChars
            ? q.substring(0, kHostedMaxQuestionChars)
            : q;
        liveQuestion = '${ctx.toString()}\nUser’s question: $asked';
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
      // Everything in the reply may have been removed: never show nothing.
      if (clean.trim().isEmpty) {
        clean = 'I could not find a reply here that I can stand behind. '
            'Please ask in other words, or ask a qualified scholar.';
      }
      if (hosted) {
        final int cap =
            kHadiPackageLimits[ref.read(hadiPackageProvider)]!.maxReplyChars;
        clean = '${limitReply(clean, cap)}\n\n$kHostedAiLabel';
      }
    } else if (crisis == null) {
      // The built-in shelf is written by hand. Whatever Qur'an verse or
      // library hadith its answer cites is printed under it from the app's
      // own library (Arabic, translation, grade), exactly as for a live
      // answer. A reference that is not in the library gets no card.
      // A composed reply quotes several lines; two cards are enough, so the
      // answer never turns into a wall of verses.
      sources = AnswerVerifier.citedIds(
        clean,
        corpus,
        limit: HadiExplain.isComposed(clean) ? 2 : 5,
      );      // Said once per conversation, plainly: with no key, every answer here
      // comes from the app's built-in checked library and nothing else.
      if (!grief &&
          !HadiRouting.isRefusal(clean) &&
          _apiKey == null &&
          !state.messages.any(
            (HadiMessage m) => m.notes.contains(HadiFinder.offlineNote),
          )) {
        notes.add(HadiFinder.offlineNote);
      }
      // A refusal is never a dead end: the closest places in the app and
      // Search go under it as buttons.
      final List<String> help = OfflineHadiProvider.refusalRoutes(q, clean);
      if (help.isNotEmpty) {
        for (final String r in help) {
          if (!routes.contains(r)) routes.add(r);
        }
        clean = '$clean\n\n${HadiRouting.refusalLeadIn}';
      }
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
    final KnowledgeMatch? cm = closestMatch;
    if (cm != null && !usedLive && crisis == null && HadiRouting.isRefusal(clean)) {
      final String r = cm.entry.route ?? '';
      clean = '$clean\n\nClosest in my library: ${cm.entry.title}.';
      if (HadiTokens.isAllowed(r) && !routes.contains(r)) routes.insert(0, r);
    }
    // "Halal food near me" is a request for a place, not a ruling.
    if (ruling == RulingClass.general &&
        !clean.contains('I cannot see where you are, so I cannot name the '
            'nearest')) {
      clean = '$clean\n\n${RulingGate.generalFooter}';
    }
    if (crisis != null) {
      clean = '$clean\n\n${CrisisResponses.reminderFor(crisis)}';
    }
    // "These may help in the meantime:" only ever sits right above buttons
    // that exist; with none, the line is removed.
    clean = HadiRouting.guardLeadIn(clean, routes);
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
    final HadiProvider finalProvider = p;
    await _stat(
      crisis != null || grief
          ? HadiAnswerKind.safety
          : failedLive
              ? HadiAnswerKind.failed
              : usedLive && hosted
                  ? (finalProvider is HostedHadiProvider &&
                          finalProvider.servedFromCache
                      ? HadiAnswerKind.cache
                      : HadiAnswerKind.hosted)
                  : usedLive
                      ? HadiAnswerKind.hosted
                      : HadiRouting.isRefusal(clean)
                          ? HadiAnswerKind.miss
                          : HadiAnswerKind.local,
    );
    return clean;
  }

  /// Counts how this reply was made (on this device only).
  Future<void> _stat(HadiAnswerKind k) async {
    try {
      await ref.read(hadiStatsProvider).record(k);
    } catch (_) {}
  }
}

const String kHadiGreeting =
    'As-Salaamu Alaikum. I am Hādi — walking beside you as you seek '
    'authentic knowledge. Ask me about worship, the Qur\'an, or where '
    'anything lives in this app. And when the weight is heavy, tell me '
    'that too — I will stay with it.';

final NotifierProvider<HadiController, HadiState> hadiControllerProvider =
    NotifierProvider<HadiController, HadiState>(HadiController.new);
