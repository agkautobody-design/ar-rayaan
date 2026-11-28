import 'dart:convert';

import '../../support/domain/user_memory.dart';
import 'hadi_report_service.dart' show HadiReportPolicy;

/// One subject the person keeps coming back to.
class KnownTopic {
  const KnownTopic({required this.count, required this.last});

  /// How many questions touched it (capped, so one subject cannot drown the
  /// rest).
  final int count;

  /// The last day it came up, YYYY-MM-DD.
  final String last;

  Map<String, Object> toJson() => <String, Object>{'c': count, 'd': last};

  static KnownTopic? fromJson(Object? j) {
    if (j is! Map) return null;
    final Object? c = j['c'];
    final Object? d = j['d'];
    if (c is! int || d is! String) return null;
    return KnownTopic(count: UserKnowsRules.cap(c), last: d);
  }
}

/// What Hadi has noticed about one person from how they use him: subjects
/// they ask about, and a few plain facts they said about themselves ("my
/// son", "I am new to Islam"). It lives on the device (and, for a signed-in
/// grown-up, in their own account). It is never a score, a mood, a health
/// fact or anything from a support or crisis exchange, and it never leaves
/// the person's own control: every item can be seen and deleted.
class UserKnows {
  const UserKnows({
    this.topics = const <String, KnownTopic>{},
    this.roles = const <String>{},
    this.asked = 0,
    this.since = '',
    this.covered = const <String, KnownTopic>{},
  });

  static const UserKnows empty = UserKnows();

  /// subject label (see [UserKnowsRules.labels]) → how often and when.
  final Map<String, KnownTopic> topics;

  /// Plain things the person said about themselves: see
  /// [UserKnowsRules.roleLabels].
  final Set<String> roles;

  /// How many questions it has learned from.
  final int asked;

  /// The day it started, YYYY-MM-DD.
  final String since;

  /// Built-in answers Hadi has already given this person (answer id → how
  /// often and when). Ids only, never the question or the words, so he can
  /// say "we went over this" and not repeat himself. Kept for a year.
  final Map<String, KnownTopic> covered;

  bool get isEmpty => topics.isEmpty && roles.isEmpty && covered.isEmpty;

  UserKnows copyWith({
    Map<String, KnownTopic>? topics,
    Set<String>? roles,
    int? asked,
    String? since,
    Map<String, KnownTopic>? covered,
  }) =>
      UserKnows(
        topics: topics ?? this.topics,
        roles: roles ?? this.roles,
        asked: asked ?? this.asked,
        since: since ?? this.since,
        covered: covered ?? this.covered,
      );

  Map<String, Object> toJson() => <String, Object>{
        't': <String, Object>{
          for (final MapEntry<String, KnownTopic> e in topics.entries)
            e.key: e.value.toJson(),
        },
        'r': roles.toList()..sort(),
        'n': asked,
        's': since,
        'e': <String, Object>{
          for (final MapEntry<String, KnownTopic> e in covered.entries)
            e.key: e.value.toJson(),
        },
      };

  String encode() => json.encode(toJson());

  static UserKnows decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final Object? d = json.decode(raw);
      return fromJson(d);
    } catch (_) {
      return empty;
    }
  }

  static UserKnows fromJson(Object? d) {
    if (d is! Map) return empty;
    final Map<String, KnownTopic> topics = <String, KnownTopic>{};
    final Object? t = d['t'];
    if (t is Map) {
      for (final MapEntry<dynamic, dynamic> e in t.entries) {
        final String k = e.key.toString();
        final KnownTopic? v = KnownTopic.fromJson(e.value);
        if (v != null && UserKnowsRules.labels.containsKey(k)) topics[k] = v;
      }
    }
    final Set<String> roles = <String>{};
    final Object? r = d['r'];
    if (r is List) {
      for (final Object? e in r) {
        if (e is String && UserKnowsRules.roleLabels.containsKey(e)) {
          roles.add(e);
        }
      }
    }
    final Map<String, KnownTopic> covered = <String, KnownTopic>{};
    final Object? ce = d['e'];
    if (ce is Map) {
      for (final MapEntry<dynamic, dynamic> e in ce.entries) {
        final String k = e.key.toString();
        final KnownTopic? v = KnownTopic.fromJson(e.value);
        if (v != null && UserKnowsRules.idRe.hasMatch(k)) covered[k] = v;
      }
    }
    final Object? n = d['n'];
    final Object? s = d['s'];
    return UserKnows(
      topics: topics,
      roles: roles,
      asked: n is int ? n : 0,
      since: s is String ? s : '',
      covered: covered,
    );
  }

  UserKnows withoutTopic(String key) => copyWith(
        topics: <String, KnownTopic>{
          for (final MapEntry<String, KnownTopic> e in topics.entries)
            if (e.key != key) e.key: e.value,
        },
      );

  UserKnows withoutRole(String key) =>
      copyWith(roles: <String>{...roles}..remove(key));

  UserKnows withoutCovered(String key) => copyWith(
        covered: <String, KnownTopic>{
          for (final MapEntry<String, KnownTopic> e in covered.entries)
            if (e.key != key) e.key: e.value,
        },
      );
}

