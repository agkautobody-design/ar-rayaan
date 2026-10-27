/// Tells a PERSON from a QUESTION.
///
/// "Is alcohol haram?" is a question about the rule, and the library answers
/// it. "I drank again last night and I cannot stop" is a person, and the
/// answer to a person is not a ruling card. This reads a message on the
/// device, with plain word lists, and says whether it is a disclosure, a
/// craving, a relapse or a plea about alcohol, drugs, gambling, pornography,
/// smoking and vaping, or about someone close who is struggling with them.
///
/// It never stores anything, never calls a service, and it only decides where
/// the message goes: to a listening reply (see [SupportReplies]) instead of
/// the ruling shelf.
///
/// CLINICIAN REVIEW NEEDED: the word lists are English, with a few Roman
/// Urdu words, written for coverage. A clinician and a native speaker of each
/// language must read them (docs/SCHOLAR_REVIEW_REGISTER.md).
library;

import '../../sakina/domain/crisis_detector.dart';
import '../../sakina/domain/sakina_content.dart';

/// What the person is talking about.
enum SupportTopic {
  alcohol,
  drugs,
  gambling,
  porn,
  smoking,

  /// A relapse or an addiction with no named substance.
  general,

  /// Someone close to the person is struggling.
  family,
}

abstract final class SupportSignal {
  static const Set<String> _alcoholStrong = <String>{
    'alcohol', 'alcoholic', 'alcoholism', 'beer', 'wine', 'whisky', 'whiskey',
    'vodka', 'liquor', 'booze', 'hangover', 'khamr', 'sharab', 'sharaab',
    'shraab', 'daru', 'peene', 'peena',
  };

  /// Words that mean alcohol only with a cue beside them: "drink water" is
  /// not about alcohol.
  static const Set<String> _alcoholDrink = <String>{
    'drink', 'drinks', 'drinking', 'drank', 'drunk',
  };

  static const Set<String> _drugs = <String>{
    'drugs', 'drug', 'weed', 'cannabis', 'marijuana', 'hash', 'hashish',
    'cocaine', 'heroin', 'meth', 'methamphetamine', 'xanax', 'valium',
    'ecstasy', 'mdma', 'opioid', 'opioids', 'tramadol', 'captagon', 'lsd',
    'ketamine', 'fentanyl', 'crack', 'methadone', 'suboxone', 'benzos',
    'narcotics',
  };

  static const Set<String> _gambling = <String>{
    'gambling', 'gamble', 'gambled', 'gambles', 'gambler', 'betting', 'bets',
    'casino', 'lottery', 'poker', 'slots', 'bookie', 'wager', 'wagering',
  };

  static const Set<String> _porn = <String>{
    'porn', 'pornography', 'pornographic', 'masturbation', 'masturbating',
    'masturbate',
  };

  static const Set<String> _smoking = <String>{
    'vape', 'vapes', 'vaping', 'smoke', 'smoking', 'smoked', 'smokes',
    'cigarette', 'cigarettes', 'nicotine', 'shisha', 'hookah', 'tobacco',
    'cigar', 'cigars',
  };

  /// Words that, alone, say the person is talking about dependence.
  static const Set<String> _strong = <String>{
    'relapse', 'relapsed', 'relapsing', 'addicted', 'addiction', 'addict',
    'sober', 'sobriety',
  };

  /// Words that turn a topic word into a disclosure.
  static const Set<String> _personalCue = <String>{
    'want', 'wanna', 'need', 'cant', 'cannot', 'stop', 'stopped', 'quit',
    'quitting', 'again', 'lost', 'tried', 'trying', 'struggle', 'struggling',
    'ashamed', 'shame', 'hide', 'hiding', 'secret', 'tonight', 'keep',
    'keeps', 'always', 'daily', 'craving', 'cravings', 'crave', 'slipped',
    'hooked', 'took', 'smoked', 'drank', 'gambled', 'used', 'using', 'tempted',
    'urge', 'urges', 'debt', 'worried', 'help', 'dil', 'mann', 'karta',
    'karti', 'piya', 'chorna', 'chhorna',
  };

