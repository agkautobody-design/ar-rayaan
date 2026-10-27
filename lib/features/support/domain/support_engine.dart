import 'emotion_intent.dart';
import 'rotation.dart';
import 'support_pack.dart';
import 'tone.dart';

/// Where a support conversation is. `crisis` interrupts any state and is
/// handled by the crisis detector before this engine is ever asked.
enum ConvState { open, checkin, listen, reflect, explore, plan, close, crisis, handoff }

/// Everything one conversation remembers, in memory only. Nothing here is
/// written to disk; closing the screen forgets it.
class SupportSession {
  SupportSession({int seed = 0, int defaultGap = 6})
      : rotator = SnippetRotator(seed: seed, defaultMinGap: defaultGap);

  final SnippetRotator rotator;
  ConvState state = ConvState.open;
  int turns = 0;
  int exploreTurns = 0;

  /// A snippet waiting for the person to say yes or no (information they did
  /// not ask for is always offered first).
  String? pendingId;
  String? pendingPack;

  bool faithOffered = false;
  bool referralOffered = false;
  final List<int> lengths = <int>[];

  /// Confirmed themes, for the closing summary only.
  final List<String> themes = <String>[];

  /// The topic of this conversation (a pack name), for the summary.
  String? topic;

  /// A short summary of the conversation so far, built from tags only and
  /// kept on the device. It never contains the person's words. Used as the
  /// context for an online model (if allowed) instead of the raw history.
  String get contextSummary {
    final StringBuffer b = StringBuffer();
    if (topic != null) b.write('Topic: $topic. ');
    if (themes.isNotEmpty) b.write('Feelings noticed: ${themes.join(', ')}. ');
    b.write('Turns so far: $turns.');
    return b.toString();
  }
}

/// One reply from the engine.
class SupportTurn {
  const SupportTurn({
    required this.text,
    required this.ids,
    required this.state,
    this.showHelplines = false,
    this.fixed = false,
    this.sources = const <Map<String, dynamic>>[],
    this.needsScholarReview = false,
    this.needsClinicianReview = true,
    this.status = 'draft',
  });

  final String text;
  final List<String> ids;
  final ConvState state;

  /// The reply points to people; the screen shows the help lines under it.
  final bool showHelplines;

  /// Fixed wording that must be shown exactly as written.
  final bool fixed;
  final List<Map<String, dynamic>> sources;
  final bool needsScholarReview;
  final bool needsClinicianReview;
  final String status;
}

/// Builds a support reply from knowledge packs, with no model call.
///
/// Motivational-interviewing shape: reflect, then at most one question; never
/// a lecture; information and plan steps are offered, not pushed; medical and
/// ruling questions are handed over. Wording comes from the packs and is
/// rotated so a line is never repeated within its gap.
class SupportEngine {
  SupportEngine({
    required List<SupportPack> packs,
    this.allowDraft = true,
    DateTime? now,
  })  : _packs = <String, SupportPack>{for (final SupportPack p in packs) p.name: p},
        _now = now ?? DateTime.now();

  final Map<String, SupportPack> _packs;
  final DateTime _now;

  /// Internal builds show draft wording (always with the review labels);
  /// a release build with this off shows `shippable` snippets only.
  final bool allowDraft;

  static const int maxWords = 90;

  bool hasPack(String name) => _packs.containsKey(name);

  /// The persistent "how to ask permission" lines. Used when no conversation
  /// pack supplies them. Three, rotated.
  static const List<String> _permissionAsks = <String>[
    'Would it be all right if I shared something that helps some people?',
    'I have one idea, if you would like to hear it. Is that all right?',
    'May I offer a small suggestion? You can say no.',
  ];

  static const List<String> _scholarHandoffs = <String>[
    'That is a question for a qualified scholar, and I am not one. I can stay with how this feels while you find one.',
    'I cannot give a ruling on your own situation. A scholar you trust can, and the support here is yours either way.',
    'A verdict is not mine to give. A scholar who knows you can answer it properly, and I am still here.',
  ];

  static const List<String> _onlyFriend = <String>[
    'I am glad you are here. I am an app, though, and you deserve people too. Is there one person who could know a little of this?',
    'I will keep talking with you, and I also want more for you than an app. Who is one person you could trust a little?',
    'This is a good place to talk, and it is not enough on its own. Could we think of one person, or a service, to add?',
  ];

  static const List<String> _aboutAi = <String>[
    'I am an app, not a person, so I cannot love or feel as a person does. I can listen and I am here now.',
    'I am a program inside this app. I do not feel the way you do, but I take what you say seriously.',
    'Not a person, no. I am an app that listens and points to people who can help.',
  ];