/// What may be noticed, and how. Pure, so it is tested without a screen.
abstract final class UserKnowsRules {
  static const int maxCount = 50;
  static const int maxTopics = 12;
  static const int maxCovered = 40;

  /// An answer id as stored: lower-case words joined by dashes.
  static final RegExp idRe = RegExp(r'^[a-z0-9][a-z0-9-]{1,60}$');

  static int cap(int n) => n < 1 ? 1 : (n > maxCount ? maxCount : n);

  /// A subject unmentioned for this many days is forgotten (a year: Hadi is
  /// meant to know a person over time, not for a week).
  static const int forgetAfterDays = 365;

  /// Subject key → how it is shown to the person.
  static const Map<String, String> labels = <String, String>{
    'prayer': 'Prayer (salah)',
    'wudu': 'Wudu and cleanliness',
    'fasting': 'Fasting and Ramadan',
    'zakat': 'Zakat and giving',
    'quran': 'The Qur’an',
    'dua': 'Du’as and dhikr',
    'hadith': 'Hadith',
    'seerah': 'The Prophets and the Seerah',
    'family': 'Family, marriage and parenting',
    'character': 'Character and manners',
    'hajj': 'Hajj and Umrah',
    'learning': 'Study and learning',
    'closeness': 'Feeling close to Allah',
    'goals': 'Goals and purpose',
    'habits': 'Steady habits',
    'patience': 'Patience and gratitude',
    'freshstart': 'Starting again and hope',
  };

  /// An answer id as it is stored (see [idRe]): a built-in knowledge
  /// snippet id such as `closeness_to_allah.howto.001` becomes
  /// `closeness-to-allah-howto-001`.
  static String coveredId(String id) {
    final String c = id
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return c.length > 60 ? c.substring(0, 60) : c;
  }

  /// Plain things a person says about themselves, shown as they were
  /// understood.
  static const Map<String, String> roleLabels = <String, String>{
    'parent': 'You have children',
    'student': 'You are studying',
    'new': 'You are new to Islam',
  };

  static final List<(String, RegExp)> _topicRes = <(String, RegExp)>[
    ('closeness', RegExp(r'\b(?:closer to allah|close to allah|feel allah|connect(?:ed)? (?:with|to) allah|khushu|khushoo|feel nothing (?:when|in) (?:i )?(?:pray|prayer|salah)|prayer feels (?:empty|dry))\b')),
    ('freshstart', RegExp(r'\b(?:start again|start over|fresh start|new beginning|repent\w*|tawbah|tawba|can allah forgive)\b')),
    ('goals', RegExp(r'\b(?:my goals?|achieve|accomplish|purpose|motivat\w*|procrastinat\w*|tawakkul|my dreams?)\b')),
    ('habits', RegExp(r'\b(?:consisten\w*|habits?|routine|fajr alarm|wake (?:up )?for fajr|after ramadan)\b')),
    ('wudu', RegExp(r'\b(?:wudu|ablution|ghusl|tayammum|najas|purif\w*|istinja)\b')),
    ('prayer', RegExp(r'\b(?:pray\w*|salah|salat|namaz|rakah|rakat|rak ?ahs?|sujud|ruku|witr|tahajjud|jumu?ah|friday prayer|adhan|azan|qibla|prayer times?)\b')),
    ('fasting', RegExp(r'\b(?:fast\w*|ramadan|ramzan|sawm|suhoor|sehri|iftar|taraweeh|laylat al ?qadr|eid)\b')),
    ('zakat', RegExp(r'\b(?:zakat|zakah|sadaqah|sadaqa|charity|nisab|fitrana|fitr)\b')),
    ('quran', RegExp(r'\b(?:quran|qur ?an|surah|surat|ayah|ayat|tafsir|tajweed|memori[sz]\w*|hifz|juz)\b')),
    ('dua', RegExp(r'\b(?:dua|du ?a|duas|supplication\w*|dhikr|zikr|adhkar|tasbih|istighfar|astaghfirullah)\b')),
    ('hadith', RegExp(r'\b(?:hadith|hadiths|sunnah|bukhari|muslim|sahih|isnad)\b')),
    ('seerah', RegExp(r'\b(?:seerah|sirah|prophets?|muhammad|ibrahim|musa|isa|yusuf|nuh|companions?|sahaba|khalifa|caliph\w*|uhud|badr|hijrah)\b')),
    ('family', RegExp(r'\b(?:marriage|nikah|wife|husband|spouse|parent\w*|mother|father|mum|mom|dad|raise|raising|children|kids|family|in-?laws?)\b')),
    ('patience', RegExp(r'\b(?:patience|sabr|grateful|gratitude|shukr|thankful|envy|jealous\w*)\b')),
    ('character', RegExp(r'\b(?:honest\w*|gratitude|shukr|humble|humility|kindness|forgiv\w*|anger|backbiting|ghibah|manners|akhlaq|neighbou?rs?)\b')),
    ('hajj', RegExp(r'\b(?:hajj|umrah|ihram|kaaba|kabah|mecca|makkah|madinah|medina|tawaf|arafah)\b')),
    ('learning', RegExp(r'\b(?:learn\w*|study|studying|arabic|alphabet|lesson|course|school|madrasa|madrasah|teacher|knowledge)\b')),
  ];