  /// The speaker: "I", "me", "myself".
  static const Set<String> _speaker = <String>{
    'i', 'im', 'ive', 'me', 'myself', 'main', 'mujhe',
  };

  /// "my" alone also counts as the speaker, unless it only belongs to a
  /// relation ("my husband").
  static const Set<String> _possessive = <String>{'my', 'mera', 'meri'};

  /// Verbs that say the speaker did it themselves.
  static const Set<String> _selfVerb = <String>{
    'relapsed', 'relapse', 'drank', 'gambled', 'smoked', 'slipped',
    'craving', 'cravings', 'crave',
  };

  static const Set<String> _relation = <String>{
    'husband', 'wife', 'son', 'daughter', 'brother', 'sister', 'father',
    'dad', 'mum', 'mom', 'mother', 'friend', 'cousin', 'uncle', 'parents',
    'partner', 'fiance',
  };

  /// A drink that is not alcohol, removed before reading.
  static final RegExp _innocentDrink = RegExp(
    r'\b(?:drink|drinks|drinking|drank|drunk)\s+(?:some\s+|a\s+glass\s+of\s+|'
    r'more\s+|enough\s+|plenty\s+of\s+)?(?:water|tea|coffee|milk|juice|zamzam|'
    r'soda|cola|smoothie|shake|chai|lassi|broth|soup)\b',
  );

  /// The topic of [text] when it is a person speaking (or a person writing
  /// about someone close), or null when it is a question about a rule, or
  /// nothing to do with the subject.
  static SupportTopic? classify(String text) {
    String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return null;
    n = n.replaceAll(_innocentDrink, ' ');
    final List<String> tokens = n.split(' ');
    final Set<String> words = tokens.toSet();

    bool any(Set<String> list) => words.any(list.contains);

    final bool strong = any(_strong);
    final bool cue = any(_personalCue);
    final bool relation = any(_relation);
    final bool selfFirst =
        any(_speaker) || (any(_possessive) && !relation);

    SupportTopic? topic;
    if (any(_alcoholStrong) || (any(_alcoholDrink) && (cue || strong))) {
      topic = SupportTopic.alcohol;
    } else if (any(_drugs)) {
      topic = SupportTopic.drugs;
    } else if (any(_gambling)) {
      topic = SupportTopic.gambling;
    } else if (any(_porn)) {
      topic = SupportTopic.porn;
    } else if (any(_smoking)) {
      topic = SupportTopic.smoking;
    }
    if (topic == null && !strong) return null;

    // "My husband gambles away our money", "my brother is an addict": the
    // person is writing about someone else unless they also say they did it.
    if (relation && !any(_selfVerb)) {
      if (strong || _familyVerb(words)) return SupportTopic.family;
      return topic != null && cue ? SupportTopic.family : null;
    }
    if (strong || (topic != null && selfFirst && cue)) {
      return topic ?? SupportTopic.general;
    }
    return null;
  }

  /// A word that says the other person does it ("gambles", "drinks").
  static bool _familyVerb(Set<String> words) =>
      words.contains('gambles') ||
      words.contains('drinks') ||
      words.contains('smokes') ||
      words.contains('vapes') ||
      words.contains('high') ||
      words.contains('drunk') ||
      words.contains('using') ||
      words.contains('addict') ||
      words.contains('addicted');

  /// True when the message also asks for a ruling or a verdict on the
  /// person's own case ("is it a sin to relapse"). The reply then says, kindly,
  /// that a scholar answers that and it is a separate question from support.
  static bool asksVerdict(String text) {
    final String n = ' ${CrisisDetector.normalize(text)} ';
    for (final String w in const <String>[
      ' haram ', ' halal ', ' sin ', ' sinful ', ' forgiven ', ' forgive ',
      ' allowed ', ' permissible ', ' punished ', ' accepted ', ' ruling ',
      ' fatwa ', ' valid ',
    ]) {
      if (n.contains(w)) return true;
    }
    return false;
  }
}

