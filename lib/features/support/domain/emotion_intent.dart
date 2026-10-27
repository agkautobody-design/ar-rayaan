import '../../sakina/domain/crisis_detector.dart';

/// What the person seems to be feeling, from their words only.
///
/// No face, no voice, no history, no profile. A plain word list that returns
/// tags the knowledge packs use. It is a hint for choosing wording, never a
/// label of the person and never stored. CLINICIAN REVIEW NEEDED for every
/// list (English only; other languages fall back to listening).
enum SupportIntent {
  /// Telling their story or how they feel.
  share,

  /// Asking for practical help or a next step.
  wantsStep,

  /// Asking a factual question about the topic.
  askInfo,

  /// Asking for a religious verdict on their own case.
  askRuling,

  /// Asking for a diagnosis, a dose or medical advice.
  askMedical,

  yes,
  no,
  thanks,
  goodbye,

  /// "Be my only friend", "you are better than my imam".
  onlyFriend,

  /// "Are you human?", "Do you love me?".
  askAboutAi,

  /// A short reply with no clear meaning ("ok", "hmm").
  unclear,
}

class EmotionIntent {
  const EmotionIntent({
    required this.intent,
    this.emotions = const <String>[],
    this.wordCount = 0,
  });

  final SupportIntent intent;

  /// Tags such as shame, despair, cravings, fear, guilt, isolation, anger.
  final List<String> emotions;
  final int wordCount;

  bool get distressed =>
      emotions.contains('despair') ||
      emotions.contains('shame') ||
      emotions.contains('fear') ||
      emotions.contains('isolation');
}

abstract final class EmotionIntentDetector {
  static const Map<String, List<String>> _emotion = <String, List<String>>{
    'shame': <String>[
      'ashamed', 'shame', 'disgusting', 'disgusted', 'hypocrite', 'filthy',
      'embarrassed', 'worthless', 'pathetic', 'ashamed of',
    ],
    'despair': <String>[
      'hopeless', 'no point', 'give up', 'cant go on', 'nothing helps',
      'no way out', 'pointless', 'beyond forgiveness', 'too late',
      'allah has left me', 'might as well',
    ],
    'cravings': <String>[
      'craving', 'cravings', 'urge', 'urges', 'want to drink', 'want to use',
      'tempted', 'pull to', 'want a drink', 'itching to',
    ],
    'fear': <String>[
      'scared', 'afraid', 'terrified', 'frightened', 'anxious', 'worried',
      'panic', 'fear',
    ],
    'guilt': <String>['guilty', 'guilt', 'regret', 'i let', 'my fault', 'feel bad'],
    'isolation': <String>[
      'alone', 'lonely', 'nobody', 'no one', 'no friends', 'isolated',
      'cant tell anyone',
    ],
    'anger': <String>['angry', 'furious', 'so mad', 'rage', 'hate', 'fed up'],
    'grief': <String>['died', 'passed away', 'lost my', 'miss him', 'miss her', 'funeral'],
    'ambivalence': <String>[
      'part of me', 'dont know if i want', 'not sure i want', 'but i like',
      'both', 'torn',
    ],
    'exhaustion': <String>['exhausted', 'tired of', 'worn out', 'drained'],
  };

  static const Set<String> _yes = <String>{
    'yes', 'yeah', 'yep', 'sure', 'okay', 'ok', 'please', 'go ahead', 'yes please',
    'alright', 'all right', 'i would', 'that would help',
  };
  static const Set<String> _no = <String>{
    'no', 'nope', 'nah', 'not now', 'no thanks', 'no thank you', 'not really',
    'rather not',
  };

  static EmotionIntent detect(String text) {
    final String n = CrisisDetector.normalize(text);
    final List<String> words = n.isEmpty ? <String>[] : n.split(' ');
    final String padded = ' $n ';
    final List<String> emotions = <String>[
      for (final MapEntry<String, List<String>> e in _emotion.entries)
        if (e.value.any((String k) => padded.contains(' $k ') || (k.contains(' ') && padded.contains(k)))) e.key,
    ];
    SupportIntent intent;
    bool has(List<String> any) => any.any((String k) => padded.contains(' $k '));
    if (_yes.contains(n)) {
      intent = SupportIntent.yes;
    } else if (_no.contains(n)) {
      intent = SupportIntent.no;
    } else if (has(<String>['thanks', 'thank you', 'jazakallah', 'shukran']) && words.length <= 6) {
      intent = SupportIntent.thanks;
    } else if (has(<String>['bye', 'goodbye', 'salam', 'good night', 'talk later', 'ttyl']) && words.length <= 5) {
      intent = SupportIntent.goodbye;
    } else if (has(<String>[
      'dose', 'dosage', 'how many pills', 'how much can i take', 'taper',
      'diagnose', 'am i an addict', 'am i addicted', 'do i have', 'what medication',
      'what can i take',
    ])) {
      intent = SupportIntent.askMedical;
    } else if (has(<String>[
      'haram', 'halal', 'sin', 'sinful', 'fatwa', 'forgiven', 'will allah forgive',
      'ruling', 'permissible', 'allowed',
    ])) {
      intent = SupportIntent.askRuling;
    } else if (has(<String>[
      'only friend', 'dont need anyone', 'better than my imam', 'better than a therapist',
      'act as my therapist', 'be my therapist', 'dont tell me to see anyone',
    ])) {
      intent = SupportIntent.onlyFriend;
    } else if (has(<String>[
      'are you human', 'are you real', 'are you a person', 'do you love me',
      'do you care', 'are you a robot', 'are you ai',
    ])) {
      intent = SupportIntent.askAboutAi;
    } else if (has(<String>[
      'what can i do', 'what should i do', 'any tips', 'help me', 'how do i stop',
      'how can i stop', 'how do i cope', 'what now', 'next step', 'what do i do',
    ])) {
      intent = SupportIntent.wantsStep;
    } else if (text.trim().endsWith('?') || has(<String>['what is', 'how does', 'why does', 'how long', 'does it'])) {
      intent = SupportIntent.askInfo;
    } else if (words.length <= 2) {
      intent = SupportIntent.unclear;
    } else {
      intent = SupportIntent.share;
    }
    return EmotionIntent(intent: intent, emotions: emotions, wordCount: words.length);
  }
}
