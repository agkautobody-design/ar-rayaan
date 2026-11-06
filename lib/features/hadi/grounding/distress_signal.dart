/// Tells a HEAVY HEART from a QUESTION.
///
/// "What is the dua for anxiety?" is a question, and the library answers it.
/// "I feel anxious and heavy most days and I am tired of carrying it alone"
/// is a person, and the answer to a person is listening first. This reads a
/// message on the device, with plain word and phrase lists, and says which
/// support pack should answer: grief, shame and despair, or the general
/// being-heard pack for sadness, anxiety, loneliness, overwhelm, comparison
/// and feeling far from Allah.
///
/// It runs only after the crisis layer, the safe-reply layer and
/// [SupportSignal] have all said "not mine", and it stays quiet for anything
/// that is really a question (a ruling, a diagnosis, a fact, or anything
/// asked with a "?"). It never stores anything and never calls a service: it
/// only decides where the message goes.
///
/// CLINICIAN REVIEW NEEDED: the lists are English, written for coverage. A
/// clinician and a native speaker of each language must read them
/// (docs/SCHOLAR_REVIEW_REGISTER.md).
library;

import '../../sakina/domain/crisis_detector.dart';
import '../../support/domain/emotion_intent.dart';

abstract final class DistressSignal {
  /// The speaker, first person only: the message must be about the person
  /// themselves, not a general topic. "i", "me", "feel", "cant" and a few
  /// Roman Urdu words, matching the house lists in [SupportSignal]. "feels"
  /// is left out on purpose: "my friend feels lonely" is about someone else.
  static const Set<String> _firstPerson = <String>{
    'i', 'im', 'ive', 'me', 'myself', 'am', 'feel', 'feeling', 'felt',
    'cant', 'cannot', 'main', 'mujhe',
  };

  /// "my" counts as the speaker too, unless it only belongs to a relation
  /// ("my husband is…" is about him; "my chest feels tight" is about me).
  static const Set<String> _possessive = <String>{'my', 'mera', 'meri'};

  static const Set<String> _relation = <String>{
    'husband', 'wife', 'son', 'daughter', 'brother', 'sister', 'father',
    'dad', 'mum', 'mom', 'mother', 'friend', 'cousin', 'uncle', 'parents',
    'partner', 'fiance',
  };

  /// A death: grief is answered by the grief pack, never the general one.
  static const List<String> _griefPhrases = <String>[
    'died', 'death of', 'passed away', 'passed on', 'funeral', 'janaza',
    'janazah', 'buried', 'burial', 'grave', 'widowed', 'miscarriage',
    'miscarried', 'stillborn', 'lost the baby', 'lost our baby',
    'lost someone', 'lost a baby', 'lost my baby', 'inna lillah',
    'martyred', 'posthumous',
  ];

  /// "lost my mother" is grief; "lost my job" is not. A relation word makes
  /// the difference.
  static const Set<String> _lostRelation = <String>{
    'mother', 'father', 'mum', 'mom', 'dad', 'husband', 'wife', 'son',
    'daughter', 'brother', 'sister', 'grandmother', 'grandfather', 'grandma',
    'grandpa', 'uncle', 'aunt', 'aunty', 'friend', 'baby', 'child',
    'parents', 'cousin', 'nephew', 'niece', 'nan', 'nana', 'dada', 'dadi',
    'nani', 'abu', 'abba', 'ammi', 'appa', 'baba', 'bhai', 'behen',
  };

  /// Sadness and heaviness.
  static const List<String> _sadness = <String>[
    'sad', 'sadness', 'unhappy', 'miserable', 'depressed', 'depressing',
    'depression', 'feel low', 'feeling low', 'feeling down', 'felt down',
    'empty', 'emptiness', 'numb', 'crying', 'cried', 'tears', 'weeping',
    'heartbroken', 'broken heart', 'heavy heart', 'heart is heavy',
    'heart hurts', 'hurting me', 'it hurts', 'hurt inside', 'cry myself',
    'want to cry', 'feel like crying', 'gloomy', 'down bad', 'not okay',
    'not ok', 'broken inside', 'so heavy', 'feels heavy', 'feel heavy',
    'feeling heavy', 'very heavy', 'lost my job', 'lost my home',
    'lost everything',
  ];

