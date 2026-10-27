/// What happens AFTER a crisis card.
///
/// A person who has just been shown a crisis card may then type "ok",
/// "tonight", "later" or "yes". Those words carry no trigger phrase, so a
/// plain message reader treats them as ordinary, and a live model that was
/// never told about the crisis answers them as small talk. Both are wrong.
/// The conversation is therefore "latched" once a card has been shown (the
/// controllers keep the kind in memory, never on disk), and while it is
/// latched a very short reply gets a plain check instead: are you safe right
/// now? The latch also keeps every live model out of the conversation.
///
/// Pure Dart. CLINICIAN REVIEW NEEDED for every wording below.
library;

import 'crisis_detector.dart';

abstract final class CrisisLatch {
  static const Set<String> _ambiguousWords = <String>{
    'ok', 'okay', 'k', 'kk', 'yes', 'yeah', 'yep', 'yea', 'no', 'nope', 'nah',
    'tonight', 'later', 'soon', 'now', 'maybe', 'idk', 'sure', 'fine',
    'nothing', 'whatever', 'alright', 'tomorrow', 'today', 'hmm', 'mm', 'i',
    'dont', 'know', 'not', 'am', 'im', 'guess', 'then', 'right', 'never',
    'mind', 'nevermind', 'all',
  };

  /// A very short reply that could mean anything.
  static bool isAmbiguous(String text) {
    final String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return false;
    final List<String> words = n.split(' ');
    if (words.length > 4) return false;
    for (final String w in words) {
      if (!_ambiguousWords.contains(w)) return false;
    }
    return true;
  }

  static final RegExp _safeNow = RegExp(
    r'^(?:i am|im) safe(?: now| right now| today| tonight)?$',
  );

  /// True when the person says, in so many words, that they are safe.
  static bool saysSafe(String text) =>
      _safeNow.hasMatch(CrisisDetector.normalize(text));

  /// The plain check that follows an ambiguous reply while latched. [n] is
  /// how many checks this latch has already produced (it picks the wording,
  /// so the same sentence is not sent twice running). [child] uses a child's
  /// words.
  static String checkFor(CrisisKind kind, int n, {bool child = false}) {
    if (child) {
      const List<String> kids = <String>[
        'I am still here. Are you safe right now? You can answer with one '
            'word. If you are not sure, tell a grown-up you trust now, or '
            'use the help lines below.',
        'Thank you for staying. Before anything else: are you safe at this '
            'moment? If the answer is no, or maybe, please tell a grown-up '
            'you trust, or call or text a helpline below.',
        'I do not want to guess what you mean, so I will ask: are you in a '
            'safe place, and is someone with you? One word is enough.',
      ];
      return kids[n % kids.length];
    }
    if (kind == CrisisKind.substanceEmergency) {
      const List<String> medical = <String>[
        'I am here. Is everyone awake and breathing normally right now? If '
            'someone is hard to wake, breathing slowly, or having a seizure, '
            'call your local emergency number now and stay with them.',
        'Thank you for staying. Before anything else: is anyone in danger '
            'at this moment? If you are not sure, call your local emergency '
            'number, and I will stay right here.',
        'I do not want to guess what that means, so I will ask plainly: is '
            'the person safe and awake, and is someone with them? One word '
            'is enough.',
      ];
      return medical[n % medical.length];
    }
    const List<String> checks = <String>[
      'I am still here. Are you safe right now? You can answer in one word. '
          'If you are not sure, or tonight feels dangerous, call your local '
          'emergency number or one of the lines above.',
      'Thank you for staying. Before anything else: are you safe at this '
          'moment? If the answer is no, or maybe, please call the number for '
          'your country now, and I will stay right here.',
      'I do not want to guess what that means, so I will ask plainly: are '
          'you in a safe place right now, and is someone with you? One word '
          'is enough.',
    ];
    return checks[n % checks.length];
  }

  /// Said when the person says they are safe.
  static const String relief =
      'I am glad you are safe. I am here if that changes, and the help lines '
      'stay where they are. What would you like to do next?';
}
