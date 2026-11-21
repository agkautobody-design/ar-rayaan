import '../data/hadi_core.dart';
import '../data/user_knows.dart';
import 'hadi_provider.dart';

/// Hādi's friendly voice for the built-in answers.
///
/// The answers themselves are checked text and are never changed. This adds,
/// around one of them, a short human opening that fits the kind of question
/// (and says the person's own subject back where that reads naturally), and
/// sometimes a short invitation to go on. It works offline, is deterministic
/// for a given conversation (so tests are stable), and is built not to repeat
/// itself: an opening already used in the last few replies is not used again,
/// roughly one answer in four gets no opening at all, and short follow-ups are
/// answered straight.
///
/// It also uses what Hādi has come to know about the person ([UserKnows]):
/// "we went over this before", a gentler pace for someone new to Islam, and a
/// word about a subject they keep coming back to. Nothing from a sensitive
/// subject is dressed at all: a question about death, grief, illness, hell,
/// divorce, abuse or fear gets the plain answer and nothing else.
abstract final class HadiVoice {
  static final RegExp _grave = RegExp(
    r'\b(?:death|dying|dead|die|grave|janazah|funeral|munkar|nakir|dajjal|'
    r'hell|hellfire|punish\w*|torment|divorce|abuse\w*|suicid\w*|miscarr\w*|'
    r'stillborn|illness|sick|cancer|depress\w*|grief|grieving|anxi\w*|fear|'
    r'afraid|scared|lonely|hopeless|widow|bereave\w*|judgement|judgment|'
    r'zina|adultery|sin|sins|forgive\w*|repent\w*|tawbah)\b',
  );

  /// Openings by kind of question. `{a}` is an action phrase, `{s}` a subject.
  static const List<String> _howReflect = <String>[
    'Good question. Here is how to {a}.',
    'Let me walk you through how to {a}.',
    'Okay, how to {a}. Here it is.',
    'Happy to help. This is how to {a}.',
    'Sure. How to {a} comes down to this.',
  ];
  static const List<String> _whatReflect = <String>[
    'Here is what I know about {s}.',
    'Let me explain {s} the way I would to a friend.',
    'Good one. About {s}:',
    'Okay, {s}. Short version first, then the detail.',
    'I will keep {s} simple.',
  ];
  static const List<String> _how = <String>[
    'Good one to ask. Here is the way.',
    'Sure, let us go through it together.',
    'Okay, here is how it goes.',
    'Happy to. This is the usual way.',
    'Alright, step by step.',
    'Glad you asked. Here you go.',
    'Let me lay it out simply.',
    'Of course. Here is how it works.',
  ];
  static const List<String> _why = <String>[
    'Fair question. Here is the reason.',
    'Good to ask why, not just what.',
    'Here is the thinking behind it.',
    'Let me explain the reason.',
    'The reason is worth knowing. Here it is.',
    'I like that you asked why.',
  ];
  static const List<String> _ok = <String>[
    'Good thing to check before acting.',
    'Fair thing to ask. Here is where it stands.',
    'Let me tell you what is established.',
    'Worth asking. Here is what the sources say.',
    'Glad you asked rather than guessed.',
    'Here is what is known about it.',
  ];
  static const List<String> _what = <String>[
    'Here is what I know.',
    'Let me put it simply.',
    'Short version first, then the detail.',
    'Good one. Here you go.',
    'Let me explain it the way I would to a friend.',
    'Here is the plain explanation.',
  ];
  static const List<String> _virtue = <String>[
    'Lovely thing to ask about.',
    'A good one to know. Here it is.',
    'Here is what has come to us about it.',
    'This one is encouraging. Here it is.',
    'Worth knowing. Here is what is reported.',
  ];
  static const List<String> _other = <String>[
    'Here is what I have on that.',
    'Sure. Here you go.',
    'Good question. Here is the answer.',
    'Happy to help with that.',
    'Let me share what I know.',
  ];

  static const List<String> _again = <String>[
    'We went over this before, so here it is again in full.',
    'You asked me this earlier. No problem, here it is again.',
    'This one came up between us before. Here it is once more.',
    'We have been through this one. A second look never hurts.',
  ];
  static const List<String> _againToday = <String>[
    'Here it is again, in case it helps.',
    'Same answer as a moment ago, in full.',
  ];
  static const List<String> _newcomer = <String>[
    'No rush with this. One step at a time is fine.',
    'You do not have to get all of it right today.',
    'Take this at your own pace.',
  ];
  static const List<String> _habit = <String>[
    'This is a subject you keep coming back to, and I like that.',
    'You come back to this subject often. Here is more.',
    'This one is clearly on your mind. Here you go.',
  ];

  static const List<String> _closers = <String>[
    'If one part is unclear, ask me about just that part.',
    'Which part would you like me to go deeper on?',
    'Tell me where you want more detail and I will go deeper.',
    'Ask me a follow-up if something did not sit right.',
    'Is there a part of this that is unclear? I can say it another way.',
    'If it is for a particular situation, tell me and I will point you to the right place.',
  ];

  static final List<String> _allOpeners = <String>[
    ..._how, ..._why, ..._ok, ..._what, ..._virtue, ..._other,
    ..._again, ..._againToday, ..._newcomer, ..._habit,
  ];