  /// Anxiety, stress, overwhelm.
  static const List<String> _anxiety = <String>[
    'anxious', 'anxiety', 'panic', 'panicking', 'overwhelmed',
    'overwhelming', 'stressed', 'stressful', 'on edge', 'cant breathe',
    'cannot breathe', 'racing thoughts', 'mind is racing', 'mind keeps',
    'overthinking', 'overthink', 'restless', 'tense', 'worried sick',
    'worrying', 'constant worry', 'cant switch off', 'cant relax',
    'cannot relax', 'too much pressure',
  ];

  /// Loneliness and being unseen.
  static const List<String> _lonely = <String>[
    'lonely', 'loneliness', 'all alone', 'no friends', 'nobody cares',
    'no one cares', 'no one to talk to', 'nobody to talk to', 'no one to turn to',
    'invisible', 'left out', 'isolated', 'no one understands',
    'nobody understands', 'no one listens', 'nobody listens', 'no one asks',
    'by myself', 'on my own with',
  ];

  /// Feeling far from Allah, or numb in worship.
  static const List<String> _farFromAllah = <String>[
    'far from allah', 'far from god', 'distant from allah',
    'disconnected from allah', 'away from allah', 'far from my faith',
    'far from islam', 'far from the deen', 'left the deen',
    'lost my iman', 'iman is low', 'low iman', 'no iman', 'iman feels',
    'stopped praying', 'left my prayers', 'cant pray', 'cannot pray',
    'missed my prayers', 'keep missing prayers', 'feel nothing when i pray',
    'empty in salah', 'empty in prayer', 'no khushu', 'khushu',
    'ashamed to come back', 'ashamed to return', 'do not feel close to allah',
    'dont feel close to allah', 'feel far from', 'drifting from allah',
  ];

  /// Exhaustion and burnout.
  static const List<String> _exhaustion = <String>[
    'exhausted', 'exhaustion', 'burnt out', 'burned out', 'burnout',
    'worn out', 'drained', 'no energy', 'cant cope', 'cannot cope',
    'falling apart', 'tired of everything', 'tired of it all',
    'tired of carrying', 'cant do this anymore', 'cannot do this anymore',
    'at my limit', 'breaking point', 'running on empty', 'running on fumes',
    'too much for me', 'so tired of',
  ];

  /// Comparison, social-media pressure, feeling behind.
  static const List<String> _comparison = <String>[
    'everyone else is', 'everyone is better', 'everyone else has',
    'comparing myself', 'compare myself', 'behind in life', 'behind everyone',
    'not good enough', 'never good enough', 'social media makes me',
    'instagram makes me', 'tiktok makes me', 'feel like a failure',
    'feel like a loser', 'worthless', 'useless', 'nobody would miss me',
    'feel invisible',
  ];

  /// Wanting to be heard, not fixed.
  static const List<String> _heard = <String>[
    'just need to be heard', 'need someone to listen', 'need to vent',
    'want to vent', 'just listen', 'hear me out', 'someone to hear me',
    'need to talk', 'get this off my chest', 'say it out loud',
    'no advice', 'dont want advice', 'do not want advice',
    'not looking for advice', 'will not judge', 'without judging',
    'wont judge', 'just hear me', 'hear how i feel',
    'listen to me', 'need someone to hear',
  ];

  /// Hurt at home that is not an abuse disclosure (the crisis layer reads
  /// those first and this never runs).
  static const List<String> _home = <String>[
    'things at home', 'problems at home', 'family problems', 'family issues',
    'my family is', 'home is hard', 'hard at home', 'fighting at home',
    'my parents fight', 'my marriage is hurting', 'marriage problems',
  ];

  /// True when the message asks for a piece of content (a dua, a verse, a
  /// hadith) rather than a listening ear. The checked shelf answers those.
  static bool asksForContent(String text) {
    final String padded = ' ${CrisisDetector.normalize(text)} ';
    for (final String w in const <String>[
      ' dua ', ' duas ', ' verse ', ' verses ', ' ayah ', ' ayat ',
      ' surah ', ' hadith ',
    ]) {
      if (padded.contains(w)) return true;
    }
    return false;
  }

