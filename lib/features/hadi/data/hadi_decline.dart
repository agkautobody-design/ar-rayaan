/// What Hādi says when it cannot answer. Never the same flat line for every
/// kind of question: a question about the weather is told plainly that it is
/// outside what Hādi does and where to look instead, a request to do harm is
/// refused as such, and a question about Islam that is not on the shelf is
/// told what Hādi can do next (reword it, search, ask a scholar).
///
/// Every reply here carries one of the markers `HadiRouting.isRefusal` looks
/// for, so the rest of the app treats it as a refusal (online mode, the
/// "closest in my library" line, the miss count).
///
/// Pure Dart (no Flutter).
library;

import '../../sakina/domain/crisis_detector.dart';

/// The kinds of question Hādi does not answer, each with its own reply.
enum _Kind {
  injection,
  harm,
  weather,
  clock,
  sports,
  politics,
  recipe,
  homework,
  joke,
  maths,
  translate,
  creative,
  knowledge,
  tech,
}

abstract final class HadiDecline {
  /// The words every out-of-scope reply contains (see `HadiRouting._markers`).
  static const String outOfScopeMarker = 'That is outside what I do';

  static final Map<_Kind, RegExp> _patterns = <_Kind, RegExp>{
    _Kind.injection: RegExp(
        r'\b(?:ignore|forget|disregard)\b.*\b(?:previous|prior|above|all|your)\b'
        r'.*\b(?:instructions?|rules?|prompt)\b|\bsystem prompt\b|\bjailbreak\b|'
        r'\bdeveloper mode\b|\bpretend (?:you are|to be|you re)\b|'
        r'\bact as (?:an? )?(?:different|unrestricted|dan)\b|\byou are now\b'),
    _Kind.harm: RegExp(
        r'\b(?:make|build|making|building|create|assemble)\b.*\b(?:bomb|bombs|'
        r'explosive|explosives|weapon|weapons|poison|gun|guns)\b|'
        r'\bhow (?:to|do i|can i) (?:kill|hurt|poison|stab|shoot|hack|steal from|'
        r'stalk|spy on)\b'),
    _Kind.weather: RegExp(
        r'\b(?:weather|forecast|temperature|rain|raining|snow|snowing|humid|'
        r'humidity|sunny|cloudy)\b'),
    _Kind.clock: RegExp(
        r'\bwhat (?:is |s )?(?:the )?(?:time|date|day)\b.*\b(?:now|today|right now)\b|'
        r'\bwhat time is it\b|\bwhat day is (?:it|today)\b|'
        r'\bwhat (?:is |s )?today s date\b|\bcurrent (?:time|date)\b'),
    _Kind.sports: RegExp(
        r'\b(?:football|soccer|world cup|premier league|champions league|nba|nfl|'
        r'basketball|baseball|cricket match|cricket score|ipl|match score|'
        r'who won|who will win|league table|transfer news|tennis|formula 1|f1)\b'),
    _Kind.politics: RegExp(
        r'\b(?:president|prime minister|election result|elections|senate|'
        r'congress|parliament|trump|biden|putin|modi|netanyahu|brexit|'
        r'republican|democrat)\b'),
    _Kind.recipe: RegExp(
        r'\b(?:recipe|recipes|how (?:do i|to) (?:cook|bake|make) (?:a |an |the |some )?'
        r'(?:biryani|pasta|cake|bread|pizza|curry|rice|soup|chicken|steak|burger))'
        r'|\bbiryani\b|\bwhat should i (?:cook|eat) (?:today|tonight|for)\b'),
    _Kind.homework: RegExp(
        r'\b(?:homework|essay|assignment|thesis|term paper|book report|'
        r'write (?:my|me|an?|the) (?:essay|report|paper|speech|cv|resume|cover letter|'
        r'email|code|program|script))\b'),
    _Kind.joke: RegExp(
        r'\b(?:jokes?|funny|make me laugh|riddle|riddles|knock knock|meme|memes)\b'),
    _Kind.maths: RegExp(
        r'(?:^|\s)\d+\s*(?:\+|-|\*|x|/|plus|minus|times|divided by)\s*\d+(?:\s|$|\?)|'
        r'\bsquare root\b|\bsolve (?:this|for)\b|\bcalculate\b.*\b(?:\d+)\b.*\b'
        r'(?:percent|%)\b|^(?:what is |whats )?\d+(?: \d+)+$'),
    _Kind.translate: RegExp(
        r'\btranslate\b.*\b(?:to|into|in)\b|\bhow do you say\b.*\bin '
        r'(?:french|spanish|german|italian|chinese|japanese|korean|hindi|russian|'
        r'portuguese|turkish|english)\b'),
    _Kind.creative: RegExp(
        r'\b(?:write|compose|sing|draw|paint)\b.*\b(?:poem|poetry|song|story|'
        r'lyrics|rap|haiku|picture|image|logo|essay)\b'),
    _Kind.knowledge: RegExp(
        r'\bcapital of\b|\bpopulation of\b|\bhow tall is\b|\bhow far is\b|'
        r'\bwho (?:invented|discovered|wrote the novel|directed|starred)\b|'
        r'\bstock (?:price|market)\b|\bbitcoin price\b|\bmovie\b|\bmovies\b|'
        r'\bnetflix\b|\bcelebrity\b|\bsong lyrics\b|\bvideo game walkthrough\b'),
    _Kind.tech: RegExp(
        r'\b(?:wifi password|fix my (?:phone|laptop|computer|wifi|printer)|'
        r'install (?:windows|linux)|python code|javascript code|html code|'
        r'excel formula|iphone vs android)\b'),
  };