  /// The subject a question is about, or null when none is clear.
  static String? topicOf(String question) {
    final String q = question.toLowerCase();
    for (final (String, RegExp) t in _topicRes) {
      if (t.$2.hasMatch(q)) return t.$1;
    }
    return null;
  }

  static final RegExp _parent = RegExp(
      r'\bmy (?:son|daughter|sons|daughters|kids?|children|child|toddler|baby|boys?|girls?)\b|\bi am a (?:mum|mom|dad|father|mother|parent)\b|\bas a (?:mum|mom|dad|father|mother|parent)\b');
  static final RegExp _student = RegExp(
      r'\bi(?: am|m)? (?:studying|a student|in (?:university|college|school))\b|\bmy (?:exam|exams|class|course|madrasa|madrasah|teacher|homework)\b');
  static final RegExp _newMuslim = RegExp(
      r'\bi(?: am|m)? (?:a )?(?:new muslim|new to islam|a revert|a convert)\b|\bi (?:just |recently )?(?:reverted|converted|became a muslim|embraced islam)\b');

  /// Things the person plainly said about themselves in this question.
  static Set<String> rolesOf(String question) {
    final String q = question.toLowerCase();
    return <String>{
      if (_parent.hasMatch(q)) 'parent',
      if (_student.hasMatch(q)) 'student',
      if (_newMuslim.hasMatch(q)) 'new',
    };
  }

  /// Whether anything may be noticed from [question]. A question about
  /// health, medicines, drinking, drugs, safety, a crisis, support or a
  /// person under 18, and a question carrying a link, e-mail address or long
  /// number, teaches Hadi nothing. "When in doubt, keep nothing."
  static bool mayLearnFrom(String question) {
    final String q = question.trim();
    if (q.length < 4 || q.length > 400) return false;
    if (!HadiReportPolicy.mayInclude(q)) return false;
    if (!UserMemory.mayRemember(q)) return false;
    if (RegExp(r'https?://|www\.|@[a-z0-9.-]+\.[a-z]{2,}', caseSensitive: false)
        .hasMatch(q)) {
      return false;
    }
    if (RegExp(r'\d{7,}').hasMatch(q.replaceAll(RegExp(r'[\s-]'), ''))) {
      return false;
    }
    return true;
  }