/// Listening replies for [SupportSignal] disclosures. Plain, warm, no
/// ruling, no label for the person, no dose, no plan to stop. Three
/// differently worded replies per topic, rotated, so a second message in the
/// same conversation never gets the same sentence back.
///
/// CLINICIAN REVIEW NEEDED and SCHOLAR REVIEW NEEDED: every reply here is
/// shown with both labels until named reviewers have signed it off.
abstract final class SupportReplies {
  /// How many different replies each topic has.
  static const int variantsPerTopic = 3;

  static const Map<SupportTopic, List<String>> _bodies =
      <SupportTopic, List<String>>{
    SupportTopic.alcohol: <String>[
      'Thank you for telling me. That took honesty, and I am not going to '
          'lecture you. It sounds like this is weighing on you. What would '
          'you like to be different?',
      'I am glad you said it out loud. A hard night does not wipe out the '
          'effort you have put in. Would you like to tell me what happened, '
          'or work out one small step for the next hour?',
      'I am still here, and you do not have to have it worked out. Is there '
          'one person you trust, or a doctor, who could know about this?',
    ],
    SupportTopic.drugs: <String>[
      'Thank you for trusting me with that. You are not in trouble here, and '
          'I am not going to lecture you. What is the hardest part of it '
          'right now?',
      'I hear you. Wanting things to be different is a real step, even on a '
          'bad day. Would you like to talk about what is happening tonight, '
          'or about who could be beside you?',
      'I am staying with you in this conversation. You do not have to '
          'decide everything now. Is there someone who could be with you, or '
          'a doctor you could call?',
    ],
    SupportTopic.gambling: <String>[
      'Thank you for saying it. Money and shame can pile up together, and '
          'carrying that alone is heavy. Do you feel safe right now, with '
          'the money and with yourself?',
      'That sounds painful, and it is not the end of the road. You do not '
          'have to solve the debt tonight. What feels most urgent to you '
          'right now?',
      'I am here, and I am not here to judge. One thing that helps many '
          'people is telling one safe person. Is there someone you could '
          'tell?',
    ],
    SupportTopic.porn: <String>[
      'Thank you for telling me. A lot of people carry this quietly, and '
          'carrying it does not make you a bad person. What would you like '
          'to be different?',
      'I hear you, and there is no need to go into detail with me. The '
          'urge tends to rise and then pass. Would it help to talk about '
          'what usually comes just before?',
      'I am here, and I am not shocked. Many people find it easier once '
          'one trusted person or a counsellor knows. Is there someone like '
          'that for you?',
    ],
    SupportTopic.smoking: <String>[
      'Wanting to quit is a good thing to bring here, and the fact that it '
          'is hard does not mean you are weak. What has helped you most in '
          'the past, even a little?',
      'Thank you for telling me. Many people try several times before it '
          'sticks, and each try teaches something. What is the hardest time '
          'of day for you?',
      'I am here. A doctor or a pharmacist can talk through ways of '
          'quitting that fit your life. Would you like to think about what '
          'to ask them?',
    ],
    SupportTopic.general: <String>[
      'Thank you for telling me. I am not going to lecture you. What '
          'happened, or what would help most right now?',
      'I hear you. Coming back after a slip is something that takes courage. '
          'What would you like to be different?',
      'I am still here. You do not have to explain everything. Is there '
          'someone you trust who could be with you tonight?',
    ],
    SupportTopic.family: <String>[
      'It is exhausting to love someone who is struggling, and your own '
          'tiredness counts too. What does a hard day look like for you?',
      'Thank you for telling me. You did not cause this and you cannot fix '
          'it for them, but you can look after yourself. What do you need '
          'most at the moment?',
      'I hear how much you care. Families often need support of their own, '
          'apart from the person who is struggling. Is there someone you can '
          'talk to?',
    ],
  };