  static const Map<_Kind, List<String>> _replies = <_Kind, List<String>>{
    _Kind.injection: <String>[
      'That is outside what I do, and I cannot set aside how I work. I am '
          'Hādi, the guide to Islam and this app, and I answer from the '
          'Qur’an and the Sunnah with sources. Ask me about worship, halal '
          'and haram, the Prophet’s life, family, or where something is in '
          'the app.',
    ],
    _Kind.harm: <String>[
      'That is outside what I do, and I will not help with anything that '
          'could hurt people. If you are in danger, or are thinking of '
          'harming someone or yourself, please contact your local emergency '
          'number or someone you trust now. If anger or pain is behind the '
          'question, I can share du’as and guidance for it: the Sakina '
          'screen is made for that.\n[GO:/sakina]',
    ],
    _Kind.weather: <String>[
      'That is outside what I do: I have no live weather. Your phone’s '
          'weather app will tell you. What I can show for your location is '
          'when each prayer begins today, on the Prayer Times screen.\n'
          '[GO:/prayer]',
      'That is outside what I do, and I cannot see a forecast. For the '
          'weather use your phone’s weather app. If you are planning your '
          'day around prayer, Prayer Times has today’s times.\n[GO:/prayer]',
    ],
    _Kind.clock: <String>[
      'That is outside what I do: I cannot see a clock or a calendar, so I '
          'would only be guessing the time. Your device shows it. For the '
          'Islamic date there is the Islamic Calendar, and for when each '
          'prayer begins today there is Prayer Times.\n[GO:/calendar]\n'
          '[GO:/prayer]',
    ],
    _Kind.sports: <String>[
      'That is outside what I do: I do not follow sports scores or news, so I '
          'cannot tell you who won. A sports app or a news site will be '
          'better. I am here for Islam and this app; try asking about prayer, '
          'fasting, the Qur’an or the Prophet’s life.',
    ],
    _Kind.politics: <String>[
      'That is outside what I do: I do not follow politics or who holds an '
          'office, and anything I said could be out of date, so I will not '
          'name anyone. For Islam’s guidance on justice, honesty and '
          'leadership I can help, and I can say what the Qur’an and Sunnah '
          'teach.',
    ],
    _Kind.recipe: <String>[
      'That is outside what I do: I do not have recipes. What I can do is '
          'tell you whether an ingredient is halal (try “is gelatin halal”) '
          'and how to eat with good manners. The Masajid and Halal screen '
          'lists halal places near you.\n[GO:/masajid]\n'
          '[GO:/huda/guide?id=huda-food]',
    ],
    _Kind.homework: <String>[
      'That is outside what I do: I will not write your homework or essay. '
          'If your topic is Islam, I can explain it from the Qur’an and the '
          'Sunnah with sources you can cite, and the Academy has the Seerah, '
          'Aqeedah and Hadith schools to study from.\n[GO:/academy]',
    ],
    _Kind.joke: <String>[
      'That is outside what I do: I do not tell jokes. If you would like '
          'something light and true, the Stories section has short stories '
          'from the Prophets and the Companions, and the Games are a good '
          'way to unwind.\n[GO:/stories]\n[GO:/games]',
    ],
    _Kind.maths: <String>[
      'That is outside what I do: I am not a calculator, and I would not want '
          'to give you a wrong number. Your phone’s calculator will do it. If '
          'the sum is for zakat, the Zakat calculator in the app does the '
          'arithmetic.\n[GO:/zakat]',
    ],
    _Kind.translate: <String>[
      'That is outside what I do: I do not translate between languages. For '
          'the meaning of a Qur’an verse, the Qur’an screen shows an English '
          'translation under the Arabic. For the Arabic of the Qur’an, the '
          'Quranic Arabic school teaches the words.\n[GO:/quran]\n'
          '[GO:/academy/quranic-arabic]',
    ],
    _Kind.creative: <String>[
      'That is outside what I do: I do not write poems, songs or stories of '
          'my own. The Stories section has true stories from the Prophets, '
          'and the Qur’an screen has the finest words there are.\n'
          '[GO:/stories]\n[GO:/quran]',
    ],
    _Kind.knowledge: <String>[
      'That is outside what I do: general knowledge, entertainment and '
          'prices are not on my shelf, and I would not be a reliable source. '
          'I answer about Islam: worship, the Qur’an and the Sunnah, halal '
          'and haram, family, belief and history, and where things are in '
          'this app.',
    ],
    _Kind.tech: <String>[
      'That is outside what I do: I cannot help with phones, computers or '
          'code. If something in this app is not working, tell me which '
          'screen and what you see, and I will point you to the right place '
          'in Settings or Downloads.\n[GO:/settings]',
    ],
  };