  List<SupportSnippet> _pool(
    String pack, {
    required String kind,
    required List<String> stages,
    required String ageBand,
    required String lang,
    bool allowAsk = false,
  }) {
    final SupportPack? p = _packs[pack];
    if (p == null || p.expiredAt(_now)) return const <SupportSnippet>[];
    return <SupportSnippet>[
      for (final SupportSnippet s in p.snippets)
        if (s.kind == kind &&
            stages.any(s.matchesStage) &&
            s.matchesAge(ageBand) &&
            s.text.isNotEmpty &&
            (allowDraft || s.shippable) &&
            (allowAsk || !s.askPermission))
          s,
    ];
  }

  /// Keeps the best-matching snippets for the cues (emotion tags and words).
  List<SupportSnippet> _best(List<SupportSnippet> pool, Set<String> cues) {
    if (pool.isEmpty) return pool;
    int score(SupportSnippet s) =>
        s.tags.where(cues.contains).length * 2 +
        s.triggers.where((String t) => cues.contains(t)).length;
    int top = 0;
    for (final SupportSnippet s in pool) {
      final int v = score(s);
      if (v > top) top = v;
    }
    if (top == 0) return pool;
    // Keep everything within one point of the best, so there is always a
    // choice to rotate through.
    return <SupportSnippet>[
      for (final SupportSnippet s in pool)
        if (score(s) >= top - 1) s,
    ];
  }

  SupportSnippet? _choose(
    SupportSession session,
    List<String> packs, {
    required String kind,
    required List<String> stages,
    required String ageBand,
    required String lang,
    required Set<String> cues,
    required List<String> toneOrder,
    bool allowAsk = false,
  }) {
    final List<SupportSnippet> pool = <SupportSnippet>[
      for (final String p in packs)
        ..._pool(p, kind: kind, stages: stages, ageBand: ageBand, lang: lang, allowAsk: allowAsk),
    ];
    return session.rotator.pick(
      _best(pool, cues),
      toneOrder: toneOrder,
      text: (SupportSnippet s) => s.textIn(lang),
    );
  }

  String _rotateStatic(SupportSession session, List<String> options, String key) {
    // A tiny rotation for the few fixed fallback lines, kept in the session.
    final int i = session.rotator.turn % options.length;
    return options[i];
  }

