import 'rotation.dart';
import 'support_pack.dart';
import '../../sakina/domain/crisis_detector.dart';

/// The everyday conversation: greetings by time of day, how-are-you, thanks,
/// goodbye, "I did not understand", a gentle "I do not know". Wording comes
/// from the conversation packs (many interchangeable variants per move and age
/// band) and is rotated so a line is never repeated within its gap.
abstract final class ConversationMoves {
  /// The move a short chit-chat message asks for, or null when it is not
  /// chit-chat (then the normal answering path goes on).
  static String? moveFor(String text, DateTime now) {
    final String n = CrisisDetector.normalize(text);
    if (n.isEmpty) return null;
    final int words = n.split(' ').length;
    bool hasAny(List<String> l) => l.any((String k) => ' $n '.contains(' $k '));
    if (words > 6) return null;
    if (hasAny(<String>['how are you', 'how r u', 'hows it going', 'how are you doing'])) {
      return 'how_are_you_reply';
    }
    // A bare "what?" or "I don't understand" is confusion. "What is zakat?"
    // is a question: it must reach the answers, never this line.
    if (n == 'what' ||
        n == 'huh' ||
        n == 'what do you mean' ||
        n == 'i dont understand' ||
        n == 'i do not understand' ||
        n == 'i dont get it' ||
        n == 'confused' ||
        n == 'im confused' ||
        n == 'i am confused') {
      return 'handle_confusion';
    }
    // "What is salam?" / "Is hi a greeting?" are questions about a word, not a
    // greeting: they go on to the answers.
    if (RegExp(r'\b(?:what|whats|how|why|when|where|who|which)\b|'
            r'^(?:is|are|can|could|do|does|did|should|will|would)\b')
        .hasMatch(n)) {
      return null;
    }
    if (hasAny(<String>['thanks', 'thank you', 'jazakallah', 'jazak allah', 'shukran'])) {
      return 'gratitude_receive';
    }
    if (hasAny(<String>['bye', 'goodbye', 'see you', 'talk later', 'good night', 'goodnight'])) {
      return 'goodbye';
    }
    if (hasAny(<String>['assalamu alaikum', 'assalamualaikum', 'salam', 'salaam', 'hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      final int h = now.hour;
      if (h < 12) return 'greet_morning';
      if (h < 17) return 'greet_afternoon';
      if (h < 21) return 'greet_evening';
      return 'greet_night';
    }
    return null;
  }

  /// One variant of [move] for [ageBand], rotated. Null when no conversation
  /// pack has one (the caller then does what it did before packs existed).
  static SupportSnippet? pick(
    String move,
    List<SupportPack> packs,
    SnippetRotator rotator, {
    String ageBand = 'adult',
    List<String> toneOrder = const <String>['warm'],
    String lang = 'en',
    bool allowDraft = true,
    Map<String, String> slots = const <String, String>{},
    DateTime? now,
  }) {
    final DateTime t = now ?? DateTime.now();
    final List<SupportSnippet> options = <SupportSnippet>[
      for (final SupportPack p in packs)
        if (p.kind == 'conversation' && !p.expiredAt(t))
          for (final SupportSnippet s in p.snippets)
            if (s.move == move &&
                s.matchesAge(ageBand) &&
                (allowDraft || s.shippable) &&
                s.fill(lang, slots) != null)
              s,
    ];
    return rotator.pick(
      options,
      toneOrder: toneOrder,
      text: (SupportSnippet s) => s.fill(lang, slots) ?? s.textIn(lang),
    );
  }
}