  /// The pain the message carries, in words the reply can reflect back:
  /// 'sadness', 'anxiety', 'loneliness', 'far' (far from Allah),
  /// 'exhaustion', 'comparison', 'home', 'shame', 'despair', 'grief',
  /// 'heard' — or null when nothing specific is said. Used so that no
  /// reply, even the fixed fallback, is generic: it names what the person
  /// actually said.
  static String? themeFor(String text) {
    final String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return null;
    final String padded = ' $n ';
    final Set<String> words = n.split(' ').toSet();
    final EmotionIntent ei = EmotionIntentDetector.detect(text);
    if (_has(padded, _griefPhrases) ||
        (padded.contains('lost my') && words.any(_lostRelation.contains)) ||
        (padded.contains('lost our') && words.any(_lostRelation.contains))) {
      return 'grief';
    }
    if (ei.emotions.contains('shame')) return 'shame';
    if (ei.emotions.contains('despair')) return 'despair';
    if (_has(padded, _farFromAllah)) return 'far';
    if (_has(padded, _anxiety) || ei.emotions.contains('fear')) {
      return 'anxiety';
    }
    if (_has(padded, _lonely) || ei.emotions.contains('isolation')) {
      return 'loneliness';
    }
    if (_has(padded, _comparison)) return 'comparison';
    if (_has(padded, _exhaustion) || ei.emotions.contains('exhaustion')) {
      return 'exhaustion';
    }
    if (_has(padded, _home)) return 'home';
    if (_has(padded, _sadness)) return 'sadness';
    return null;
  }

  static bool _has(String padded, List<String> phrases) {
    for (final String k in phrases) {
      if (k.contains(' ')) {
        if (padded.contains(k)) return true;
      } else if (padded.contains(' $k ')) {
        return true;
      }
    }
    return false;
  }

  /// The pack that should answer [text], or null when this is not a person
  /// carrying something heavy. `grief_loss` for a death, `shame_despair`
  /// when the words carry shame or despair, otherwise `being_heard`.
  static String? packFor(String text) {
    final String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return null;
    final EmotionIntent ei = EmotionIntentDetector.detect(text);

    // A question stays a question: rulings go to the scholar hand-off,
    // medical questions to the medical hand-off, facts to the library, and
    // "are you human" to the about-Hadi reply. A first message that asks
    // what to do ("I missed my prayers for years, what do I do?") keeps its
    // ruling hand-off too; inside a conversation, asking for a step is the
    // engine's plan-step turn, handled by the continuation, not here.
    const Set<SupportIntent> skip = <SupportIntent>{
      SupportIntent.askInfo,
      SupportIntent.askRuling,
      SupportIntent.askMedical,
      SupportIntent.onlyFriend,
      SupportIntent.askAboutAi,
      SupportIntent.wantsStep,
    };
    if (skip.contains(ei.intent)) return null;
    // A direct ask for content ("a dua for my mother") is for the checked
    // shelf, which can give the actual words; a listening pack cannot.
    if (asksForContent(text)) return null;

    final List<String> tokens = n.split(' ');
    final Set<String> words = tokens.toSet();
    final String padded = ' $n ';

    // The message must be about the speaker, or carry one of the feelings
    // that are almost always first-person ("i hate myself", "hopeless",
    // "died" beside "my mother").
    final bool self = words.any(_firstPerson.contains) ||
        (words.any(_possessive.contains) && !words.any(_relation.contains)) ||
        ei.emotions.any((String e) => const <String>{
              'shame', 'despair', 'guilt', 'isolation', 'grief', 'exhaustion',
            }.contains(e));
    if (!self) return null;

    // Grief first: a death is answered by the grief pack.
    if (_has(padded, _griefPhrases) ||
        (padded.contains('lost my') && words.any(_lostRelation.contains)) ||
        (padded.contains('lost our') && words.any(_lostRelation.contains))) {
      return 'grief_loss';
    }

    // Shame and despair already have a pack; the words alone carry them.
    if (ei.emotions.contains('shame') || ei.emotions.contains('despair')) {
      return 'shame_despair';
    }

    if (_has(padded, _sadness) ||
        _has(padded, _anxiety) ||
        _has(padded, _lonely) ||
        _has(padded, _farFromAllah) ||
        _has(padded, _exhaustion) ||
        _has(padded, _comparison) ||
        _has(padded, _heard) ||
        _has(padded, _home) ||
        ei.emotions.contains('fear') ||
        ei.emotions.contains('isolation')) {
      return 'being_heard';
    }
    return null;
  }
}