  /// Variants for a question about Islam or the app that is simply not on the
  /// shelf. Each keeps the words "rather not guess", which the rest of the app
  /// and its tests recognise.
  static const List<String> _unknown = <String>[
    'I don’t have a checked answer for that, and I would rather not guess. '
        'I answer questions on worship, the Qur’an, the Sunnah, du’as, halal '
        'and haram, family, belief and history, and where things are in this '
        'app. Try it in a few plain words (for example “zakat on gold”), or '
        'use Find Anything to search every story, guide and du’a. For a '
        'ruling on your own situation a qualified scholar is the right '
        'person.',
    'I could not find a checked answer to that, so I would rather not guess '
        'and risk telling you something wrong. If you tell me the topic in a '
        'word or two (“wudu”, “inheritance”, “Hajj”), I can often do better. '
        'Find Anything searches the whole app, and Our Sources lists a '
        'qualified scholar for anything I cannot answer.',
    'This one is not on my shelf yet, and I would rather not guess about '
        'religion. What helps: ask about one thing at a time, name the act or '
        'the person, or open Find Anything to look through every guide and '
        'story. If it is about your own case, please take it to a scholar.',
  ];

  /// The out-of-scope reply for [question], or null when it is a question
  /// about Islam or the app. [round] is how many unanswered questions came
  /// just before (so a repeat gets another wording). [islamic] is true when
  /// the question names something Islamic.
  static String? outOfScope(
    String question, {
    int round = 0,
    bool islamic = false,
  }) {
    final String n = CrisisDetector.normalize(question);
    if (n.isEmpty) return null;
    for (final _Kind k in _Kind.values) {
      // A question that names something Islamic ("a du'a for rain") is never
      // called outside what Hādi does, except to refuse harm.
      if (islamic && k != _Kind.harm && k != _Kind.injection) continue;
      if (_patterns[k]!.hasMatch(n)) {
        final List<String> pool = _replies[k]!;
        return pool[round % pool.length];
      }
    }
    return null;
  }

  /// The reply for a question about Islam or the app that has no answer.
  static String unknown(String question, {int round = 0}) {
    final int pick =
        question.codeUnits.fold<int>(0, (int a, int b) => a + b) + round;
    return _unknown[pick % _unknown.length];
  }

  /// The reply for something plainly outside Islam and the app that no more
  /// specific reply covers.
  static String general() => _replies[_Kind.knowledge]!.first;

  /// True when [text] is one of the replies above.
  static bool isDecline(String text) =>
      text.contains(outOfScopeMarker) ||
      _unknown.any((String u) => text.contains(u)) ||
      _replies.values.any(
          (List<String> l) => l.any((String r) => text.contains(r.split('\n').first)));

  /// Every fixed reply, for the tests that check them all.
  static List<String> get all => <String>[
        ..._unknown,
        for (final List<String> l in _replies.values) ...l,
      ];
}