  int _words(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

  /// The reply to [userText] in a conversation about [pack]. [extraPacks] are
  /// consulted too (for example `shame_despair` and `cravings_toolkit`).
  SupportTurn? reply(
    SupportSession session, {
    required String pack,
    required String userText,
    List<String> extraPacks = const <String>[],
    String lang = 'en',
    String ageBand = 'adult',
    String toneSetting = 'auto',
    Set<String> extraCues = const <String>{},
  }) {
    if (!hasPack(pack)) return null;
    session.rotator.nextTurn();
    session.turns++;
    final EmotionIntent ei = EmotionIntentDetector.detect(userText);
    session.lengths.add(ei.wordCount);
    session.topic = pack;
    for (final String e in ei.emotions) {
      if (!session.themes.contains(e)) session.themes.add(e);
    }
    final List<String> tones = ToneChooser.order(
      setting: toneSetting,
      recentLengths: session.lengths,
      distress: ei.distressed,
    );
    final Set<String> cues = <String>{
      ...ei.emotions,
      ...extraCues,
      pack,
      ...userText.toLowerCase().split(RegExp(r'[^a-z]+')).where((String w) => w.length > 2),
    };
    final List<String> packs = <String>[
      pack,
      for (final String e in extraPacks)
        if (hasPack(e)) e,
    ];

    SupportTurn out(String text, List<SupportSnippet> used, ConvState st,
        {bool helplines = false, bool fixed = false}) {
      session.state = st;
      return SupportTurn(
        text: text,
        ids: <String>[for (final SupportSnippet s in used) s.id],
        state: st,
        showHelplines: helplines,
        fixed: fixed,
        sources: <Map<String, dynamic>>[for (final SupportSnippet s in used) ...s.sources],
        needsScholarReview: used.any((SupportSnippet s) => s.needsScholarReview),
        needsClinicianReview: used.isEmpty || used.any((SupportSnippet s) => s.needsClinicianReview),
        status: used.isNotEmpty && used.every((SupportSnippet s) => s.shippable) ? 'shippable' : 'draft',
      );
    }

    SupportSnippet? one(String kind, List<String> stages, {bool allowAsk = false}) => _choose(
          session, packs,
          kind: kind, stages: stages, ageBand: ageBand, lang: lang,
          cues: cues, toneOrder: tones, allowAsk: allowAsk,
        );

    String join(List<String> parts) =>
        parts.where((String p) => p.trim().isNotEmpty).join('\n\n');

    // A snippet the person was asked about.
    final String? pend = session.pendingId;
    if (pend != null) {
      SupportSnippet? waiting;
      for (final String p in packs) {
        for (final SupportSnippet s in _packs[p]!.snippets) {
          if (s.id == pend) waiting = s;
        }
      }
      session.pendingId = null;
      if (waiting != null && ei.intent == SupportIntent.yes) {
        session.state = waiting.kind == 'plan-step' ? ConvState.plan : ConvState.explore;
        session.rotator.pick(<SupportSnippet>[waiting]);
        return out(waiting.textIn(lang), <SupportSnippet>[waiting], session.state);
      }
      if (ei.intent == SupportIntent.no) {
        final SupportSnippet? a = one('affirm', <String>['reflect']);
        return out(
          join(<String>[
            'That is completely fine. Nothing has to change tonight.',
            a?.textIn(lang) ?? '',
          ]),
          <SupportSnippet>[?a],
          ConvState.listen,
        );
      }
    }

    // Medical questions are handed over: fixed wording, then people.
    if (ei.intent == SupportIntent.askMedical) {
      final SupportSnippet? s = one('safety', <String>['handoff', 'crisis']);
      final SupportSnippet? r = one('referral', <String>['handoff']);
      if (s != null || r != null) {
        session.referralOffered = true;
        return out(
          join(<String>[s?.textIn(lang) ?? '', r?.textIn(lang) ?? '']),
          <SupportSnippet>[?s, ?r],
          ConvState.handoff,
          helplines: true,
          fixed: true,
        );
      }
    }

    if (ei.intent == SupportIntent.askRuling) {
      final SupportSnippet? a = one('ask', <String>['explore']);
      return out(
        join(<String>[_rotateStatic(session, _scholarHandoffs, 'ruling'), a?.textIn(lang) ?? '']),
        <SupportSnippet>[?a],
        ConvState.listen,
      );
    }
    if (ei.intent == SupportIntent.onlyFriend) {
      return out(_rotateStatic(session, _onlyFriend, 'friend'), const <SupportSnippet>[], ConvState.listen);
    }
    if (ei.intent == SupportIntent.askAboutAi) {
      return out(_rotateStatic(session, _aboutAi, 'ai'), const <SupportSnippet>[], ConvState.listen);
    }

    if (ei.intent == SupportIntent.thanks || ei.intent == SupportIntent.goodbye) {
      final SupportSnippet? a = one('affirm', <String>['close']);
      final SupportSnippet? sum = session.themes.isNotEmpty ? one('summary', <String>['close']) : null;
      return out(
        join(<String>[a?.textIn(lang) ?? 'I am glad you came by.', sum?.fill(lang, <String, String>{}) ?? '']),
        <SupportSnippet>[?a, ?sum],
        ConvState.close,
      );
    }

    // Ready for a small step: offered, never pushed.
    final bool readyForStep = ei.intent == SupportIntent.wantsStep ||
        (session.exploreTurns >= 2 && ei.intent == SupportIntent.share && session.turns % 2 == 0);
    if (readyForStep) {
      final SupportSnippet? step = one('plan-step', <String>['plan'], allowAsk: true);
      if (step != null) {
        if (step.askPermission && ei.intent != SupportIntent.wantsStep) {
          session.pendingId = step.id;
          return out(_rotateStatic(session, _permissionAsks, 'ask'), <SupportSnippet>[step], ConvState.plan);
        }
        return out(step.textIn(lang), <SupportSnippet>[step], ConvState.plan);
      }
    }

    // Offer a faith frame once, to someone carrying shame or despair.
    if (!session.faithOffered &&
        session.turns >= 2 &&
        (ei.emotions.contains('shame') || ei.emotions.contains('despair'))) {
      final SupportSnippet? f = one('islamic', <String>['explore'], allowAsk: true);
      if (f != null) {
        session.faithOffered = true;
        session.pendingId = f.id;
        return out(
          'Would it be all right if I shared how some people of faith see this? You can say no.',
          <SupportSnippet>[f],
          ConvState.explore,
        );
      }
    }

    // The heart of it: reflect, then one question.
    final List<SupportSnippet> used = <SupportSnippet>[];
    final List<String> parts = <String>[];
    if (session.turns == 1) {
      final SupportSnippet? o = one('orient', <String>['open']);
      if (o != null) {
        used.add(o);
        parts.add(o.textIn(lang));
      }
    }
    final SupportSnippet? r = one('reflect', <String>['reflect']) ?? one('affirm', <String>['reflect']);
    if (r != null) {
      used.add(r);
      parts.add(r.textIn(lang));
    }
    if (!parts.any((String p) => p.trim().endsWith('?'))) {
      final SupportSnippet? q = one('ask', <String>['explore']);
      if (q != null) {
        used.add(q);
        parts.add(q.textIn(lang));
      }
    }
    if (parts.isEmpty) return null;
    // Stay inside the length limit: drop the orienting line first.
    while (_words(parts.join(' ')) > maxWords && parts.length > 1) {
      parts.removeAt(0);
      used.removeAt(0);
    }
    session.exploreTurns++;
    return out(join(parts), used, session.turns == 1 ? ConvState.reflect : ConvState.explore);
  }
}