  static String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Drops subjects not seen for [forgetAfterDays] and keeps the strongest
  /// [maxTopics].
  static UserKnows tidy(UserKnows k, DateTime now) {
    final Map<String, KnownTopic> kept = <String, KnownTopic>{};
    for (final MapEntry<String, KnownTopic> e in k.topics.entries) {
      final DateTime? d = DateTime.tryParse(e.value.last);
      if (d != null && now.difference(d).inDays > forgetAfterDays) continue;
      kept[e.key] = e.value;
    }
    final List<MapEntry<String, KnownTopic>> sorted = kept.entries.toList()
      ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
          b.value.count.compareTo(a.value.count));
    final Map<String, KnownTopic> keptCovered = <String, KnownTopic>{};
    for (final MapEntry<String, KnownTopic> e in k.covered.entries) {
      final DateTime? d = DateTime.tryParse(e.value.last);
      if (d != null && now.difference(d).inDays > forgetAfterDays) continue;
      keptCovered[e.key] = e.value;
    }
    final List<MapEntry<String, KnownTopic>> newest = keptCovered.entries.toList()
      ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
          b.value.last.compareTo(a.value.last));
    return k.copyWith(
      topics: <String, KnownTopic>{
        for (final MapEntry<String, KnownTopic> e in sorted.take(maxTopics))
          e.key: e.value,
      },
      covered: <String, KnownTopic>{
        for (final MapEntry<String, KnownTopic> e in newest.take(maxCovered))
          e.key: e.value,
      },
    );
  }

  /// What [k] becomes after the person asks [question]. Unchanged when
  /// nothing may be noticed.
  static UserKnows learn(UserKnows k, String question, DateTime now,
      {String? answerId}) {
    if (!mayLearnFrom(question)) return k;
    final String? topic = topicOf(question);
    final Set<String> roles = rolesOf(question);
    final String? id =
        answerId != null && idRe.hasMatch(answerId) ? answerId : null;
    if (topic == null && roles.isEmpty && id == null) return k;
    final String today = day(now);
    final Map<String, KnownTopic> topics = <String, KnownTopic>{...k.topics};
    if (topic != null) {
      final KnownTopic? old = topics[topic];
      topics[topic] = KnownTopic(
        count: cap((old?.count ?? 0) + 1),
        last: today,
      );
    }
    final Map<String, KnownTopic> covered = <String, KnownTopic>{...k.covered};
    if (id != null) {
      final KnownTopic? old = covered[id];
      covered[id] = KnownTopic(count: cap((old?.count ?? 0) + 1), last: today);
    }
    return tidy(
      k.copyWith(
        topics: topics,
        roles: <String>{...k.roles, ...roles},
        asked: k.asked + 1,
        since: k.since.isEmpty ? today : k.since,
        covered: covered,
      ),
      now,
    );
  }

  /// Two copies of the same person's notes (this device and their account)
  /// become one: the larger count and the later day win, so neither copy
  /// can erase the other's progress.
  static UserKnows merge(UserKnows a, UserKnows b, DateTime now) {
    final Map<String, KnownTopic> topics = <String, KnownTopic>{...a.topics};
    for (final MapEntry<String, KnownTopic> e in b.topics.entries) {
      final KnownTopic? o = topics[e.key];
      topics[e.key] = o == null
          ? e.value
          : KnownTopic(
              count: o.count > e.value.count ? o.count : e.value.count,
              last: o.last.compareTo(e.value.last) >= 0 ? o.last : e.value.last,
            );
    }
    final String since = a.since.isEmpty
        ? b.since
        : (b.since.isEmpty || a.since.compareTo(b.since) <= 0 ? a.since : b.since);
    final Map<String, KnownTopic> covered = <String, KnownTopic>{...a.covered};
    for (final MapEntry<String, KnownTopic> e in b.covered.entries) {
      final KnownTopic? o = covered[e.key];
      covered[e.key] = o == null
          ? e.value
          : KnownTopic(
              count: o.count > e.value.count ? o.count : e.value.count,
              last: o.last.compareTo(e.value.last) >= 0 ? o.last : e.value.last,
            );
    }
    return tidy(
      UserKnows(
        topics: topics,
        roles: <String>{...a.roles, ...b.roles},
        asked: a.asked > b.asked ? a.asked : b.asked,
        since: since,
        covered: covered,
      ),
      now,
    );
  }

  /// Plain lines for the "What Hadi has noticed" screen and for the chat
  /// command, strongest subject first.
  static List<String> describe(UserKnows k) {
    final List<MapEntry<String, KnownTopic>> sorted = k.topics.entries.toList()
      ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
          b.value.count.compareTo(a.value.count));
    return <String>[
      for (final String r in k.roles) roleLabels[r]!,
      for (final MapEntry<String, KnownTopic> e in sorted)
        'You often ask about: ${labels[e.key]}',
    ];
  }

  /// [items] with the ones that match the person's subjects moved up, at most
  /// [lift] of them, ahead of the rest; every other item keeps its order and
  /// place. Never removes anything, so the support chips stay where they are.
  static List<T> rank<T>(
    List<T> items,
    UserKnows k,
    String Function(T) question, {
    int lift = 2,
    int window = 5,
  }) {
    if (k.topics.isEmpty || items.length <= window) return items;
    final List<String> wanted = (k.topics.entries.toList()
          ..sort((MapEntry<String, KnownTopic> a, MapEntry<String, KnownTopic> b) =>
              b.value.count.compareTo(a.value.count)))
        .map((MapEntry<String, KnownTopic> e) => e.key)
        .toList();
    final List<T> front = <T>[];
    for (final String topic in wanted) {
      for (int i = window; i < items.length; i++) {
        final T item = items[i];
        if (front.contains(item)) continue;
        if (topicOf(question(item)) == topic) {
          front.add(item);
          break;
        }
      }
      if (front.length >= lift) break;
    }
    if (front.isEmpty) return items;
    // The lifted chips take the last places inside the opening window, so the
    // first (the du'a and company chips people already rely on) stay put.
    final List<T> head = items.take(window - front.length).toList();
    final List<T> rest = <T>[
      for (final T i in items.skip(window - front.length))
        if (!front.contains(i)) i,
    ];
    return <T>[...head, ...front, ...rest];
  }
}