  /// Said with the first reply, and every third reply after: stopping heavy
  /// use suddenly can be dangerous. Not a plan, not a dose.
  static const String safetyNote =
      'One safety note, because it matters: if you drink or use heavily most '
      'days, or take a medicine for a long time, please do not stop suddenly '
      'on your own. That can be dangerous, and a doctor can help you stop '
      'safely. If you have shaking, confusion, a seizure, or see things that '
      'are not there, call your local emergency number now.';

  /// Said when the person also asks for a verdict on their own case.
  static const String verdictNote =
      'You asked about a ruling. I do not give rulings on your own case, and '
      'it is a different question from getting support. A qualified scholar '
      'can answer it, and the support is yours either way.';

  /// The honest label under every support reply.
  static const String appNote =
      'I am an app, not a doctor or a counsellor, so I cannot call anyone for '
      'you. These people can do what I cannot:';

  /// The free, verified lines for [topic] in [countryCode], as plain text.
  /// Only rows that carry a verified-on date and a source. Gambling, porn and
  /// smoking get the worldwide directory only, because the country lines
  /// listed here are for alcohol and drugs.
  static String linesFor(SupportTopic topic, String? countryCode) {
    final List<HelpResource> rows = HelpResources.forCountry(
      countryCode,
      kinds: const <HelpKind>{HelpKind.addiction},
    );
    final bool substance = topic == SupportTopic.alcohol ||
        topic == SupportTopic.drugs ||
        topic == SupportTopic.general ||
        topic == SupportTopic.family;
    final StringBuffer b = StringBuffer();
    int n = 0;
    for (final HelpResource r in rows) {
      if (n >= 3) break;
      if (!r.verified) continue;
      if (!substance && r.countries.isNotEmpty) continue;
      b.writeln('• ${r.name} (${r.region}): ${r.contact}');
      n++;
    }
    return b.toString().trimRight();
  }

  /// The reply for [topic]. [prior] is how many support replies have already
  /// been given in this conversation (it picks the wording and decides
  /// whether the safety note is repeated).
  static String build({
    required SupportTopic topic,
    required int prior,
    String? countryCode,
    bool verdict = false,
  }) {
    final List<String> bodies = _bodies[topic]!;
    final StringBuffer b = StringBuffer(bodies[prior % bodies.length]);
    if (verdict) b.write('\n\n$verdictNote');
    final bool medical = topic == SupportTopic.alcohol ||
        topic == SupportTopic.drugs ||
        topic == SupportTopic.general;
    if (medical && prior % 3 == 0) b.write('\n\n$safetyNote');
    final String lines = linesFor(topic, countryCode);
    if (lines.isNotEmpty) b.write('\n\n$appNote\n$lines');
    return b.toString();
  }

  /// The reply for a person who has said they are under 18. No ruling, no
  /// secrecy, no "tell your parents" default.
  static String buildForMinor({required int prior}) {
    final List<String> bodies = <String>[
      'Thank you for telling me. You are not in trouble. I am an app, so I '
          'cannot keep you safe or call anyone for you, and I will not '
          'promise to keep a secret that could put you at risk. Please talk '
          'to ${CrisisResponses.trustedAdultChoices}. You choose who. The '
          'lines below are free to call or text.',
      'I am glad you said it. Whatever is going on, you deserve support and '
          'not a telling-off. You decide who to tell: '
          '${CrisisResponses.trustedAdultChoices}. If it is an emergency, '
          'call your local emergency number.',
      'You can always come back and say more. When you are ready, '
          '${CrisisResponses.trustedAdultChoices} can help in ways I '
          'cannot. The lines below are made for young people.',
    ];
    return bodies[prior % bodies.length];
  }
}