  static int _hash(String s) {
    int h = 0x811c9dc5;
    for (final int c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  /// "pray witr" → "pray witr"; "make my wudu" → "make your wudu"; null for
  /// anything with a first person in it, too long or odd to say back.
  static String? _sayBack(String phrase) {
    final String p = phrase.trim();
    if (p.isEmpty || p.length > 40) return null;
    final List<String> words = p.split(' ');
    if (words.length > 5) return null;
    if (RegExp(r'\d').hasMatch(p)) return null;
    final List<String> out = <String>[];
    for (final String w in words) {
      if (<String>{'i', 'me', 'am', 'we', 'us', 'our', 'im', 'mine'}.contains(w)) {
        return null;
      }
      if (<String>{'it', 'this', 'that', 'them', 'there', 'here'}.contains(w) &&
          words.length < 3) {
        return null;
      }
      out.add(w == 'my' ? 'your' : w);
    }
    return out.join(' ');
  }

  static String _kind(String c) {
    if (RegExp(r'^why\b').hasMatch(c)) return 'why';
    if (RegExp(r'^(?:is|are|was|can|could|may|am|do|does|should|must|will)\b').hasMatch(c) ||
        RegExp(r'\b(?:allowed|permissible|haram|halal|forbidden|permitted)\b').hasMatch(c)) {
      return 'ok';
    }
    if (RegExp(r'\b(?:reward|virtue|virtues|benefit|benefits|merit|merits|excellence|blessing)\b').hasMatch(c)) {
      return 'virtue';
    }
    if (RegExp(r'^how\b').hasMatch(c)) return 'how';
    if (RegExp(r'^(?:what|whats|who|which|when|where|tell)\b').hasMatch(c)) return 'what';
    return 'other';
  }

  static bool _usedRecently(String line, List<HadiMessage> history) {
    int seen = 0;
    for (int i = history.length - 1; i >= 0 && seen < 6; i--) {
      final HadiMessage m = history[i];
      if (!m.fromHadi) continue;
      seen++;
      if (m.text.contains(line)) return true;
    }
    return false;
  }

  /// Picks from [pool] by [seed], skipping lines used in the last few replies.
  static String? _pick(List<String> pool, int seed, List<HadiMessage> history) {
    for (int i = 0; i < pool.length; i++) {
      final String line = pool[(seed + i) % pool.length];
      if (!line.contains('{') && !_usedRecently(line, history)) return line;
    }
    return null;
  }

  static bool _alreadyDressed(String answer) {
    final String head = answer.split('\n').first;
    for (final String o in _allOpeners) {
      if (head.startsWith(o)) return true;
    }
    return false;
  }

  /// [answer] (the entry's own text, tokens already removed) with a friendly
  /// opening and sometimes a closing line. Returns [answer] untouched when
  /// the topic is grave, the reply is not a single entry's, it is a short
  /// follow-up, or it has been dressed already.
  static String dress({
    required String question,
    required CoreEntry entry,
    required String answer,
    required List<HadiMessage> history,
    UserKnows knows = UserKnows.empty,
    DateTime? now,
  }) {
    if (answer.startsWith('**') || answer.length < 80) return answer;
    if (_alreadyDressed(answer)) return answer;
    if (HadiCore.bodyOf(answer).startsWith(HadiCore.bodyOf(entry.answer)) ==
        false) {
      return answer;
    }
    final String c = HadiCore.canon(question);
    if (c.isEmpty) return answer;
    if (_grave.hasMatch(c) || _grave.hasMatch(entry.id.replaceAll('-', ' '))) {
      return answer;
    }
    final bool shortFollowUp =
        c.split(' ').length <= 3 && history.any((HadiMessage m) => m.fromHadi);
    if (shortFollowUp) return answer;

    final int seed = _hash('$c|${history.length}|${entry.id}');
    final String today = UserKnowsRules.day(now ?? DateTime.now());
    final KnownTopic? seen = knows.covered[entry.id];
    String? opener;

    if (seen != null) {
      opener = _pick(seen.last == today ? _againToday : _again, seed, history);
    }
    if (opener == null && knows.roles.contains('new') && seed % 4 == 0) {
      opener = _pick(_newcomer, seed, history);
    }
    final String? subject = UserKnowsRules.topicOf(question);
    final KnownTopic? habit = subject == null ? null : knows.topics[subject];
    if (opener == null && habit != null && habit.count >= 4 && seed % 3 == 0) {
      opener = _pick(_habit, seed, history);
    }
    if (opener == null && seed % 4 != 1) {
      final String kind = _kind(c);
      final bool reflect = seed % 2 == 0;
      if (reflect && kind == 'how') {
        final RegExpMatch? m =
            RegExp(r'^how (?:do i|do you|can i|should i|to|does one) (.+)$').firstMatch(c);
        final String? a = m == null ? null : _sayBack(m.group(1)!);
        if (a != null) {
          final String line = _howReflect[seed % _howReflect.length].replaceAll('{a}', a);
          if (!_usedRecently(line, history)) opener = line;
        }
      } else if (reflect && kind != 'why') {
        final RegExpMatch? m = RegExp(r'^(?:what is|what are|whats|what does) (?:the )?(.+)$').firstMatch(c);
        final String? s = m == null ? null : _sayBack(m.group(1)!);
        if (s != null) {
          final String line = _whatReflect[seed % _whatReflect.length].replaceAll('{s}', s);
          if (!_usedRecently(line, history)) opener = line;
        }
      }
      opener ??= _pick(
        switch (kind) {
          'how' => _how,
          'why' => _why,
          'ok' => _ok,
          'virtue' => _virtue,
          'what' => _what,
          _ => _other,
        },
        seed ~/ 7,
        history,
      );
    }

    String closer = '';
    if (answer.length > 220 && (seed ~/ 11) % 3 == 0) {
      closer = _pick(_closers, seed ~/ 13, history) ?? '';
    }
    if (opener == null && closer.isEmpty) return answer;
    return <String>[
      if (opener != null) opener,
      answer,
      if (closer.isNotEmpty) closer,
    ].join('\n\n');
  }
}
